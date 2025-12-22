class SettingsModel {
  final bool parentalControlsEnabled;
  final int? dailyTimeLimitMinutes;
  final List<String> blockedKeywords;
  final List<String> blockedCategories;
  final String? parentPasswordHash;
  final bool requirePasswordForSettings;
  final DateTime? lastResetDate;
  final bool breakRemindersEnabled;
  final int? breakIntervalMinutes;
  final int? breakDurationMinutes;

  SettingsModel({
    this.parentalControlsEnabled = false,
    this.dailyTimeLimitMinutes,
    this.blockedKeywords = const [],
    this.blockedCategories = const [],
    this.parentPasswordHash,
    this.requirePasswordForSettings = true,
    this.lastResetDate,
    this.breakRemindersEnabled = false,
    this.breakIntervalMinutes,
    this.breakDurationMinutes,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      parentalControlsEnabled: json['parentalControlsEnabled'] ?? false,
      dailyTimeLimitMinutes: json['dailyTimeLimitMinutes'],
      blockedKeywords: List<String>.from(json['blockedKeywords'] ?? []),
      blockedCategories: List<String>.from(json['blockedCategories'] ?? []),
      parentPasswordHash: json['parentPasswordHash'],
      requirePasswordForSettings: json['requirePasswordForSettings'] ?? true,
      lastResetDate: json['lastResetDate'] != null
          ? DateTime.tryParse(json['lastResetDate'])
          : null,
      breakRemindersEnabled: json['breakRemindersEnabled'] ?? false,
      breakIntervalMinutes: json['breakIntervalMinutes'],
      breakDurationMinutes: json['breakDurationMinutes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parentalControlsEnabled': parentalControlsEnabled,
      'dailyTimeLimitMinutes': dailyTimeLimitMinutes,
      'blockedKeywords': blockedKeywords,
      'blockedCategories': blockedCategories,
      'parentPasswordHash': parentPasswordHash,
      'requirePasswordForSettings': requirePasswordForSettings,
      'lastResetDate': lastResetDate?.toIso8601String(),
      'breakRemindersEnabled': breakRemindersEnabled,
      'breakIntervalMinutes': breakIntervalMinutes,
      'breakDurationMinutes': breakDurationMinutes,
    };
  }

  SettingsModel copyWith({
    bool? parentalControlsEnabled,
    int? dailyTimeLimitMinutes,
    List<String>? blockedKeywords,
    List<String>? blockedCategories,
    String? parentPasswordHash,
    bool? requirePasswordForSettings,
    DateTime? lastResetDate,
    bool? breakRemindersEnabled,
    int? breakIntervalMinutes,
    int? breakDurationMinutes,
  }) {
    return SettingsModel(
      parentalControlsEnabled: parentalControlsEnabled ?? this.parentalControlsEnabled,
      dailyTimeLimitMinutes: dailyTimeLimitMinutes ?? this.dailyTimeLimitMinutes,
      blockedKeywords: blockedKeywords ?? this.blockedKeywords,
      blockedCategories: blockedCategories ?? this.blockedCategories,
      parentPasswordHash: parentPasswordHash ?? this.parentPasswordHash,
      requirePasswordForSettings: requirePasswordForSettings ?? this.requirePasswordForSettings,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      breakRemindersEnabled: breakRemindersEnabled ?? this.breakRemindersEnabled,
      breakIntervalMinutes: breakIntervalMinutes ?? this.breakIntervalMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
    );
  }
}

