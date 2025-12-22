import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_model.dart';
import '../utils/constants.dart';

class YouTubeService {
  final String apiKey;

  YouTubeService({required this.apiKey});

  Future<List<VideoModel>> searchVideos(String query, {int maxResults = 25}) async {
    try {
      final uri = Uri.parse(
        '${Constants.youtubeBaseUrl}${Constants.searchEndpoint}'
        '?part=snippet'
        '&q=${Uri.encodeComponent(query)}'
        '&type=video'
        '&videoEmbeddable=true'
        '&safeSearch=strict'
        '&maxResults=$maxResults'
        '&key=$apiKey',
      );

      final response = await http.get(uri);

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
        '&maxResults=$maxResults'
        '&order=viewCount'
        '&key=$apiKey',
      );

      final response = await http.get(uri);

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

      final response = await http.get(uri);

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

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List?;
        
        if (items != null && items.isNotEmpty) {
          final item = items[0];
          final snippet = item['snippet'] ?? {};
          final contentDetails = item['contentDetails'] ?? {};
          final statistics = item['statistics'] ?? {};
          
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
}

