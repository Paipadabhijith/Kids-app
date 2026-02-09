import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  static const String _subscriptionKey = 'user_subscription';
  static const String _calmModeUsageKey = 'calm_mode_usage_minutes';
  static const String _calmModeResetDateKey = 'calm_mode_reset_date';
  
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get current subscription status
  Future<SubscriptionModel> getSubscription() async {
    await init();
    final subscriptionJson = _prefs!.getString(_subscriptionKey);
    
    if (subscriptionJson == null) {
      return SubscriptionModel(); // Default to free tier
    }
    
    try {
      final Map<String, dynamic> decoded = json.decode(subscriptionJson);
      return SubscriptionModel.fromJson(decoded);
    } catch (e) {
      debugPrint('Error parsing subscription: $e');
      return SubscriptionModel();
    }
  }

  /// Save subscription status
  Future<void> saveSubscription(SubscriptionModel subscription) async {
    await init();
    final subscriptionJson = json.encode(subscription.toJson());
    await _prefs!.setString(_subscriptionKey, subscriptionJson);
  }

  /// Upgrade to premium (Zen Kids)
  Future<void> upgradeToPremium() async {
    final subscription = SubscriptionModel(
      tier: SubscriptionTier.zenKids,
      isActive: true,
      expiryDate: DateTime.now().add(const Duration(days: 365)), // 1 year
    );
    await saveSubscription(subscription);
  }

  /// Downgrade to free (Bright Kids)
  Future<void> downgradeToFree() async {
    final subscription = SubscriptionModel(
      tier: SubscriptionTier.brightKids,
      isActive: true,
    );
    await saveSubscription(subscription);
  }

  /// Check if user has premium access
  Future<bool> isPremium() async {
    final subscription = await getSubscription();
    return subscription.isPremium;
  }

  /// Check if feature is available based on subscription tier
  Future<bool> canAccessFeature(PremiumFeature feature) async {
    final isPremiumUser = await isPremium();
    
    if (isPremiumUser) {
      return true; // Premium users get all features
    }
    
    // Free users can access basic features
    switch (feature) {
      case PremiumFeature.basicVideoPlayback:
      case PremiumFeature.basicSearch:
      case PremiumFeature.basicCategories:
      case PremiumFeature.basicPlaylists:
      case PremiumFeature.basicParentalControls:
      case PremiumFeature.basicBreakReminders:
        return true;
      
      case PremiumFeature.binauralBeats:
      case PremiumFeature.unlimitedCalmMode:
      case PremiumFeature.allCategories:
      case PremiumFeature.unlimitedSearch:
      case PremiumFeature.unlimitedPlaylists:
      case PremiumFeature.channelControl:
      case PremiumFeature.breakReminderGames:
      case PremiumFeature.multipleChildProfiles:
      case PremiumFeature.customProfilePicture:
      case PremiumFeature.fullUsageDashboard:
        return false;
    }
  }

  /// Track calm mode usage for free users (2 hour limit)
  Future<int> getCalmModeUsageMinutes() async {
    await init();
    
    // Check if we need to reset (new day)
    final resetDateStr = _prefs!.getString(_calmModeResetDateKey);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    
    if (resetDateStr != todayStr) {
      // Reset usage for new day
      await _prefs!.setInt(_calmModeUsageKey, 0);
      await _prefs!.setString(_calmModeResetDateKey, todayStr);
      return 0;
    }
    
    return _prefs!.getInt(_calmModeUsageKey) ?? 0;
  }

  /// Add calm mode usage minutes
  Future<void> addCalmModeUsage(int minutes) async {
    await init();
    final current = await getCalmModeUsageMinutes();
    await _prefs!.setInt(_calmModeUsageKey, current + minutes);
  }

  /// Check if calm mode is available for free users (under 2 hour limit)
  Future<bool> canUseCalmMode() async {
    final isPremiumUser = await isPremium();
    if (isPremiumUser) {
      return true; // No limit for premium users
    }
    
    final usageMinutes = await getCalmModeUsageMinutes();
    return usageMinutes < 120; // 2 hours = 120 minutes
  }

  /// Get remaining calm mode minutes for free users
  Future<int> getRemainingCalmModeMinutes() async {
    final isPremiumUser = await isPremium();
    if (isPremiumUser) {
      return -1; // Unlimited
    }
    
    final usageMinutes = await getCalmModeUsageMinutes();
    return 120 - usageMinutes; // 2 hours - used minutes
  }
}

enum PremiumFeature {
  // Free features
  basicVideoPlayback,
  basicSearch,
  basicCategories,
  basicPlaylists,
  basicParentalControls,
  basicBreakReminders,
  
  // Premium features
  binauralBeats,
  unlimitedCalmMode,
  allCategories,
  unlimitedSearch,
  unlimitedPlaylists,
  channelControl,
  breakReminderGames,
  multipleChildProfiles,
  customProfilePicture,
  fullUsageDashboard,
}

