enum ReelType { image, video }

class AxisReelModel {
  final String id;
  final String url;
  final ReelType type;
  final String? thumbnailUrl;
  final String? title;
  final String? description;
  final int loopCount; // For video finite looping

  const AxisReelModel({
    required this.id,
    required this.url,
    required this.type,
    this.thumbnailUrl,
    this.title,
    this.description,
    this.loopCount = 3, // Default to 3 loops for videos
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AxisReelModel &&
        other.id == id &&
        other.url == url &&
        other.type == type &&
        other.thumbnailUrl == thumbnailUrl &&
        other.title == title &&
        other.description == description &&
        other.loopCount == loopCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        url.hashCode ^
        type.hashCode ^
        thumbnailUrl.hashCode ^
        title.hashCode ^
        description.hashCode ^
        loopCount.hashCode;
  }
} 