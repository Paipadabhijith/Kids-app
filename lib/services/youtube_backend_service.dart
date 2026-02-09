import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_model.dart';

/// Backend service that calls Firebase Functions instead of YouTube API directly
/// This provides caching, rate limiting, and auto-scaling
class YouTubeBackendService {
  // Change this to your Firebase Functions URL after deployment
  // Format: https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net
  static const String backendBaseUrl = 'https://us-central1-kids-attention-app.cloudfunctions.net';
  
  // Fallback to direct API if backend not configured
  static const bool useBackend = true; // Set to false to use direct API

  /// Search videos via backend
  Future<List<VideoModel>> searchVideos(String query, {int maxResults = 25}) async {
    if (!useBackend) {
      throw Exception('Backend service not enabled. Use YouTubeService instead.');
    }

    try {
      final uri = Uri.parse('$backendBaseUrl/youtubeSearch')
          .replace(queryParameters: {
            'q': query,
            'maxResults': maxResults.toString(),
          });

      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['error'] != null) {
          throw Exception('Backend Error: ${data['error']}');
        }
        
        final items = data['items'] as List? ?? [];
        return items.map((item) => VideoModel.fromJson(item)).toList();
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Unknown error';
        throw Exception('Failed to search videos (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      throw Exception('Error searching videos: $e');
    }
  }

  /// Get video details via backend
  Future<VideoModel?> getVideoDetails(String videoId) async {
    if (!useBackend) {
      throw Exception('Backend service not enabled');
    }

    try {
      final uri = Uri.parse('$backendBaseUrl/youtubeVideo')
          .replace(queryParameters: {'id': videoId});

      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['error'] != null) {
          throw Exception('Backend Error: ${data['error']}');
        }
        
        final items = data['items'] as List? ?? [];
        if (items.isEmpty) return null;
        
        return VideoModel.fromJson(items[0]);
      } else {
        throw Exception('Failed to get video details (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error getting video details: $e');
    }
  }

  /// Get trending kids shows via backend
  Future<List<VideoModel>> getTrendingKidsShows({int maxResults = 25}) async {
    try {
      final kidsQueries = [
        'kids shows for children',
        'educational videos for kids',
        'kids cartoons',
        'nursery rhymes for kids',
        'kids songs',
      ];
      
      final allVideos = <VideoModel>[];
      
      for (final query in kidsQueries) {
        try {
          final videos = await searchVideos(
            query,
            maxResults: (maxResults / kidsQueries.length).ceil() + 2,
          );
          allVideos.addAll(videos);
        } catch (e) {
          continue;
        }
      }
      
      // Remove duplicates
      final uniqueVideos = <String, VideoModel>{};
      for (final video in allVideos) {
        if (!uniqueVideos.containsKey(video.id)) {
          uniqueVideos[video.id] = video;
        }
      }
      
      // Sort by view count
      final sortedVideos = uniqueVideos.values.toList()
        ..sort((a, b) => (b.viewCount ?? 0).compareTo(a.viewCount ?? 0));
      
      return sortedVideos.take(maxResults).toList();
    } catch (e) {
      throw Exception('Error getting trending kids shows: $e');
    }
  }
}

