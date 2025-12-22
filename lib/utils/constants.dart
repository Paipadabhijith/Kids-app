import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constants {
  // YouTube Data API v3 key loaded from .env file
  // Get it from: https://console.cloud.google.com/
  // Add it to .env file as: YOUTUBE_API_KEY=your_key_here
  static String get youtubeApiKey {
    final key = dotenv.env['YOUTUBE_API_KEY'] ?? '';
    if (key.isEmpty) {
      throw Exception(
        'YOUTUBE_API_KEY is not set in .env file. '
        'Please create a .env file with your YouTube API key. '
        'See .env.example for reference.'
      );
    }
    return key;
  }
  
  static const String youtubeBaseUrl = 'https://www.googleapis.com/youtube/v3';
  
  // YouTube API endpoints
  static const String searchEndpoint = '/search';
  static const String videosEndpoint = '/videos';
  static const String categoriesEndpoint = '/videoCategories';
  
  // App constants
  static const int maxSearchResults = 50;
  static const int defaultTimeLimitMinutes = 60;
  
  // Storage keys
  static const String playlistsKey = 'playlists';
  static const String settingsKey = 'settings';
  static const String watchHistoryKey = 'watch_history';
  static const String dailyUsageKey = 'daily_usage';
  static const String weeklyUsageKey = 'weekly_usage';
  static const String curatedVideosKey = 'curated_videos';
  
  // Break reminder defaults
  static const int defaultBreakIntervalMinutes = 30;
  static const int defaultBreakDurationMinutes = 5;
  
  // YouTube category IDs (common categories)
  static const Map<String, String> categoryNames = {
    '1': 'Film & Animation',
    '2': 'Autos & Vehicles',
    '10': 'Music',
    '15': 'Pets & Animals',
    '17': 'Sports',
    '19': 'Travel & Events',
    '20': 'Gaming',
    '22': 'People & Blogs',
    '23': 'Comedy',
    '24': 'Entertainment',
    '25': 'News & Politics',
    '26': 'Howto & Style',
    '27': 'Education',
    '28': 'Science & Technology',
  };
}

