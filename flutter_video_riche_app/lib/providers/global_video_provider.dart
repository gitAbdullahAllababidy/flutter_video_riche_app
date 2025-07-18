import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/global_video_visibility_manager.dart';

/// Provider for the global video visibility manager
final globalVideoManagerProvider = Provider<GlobalVideoVisibilityManager>((ref) {
  final manager = GlobalVideoVisibilityManager();
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    manager.dispose();
  });
  
  return manager;
});

/// Provider for video playback statistics
final videoPlaybackStatsProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final manager = ref.watch(globalVideoManagerProvider);
  
  // Emit stats every second
  while (true) {
    await Future.delayed(const Duration(seconds: 1));
    yield manager.getPlaybackStats();
  }
});
