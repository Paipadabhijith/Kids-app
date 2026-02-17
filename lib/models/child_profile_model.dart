import 'package:flutter/material.dart';

class ChildProfileModel {
  final String id;
  final String name;
  final int age;
  final String? avatarUrl;
  final int dailyTimeLimitMinutes;
  final List<String> blockedKeywords;
  final List<String> preferredTopics;
  final List<String> whitelistedChannels;
  final List<String> blacklistedChannels;
  final bool calmModeEnabled;
  final DateTime createdAt;
  final bool isActive;

  ChildProfileModel({
    required this.id,
    required this.name,
    required this.age,
    this.avatarUrl,
    this.dailyTimeLimitMinutes = 60,
    this.blockedKeywords = const [],
    this.preferredTopics = const [],
    this.whitelistedChannels = const [],
    this.blacklistedChannels = const [],
    this.calmModeEnabled = false,
    DateTime? createdAt,
    this.isActive = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChildProfileModel.fromJson(Map<String, dynamic> json) {
    return ChildProfileModel(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      avatarUrl: json['avatarUrl'],
      dailyTimeLimitMinutes: json['dailyTimeLimitMinutes'] ?? 60,
      blockedKeywords: List<String>.from(json['blockedKeywords'] ?? []),
      preferredTopics: List<String>.from(json['preferredTopics'] ?? []),
      whitelistedChannels: List<String>.from(json['whitelistedChannels'] ?? []),
      blacklistedChannels: List<String>.from(json['blacklistedChannels'] ?? []),
      calmModeEnabled: json['calmModeEnabled'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'avatarUrl': avatarUrl,
      'dailyTimeLimitMinutes': dailyTimeLimitMinutes,
      'blockedKeywords': blockedKeywords,
      'preferredTopics': preferredTopics,
      'whitelistedChannels': whitelistedChannels,
      'blacklistedChannels': blacklistedChannels,
      'calmModeEnabled': calmModeEnabled,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  ChildProfileModel copyWith({
    String? id,
    String? name,
    int? age,
    String? avatarUrl,
    int? dailyTimeLimitMinutes,
    List<String>? blockedKeywords,
    List<String>? preferredTopics,
    List<String>? whitelistedChannels,
    List<String>? blacklistedChannels,
    bool? calmModeEnabled,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ChildProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dailyTimeLimitMinutes: dailyTimeLimitMinutes ?? this.dailyTimeLimitMinutes,
      blockedKeywords: blockedKeywords ?? this.blockedKeywords,
      preferredTopics: preferredTopics ?? this.preferredTopics,
      whitelistedChannels: whitelistedChannels ?? this.whitelistedChannels,
      blacklistedChannels: blacklistedChannels ?? this.blacklistedChannels,
      calmModeEnabled: calmModeEnabled ?? this.calmModeEnabled,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  String get ageGroup {
    if (age < 5) return 'Toddler';
    if (age < 8) return 'Young Child';
    if (age < 13) return 'Pre-Teen';
    return 'Teen';
  }

  Color get profileColor {
    final colors = [
      const Color(0xFF4CAF50), // Green
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFE91E63), // Pink
      const Color(0xFF00BCD4), // Cyan
    ];
    return colors[id.hashCode % colors.length];
  }
}

