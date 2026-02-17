import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/video_model.dart';
import '../utils/constants.dart';

class YouTubeService {
  final String apiKey;
  static const Duration _requestTimeout = Duration(seconds: 10);

  YouTubeService({required this.apiKey});

  Future<http.Response> _getWithTimeout(Uri uri) {
    return http.get(uri).timeout(
      _requestTimeout,
      onTimeout: () {
        throw Exception('Request timed out. Please check your internet connection.');
      },
    );
  }

  /// Sanitize search query to remove inappropriate terms and add "for kids" modifier
  static String sanitizeSearchQuery(String query) {
    // Remove inappropriate terms
    final inappropriateTerms = [
      'violence', 'adult', 'explicit', 'nsfw', 'horror', 'scary',
      'drugs', 'alcohol', '18+', 'mature', 'curse', 'swear',
      'gun', 'weapon', 'kill', 'death', 'blood', 'gore',
    ];
    
    String sanitized = query.toLowerCase();
    
    // Remove inappropriate terms
    for (final term in inappropriateTerms) {
      sanitized = sanitized.replaceAll(term, '');
    }
    
    // Clean up extra spaces
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // If query is empty after sanitization, use default
    if (sanitized.isEmpty) {
      sanitized = 'kids videos';
    }
    
    // Add "for kids" modifier if not already present
    if (!sanitized.contains('kids') && 
        !sanitized.contains('children') && 
        !sanitized.contains('child')) {
      sanitized = '$sanitized for kids';
    }
    
    return sanitized;
  }

  Future<List<VideoModel>> searchVideos(String query, {int maxResults = 25}) async {
    try {
      // Sanitize the query first
      final sanitizedQuery = sanitizeSearchQuery(query);
      
      // Request more results to account for filtering
      final requestCount = (maxResults * 1.5).toInt();
      
      final uri = Uri.parse(
        '${Constants.youtubeBaseUrl}${Constants.searchEndpoint}'
        '?part=snippet'
        '&q=${Uri.encodeComponent(sanitizedQuery)}'
        '&type=video'
        '&videoEmbeddable=true'
        '&safeSearch=strict'
        '&maxResults=$requestCount'
        '&key=$apiKey',
      );

      final response = await _getWithTimeout(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check for API errors
        if (data['error'] != null) {
          final error = data['error'];
          final message = error['message'] ?? 'Unknown API error';
          throw Exception('YouTube API Error: $message');
        }
        
        final items = data['items'] as List? ?? [];
        
        return items.map((item) => VideoModel.fromJson(item)).toList();
      } else {
        String errorMessage = 'Unknown error';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        } catch (_) {
          // If JSON decode fails, use default message
        }
        throw Exception('Failed to search videos (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      throw Exception('Error searching videos: $e');
    }
  }

  Future<List<VideoModel>> getVideosByCategory(String categoryId, {int maxResults = 25}) async {
    try {
      final uri = Uri.parse(
        '${Constants.youtubeBaseUrl}${Constants.searchEndpoint}'
        '?part=snippet'
        '&videoCategoryId=$categoryId'
        '&type=video'
        '&videoEmbeddable=true'
        '&safeSearch=strict'
        '&maxResults=$maxResults'
        '&order=viewCount'
        '&key=$apiKey',
      );

      final response = await _getWithTimeout(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check for API errors
        if (data['error'] != null) {
          final error = data['error'];
          final message = error['message'] ?? 'Unknown API error';
          throw Exception('YouTube API Error: $message');
        }
        
        final items = data['items'] as List? ?? [];
        
        return items.map((item) => VideoModel.fromJson(item)).toList();
      } else {
        String errorMessage = 'Unknown error';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        } catch (_) {
          // If JSON decode fails, use default message
        }
        throw Exception('Failed to get videos by category (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      throw Exception('Error getting videos by category: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final uri = Uri.parse(
        '${Constants.youtubeBaseUrl}${Constants.categoriesEndpoint}'
        '?part=snippet'
        '&regionCode=US'
        '&key=$apiKey',
      );

      final response = await _getWithTimeout(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];
        
        return items.map((item) {
          final snippet = item['snippet'] ?? {};
          return {
            'id': item['id'] ?? '',
            'title': snippet['title'] ?? '',
          };
        }).toList();
      } else {
        // Return default categories if API fails
        return Constants.categoryNames.entries
            .map((e) => {'id': e.key, 'title': e.value})
            .toList();
      }
    } catch (e) {
      // Return default categories on error
      return Constants.categoryNames.entries
          .map((e) => {'id': e.key, 'title': e.value})
          .toList();
    }
  }

  Future<VideoModel?> getVideoDetails(String videoId) async {
    try {
      final uri = Uri.parse(
        '${Constants.youtubeBaseUrl}${Constants.videosEndpoint}'
        '?part=snippet,contentDetails,statistics'
        '&id=$videoId'
        '&key=$apiKey',
      );

      final response = await _getWithTimeout(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List?;
        
        if (items != null && items.isNotEmpty) {
          final item = items[0];
          final snippet = item['snippet'] ?? {};
          final contentDetails = item['contentDetails'] ?? {};
          final statistics = item['statistics'] ?? {};
          
          // Check for age restriction
          final contentRating = snippet['contentRating'] ?? {};
          final ytRating = contentRating['ytRating'] ?? '';
          
          // Block age-restricted content
          if (ytRating == 'ytAgeRestricted') {
            return null; // Don't return age-restricted videos
          }
          
          return VideoModel(
            id: videoId,
            title: snippet['title'] ?? '',
            description: snippet['description'] ?? '',
            thumbnailUrl: snippet['thumbnails']?['high']?['url'] ?? '',
            channelTitle: snippet['channelTitle'] ?? '',
            duration: contentDetails['duration'],
            publishedAt: snippet['publishedAt'] != null
                ? DateTime.tryParse(snippet['publishedAt'])
                : null,
            viewCount: statistics['viewCount'] != null
                ? int.tryParse(statistics['viewCount'])
                : null,
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get trending kids shows by searching popular kids content
  Future<List<VideoModel>> getTrendingKidsShows({int maxResults = 25}) async {
    try {
      // Reduced to 2 queries for faster loading
      final kidsQueries = [
        'popular kids shows educational',
        'trending kids cartoons nursery rhymes',
      ];
      
      final allVideos = <VideoModel>[];
      
      // Fetch each query in parallel to reduce end-to-end latency.
      final queryResults = await Future.wait(
        kidsQueries.map((query) async {
          try {
            return await searchVideos(
              query,
              maxResults: (maxResults / kidsQueries.length).ceil() + 5,
            );
          } catch (e) {
            debugPrint('Query failed: $query - $e');
            return <VideoModel>[];
          }
        }),
      );
      for (final videos in queryResults) {
        allVideos.addAll(videos);
      }
      
      // Remove duplicates based on video ID
      final uniqueVideos = <String, VideoModel>{};
      for (final video in allVideos) {
        if (!uniqueVideos.containsKey(video.id)) {
          uniqueVideos[video.id] = video;
        }
      }
      
      // Sort by view count (most viewed = most trending)
      final sortedVideos = uniqueVideos.values.toList()
        ..sort((a, b) => (b.viewCount ?? 0).compareTo(a.viewCount ?? 0));
      
      return sortedVideos.take(maxResults).toList();
    } catch (e) {
      throw Exception('Error getting trending kids shows: $e');
    }
  }
}

