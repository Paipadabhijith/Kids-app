import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constants {
  // YouTube Data API v3 key loaded from .env file
  // Get it from: https://console.cloud.google.com/
  // Add it to .env file as: YOUTUBE_API_KEY=your_key_here
  static String get youtubeApiKey {
    try {
      final envKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';

      // Prefer key from .env if present and not the placeholder
      if (envKey.isNotEmpty && envKey != 'your_youtube_api_key_here') {
        return envKey;
      }

      // Fallback: hard-coded key provided for local testing ONLY.
      // NOTE: Before committing or sharing the repo, remove this fallback
      // and keep the key only in the .env file.
      const fallbackKey = 'AIzaSyAjrv50h1xxXY96CsJ2xvliYhMNpepyewo';
      return fallbackKey;
    } catch (e) {
      return '';
    }
  }
  
  static bool get hasValidApiKey {
    final key = youtubeApiKey;
    return key.isNotEmpty && key != 'your_youtube_api_key_here';
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
  static const String searchHistoryKey = 'search_history';
  
  // Break reminder defaults
  static const int defaultBreakIntervalMinutes = 30;
  static const int defaultBreakDurationMinutes = 5;
  
  // Kid-friendly categories with search queries
  static const List<Map<String, String>> kidCategories = [
    {'id': 'nursery_rhymes', 'title': 'Nursery Rhymes', 'query': 'nursery rhymes for kids', 'icon': 'music_note'},
    {'id': 'cartoons', 'title': 'Cartoons', 'query': 'cartoons for children safe', 'icon': 'tv'},
    {'id': 'learning_abc', 'title': 'ABCs & 123s', 'query': 'alphabet and numbers for kids learning', 'icon': 'abc'},
    {'id': 'animals', 'title': 'Animals', 'query': 'animals for kids educational', 'icon': 'pets'},
    {'id': 'stories', 'title': 'Stories', 'query': 'bedtime stories for kids', 'icon': 'auto_stories'},
    {'id': 'science', 'title': 'Science Fun', 'query': 'science experiments for kids easy', 'icon': 'science'},
    {'id': 'arts_crafts', 'title': 'Arts & Crafts', 'query': 'easy crafts for kids', 'icon': 'palette'},
    {'id': 'dancing', 'title': 'Dance Along', 'query': 'dance songs for kids', 'icon': 'directions_run'},
    {'id': 'nature', 'title': 'Nature', 'query': 'nature videos for children', 'icon': 'park'},
    {'id': 'cooking', 'title': 'Kids Cooking', 'query': 'easy cooking for kids recipes', 'icon': 'restaurant'},
    {'id': 'superheroes', 'title': 'Superheroes', 'query': 'superhero cartoons for kids', 'icon': 'flash_on'},
    {'id': 'dinosaurs', 'title': 'Dinosaurs', 'query': 'dinosaurs for kids educational', 'icon': 'egg'},
    {'id': 'space', 'title': 'Space', 'query': 'space videos for kids planets', 'icon': 'rocket_launch'},
    {'id': 'vehicles', 'title': 'Cars & Trucks', 'query': 'vehicles for kids trucks cars trains', 'icon': 'directions_car'},
    {'id': 'princess', 'title': 'Princess', 'query': 'princess stories for kids', 'icon': 'auto_awesome'},
    {'id': 'funny', 'title': 'Funny Videos', 'query': 'funny videos for kids clean', 'icon': 'sentiment_very_satisfied'},
  ];
  
  // Legacy YouTube category IDs (kept for compatibility)
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

