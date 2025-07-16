import 'dart:async';

import 'package:flutter/foundation.dart';

import 'grid_video_cache_service.dart';

/// Manages video playback with intelligent prioritization and resource optimization
class GridVideoPlaybackManager {
  static final GridVideoPlaybackManager _instance = GridVideoPlaybackManager._internal();
  factory GridVideoPlaybackManager() => _instance;
  GridVideoPlaybackManager._internal();

  final GridVideoCacheService _cacheService = GridVideoCacheService();
  
  // Scroll detection
  bool _isScrolling = false;
  Timer? _scrollStopTimer;
  final Duration _scrollDebounceDelay = const Duration(milliseconds: 300);
  
  // Performance monitoring
  int _playbackRequests = 0;
  int _playbackDenials = 0;
  DateTime? _lastPerformanceCheck;
  
  // Stream controllers for manager events
  final StreamController<PlaybackEvent> _eventsController = StreamController.broadcast();
  final StreamController<PlaybackStats> _statsController = StreamController.broadcast();

  // Getters
  bool get isScrolling => _isScrolling;
  Stream<PlaybackEvent> get events => _eventsController.stream;
  Stream<PlaybackStats> get stats => _statsController.stream;

  /// Handle scroll state changes from UI
  void onScrollStateChanged(bool isScrolling) {
    if (_isScrolling == isScrolling) return;
    
    _isScrolling = isScrolling;
    
    if (isScrolling) {
      _handleScrollStart();
    } else {
      _handleScrollStop();
    }
    
    if (kDebugMode) {
      print('[PlaybackManager] Scroll state: ${isScrolling ? "started" : "stopped"}');
    }
  }

  /// Handle start of scrolling
  void _handleScrollStart() {
    _scrollStopTimer?.cancel();
    
    // Pause all videos immediately when scrolling starts
    final playingVideos = _cacheService.playingVideos.toList();
    for (final videoId in playingVideos) {
      _pauseVideo(videoId, PlaybackPauseReason.scrolling);
    }
    
    _emitEvent(PlaybackEvent(
      type: PlaybackEventType.scrollStarted,
      timestamp: DateTime.now(),
      affectedVideos: playingVideos,
    ));
  }

  /// Handle end of scrolling with debounce
  void _handleScrollStop() {
    _scrollStopTimer?.cancel();
    _scrollStopTimer = Timer(_scrollDebounceDelay, () {
      _isScrolling = false;
      _resumeVisibleVideos();
      
      _emitEvent(PlaybackEvent(
        type: PlaybackEventType.scrollStopped,
        timestamp: DateTime.now(),
      ));
      
      if (kDebugMode) {
        print('[PlaybackManager] Scroll settled - resuming visible videos');
      }
    });
  }

  /// Request playback for a video with priority system
  Future<bool> requestPlayback(String videoId, {PlaybackPriority priority = PlaybackPriority.normal}) async {
    _playbackRequests++;
    
    if (_isScrolling) {
      if (kDebugMode) {
        print('[PlaybackManager] Denying playback for $videoId - currently scrolling');
      }
      _playbackDenials++;
      return false;
    }

    final video = _cacheService.getCachedVideo(videoId);
    if (video == null) {
      if (kDebugMode) {
        print('[PlaybackManager] Video $videoId not found in cache');
      }
      _playbackDenials++;
      return false;
    }

    // Check if video can play (max 2 limit)
    if (_cacheService.canVideoPlay(videoId)) {
      return await _startPlayback(videoId, priority);
    }

    // Try to free up a slot by stopping lower priority video
    final success = await _freePlaybackSlot(videoId, priority);
    if (success) {
      return await _startPlayback(videoId, priority);
    }

    _playbackDenials++;
    return false;
  }

  /// Stop playback for a video
  void stopPlayback(String videoId, {PlaybackStopReason reason = PlaybackStopReason.notVisible}) {
    if (_cacheService.playingVideos.contains(videoId)) {
      _cacheService.removeFromPlayingList(videoId);
      
      final video = _cacheService.getCachedVideo(videoId);
      if (video != null) {
        final updatedVideo = video.copyWith(isPlaying: false);
        _cacheService.updateVideoState(videoId, updatedVideo);
      }
      
      _emitEvent(PlaybackEvent(
        type: PlaybackEventType.stopped,
        timestamp: DateTime.now(),
        videoId: videoId,
        reason: reason.toString(),
      ));
      
      if (kDebugMode) {
        print('[PlaybackManager] Stopped playback: $videoId (${reason.name})');
      }
    }
  }

  /// Pause video temporarily (can be resumed)
  void _pauseVideo(String videoId, PlaybackPauseReason reason) {
    final video = _cacheService.getCachedVideo(videoId);
    if (video != null && video.isPlaying) {
      final updatedVideo = video.copyWith(isPlaying: false);
      _cacheService.updateVideoState(videoId, updatedVideo);
      
      _emitEvent(PlaybackEvent(
        type: PlaybackEventType.paused,
        timestamp: DateTime.now(),
        videoId: videoId,
        reason: reason.toString(),
      ));
      
      if (kDebugMode) {
        print('[PlaybackManager] Paused video: $videoId (${reason.name})');
      }
    }
  }

  /// Resume visible videos after scroll or other events
  void _resumeVisibleVideos() {
    final allVideos = _cacheService.cachedVideos.values.toList();
    final visibleVideos = allVideos.where((video) => video.isVisible && !video.hasError).toList();
    
    // Sort by priority for fair resumption
    visibleVideos.sort((a, b) {
      final priorityA = _cacheService.getPlaybackPriority(a.id);
      final priorityB = _cacheService.getPlaybackPriority(b.id);
      return priorityB.compareTo(priorityA); // Higher priority first
    });
    
    int resumed = 0;
    for (final video in visibleVideos) {
      if (resumed >= 2) break; // Max 2 concurrent videos
      
      if (!video.isPlaying && _cacheService.canVideoPlay(video.id)) {
        _startPlayback(video.id, PlaybackPriority.normal);
        resumed++;
      }
    }
    
    if (kDebugMode) {
      print('[PlaybackManager] Resumed $resumed visible videos');
    }
  }

  /// Try to free up a playback slot by stopping lower priority video
  Future<bool> _freePlaybackSlot(String requestingVideoId, PlaybackPriority requestPriority) async {
    final playingVideos = _cacheService.playingVideos;
    if (playingVideos.length < 2) return true;
    
    final requestingPriority = _calculateDynamicPriority(requestingVideoId, requestPriority);
    
    String? lowestPriorityVideoId;
    int lowestPriority = double.maxFinite.toInt();
    
    for (final playingVideoId in playingVideos) {
      final priority = _calculateDynamicPriority(playingVideoId, PlaybackPriority.normal);
      if (priority < lowestPriority) {
        lowestPriority = priority;
        lowestPriorityVideoId = playingVideoId;
      }
    }
    
    if (lowestPriorityVideoId != null && requestingPriority > lowestPriority) {
      stopPlayback(lowestPriorityVideoId, reason: PlaybackStopReason.priorityReplaced);
      
      if (kDebugMode) {
        print('[PlaybackManager] Freed slot: stopped $lowestPriorityVideoId (priority: $lowestPriority) for $requestingVideoId (priority: $requestingPriority)');
      }
      
      return true;
    }
    
    return false;
  }

  /// Calculate dynamic priority including context factors
  int _calculateDynamicPriority(String videoId, PlaybackPriority basePriority) {
    int priority = _cacheService.getPlaybackPriority(videoId);
    
    // Apply base priority multiplier
    switch (basePriority) {
      case PlaybackPriority.low:
        priority = (priority * 0.8).round();
        break;
      case PlaybackPriority.normal:
        // No change
        break;
      case PlaybackPriority.high:
        priority = (priority * 1.2).round();
        break;
    }
    
    return priority;
  }

  /// Start playback for a video
  Future<bool> _startPlayback(String videoId, PlaybackPriority priority) async {
    if (!_cacheService.addToPlayingList(videoId)) {
      return false;
    }
    
    final video = _cacheService.getCachedVideo(videoId);
    if (video != null) {
      final updatedVideo = video.copyWith(
        isPlaying: true,
        lastPlayedAt: DateTime.now(),
      );
      _cacheService.updateVideoState(videoId, updatedVideo);
      
      _emitEvent(PlaybackEvent(
        type: PlaybackEventType.started,
        timestamp: DateTime.now(),
        videoId: videoId,
        priority: priority.toString(),
      ));
      
      if (kDebugMode) {
        print('[PlaybackManager] Started playback: $videoId (${priority.name})');
      }
      
      return true;
    }
    
    return false;
  }

  /// Get current playback statistics
  PlaybackStats getStats() {
    final stats = PlaybackStats(
      totalRequests: _playbackRequests,
      totalDenials: _playbackDenials,
      successRate: _playbackRequests > 0 ? (_playbackRequests - _playbackDenials) / _playbackRequests : 0.0,
      currentlyPlaying: _cacheService.playingVideos.length,
      maxConcurrent: 2,
      isScrolling: _isScrolling,
      timestamp: DateTime.now(),
    );
    
    _emitStats(stats);
    return stats;
  }

  /// Emit playback event
  void _emitEvent(PlaybackEvent event) {
    _eventsController.add(event);
  }

  /// Emit stats update
  void _emitStats(PlaybackStats stats) {
    _statsController.add(stats);
  }

  /// Dispose the manager
  void dispose() {
    _scrollStopTimer?.cancel();
    _eventsController.close();
    _statsController.close();
    
    if (kDebugMode) {
      print('[PlaybackManager] Disposed');
    }
  }
}

/// Playback priority levels
enum PlaybackPriority {
  low,
  normal,
  high,
}

/// Reasons for stopping playback
enum PlaybackStopReason {
  notVisible,
  priorityReplaced,
  userAction,
  error,
  sessionEnd,
}

/// Reasons for pausing playback
enum PlaybackPauseReason {
  scrolling,
  backgrounded,
  resourceConstraint,
}

/// Playback event types
enum PlaybackEventType {
  started,
  stopped,
  paused,
  resumed,
  scrollStarted,
  scrollStopped,
  error,
}

/// Playback event data
class PlaybackEvent {
  final PlaybackEventType type;
  final DateTime timestamp;
  final String? videoId;
  final String? reason;
  final String? priority;
  final List<String>? affectedVideos;

  const PlaybackEvent({
    required this.type,
    required this.timestamp,
    this.videoId,
    this.reason,
    this.priority,
    this.affectedVideos,
  });

  @override
  String toString() {
    return 'PlaybackEvent(type: $type, videoId: $videoId, reason: $reason, timestamp: $timestamp)';
  }
}

/// Playback statistics
class PlaybackStats {
  final int totalRequests;
  final int totalDenials;
  final double successRate;
  final int currentlyPlaying;
  final int maxConcurrent;
  final bool isScrolling;
  final DateTime timestamp;

  const PlaybackStats({
    required this.totalRequests,
    required this.totalDenials,
    required this.successRate,
    required this.currentlyPlaying,
    required this.maxConcurrent,
    required this.isScrolling,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'PlaybackStats(requests: $totalRequests, denials: $totalDenials, successRate: ${(successRate * 100).toStringAsFixed(1)}%, playing: $currentlyPlaying/$maxConcurrent)';
  }
} 