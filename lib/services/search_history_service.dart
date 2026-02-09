import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class SearchHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Save a search query
  Future<void> saveSearch(String query) async {
    if (query.trim().isEmpty) return;

    final user = _auth.currentUser;
    final searchQuery = query.trim().toLowerCase();
    final timestamp = DateTime.now();

    // Save to Firestore if user is signed in (with timeout to prevent hanging)
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('search_history')
            .add({
          'query': searchQuery,
          'timestamp': Timestamp.fromDate(timestamp),
          'created_at': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 3), onTimeout: () {
          debugPrint('Firestore save timed out');
          throw Exception('Firestore timeout');
        });

        // Also update search count for this query
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('search_stats')
            .doc(searchQuery)
            .set({
          'query': searchQuery,
          'count': FieldValue.increment(1),
          'last_searched': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 3), onTimeout: () {
          debugPrint('Firestore stats save timed out');
          throw Exception('Firestore timeout');
        });
      } catch (e) {
        debugPrint('Error saving search to Firestore: $e');
      }
    }

    // Also save locally for offline access
    try {
      await _saveSearchLocally(searchQuery, timestamp);
    } catch (e) {
      debugPrint('Error saving search locally: $e');
    }
  }

  // Save search locally (fallback)
  Future<void> _saveSearchLocally(String query, DateTime timestamp) async {
    await init();
    if (_prefs == null) await init();
    
    final historyJson = _prefs!.getString(Constants.searchHistoryKey);
    List<Map<String, dynamic>> searches = [];
    
    if (historyJson != null) {
      final List<dynamic> decoded = json.decode(historyJson);
      searches = decoded.cast<Map<String, dynamic>>();
    }
    
    // Remove duplicate if exists
    searches.removeWhere((s) => s['query'] == query);
    
    // Add to beginning
    searches.insert(0, {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
    });
    
    // Keep only last 100 searches
    if (searches.length > 100) {
      searches.removeRange(100, searches.length);
    }
    
    await _prefs!.setString(
      Constants.searchHistoryKey,
      json.encode(searches),
    );
  }

  // Get search history
  Future<List<Map<String, dynamic>>> getSearchHistory({int limit = 50}) async {
    final user = _auth.currentUser;
    
    try {
      if (user != null) {
        // Try to get from Firestore first (with timeout)
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('search_history')
            .orderBy('timestamp', descending: true)
            .limit(limit)
            .get()
            .timeout(const Duration(seconds: 3), onTimeout: () {
              debugPrint('Firestore get history timed out');
              throw Exception('Firestore timeout');
            });

        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'query': data['query'] ?? '',
              'timestamp': (data['timestamp'] as Timestamp?)?.toDate().toIso8601String() ?? 
                          DateTime.now().toIso8601String(),
            };
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting search history from Firestore: $e');
    }

    // Fallback to local storage
    try {
      await init();
      final historyJson = _prefs!.getString(Constants.searchHistoryKey);
      if (historyJson == null) return [];
      
      final List<dynamic> decoded = json.decode(historyJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error decoding local search history: $e');
      // If JSON is corrupted, clear it and return empty list
      try {
        await _prefs?.remove(Constants.searchHistoryKey);
      } catch (_) {
        // Ignore errors when clearing
      }
      return [];
    }
  }

  // Get popular search terms (most searched)
  Future<List<Map<String, dynamic>>> getPopularSearches({int limit = 10}) async {
    final user = _auth.currentUser;
    
    try {
      if (user != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('search_stats')
            .orderBy('count', descending: true)
            .limit(limit)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'query': data['query'] ?? '',
            'count': data['count'] ?? 0,
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('Error getting popular searches: $e');
    }

    // Fallback: analyze local history
    final history = await getSearchHistory(limit: 100);
    final Map<String, int> queryCounts = {};
    
    for (final search in history) {
      final query = search['query'] as String? ?? '';
      queryCounts[query] = (queryCounts[query] ?? 0) + 1;
    }
    
    final sorted = queryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) => {
      'query': e.key,
      'count': e.value,
    }).toList();
  }

  // Extract keywords/categories from search queries
  Future<List<String>> extractCategoriesFromHistory({int limit = 20}) async {
    final popularSearches = await getPopularSearches(limit: limit);
    final categories = <String>{};
    
    // Common kid-friendly category keywords
    final categoryKeywords = {
      'alphabet': 'Alphabets',
      'abc': 'Alphabets',
      'letter': 'Alphabets',
      'number': 'Numbers',
      'counting': 'Numbers',
      'math': 'Numbers',
      'color': 'Colors',
      'colour': 'Colors',
      'shape': 'Shapes',
      'animal': 'Animals',
      'pet': 'Animals',
      'song': 'Music',
      'music': 'Music',
      'rhyme': 'Music',
      'nursery': 'Music',
      'story': 'Stories',
      'book': 'Stories',
      'cartoon': 'Cartoons',
      'animation': 'Cartoons',
      'science': 'Science',
      'experiment': 'Science',
      'art': 'Art & Craft',
      'craft': 'Art & Craft',
      'drawing': 'Art & Craft',
      'dance': 'Dance',
      'exercise': 'Exercise',
      'sport': 'Sports',
      'game': 'Games',
      'puzzle': 'Puzzles',
      'learning': 'Learning',
      'education': 'Education',
      'cooking': 'Cooking',
      'recipe': 'Cooking',
    };
    
    for (final search in popularSearches) {
      final query = (search['query'] as String? ?? '').toLowerCase();
      
      // Check if query matches any category keyword
      for (final entry in categoryKeywords.entries) {
        if (query.contains(entry.key)) {
          categories.add(entry.value);
          break;
        }
      }
      
      // Also add the query itself if it's a single word and looks like a category
      final words = query.split(' ');
      if (words.length == 1 && words[0].length > 3) {
        // Capitalize first letter
        final capitalized = words[0][0].toUpperCase() + words[0].substring(1);
        categories.add(capitalized);
      }
    }
    
    return categories.toList();
  }

  // Clear search history
  Future<void> clearSearchHistory() async {
    final user = _auth.currentUser;
    
    try {
      if (user != null) {
        // Clear Firestore
        final batch = _firestore.batch();
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('search_history')
            .get();
        
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        
        // Clear search stats
        final statsSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('search_stats')
            .get();
        
        final statsBatch = _firestore.batch();
        for (final doc in statsSnapshot.docs) {
          statsBatch.delete(doc.reference);
        }
        await statsBatch.commit();
      }
    } catch (e) {
      debugPrint('Error clearing Firestore search history: $e');
    }
    
    // Clear local storage
    await init();
    await _prefs!.remove(Constants.searchHistoryKey);
  }
}

