class GridVideoModel {
  final String id;
  final String url;
  final String thumbnailUrl;
  final String? title;
  final String? description;
  final Duration? duration;
  
  // Caching and state tracking
  final bool isLoaded;
  final bool isPlaying;
  final bool isVisible;
  final double lastPosition;
  final DateTime? lastPlayedAt;
  final bool hasError;
  final String? errorMessage;
  
  const GridVideoModel({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    this.title,
    this.description,
    this.duration,
    this.isLoaded = false,
    this.isPlaying = false,
    this.isVisible = false,
    this.lastPosition = 0.0,
    this.lastPlayedAt,
    this.hasError = false,
    this.errorMessage,
  });

  GridVideoModel copyWith({
    String? id,
    String? url,
    String? thumbnailUrl,
    String? title,
    String? description,
    Duration? duration,
    bool? isLoaded,
    bool? isPlaying,
    bool? isVisible,
    double? lastPosition,
    DateTime? lastPlayedAt,
    bool? hasError,
    String? errorMessage,
  }) {
    return GridVideoModel(
      id: id ?? this.id,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      isLoaded: isLoaded ?? this.isLoaded,
      isPlaying: isPlaying ?? this.isPlaying,
      isVisible: isVisible ?? this.isVisible,
      lastPosition: lastPosition ?? this.lastPosition,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GridVideoModel &&
        other.id == id &&
        other.url == url &&
        other.thumbnailUrl == thumbnailUrl &&
        other.title == title &&
        other.description == description &&
        other.duration == duration &&
        other.isLoaded == isLoaded &&
        other.isPlaying == isPlaying &&
        other.isVisible == isVisible &&
        other.lastPosition == lastPosition &&
        other.lastPlayedAt == lastPlayedAt &&
        other.hasError == hasError &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        url.hashCode ^
        thumbnailUrl.hashCode ^
        title.hashCode ^
        description.hashCode ^
        duration.hashCode ^
        isLoaded.hashCode ^
        isPlaying.hashCode ^
        isVisible.hashCode ^
        lastPosition.hashCode ^
        lastPlayedAt.hashCode ^
        hasError.hashCode ^
        errorMessage.hashCode;
  }

  @override
  String toString() {
    return 'GridVideoModel('
        'id: $id, '
        'title: $title, '
        'isLoaded: $isLoaded, '
        'isPlaying: $isPlaying, '
        'isVisible: $isVisible, '
        'hasError: $hasError'
        ')';
  }
} 