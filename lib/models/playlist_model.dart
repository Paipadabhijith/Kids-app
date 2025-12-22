class PlaylistModel {
  final String id;
  final String name;
  final String? description;
  final List<String> videoIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PlaylistModel({
    required this.id,
    required this.name,
    this.description,
    required this.videoIds,
    required this.createdAt,
    this.updatedAt,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      videoIds: List<String>.from(json['videoIds'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'videoIds': videoIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? videoIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      videoIds: videoIds ?? this.videoIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

