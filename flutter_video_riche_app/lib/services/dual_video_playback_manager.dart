import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/dual_video_clip_model.dart';
import 'hardware_detection_service.dart';

/// Manager for Instagram-style dual video playback with hardware-aware capabilities
class DualVideoPlaybackManager {
  static final DualVideoPlaybackManager _instance = DualVideoPlaybackManager._internal();
  factory DualVideoPlaybackManager() => _instance;
  DualVideoPlaybackManager._internal();


  
  // Current playback state
  PlaybackStrategy? _currentStrategy;
  final Map<String, int> _nativePlayerIds = {};
  final Map<String, DualVideoClipModel> _videoCache = {};
  final Set<String> _currentlyPlaying = {};
  final Set<String> _visibleVideos = {};
  
  // Priority system for video selection
  final Map<String, int> _videoPriorities = {};
  int _nextPriority = 1;
  
  // Event streams
  final StreamController<DualVideoEvent> _eventController = StreamController<DualVideoEvent>.broadcast();
  Stream<DualVideoEvent> get events => _eventController.stream;
  
  // Configuration
  static const int maxConcurrentVideos = 2;
  static const Duration visibilityDebounce = Duration(milliseconds: 150);
  
  Timer? _visibilityTimer;
  bool _isInitialized = false;

  /// Initialize the dual video playback manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // For now, just use dual texture strategy (MediaKit)
      _currentStrategy = PlaybackStrategy.dualTexture;

      _isInitialized = true;

      _emitEvent(DualVideoEvent(
        type: DualVideoEventType.initialized,
        data: {'strategy': _currentStrategy?.description},
      ));

      if (kDebugMode) {
        print('[DualVideoManager] Initialized with strategy: ${_currentStrategy?.description}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DualVideoManager] Initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Cache video clips for playback
  Future<void> cacheVideos(List<DualVideoClipModel> videos) async {
    for (final video in videos) {
      _videoCache[video.id] = video;
      
      // Pre-cache video files in background
      _preCacheVideo(video);
    }
    
    if (kDebugMode) {
      print('[DualVideoManager] Cached ${videos.length} videos');
    }
  }

  /// Update video visibility and trigger playback decisions
  Future<void> updateVideoVisibility(String videoId, bool isVisible) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (isVisible) {
      _visibleVideos.add(videoId);
      _videoPriorities[videoId] = _nextPriority++;
    } else {
      _visibleVideos.remove(videoId);
      _videoPriorities.remove(videoId);
      await _stopVideo(videoId);
    }
    
    // Debounce visibility changes to avoid rapid switching
    _visibilityTimer?.cancel();
    _visibilityTimer = Timer(visibilityDebounce, () {
      _updatePlaybackState();
    });
  }

  /// Get current playback strategy
  PlaybackStrategy? get currentStrategy => _currentStrategy;

  /// Get currently playing videos
  Set<String> get currentlyPlaying => Set.from(_currentlyPlaying);

  /// Check if video is playing
  bool isVideoPlaying(String videoId) => _currentlyPlaying.contains(videoId);

  /// Get video from cache
  DualVideoClipModel? getVideo(String videoId) => _videoCache[videoId];

  /// Update playback state based on visibility and hardware capabilities
  Future<void> _updatePlaybackState() async {
    if (_currentStrategy == null) return;
    
    // Get visible videos sorted by priority (most recent first)
    final sortedVisible = _visibleVideos.toList()
      ..sort((a, b) => (_videoPriorities[b] ?? 0).compareTo(_videoPriorities[a] ?? 0));
    
    // Determine how many videos to play based on strategy
    final maxPlayers = _currentStrategy!.supportsDualPlayback ? maxConcurrentVideos : 1;
    final videosToPlay = sortedVisible.take(maxPlayers).toList();
    
    // Stop videos that should no longer be playing
    final videosToStop = _currentlyPlaying.where((id) => !videosToPlay.contains(id)).toList();
    for (final videoId in videosToStop) {
      await _stopVideo(videoId);
    }
    
    // Start videos that should be playing
    for (final videoId in videosToPlay) {
      if (!_currentlyPlaying.contains(videoId)) {
        await _startVideo(videoId);
      }
    }
    
    _emitEvent(DualVideoEvent(
      type: DualVideoEventType.playbackStateChanged,
      data: {
        'playing': _currentlyPlaying.toList(),
        'visible': _visibleVideos.toList(),
        'strategy': _currentStrategy?.description,
      },
    ));
  }

  /// Start video playback
  Future<void> _startVideo(String videoId) async {
    final video = _videoCache[videoId];
    if (video == null) return;

    try {
      _currentlyPlaying.add(videoId);

      // Update video state
      _videoCache[videoId] = video.copyWith(
        isPlaying: true,
        lastPlayedAt: DateTime.now(),
      );

      if (kDebugMode) {
        print('[DualVideoManager] Started video: $videoId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[DualVideoManager] Failed to start video $videoId: $e');
      }
    }
  }

  /// Stop video playback
  Future<void> _stopVideo(String videoId) async {
    if (!_currentlyPlaying.contains(videoId)) return;

    _currentlyPlaying.remove(videoId);

    // Update video state
    final video = _videoCache[videoId];
    if (video != null) {
      _videoCache[videoId] = video.copyWith(
        isPlaying: false,
        lastPosition: 0.0,
      );
    }

    if (kDebugMode) {
      print('[DualVideoManager] Stopped video: $videoId');
    }
  }



  /// Pre-cache video file for smooth playback
  void _preCacheVideo(DualVideoClipModel video) {
    // This would integrate with the existing cache manager
    // For now, we'll just mark it as cached
    if (kDebugMode) {
      print('[DualVideoManager] Pre-caching video: ${video.id}');
    }
  }

  /// Emit event to listeners
  void _emitEvent(DualVideoEvent event) {
    _eventController.add(event);
  }

  /// Dispose all resources
  Future<void> dispose() async {
    _visibilityTimer?.cancel();

    // Stop all playing videos
    for (final videoId in _currentlyPlaying.toList()) {
      await _stopVideo(videoId);
    }

    _nativePlayerIds.clear();
    _videoCache.clear();
    _currentlyPlaying.clear();
    _visibleVideos.clear();
    _videoPriorities.clear();

    _eventController.close();
    _isInitialized = false;

    if (kDebugMode) {
      print('[DualVideoManager] Disposed all resources');
    }
  }
}

/// Event data for dual video playback
class DualVideoEvent {
  final DualVideoEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  DualVideoEvent({
    required this.type,
    required this.data,
  }) : timestamp = DateTime.now();
}

/// Types of dual video events
enum DualVideoEventType {
  initialized,
  playbackStateChanged,
  videoLoaded,
  error,
  fallbackMode,
}
