import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../models/video_model.dart';
import '../utils/constants.dart';
import 'api_key_service.dart';
import 'storage_service.dart';

class YouTubeService {
  final ApiKeyService _keyService = ApiKeyService();
  final StorageService _storageService = StorageService();
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const Duration _searchCacheTtl = Duration(hours: 6);
  static const Duration _categoryCacheTtl = Duration(hours: 6);
  static const Duration _trendingCacheTtl = Duration(hours: 12);
  static const Duration _videoDetailsCacheTtl = Duration(hours: 24);
  static const Duration _categoriesListCacheTtl = Duration(days: 7);

  // Keep constructor compatible with existing code
  YouTubeService({String? apiKey}) {
    // If apiKey provided, ignore it (we use ApiKeyService now)
    // This maintains backward compatibility
  }

  Future<http.Response> _getWithTimeout(Uri uri) {
    return http.get(uri).timeout(
      _requestTimeout,
      onTimeout: () {
        throw Exception('Request timed out. Please check your internet connection.');
      },
    );
  }

  Future<http.Response> _makeRequestWithRetry(String baseUrl) async {
    int attempts = 0;
    final maxAttempts = _keyService.hasNextKey() ? 3 : 1;
    
    while (attempts < maxAttempts) {
      try {
        // Get current API key
        final currentKey = _keyService.getCurrentKey();
        if (currentKey.isEmpty) {
          throw Exception('No API key available');
        }
        
        // Build full URL with API key
        final uri = Uri.parse('$baseUrl&key=${Uri.encodeComponent(currentKey)}');
        
        debugPrint('API Request: ${uri.toString().replaceAll(currentKey, 'KEY_HIDDEN')}');
        
        final response = await _getWithTimeout(uri);
        
        debugPrint('API Response status: ${response.statusCode}');
        
        // Check for quota errors
        if (response.statusCode == 403) {
          try {
            final body = json.decode(response.body);
            final errorReason = body['error']?['errors']?[0]?['reason'] ?? '';
            final errorMessage = body['error']?['message']?.toString().toLowerCase() ?? '';
            
            if (errorReason == 'quotaExceeded' || errorMessage.contains('quota')) {
              debugPrint('Quota exceeded for current key, attempting rotation...');
              
              if (_keyService.hasNextKey() && await _keyService.rotateToNextKey()) {
                attempts++;
                continue; // Retry with new key
              } else {
                throw Exception('YouTube API quota exceeded. All keys exhausted.');
              }
            }
          } catch (e) {
            // If JSON parsing fails, check error string
            if (response.body.toLowerCase().contains('quota')) {
              if (_keyService.hasNextKey() && await _keyService.rotateToNextKey()) {
                attempts++;
                continue;
              }
            }
          }
        }
        
        return response;
      } catch (e) {
        if (_keyService.isQuotaError(e) && _keyService.hasNextKey() && attempts < maxAttempts - 1) {
          if (await _keyService.rotateToNextKey()) {
            attempts++;
            continue;
          }
        }
        rethrow;
      }
    }
    
    throw Exception('Failed after $maxAttempts attempts');
  }

  String _cacheKey(String prefix, String raw) {
    final digest = md5.convert(utf8.encode(raw)).toString();
    return '${prefix}_$digest';
  }

  VideoModel _videoFromCache(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      channelTitle: json['channelTitle']?.toString() ?? '',
      duration: json['duration']?.toString(),
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      viewCount: json['viewCount'] is int
          ? json['viewCount'] as int
          : int.tryParse(json['viewCount']?.toString() ?? ''),
    );
  }

  Future<List<VideoModel>?> _getCachedVideoList(
    String cacheKey, {
    required Duration maxAge,
  }) async {
    final cached = await _storageService.getCachedApiData(cacheKey, maxAge: maxAge);
    if (cached == null) return null;
    final rawVideos = cached['videos'] as List?;
    if (rawVideos == null) return null;
    final videos = <VideoModel>[];
    for (final item in rawVideos) {
      if (item is Map) {
        videos.add(_videoFromCache(Map<String, dynamic>.from(item)));
      }
    }
    return videos;
  }

  Future<void> _setCachedVideoList(String cacheKey, List<VideoModel> videos) async {
    await _storageService.setCachedApiData(cacheKey, {
      'videos': videos.map((video) => video.toJson()).toList(),
    });
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
      final cacheKey = _cacheKey('search', '$sanitizedQuery|$requestCount');
      final cached = await _getCachedVideoList(
        cacheKey,
        maxAge: _searchCacheTtl,
      );
      if (cached != null) {
        return cached;
      }
      
      final baseUrl = '${Constants.youtubeBaseUrl}${Constants.searchEndpoint}'
        '?part=snippet'
        '&q=${Uri.encodeComponent(sanitizedQuery)}'
        '&type=video'
        '&videoEmbeddable=true'
        '&safeSearch=strict'
        '&maxResults=$requestCount';

      final response = await _makeRequestWithRetry(baseUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check for API errors
        if (data['error'] != null) {
          final error = data['error'];
          final message = error['message'] ?? 'Unknown API error';
          debugPrint('API Error: $message');
          throw Exception('YouTube API Error: $message');
        }
        
        final items = data['items'] as List? ?? [];
        debugPrint('API returned ${items.length} items for query: $query');
        final videos = items.map((item) => VideoModel.fromJson(item)).toList();
        await _setCachedVideoList(cacheKey, videos);
        return videos;
      } else {
        String errorMessage = 'Unknown error';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error']?['message'] ?? 'Unknown error';
          debugPrint('API Error: $errorMessage');
        } catch (_) {
          // If JSON decode fails, use default message
        }
        throw Exception('Failed to search videos (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      debugPrint('Error in searchVideos: $e');
      throw Exception('Error searching videos: $e');
    }
  }

  Future<List<VideoModel>> getVideosByCategory(String categoryId, {int maxResults = 25}) async {
    try {
      final cacheKey = _cacheKey('category_videos', '$categoryId|$maxResults');
      final cached = await _getCachedVideoList(
        cacheKey,
        maxAge: _categoryCacheTtl,
      );
      if (cached != null) {
        return cached;
      }

      final baseUrl = '${Constants.youtubeBaseUrl}${Constants.searchEndpoint}'
        '?part=snippet'
        '&videoCategoryId=$categoryId'
        '&type=video'
        '&videoEmbeddable=true'
        '&safeSearch=strict'
        '&maxResults=$maxResults'
        '&order=viewCount';

      final response = await _makeRequestWithRetry(baseUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check for API errors
        if (data['error'] != null) {
          final error = data['error'];
          final message = error['message'] ?? 'Unknown API error';
          throw Exception('YouTube API Error: $message');
        }
        
        final items = data['items'] as List? ?? [];
        final videos = items.map((item) => VideoModel.fromJson(item)).toList();
        await _setCachedVideoList(cacheKey, videos);
        return videos;
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
      const cacheKey = 'categories_list';
      final cached = await _storageService.getCachedApiData(
        cacheKey,
        maxAge: _categoriesListCacheTtl,
      );
      if (cached != null) {
        final rawItems = cached['items'] as List?;
        if (rawItems != null) {
          return rawItems
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }

      final baseUrl = '${Constants.youtubeBaseUrl}${Constants.categoriesEndpoint}'
        '?part=snippet'
        '&regionCode=US';

      final response = await _makeRequestWithRetry(baseUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];
        
        final categories = items.map((item) {
          final snippet = item['snippet'] ?? {};
          return {
            'id': item['id'] ?? '',
            'title': snippet['title'] ?? '',
          };
        }).toList();
        await _storageService.setCachedApiData(cacheKey, {'items': categories});
        return categories;
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
      final cacheKey = _cacheKey('video_details', videoId);
      final cached = await _storageService.getCachedApiData(
        cacheKey,
        maxAge: _videoDetailsCacheTtl,
      );
      if (cached != null && cached['video'] is Map) {
        return _videoFromCache(Map<String, dynamic>.from(cached['video'] as Map));
      }

      final baseUrl = '${Constants.youtubeBaseUrl}${Constants.videosEndpoint}'
        '?part=snippet,contentDetails,statistics'
        '&id=$videoId';

      final response = await _makeRequestWithRetry(baseUrl);

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
          
          final video = VideoModel(
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
          await _storageService.setCachedApiData(cacheKey, {'video': video.toJson()});
          return video;
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
      final cacheKey = _cacheKey('trending_kids', '$maxResults');
      final cached = await _getCachedVideoList(
        cacheKey,
        maxAge: _trendingCacheTtl,
      );
      if (cached != null) {
        return cached;
      }

      // Use single query to reduce API calls
      final kidsQueries = [
        'popular kids shows educational',
      ];
      
      final allVideos = <VideoModel>[];
      
      // Fetch single query to reduce API calls
      try {
        final videos = await searchVideos(
          kidsQueries[0],
          maxResults: maxResults + 5,
        );
        allVideos.addAll(videos);
      } catch (e) {
        debugPrint('Query failed: ${kidsQueries[0]} - $e');
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
      
      final result = sortedVideos.take(maxResults).toList();
      await _setCachedVideoList(cacheKey, result);
      return result;
    } catch (e) {
      throw Exception('Error getting trending kids shows: $e');
    }
  }
}
