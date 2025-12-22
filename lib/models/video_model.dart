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
    
    return VideoModel(
      id: json['id'] is String 
          ? json['id'] 
          : json['id']['videoId'] ?? '',
      title: snippet['title'] ?? '',
      description: snippet['description'] ?? '',
      thumbnailUrl: highThumb['url'] ?? defaultThumb['url'] ?? '',
      channelTitle: snippet['channelTitle'] ?? '',
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
}

