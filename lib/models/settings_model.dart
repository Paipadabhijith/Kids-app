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
  final bool calmModeEnabled;
  final double calmModeContrast;
  final double calmModeSaturation;
  final double calmModeBrightness;
  final double calmModeWarmth;
  final String? calmModePreset;
  // Binaural beats settings
  final bool binauralBeatsEnabled;
  final bool windDownModeEnabled;
  final bool calmFocusModeEnabled;
  final double binauralBeatsVolume;
  // Channel whitelist/blacklist
  final List<String> whitelistedChannels;
  final List<String> blacklistedChannels;

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
    this.calmModeEnabled = false,
    this.calmModeContrast = 0.75,
    this.calmModeSaturation = 0.7,
    this.calmModeBrightness = -0.1,
    this.calmModeWarmth = 0.15,
    this.calmModePreset,
    // Binaural beats defaults
    this.binauralBeatsEnabled = true,
    this.windDownModeEnabled = false,
    this.calmFocusModeEnabled = false,
    this.binauralBeatsVolume = 0.12,
    this.whitelistedChannels = const [],
    this.blacklistedChannels = const [],
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
      calmModeEnabled: json['calmModeEnabled'] ?? false,
      calmModeContrast: (json['calmModeContrast'] ?? 0.75).toDouble(),
      calmModeSaturation: (json['calmModeSaturation'] ?? 0.7).toDouble(),
      calmModeBrightness: (json['calmModeBrightness'] ?? -0.1).toDouble(),
      calmModeWarmth: (json['calmModeWarmth'] ?? 0.15).toDouble(),
      calmModePreset: json['calmModePreset'],
      // Binaural beats
      binauralBeatsEnabled: json['binauralBeatsEnabled'] ?? true,
      windDownModeEnabled: json['windDownModeEnabled'] ?? false,
      calmFocusModeEnabled: json['calmFocusModeEnabled'] ?? false,
      binauralBeatsVolume: (json['binauralBeatsVolume'] ?? 0.12).toDouble(),
      whitelistedChannels: List<String>.from(json['whitelistedChannels'] ?? []),
      blacklistedChannels: List<String>.from(json['blacklistedChannels'] ?? []),
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
      'calmModeEnabled': calmModeEnabled,
      'calmModeContrast': calmModeContrast,
      'calmModeSaturation': calmModeSaturation,
      'calmModeBrightness': calmModeBrightness,
      'calmModeWarmth': calmModeWarmth,
      'calmModePreset': calmModePreset,
      // Binaural beats
      'binauralBeatsEnabled': binauralBeatsEnabled,
      'windDownModeEnabled': windDownModeEnabled,
      'calmFocusModeEnabled': calmFocusModeEnabled,
      'binauralBeatsVolume': binauralBeatsVolume,
      'whitelistedChannels': whitelistedChannels,
      'blacklistedChannels': blacklistedChannels,
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
    bool? calmModeEnabled,
    double? calmModeContrast,
    double? calmModeSaturation,
    double? calmModeBrightness,
    double? calmModeWarmth,
    String? calmModePreset,
    // Binaural beats
    bool? binauralBeatsEnabled,
    bool? windDownModeEnabled,
    bool? calmFocusModeEnabled,
    double? binauralBeatsVolume,
    List<String>? whitelistedChannels,
    List<String>? blacklistedChannels,
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
      calmModeEnabled: calmModeEnabled ?? this.calmModeEnabled,
      calmModeContrast: calmModeContrast ?? this.calmModeContrast,
      calmModeSaturation: calmModeSaturation ?? this.calmModeSaturation,
      calmModeBrightness: calmModeBrightness ?? this.calmModeBrightness,
      calmModeWarmth: calmModeWarmth ?? this.calmModeWarmth,
      calmModePreset: calmModePreset ?? this.calmModePreset,
      // Binaural beats
      binauralBeatsEnabled: binauralBeatsEnabled ?? this.binauralBeatsEnabled,
      windDownModeEnabled: windDownModeEnabled ?? this.windDownModeEnabled,
      calmFocusModeEnabled: calmFocusModeEnabled ?? this.calmFocusModeEnabled,
      binauralBeatsVolume: binauralBeatsVolume ?? this.binauralBeatsVolume,
      whitelistedChannels: whitelistedChannels ?? this.whitelistedChannels,
      blacklistedChannels: blacklistedChannels ?? this.blacklistedChannels,
    );
  }
}

