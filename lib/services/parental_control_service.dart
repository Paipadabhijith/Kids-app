import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/settings_model.dart';
import '../models/video_model.dart';
import '../services/storage_service.dart';

class ParentalControlService {
  final StorageService _storageService = StorageService();

  Future<SettingsModel> getSettings() async {
    return await _storageService.getSettings();
  }

  Future<void> saveSettings(SettingsModel settings) async {
    await _storageService.saveSettings(settings);
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> verifyPassword(String password, String? storedHash) async {
    if (storedHash == null) return false;
    final hashedPassword = hashPassword(password);
    return hashedPassword == storedHash;
  }

  Future<bool> checkPassword(String password) async {
    final settings = await getSettings();
    if (settings.parentPasswordHash == null) return true;
    return await verifyPassword(password, settings.parentPasswordHash);
  }

  Future<void> setPassword(String password) async {
    final settings = await getSettings();
    final hashedPassword = hashPassword(password);
    await saveSettings(settings.copyWith(parentPasswordHash: hashedPassword));
  }

  Future<bool> isTimeLimitExceeded() async {
    final settings = await getSettings();
    if (!settings.parentalControlsEnabled) return false;
    if (settings.dailyTimeLimitMinutes == null) return false;

    final usage = await _storageService.getDailyUsage();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Reset if new day
    if (usage['date'] != today) {
      await _storageService.resetDailyUsage();
      return false;
    }

    final minutesUsed = usage['minutesUsed'] as int? ?? 0;
    return minutesUsed >= settings.dailyTimeLimitMinutes!;
  }

  Future<int> getRemainingTimeMinutes() async {
    final settings = await getSettings();
    if (!settings.parentalControlsEnabled) return -1; // No limit
    if (settings.dailyTimeLimitMinutes == null) return -1;

    final usage = await _storageService.getDailyUsage();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Reset if new day
    if (usage['date'] != today) {
      await _storageService.resetDailyUsage();
      return settings.dailyTimeLimitMinutes!;
    }

    final minutesUsed = usage['minutesUsed'] as int? ?? 0;
    final remaining = settings.dailyTimeLimitMinutes! - minutesUsed;
    return remaining > 0 ? remaining : 0;
  }

  Future<void> recordVideoWatch(int minutesWatched) async {
    final settings = await getSettings();
    if (!settings.parentalControlsEnabled) return;

    final usage = await _storageService.getDailyUsage();
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Reset if new day
    if (usage['date'] != today) {
      await _storageService.resetDailyUsage();
      usage['date'] = today;
      usage['minutesUsed'] = 0;
    }

    final currentMinutes = usage['minutesUsed'] as int? ?? 0;
    await _storageService.updateDailyUsage(currentMinutes + minutesWatched);
  }

  Future<bool> isVideoAllowed(VideoModel video) async {
    final settings = await getSettings();
    if (!settings.parentalControlsEnabled) return true;

    // Check blocked keywords
    final titleLower = video.title.toLowerCase();
    final descriptionLower = video.description.toLowerCase();
    
    for (final keyword in settings.blockedKeywords) {
      if (titleLower.contains(keyword.toLowerCase()) ||
          descriptionLower.contains(keyword.toLowerCase())) {
        return false;
      }
    }

    // Note: Category filtering would require additional API calls
    // This is a simplified version
    
    return true;
  }

  Future<void> enableParentalControls({
    int? dailyTimeLimitMinutes,
    List<String>? blockedKeywords,
    List<String>? blockedCategories,
    String? password,
    bool? breakRemindersEnabled,
    int? breakIntervalMinutes,
    int? breakDurationMinutes,
  }) async {
    final settings = await getSettings();
    
    String? passwordHash;
    if (password != null && password.isNotEmpty) {
      passwordHash = hashPassword(password);
    }

    final newSettings = settings.copyWith(
      parentalControlsEnabled: true,
      dailyTimeLimitMinutes: dailyTimeLimitMinutes ?? settings.dailyTimeLimitMinutes,
      blockedKeywords: blockedKeywords ?? settings.blockedKeywords,
      blockedCategories: blockedCategories ?? settings.blockedCategories,
      parentPasswordHash: passwordHash ?? settings.parentPasswordHash,
      breakRemindersEnabled: breakRemindersEnabled ?? settings.breakRemindersEnabled,
      breakIntervalMinutes: breakIntervalMinutes ?? settings.breakIntervalMinutes,
      breakDurationMinutes: breakDurationMinutes ?? settings.breakDurationMinutes,
    );

    await saveSettings(newSettings);
  }

  Future<void> disableParentalControls() async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(parentalControlsEnabled: false));
  }

  Future<bool> shouldShowBreakReminder(int minutesWatched) async {
    final settings = await getSettings();
    if (!settings.breakRemindersEnabled) return false;
    if (settings.breakIntervalMinutes == null) return false;

    // Check if minutes watched is a multiple of break interval
    return minutesWatched > 0 && 
           minutesWatched % settings.breakIntervalMinutes! == 0;
  }

  Future<int> getBreakDurationMinutes() async {
    final settings = await getSettings();
    return settings.breakDurationMinutes ?? 5;
  }

  Future<void> updateCalmModeSettings({
    bool? enabled,
    double? contrast,
    double? saturation,
    double? brightness,
    double? warmth,
    String? preset,
  }) async {
    final settings = await getSettings();
    
    final newSettings = settings.copyWith(
      calmModeEnabled: enabled ?? settings.calmModeEnabled,
      calmModeContrast: contrast ?? settings.calmModeContrast,
      calmModeSaturation: saturation ?? settings.calmModeSaturation,
      calmModeBrightness: brightness ?? settings.calmModeBrightness,
      calmModeWarmth: warmth ?? settings.calmModeWarmth,
      calmModePreset: preset ?? settings.calmModePreset,
    );
    
    await saveSettings(newSettings);
  }
}

