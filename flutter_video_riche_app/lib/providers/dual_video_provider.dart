import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_riche_app/services/hardware_detection_service.dart';

import '../models/dual_video_clip_model.dart';
import '../services/dual_video_playback_manager.dart';

/// Provider for dual video clips data
final dualVideoClipsProvider = Provider<List<DualVideoClipModel>>((ref) {
  // Sample video clips data provided by user
  final clipsData = [
    {
      "videoUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/post/2025/05/26/56801aaa-5943-4b70-9d52-ffa829516c07.mp4",
      "clipUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/post/2025/05/26/56801aaa-5943-4b70-9d52-ffa829516c07_clip.mp4",
      "thumbnail": "https://plus.unsplash.com/premium_photo-1663954642189-47be8570548e?q=80&w=854&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
    },
    {
      "videoUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/20/bc5a9f69-7e63-4560-bfb2-27bff03ca22d.mp4",
      "clipUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/20/bc5a9f69-7e63-4560-bfb2-27bff03ca22d_clip.mp4",
      "thumbnail": "https://images.unsplash.com/photo-1667068733512-ec5218389de2?q=80&w=870&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
    },
    {
      "videoUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/ff628e34-77f9-4ba5-8187-0154688e48ff.mp4",
      "clipUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/ff628e34-77f9-4ba5-8187-0154688e48ff_clip.mp4",
      "thumbnail": "https://images.unsplash.com/photo-1577154879758-6892cd7e8e87?q=80&w=742&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
    },
    {
      "videoUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/56335c22-c132-4377-8b21-3b218bf3a211.mp4",
      "clipUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/56335c22-c132-4377-8b21-3b218bf3a211_clip.mp4",
      "thumbnail": "https://images.unsplash.com/photo-1748609037278-ee86b9904f93?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
    },
    {
      "videoUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/f965c476-298d-4c63-99b8-555bdc68b034.mp4",
      "clipUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/f965c476-298d-4c63-99b8-555bdc68b034_clip.mp4",
      "thumbnail": "https://d2594vc0rpodpd.cloudfront.net/imgs/packages/2025/04/10/f965c476-298d-4c63-99b8-555bdc68b034_capture.jpeg"
    },
    {
      "videoUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/20/e2b9cfea-c68f-461b-9285-40669966a8fa.mp4",
      "clipUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/20/e2b9cfea-c68f-461b-9285-40669966a8fa_clip.mp4",
      "thumbnail": "https://d2594vc0rpodpd.cloudfront.net/imgs/packages/2025/04/20/e2b9cfea-c68f-461b-9285-40669966a8fa_capture.jpeg"
    },
    {
      "videoUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/dbeef944-c64c-4b78-8e80-bdb22b60f6ad.mp4",
      "clipUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/dbeef944-c64c-4b78-8e80-bdb22b60f6ad_clip.mp4",
      "thumbnail": "https://d2594vc0rpodpd.cloudfront.net/imgs/packages/2025/04/10/dbeef944-c64c-4b78-8e80-bdb22b60f6ad_capture.jpeg"
    },
    {
      "videoUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/7d83cc3a-8619-429f-9a6f-633876b7a6bb.mp4",
      "clipUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/7d83cc3a-8619-429f-9a6f-633876b7a6bb_clip.mp4",
      "thumbnail": "https://d2594vc0rpodpd.cloudfront.net/imgs/packages/2025/04/10/7d83cc3a-8619-429f-9a6f-633876b7a6bb_capture.jpeg"
    },
    {
      "videoUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/087880a2-46c7-4987-b7d1-9aaa10154241.mp4",
      "clipUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/087880a2-46c7-4987-b7d1-9aaa10154241_clip.mp4",
      "thumbnail": "https://d2594vc0rpodpd.cloudfront.net/imgs/packages/2025/04/10/087880a2-46c7-4987-b7d1-9aaa10154241_capture.jpeg"
    },
    {
      "videoUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/20/453404b5-0622-41c5-ad6d-1884ec138cc0.mp4",
      "clipUrl": "https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/20/453404b5-0622-41c5-ad6d-1884ec138cc0_clip.mp4",
      "thumbnail": "https://d2594vc0rpodpd.cloudfront.net/imgs/packages/2025/04/20/453404b5-0622-41c5-ad6d-1884ec138cc0_capture.jpeg"
    },
  ];

  return clipsData.asMap().entries.map((entry) {
    final index = entry.key;
    final data = entry.value;
    return DualVideoClipModel.fromJson(data, id: 'dual_video_$index');
  }).toList();
});

/// Provider for dual video playback manager
final dualVideoManagerProvider = Provider<DualVideoPlaybackManager>((ref) {
  final manager = DualVideoPlaybackManager();

  // Dispose when provider is disposed
  ref.onDispose(() async {
    try {
      await manager.dispose();
    } catch (e) {
      // Ignore disposal errors
    }
  });

  return manager;
});

/// State notifier for dual video screen state
class DualVideoScreenState {
  final List<DualVideoClipModel> videos;
  final Set<String> visibleVideos;
  final Set<String> playingVideos;
  final String? currentStrategy;
  final bool isInitialized;
  final String? error;

  const DualVideoScreenState({
    required this.videos,
    required this.visibleVideos,
    required this.playingVideos,
    this.currentStrategy,
    this.isInitialized = false,
    this.error,
  });

  DualVideoScreenState copyWith({
    List<DualVideoClipModel>? videos,
    Set<String>? visibleVideos,
    Set<String>? playingVideos,
    String? currentStrategy,
    bool? isInitialized,
    String? error,
  }) {
    return DualVideoScreenState(
      videos: videos ?? this.videos,
      visibleVideos: visibleVideos ?? this.visibleVideos,
      playingVideos: playingVideos ?? this.playingVideos,
      currentStrategy: currentStrategy ?? this.currentStrategy,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
    );
  }
}

/// State notifier for managing dual video screen
class DualVideoScreenNotifier extends StateNotifier<DualVideoScreenState> {
  final DualVideoPlaybackManager _manager;
  StreamSubscription? _eventSubscription;
  bool _isDisposed = false;

  DualVideoScreenNotifier(this._manager, List<DualVideoClipModel> videos)
      : super(DualVideoScreenState(
          videos: videos,
          visibleVideos: {},
          playingVideos: {},
        )) {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isDisposed) return;

    try {
      await _manager.initialize();
      await _manager.cacheVideos(state.videos);

      if (_isDisposed) return;

      // Listen to manager events
      _eventSubscription = _manager.events.listen(_handleManagerEvent);

      if (!_isDisposed) {
        state = state.copyWith(
          isInitialized: true,
          currentStrategy: _manager.currentStrategy?.description,
        );
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  void _handleManagerEvent(DualVideoEvent event) {
    if (_isDisposed) return;

    switch (event.type) {
      case DualVideoEventType.playbackStateChanged:
        final playing = Set<String>.from(event.data['playing'] ?? []);
        final visible = Set<String>.from(event.data['visible'] ?? []);
        final strategy = event.data['strategy'] as String?;

        if (!_isDisposed) {
          state = state.copyWith(
            playingVideos: playing,
            visibleVideos: visible,
            currentStrategy: strategy,
          );
        }
        break;
      case DualVideoEventType.error:
        if (!_isDisposed) {
          state = state.copyWith(error: event.data['error'] as String?);
        }
        break;
      default:
        break;
    }
  }

  /// Update video visibility
  Future<void> updateVideoVisibility(String videoId, bool isVisible) async {
    if (_isDisposed) return;
    await _manager.updateVideoVisibility(videoId, isVisible);
  }

  /// Check if video is playing
  bool isVideoPlaying(String videoId) {
    return state.playingVideos.contains(videoId);
  }

  /// Check if video is visible
  bool isVideoVisible(String videoId) {
    return state.visibleVideos.contains(videoId);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _eventSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for dual video screen state
final dualVideoScreenProvider = StateNotifierProvider<DualVideoScreenNotifier, DualVideoScreenState>((ref) {
  final manager = ref.watch(dualVideoManagerProvider);
  final videos = ref.watch(dualVideoClipsProvider);
  
  return DualVideoScreenNotifier(manager, videos);
});
