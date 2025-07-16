import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import '../models/grid_video_model.dart';

/// Session-based caching service for grid videos
/// Manages video metadata, playback positions, loading states, and thumbnail images
class GridVideoCacheService {
  static final GridVideoCacheService _instance = GridVideoCacheService._internal();
  factory GridVideoCacheService() => _instance;
  GridVideoCacheService._internal();

  // Video metadata and state cache
  final Map<String, GridVideoModel> _videoCache = {};
  
  // Player instances cache (max 2 for concurrent playback)
  final Map<String, Player> _playerCache = {};
  
  // Thumbnail loading states
  final Map<String, bool> _thumbnailLoadingStates = {};
  
  // Video loading states
  final Map<String, bool> _videoLoadingStates = {};
  
  // Currently playing videos (max 2)
  final List<String> _playingVideos = [];
  
  // Session timestamp for cache validation
  final DateTime _sessionStartTime = DateTime.now();
  
  // Stream controllers for state updates
  final StreamController<Map<String, GridVideoModel>> _cacheUpdatesController = StreamController.broadcast();
  final StreamController<List<String>> _playingVideosController = StreamController.broadcast();

  // Getters
  Map<String, GridVideoModel> get cachedVideos => Map.unmodifiable(_videoCache);
  List<String> get playingVideos => List.unmodifiable(_playingVideos);
  Stream<Map<String, GridVideoModel>> get cacheUpdates => _cacheUpdatesController.stream;
  Stream<List<String>> get playingVideosStream => _playingVideosController.stream;

  /// Cache a video model with metadata
  void cacheVideo(GridVideoModel video) {
    _videoCache[video.id] = video;
    _notifyCacheUpdate();
    
    if (kDebugMode) {
      print('[GridVideoCache] Cached video: ${video.id} (${video.title})');
    }
  }

  /// Get cached video by ID
  GridVideoModel? getCachedVideo(String videoId) {
    return _videoCache[videoId];
  }

  /// Update video state in cache
  void updateVideoState(String videoId, GridVideoModel updatedVideo) {
    if (_videoCache.containsKey(videoId)) {
      _videoCache[videoId] = updatedVideo;
      _notifyCacheUpdate();
      
      if (kDebugMode) {
        print('[GridVideoCache] Updated video state: $videoId - Playing: ${updatedVideo.isPlaying}, Visible: ${updatedVideo.isVisible}');
      }
    }
  }

  /// Cache player instance
  void cachePlayer(String videoId, Player player) {
    // Enforce max 2 players limit
    if (_playerCache.length >= 2 && !_playerCache.containsKey(videoId)) {
      // Remove oldest player if we exceed limit
      final oldestVideoId = _playerCache.keys.first;
      _disposePlayer(oldestVideoId);
    }
    
    _playerCache[videoId] = player;
    
    if (kDebugMode) {
      print('[GridVideoCache] Cached player for video: $videoId');
    }
  }

  /// Get cached player instance
  Player? getCachedPlayer(String videoId) {
    return _playerCache[videoId];
  }

  /// Add video to playing list (max 2)
  bool addToPlayingList(String videoId) {
    if (_playingVideos.contains(videoId)) {
      return true; // Already playing
    }
    
    if (_playingVideos.length >= 2) {
      if (kDebugMode) {
        print('[GridVideoCache] Cannot add $videoId to playing list - max 2 videos already playing');
      }
      return false; // Max limit reached
    }
    
    _playingVideos.add(videoId);
    _playingVideosController.add(_playingVideos);
    
    if (kDebugMode) {
      print('[GridVideoCache] Added $videoId to playing list. Total playing: ${_playingVideos.length}');
    }
    
    return true;
  }

  /// Remove video from playing list
  void removeFromPlayingList(String videoId) {
    if (_playingVideos.remove(videoId)) {
      _playingVideosController.add(_playingVideos);
      
      if (kDebugMode) {
        print('[GridVideoCache] Removed $videoId from playing list. Total playing: ${_playingVideos.length}');
      }
    }
  }

  /// Check if video can start playing (respects max 2 limit)
  bool canVideoPlay(String videoId) {
    return _playingVideos.contains(videoId) || _playingVideos.length < 2;
  }

  /// Get priority score for video playback (higher score = higher priority)
  int getPlaybackPriority(String videoId) {
    final video = _videoCache[videoId];
    if (video == null) return 0;
    
    int priority = 0;
    
    // Recently played videos get higher priority
    if (video.lastPlayedAt != null) {
      final timeSinceLastPlayed = DateTime.now().difference(video.lastPlayedAt!).inMinutes;
      priority += (60 - timeSinceLastPlayed).clamp(0, 60);
    }
    
    // Visible videos get higher priority
    if (video.isVisible) {
      priority += 100;
    }
    
    // Already loaded videos get slight priority
    if (video.isLoaded) {
      priority += 10;
    }
    
    return priority;
  }

  /// Set thumbnail loading state
  void setThumbnailLoading(String videoId, bool isLoading) {
    _thumbnailLoadingStates[videoId] = isLoading;
  }

  /// Check if thumbnail is loading
  bool isThumbnailLoading(String videoId) {
    return _thumbnailLoadingStates[videoId] ?? false;
  }

  /// Set video loading state
  void setVideoLoading(String videoId, bool isLoading) {
    _videoLoadingStates[videoId] = isLoading;
  }

  /// Check if video is loading
  bool isVideoLoading(String videoId) {
    return _videoLoadingStates[videoId] ?? false;
  }

  /// Clear cache for specific video
  void clearVideoCache(String videoId) {
    _videoCache.remove(videoId);
    _thumbnailLoadingStates.remove(videoId);
    _videoLoadingStates.remove(videoId);
    removeFromPlayingList(videoId);
    _disposePlayer(videoId);
    _notifyCacheUpdate();
    
    if (kDebugMode) {
      print('[GridVideoCache] Cleared cache for video: $videoId');
    }
  }

  /// Clear entire session cache
  void clearAllCache() {
    // Dispose all players first
    for (final videoId in _playerCache.keys.toList()) {
      _disposePlayer(videoId);
    }
    
    _videoCache.clear();
    _thumbnailLoadingStates.clear();
    _videoLoadingStates.clear();
    _playingVideos.clear();
    
    _notifyCacheUpdate();
    _playingVideosController.add(_playingVideos);
    
    if (kDebugMode) {
      print('[GridVideoCache] Cleared all session cache');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalVideos': _videoCache.length,
      'playingVideos': _playingVideos.length,
      'cachedPlayers': _playerCache.length,
      'sessionDuration': DateTime.now().difference(_sessionStartTime).inMinutes,
      'loadingThumbnails': _thumbnailLoadingStates.values.where((loading) => loading).length,
      'loadingVideos': _videoLoadingStates.values.where((loading) => loading).length,
    };
  }

  /// Dispose player instance
  void _disposePlayer(String videoId) {
    final player = _playerCache.remove(videoId);
    if (player != null) {
      try {
        player.dispose();
        if (kDebugMode) {
          print('[GridVideoCache] Disposed player for video: $videoId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('[GridVideoCache] Error disposing player for $videoId: $e');
        }
      }
    }
  }

  /// Notify cache update listeners
  void _notifyCacheUpdate() {
    _cacheUpdatesController.add(_videoCache);
  }

  /// Dispose the cache service
  void dispose() {
    clearAllCache();
    _cacheUpdatesController.close();
    _playingVideosController.close();
    
    if (kDebugMode) {
      print('[GridVideoCache] Disposed cache service');
    }
  }
} 