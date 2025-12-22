import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist_model.dart';
import '../models/settings_model.dart';
import '../models/video_model.dart';
import '../utils/constants.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Playlists
  Future<List<PlaylistModel>> getPlaylists() async {
    if (_prefs == null) await init();
    final playlistsJson = _prefs!.getString(Constants.playlistsKey);
    if (playlistsJson == null) return [];
    
    final List<dynamic> decoded = json.decode(playlistsJson);
    return decoded.map((json) => PlaylistModel.fromJson(json)).toList();
  }

  Future<void> savePlaylists(List<PlaylistModel> playlists) async {
    if (_prefs == null) await init();
    final playlistsJson = json.encode(
      playlists.map((p) => p.toJson()).toList(),
    );
    await _prefs!.setString(Constants.playlistsKey, playlistsJson);
  }

  Future<void> addPlaylist(PlaylistModel playlist) async {
    final playlists = await getPlaylists();
    playlists.add(playlist);
    await savePlaylists(playlists);
  }

  Future<void> updatePlaylist(PlaylistModel playlist) async {
    final playlists = await getPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlist.id);
    if (index != -1) {
      playlists[index] = playlist;
      await savePlaylists(playlists);
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final playlists = await getPlaylists();
    playlists.removeWhere((p) => p.id == playlistId);
    await savePlaylists(playlists);
  }

  // Settings
  Future<SettingsModel> getSettings() async {
    if (_prefs == null) await init();
    final settingsJson = _prefs!.getString(Constants.settingsKey);
    if (settingsJson == null) return SettingsModel();
    
    return SettingsModel.fromJson(json.decode(settingsJson));
  }

  Future<void> saveSettings(SettingsModel settings) async {
    if (_prefs == null) await init();
    final settingsJson = json.encode(settings.toJson());
    await _prefs!.setString(Constants.settingsKey, settingsJson);
  }

  // Watch History
  Future<List<VideoModel>> getWatchHistory() async {
    if (_prefs == null) await init();
    final historyJson = _prefs!.getString(Constants.watchHistoryKey);
    if (historyJson == null) return [];
    
    final List<dynamic> decoded = json.decode(historyJson);
    return decoded.map((json) => VideoModel.fromJson(json)).toList();
  }

  Future<void> addToWatchHistory(VideoModel video) async {
    final history = await getWatchHistory();
    // Remove if already exists (to move to top)
    history.removeWhere((v) => v.id == video.id);
    // Add to beginning
    history.insert(0, video);
    // Keep only last 100 videos
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    
    if (_prefs == null) await init();
    final historyJson = json.encode(
      history.map((v) => v.toJson()).toList(),
    );
    await _prefs!.setString(Constants.watchHistoryKey, historyJson);
  }

  Future<void> clearWatchHistory() async {
    if (_prefs == null) await init();
    await _prefs!.remove(Constants.watchHistoryKey);
  }

  // Daily Usage Tracking
  Future<Map<String, dynamic>> getDailyUsage() async {
    if (_prefs == null) await init();
    final usageJson = _prefs!.getString(Constants.dailyUsageKey);
    if (usageJson == null) {
      return {
        'date': DateTime.now().toIso8601String().split('T')[0],
        'minutesUsed': 0,
      };
    }
    
    return json.decode(usageJson);
  }

  Future<void> updateDailyUsage(int minutesUsed) async {
    if (_prefs == null) await init();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final usage = await getDailyUsage();
    
    // Reset if it's a new day
    if (usage['date'] != today) {
      usage['date'] = today;
      usage['minutesUsed'] = minutesUsed;
    } else {
      usage['minutesUsed'] = minutesUsed;
    }
    
    final usageJson = json.encode(usage);
    await _prefs!.setString(Constants.dailyUsageKey, usageJson);
    
    // Also update weekly usage
    await updateWeeklyUsage(today, minutesUsed);
  }

  Future<void> resetDailyUsage() async {
    if (_prefs == null) await init();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final usage = {
      'date': today,
      'minutesUsed': 0,
    };
    await _prefs!.setString(Constants.dailyUsageKey, json.encode(usage));
  }

  // Weekly Usage Tracking
  Future<Map<String, dynamic>> getWeeklyUsage() async {
    if (_prefs == null) await init();
    final usageJson = _prefs!.getString(Constants.weeklyUsageKey);
    if (usageJson == null) {
      return {
        'weekStart': _getWeekStartDate().toIso8601String().split('T')[0],
        'dailyUsage': <String, int>{},
      };
    }
    
    final data = json.decode(usageJson) as Map<String, dynamic>;
    final weekStart = _getWeekStartDate().toIso8601String().split('T')[0];
    
    // Reset if new week
    if (data['weekStart'] != weekStart) {
      return {
        'weekStart': weekStart,
        'dailyUsage': <String, int>{},
      };
    }
    
    return data;
  }

  Future<void> updateWeeklyUsage(String date, int minutesToAdd) async {
    if (_prefs == null) await init();
    final weeklyData = await getWeeklyUsage();
    final dailyUsage = Map<String, dynamic>.from(weeklyData['dailyUsage'] ?? {});
    final currentMinutes = dailyUsage[date] as int? ?? 0;
    dailyUsage[date] = currentMinutes + minutesToAdd;
    
    weeklyData['dailyUsage'] = dailyUsage;
    await _prefs!.setString(Constants.weeklyUsageKey, json.encode(weeklyData));
  }

  DateTime _getWeekStartDate() {
    final now = DateTime.now();
    final weekday = now.weekday;
    return now.subtract(Duration(days: weekday - 1));
  }

  // Curated Videos
  Future<List<VideoModel>> getCuratedVideos() async {
    if (_prefs == null) await init();
    final curatedJson = _prefs!.getString(Constants.curatedVideosKey);
    if (curatedJson == null) return [];
    
    final List<dynamic> decoded = json.decode(curatedJson);
    return decoded.map((json) => VideoModel.fromJson(json)).toList();
  }

  Future<void> saveCuratedVideos(List<VideoModel> videos) async {
    if (_prefs == null) await init();
    final curatedJson = json.encode(
      videos.map((v) => v.toJson()).toList(),
    );
    await _prefs!.setString(Constants.curatedVideosKey, curatedJson);
  }

  Future<void> addCuratedVideo(VideoModel video) async {
    final curated = await getCuratedVideos();
    if (!curated.any((v) => v.id == video.id)) {
      curated.add(video);
      await saveCuratedVideos(curated);
    }
  }

  Future<void> removeCuratedVideo(String videoId) async {
    final curated = await getCuratedVideos();
    curated.removeWhere((v) => v.id == videoId);
    await saveCuratedVideos(curated);
  }
}

