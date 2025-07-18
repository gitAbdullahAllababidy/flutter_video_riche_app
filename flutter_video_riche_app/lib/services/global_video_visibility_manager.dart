import 'dart:async';
import 'package:flutter/foundation.dart';

/// Global manager to ensure only 2 videos play at a time across the entire app
class GlobalVideoVisibilityManager {
  static final GlobalVideoVisibilityManager _instance = GlobalVideoVisibilityManager._internal();
  factory GlobalVideoVisibilityManager() => _instance;
  GlobalVideoVisibilityManager._internal();

  // Track visible videos with their visibility timestamps
  final Map<String, DateTime> _visibleVideos = {};
  final Map<String, VoidCallback?> _playCallbacks = {};
  final Map<String, VoidCallback?> _pauseCallbacks = {};
  
  // Currently playing videos (max 2)
  final Set<String> _currentlyPlaying = {};
  
  // Configuration
  static const int maxConcurrentVideos = 2;
  static const Duration visibilityDebounce = Duration(milliseconds: 150);
  
  Timer? _debounceTimer;
  bool _isDisposed = false;

  /// Register a video with play/pause callbacks
  void registerVideo(String videoId, {
    VoidCallback? onPlay,
    VoidCallback? onPause,
  }) {
    if (_isDisposed) return;
    
    _playCallbacks[videoId] = onPlay;
    _pauseCallbacks[videoId] = onPause;
    
    if (kDebugMode) {
      print('[GlobalVideoManager] 📝 Registered video: $videoId');
    }
  }

  /// Unregister a video
  void unregisterVideo(String videoId) {
    if (_isDisposed) return;
    
    _visibleVideos.remove(videoId);
    _playCallbacks.remove(videoId);
    _pauseCallbacks.remove(videoId);
    _currentlyPlaying.remove(videoId);
    
    // Trigger rebalancing after unregistering
    _debounceVisibilityUpdate();
    
    if (kDebugMode) {
      print('[GlobalVideoManager] 🗑️ Unregistered video: $videoId');
    }
  }

  /// Update video visibility
  void updateVideoVisibility(String videoId, bool isVisible) {
    if (_isDisposed) return;
    
    if (isVisible) {
      _visibleVideos[videoId] = DateTime.now();
      if (kDebugMode) {
        print('[GlobalVideoManager] 👁️ Video VISIBLE: $videoId');
      }
    } else {
      _visibleVideos.remove(videoId);
      _currentlyPlaying.remove(videoId);
      _pauseCallbacks[videoId]?.call();
      if (kDebugMode) {
        print('[GlobalVideoManager] 🙈 Video HIDDEN: $videoId');
      }
    }
    
    // Debounce visibility changes to avoid rapid switching
    _debounceVisibilityUpdate();
  }

  /// Debounce visibility updates
  void _debounceVisibilityUpdate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(visibilityDebounce, () {
      _updatePlaybackState();
    });
  }

  /// Update playback state to ensure only 2 videos play
  void _updatePlaybackState() {
    if (_isDisposed) return;
    
    // Get visible videos sorted by most recent visibility
    final sortedVisibleVideos = _visibleVideos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Most recent first
    
    // Determine which videos should be playing (top 2 most recent)
    final videosToPlay = sortedVisibleVideos
        .take(maxConcurrentVideos)
        .map((entry) => entry.key)
        .toList();
    
    // Stop videos that should no longer be playing
    final videosToStop = _currentlyPlaying.where((id) => !videosToPlay.contains(id)).toList();
    for (final videoId in videosToStop) {
      _stopVideo(videoId);
    }
    
    // Start videos that should be playing but aren't
    for (final videoId in videosToPlay) {
      if (!_currentlyPlaying.contains(videoId)) {
        _startVideo(videoId);
      }
    }
    
    if (kDebugMode) {
      print('[GlobalVideoManager] 🎬 Playback State Updated:');
      print('[GlobalVideoManager] 👁️ Visible videos: ${_visibleVideos.length}');
      print('[GlobalVideoManager] ▶️ Playing videos: ${_currentlyPlaying.length}/$maxConcurrentVideos');
      print('[GlobalVideoManager] 🎯 Currently playing: $_currentlyPlaying');
      print('[GlobalVideoManager] 📋 Should be playing: $videosToPlay');
    }
  }

  /// Start video playback
  void _startVideo(String videoId) {
    if (_isDisposed) return;
    
    _currentlyPlaying.add(videoId);
    _playCallbacks[videoId]?.call();
    
    if (kDebugMode) {
      print('[GlobalVideoManager] ▶️ STARTED playback: $videoId');
    }
  }

  /// Stop video playback
  void _stopVideo(String videoId) {
    if (_isDisposed) return;
    
    _currentlyPlaying.remove(videoId);
    _pauseCallbacks[videoId]?.call();
    
    if (kDebugMode) {
      print('[GlobalVideoManager] ⏸️ STOPPED playback: $videoId');
    }
  }

  /// Check if a video is currently playing
  bool isVideoPlaying(String videoId) {
    return _currentlyPlaying.contains(videoId);
  }

  /// Check if a video is visible
  bool isVideoVisible(String videoId) {
    return _visibleVideos.containsKey(videoId);
  }

  /// Get current playback statistics
  Map<String, dynamic> getPlaybackStats() {
    return {
      'visibleVideos': _visibleVideos.length,
      'playingVideos': _currentlyPlaying.length,
      'maxConcurrentVideos': maxConcurrentVideos,
      'currentlyPlaying': _currentlyPlaying.toList(),
      'visibleVideoIds': _visibleVideos.keys.toList(),
    };
  }

  /// Pause all videos (useful for app lifecycle events)
  void pauseAllVideos() {
    if (_isDisposed) return;
    
    for (final videoId in _currentlyPlaying.toList()) {
      _stopVideo(videoId);
    }
    
    if (kDebugMode) {
      print('[GlobalVideoManager] ⏸️ Paused all videos');
    }
  }

  /// Resume optimal playback (useful for app lifecycle events)
  void resumeOptimalPlayback() {
    if (_isDisposed) return;
    
    _updatePlaybackState();
    
    if (kDebugMode) {
      print('[GlobalVideoManager] ▶️ Resumed optimal playback');
    }
  }

  /// Dispose the manager
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    
    // Stop all videos
    for (final videoId in _currentlyPlaying.toList()) {
      _pauseCallbacks[videoId]?.call();
    }
    
    _visibleVideos.clear();
    _playCallbacks.clear();
    _pauseCallbacks.clear();
    _currentlyPlaying.clear();
    
    if (kDebugMode) {
      print('[GlobalVideoManager] 🗑️ Disposed global video manager');
    }
  }
}
