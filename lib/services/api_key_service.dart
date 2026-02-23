import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyService {
  static const String _currentKeyIndexKey = 'current_api_key_index';
  static const String _failedKeysKey = 'failed_api_keys';
  
  List<String> _apiKeys = [];
  int _currentIndex = 0;
  Set<String> _failedKeys = {};
  
  static final ApiKeyService _instance = ApiKeyService._internal();
  factory ApiKeyService() => _instance;
  ApiKeyService._internal();
  
  Future<void> init() async {
    try {
      _apiKeys = Constants.youtubeApiKeys;
      if (_apiKeys.isEmpty) {
        debugPrint('Warning: No YouTube API keys configured');
        return;
      }
      
      // Load saved state with timeout
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      _currentIndex = prefs.getInt(_currentKeyIndexKey) ?? 0;
      if (_currentIndex >= _apiKeys.length) {
        _currentIndex = 0;
      }
      
      final failedKeysJson = prefs.getString(_failedKeysKey);
      if (failedKeysJson != null) {
        _failedKeys = Set<String>.from(
          (failedKeysJson.split(',')).where((k) => k.isNotEmpty)
        );
      }
      
      debugPrint('ApiKeyService initialized with ${_apiKeys.length} keys');
    } catch (e) {
      debugPrint('Error in ApiKeyService.init(): $e');
      // Set defaults if init fails
      _apiKeys = Constants.youtubeApiKeys;
      _currentIndex = 0;
      _failedKeys = {};
    }
  }
  
  String getCurrentKey() {
    if (_apiKeys.isEmpty) return '';
    return _apiKeys[_currentIndex];
  }
  
  bool hasNextKey() {
    return _apiKeys.length > 1;
  }
  
  Future<bool> rotateToNextKey() async {
    if (_apiKeys.length <= 1) {
      debugPrint('No alternative API keys available');
      return false;
    }
    
    // Mark current key as failed
    _failedKeys.add(_apiKeys[_currentIndex]);
    
    // Find next available key
    int attempts = 0;
    while (attempts < _apiKeys.length) {
      _currentIndex = (_currentIndex + 1) % _apiKeys.length;
      
      if (!_failedKeys.contains(_apiKeys[_currentIndex])) {
        // Save state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_currentKeyIndexKey, _currentIndex);
        await prefs.setString(_failedKeysKey, _failedKeys.join(','));
        
        debugPrint('Rotated to API key ${_currentIndex + 1}/${_apiKeys.length}');
        return true;
      }
      
      attempts++;
    }
    
    // All keys failed, reset and try again
    debugPrint('All keys exhausted, resetting failed keys list');
    _failedKeys.clear();
    _currentIndex = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentKeyIndexKey, 0);
    await prefs.setString(_failedKeysKey, '');
    
    return true;
  }
  
  bool isQuotaError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('quota') || 
           errorStr.contains('403') ||
           errorStr.contains('quotaexceeded');
  }
  
  void resetFailedKeys() {
    _failedKeys.clear();
  }
}

