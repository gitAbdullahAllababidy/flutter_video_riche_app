class DualVideoClipModel {
  final String id;
  final String videoUrl;
  final String clipUrl;
  final String thumbnail;
  final String? title;
  final String? description;
  
  // Playback state tracking
  final bool isLoaded;
  final bool isPlaying;
  final bool isVisible;
  final bool isNativePlayer;
  final Duration? duration;
  final double lastPosition;
  final DateTime? lastPlayedAt;
  final bool hasError;
  final String? errorMessage;
  
  const DualVideoClipModel({
    required this.id,
    required this.videoUrl,
    required this.clipUrl,
    required this.thumbnail,
    this.title,
    this.description,
    this.isLoaded = false,
    this.isPlaying = false,
    this.isVisible = false,
    this.isNativePlayer = false,
    this.duration,
    this.lastPosition = 0.0,
    this.lastPlayedAt,
    this.hasError = false,
    this.errorMessage,
  });

  DualVideoClipModel copyWith({
    String? id,
    String? videoUrl,
    String? clipUrl,
    String? thumbnail,
    String? title,
    String? description,
    bool? isLoaded,
    bool? isPlaying,
    bool? isVisible,
    bool? isNativePlayer,
    Duration? duration,
    double? lastPosition,
    DateTime? lastPlayedAt,
    bool? hasError,
    String? errorMessage,
  }) {
    return DualVideoClipModel(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      clipUrl: clipUrl ?? this.clipUrl,
      thumbnail: thumbnail ?? this.thumbnail,
      title: title ?? this.title,
      description: description ?? this.description,
      isLoaded: isLoaded ?? this.isLoaded,
      isPlaying: isPlaying ?? this.isPlaying,
      isVisible: isVisible ?? this.isVisible,
      isNativePlayer: isNativePlayer ?? this.isNativePlayer,
      duration: duration ?? this.duration,
      lastPosition: lastPosition ?? this.lastPosition,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Factory constructor to create from JSON data
  factory DualVideoClipModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return DualVideoClipModel(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      videoUrl: json['videoUrl'] as String,
      clipUrl: json['clipUrl'] as String,
      thumbnail: json['thumbnail'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoUrl': videoUrl,
      'clipUrl': clipUrl,
      'thumbnail': thumbnail,
      'title': title,
      'description': description,
      'isLoaded': isLoaded,
      'isPlaying': isPlaying,
      'isVisible': isVisible,
      'isNativePlayer': isNativePlayer,
      'duration': duration?.inMilliseconds,
      'lastPosition': lastPosition,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      'hasError': hasError,
      'errorMessage': errorMessage,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DualVideoClipModel &&
        other.id == id &&
        other.videoUrl == videoUrl &&
        other.clipUrl == clipUrl &&
        other.thumbnail == thumbnail &&
        other.title == title &&
        other.description == description &&
        other.isLoaded == isLoaded &&
        other.isPlaying == isPlaying &&
        other.isVisible == isVisible &&
        other.isNativePlayer == isNativePlayer &&
        other.duration == duration &&
        other.lastPosition == lastPosition &&
        other.lastPlayedAt == lastPlayedAt &&
        other.hasError == hasError &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        videoUrl.hashCode ^
        clipUrl.hashCode ^
        thumbnail.hashCode ^
        title.hashCode ^
        description.hashCode ^
        isLoaded.hashCode ^
        isPlaying.hashCode ^
        isVisible.hashCode ^
        isNativePlayer.hashCode ^
        duration.hashCode ^
        lastPosition.hashCode ^
        lastPlayedAt.hashCode ^
        hasError.hashCode ^
        errorMessage.hashCode;
  }

  @override
  String toString() {
    return 'DualVideoClipModel('
        'id: $id, '
        'title: $title, '
        'isLoaded: $isLoaded, '
        'isPlaying: $isPlaying, '
        'isVisible: $isVisible, '
        'isNativePlayer: $isNativePlayer, '
        'hasError: $hasError'
        ')';
  }
}
