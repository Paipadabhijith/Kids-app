import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist_model.dart';
import '../models/settings_model.dart';
import '../models/video_model.dart';
import '../models/child_profile_model.dart';
import '../utils/constants.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static final StreamController<ChildProfileModel?> _activeProfileController =
      StreamController<ChildProfileModel?>.broadcast();
  static const String _apiCachePrefix = 'api_cache_';

  static Stream<ChildProfileModel?> get activeProfileChanges =>
      _activeProfileController.stream;

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

  Future<String?> getThemeModePreference() async {
    if (_prefs == null) await init();
    return _prefs!.getString(Constants.themeModeKey);
  }

  Future<void> saveThemeModePreference(String themeMode) async {
    if (_prefs == null) await init();
    await _prefs!.setString(Constants.themeModeKey, themeMode);
  }

  // Watch History
  Future<List<VideoModel>> getWatchHistory({String? profileId}) async {
    if (_prefs == null) await init();
    final scopedKey = _getWatchHistoryKey(profileId);
    String? historyJson = _prefs!.getString(scopedKey);
    // Backward compatibility: if this profile has no history yet, reuse legacy shared history.
    historyJson ??= profileId != null ? _prefs!.getString(Constants.watchHistoryKey) : null;
    if (historyJson == null) return [];
    
    final List<dynamic> decoded = json.decode(historyJson);
    return decoded.map((json) => VideoModel.fromJson(json)).toList();
  }

  Future<void> addToWatchHistory(VideoModel video, {String? profileId}) async {
    final history = await getWatchHistory(profileId: profileId);
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
    await _prefs!.setString(_getWatchHistoryKey(profileId), historyJson);
  }

  Future<void> clearWatchHistory({String? profileId}) async {
    if (_prefs == null) await init();
    await _prefs!.remove(_getWatchHistoryKey(profileId));
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

  Future<int> getTodayUsage() async {
    final usage = await getDailyUsage();
    return usage['minutesUsed'] as int? ?? 0;
  }

  Future<int> getUsageForDate(DateTime date) async {
    if (_prefs == null) await init();
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final weeklyUsage = await getWeeklyUsage();
    return weeklyUsage[dateKey] as int? ?? 0;
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

  Future<void> updateWeeklyUsage(String date, int totalMinutesForDay) async {
    if (_prefs == null) await init();
    final weeklyData = await getWeeklyUsage();
    final dailyUsage = Map<String, dynamic>.from(weeklyData['dailyUsage'] ?? {});
    // totalMinutesForDay is the absolute total for the day, not an incremental delta.
    dailyUsage[date] = totalMinutesForDay;
    
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

  // Child Profiles
  Future<List<ChildProfileModel>> getChildProfiles() async {
    if (_prefs == null) await init();
    final profilesJson = _prefs!.getString(Constants.childProfilesKey);
    if (profilesJson == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(profilesJson);
      return decoded.map((json) => ChildProfileModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveChildProfiles(List<ChildProfileModel> profiles) async {
    if (_prefs == null) await init();
    final profilesJson = json.encode(
      profiles.map((p) => p.toJson()).toList(),
    );
    await _prefs!.setString(Constants.childProfilesKey, profilesJson);
    _emitActiveProfile(profiles);
  }

  Future<ChildProfileModel?> getActiveProfile() async {
    final profiles = await getChildProfiles();
    try {
      return profiles.firstWhere((p) => p.isActive);
    } catch (e) {
      return null;
    }
  }

  String _getWatchHistoryKey(String? profileId) {
    if (profileId == null || profileId.isEmpty) return Constants.watchHistoryKey;
    return '${Constants.watchHistoryKey}_$profileId';
  }

  void _emitActiveProfile(List<ChildProfileModel> profiles) {
    try {
      final active = profiles.firstWhere((p) => p.isActive);
      _activeProfileController.add(active);
    } catch (_) {
      _activeProfileController.add(null);
    }
  }

  // Generic API cache helpers (TTL-based)
  Future<Map<String, dynamic>?> getCachedApiData(
    String cacheKey, {
    required Duration maxAge,
  }) async {
    if (_prefs == null) await init();
    final raw = _prefs!.getString('$_apiCachePrefix$cacheKey');
    if (raw == null) return null;
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final timestampMs = decoded['timestampMs'] as int?;
      if (timestampMs == null) return null;
      final age = DateTime.now().millisecondsSinceEpoch - timestampMs;
      if (age > maxAge.inMilliseconds) {
        await _prefs!.remove('$_apiCachePrefix$cacheKey');
        return null;
      }
      return decoded['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<void> setCachedApiData(String cacheKey, Map<String, dynamic> data) async {
    if (_prefs == null) await init();
    final payload = <String, dynamic>{
      'timestampMs': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    };
    await _prefs!.setString('$_apiCachePrefix$cacheKey', json.encode(payload));
  }
}

