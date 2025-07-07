import 'video_model.dart';

class StoryModel extends VideoModel {
  final String userName;
  final String? userAvatar;
  final DateTime timestamp;
  final Duration duration;

  const StoryModel({
    required super.url,
    required super.id,
    required this.userName,
    required this.timestamp,
    this.userAvatar,
    this.duration = const Duration(seconds: 15),
    super.title,
    super.description,
  });

  bool get isExpired {
    final now = DateTime.now();
    final expiryTime = timestamp.add(const Duration(hours: 24));
    return now.isAfter(expiryTime);
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoryModel &&
        other.url == url &&
        other.id == id &&
        other.userName == userName &&
        other.userAvatar == userAvatar &&
        other.timestamp == timestamp &&
        other.duration == duration;
  }

  @override
  int get hashCode {
    return super.hashCode ^
        userName.hashCode ^
        userAvatar.hashCode ^
        timestamp.hashCode ^
        duration.hashCode;
  }
} 