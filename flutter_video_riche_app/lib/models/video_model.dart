class VideoModel {
  final String url;
  final String id;
  final String? title;
  final String? description;

  const VideoModel({
    required this.url,
    required this.id,
    this.title,
    this.description,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoModel &&
        other.url == url &&
        other.id == id &&
        other.title == title &&
        other.description == description;
  }

  @override
  int get hashCode {
    return url.hashCode ^
        id.hashCode ^
        title.hashCode ^
        description.hashCode;
  }
} 