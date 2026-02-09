class VideoModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelTitle;
  final String? duration;
  final DateTime? publishedAt;
  final int? viewCount;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelTitle,
    this.duration,
    this.publishedAt,
    this.viewCount,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] ?? {};
    final thumbnails = snippet['thumbnails'] ?? {};
    final defaultThumb = thumbnails['default'] ?? {};
    final highThumb = thumbnails['high'] ?? {};
    final contentDetails = json['contentDetails'] ?? {};
    
    return VideoModel(
      id: json['id'] is String 
          ? json['id'] 
          : json['id']['videoId'] ?? '',
      title: snippet['title'] ?? '',
      description: snippet['description'] ?? '',
      thumbnailUrl: highThumb['url'] ?? defaultThumb['url'] ?? '',
      channelTitle: snippet['channelTitle'] ?? '',
      duration: contentDetails['duration'],
      publishedAt: snippet['publishedAt'] != null
          ? DateTime.tryParse(snippet['publishedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'channelTitle': channelTitle,
      'duration': duration,
      'publishedAt': publishedAt?.toIso8601String(),
      'viewCount': viewCount,
    };
  }

  /// Create a copy with updated fields
  VideoModel copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? channelTitle,
    String? duration,
    DateTime? publishedAt,
    int? viewCount,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      channelTitle: channelTitle ?? this.channelTitle,
      duration: duration ?? this.duration,
      publishedAt: publishedAt ?? this.publishedAt,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  /// Detect if video is a Short
  /// Uses duration if available (≤60 seconds), otherwise checks title for #shorts
  bool get isShort {
    // Check duration first (most accurate)
    if (duration != null) {
      final durationSeconds = _parseDuration(duration!);
      return durationSeconds > 0 && durationSeconds <= 60;
    }
    // Fallback: check title for #shorts hashtag (common in Shorts)
    final lowerTitle = title.toLowerCase();
    return lowerTitle.contains('#shorts') || lowerTitle.contains('#short');
  }

  /// Get aspect ratio based on video type
  /// Shorts use portrait 9:16, regular videos use landscape 16:9
  double get aspectRatio => isShort ? 9 / 16 : 16 / 9;

  /// Parse ISO 8601 duration format (e.g., "PT1M30S" = 90 seconds)
  int _parseDuration(String duration) {
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(duration);
    if (match == null) return 0;
    
    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
    
    return hours * 3600 + minutes * 60 + seconds;
  }
}

