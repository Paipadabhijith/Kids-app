import 'package:flutter/material.dart';
import 'storage_service.dart';

class AppThemeService {
  AppThemeService._();

  static final StorageService _storageService = StorageService();
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  static Future<void> init() async {
    final saved = await _storageService.getThemeModePreference();
    themeMode.value = _themeModeFromString(saved);
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    await _storageService.saveThemeModePreference(_themeModeToString(mode));
  }

  static ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

