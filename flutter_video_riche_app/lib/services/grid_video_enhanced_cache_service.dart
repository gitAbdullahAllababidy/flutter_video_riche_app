import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:media_kit/media_kit.dart';

import '../models/grid_video_model.dart';

/// Enhanced session-based caching service with flutter_cache_manager integration
/// Manages video metadata, playback positions, loading states, and cached video files
class GridVideoEnhancedCacheService {
  static final GridVideoEnhancedCacheService _instance = GridVideoEnhancedCacheService._internal();
  factory GridVideoEnhancedCacheService() => _instance;
  GridVideoEnhancedCacheService._internal();

  // Custom cache manager for videos
  static const key = 'gridVideoCache';
  static CacheManager get cacheManager => CacheManager(
    Config(
      key,
      stalePeriod: const Duration(hours: 24), // Cache videos for 24 hours
      maxNrOfCacheObjects: 50, // Max 50 cached videos
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );

  // Video metadata and state cache
  final Map<String, GridVideoModel> _videoCache = {};
  
  // Player instances cache (max 2 for concurrent playback)
  final Map<String, Player> _playerCache = {};
  
  // Cached video file paths
  final Map<String, String> _cachedVideoFiles = {};
  
  // Video duration cache (utilizing the duration parameter)
  final Map<String, Duration> _videoDurations = {};
  
  // Loading states
  final Map<String, bool> _thumbnailLoadingStates = {};
  final Map<String, bool> _videoLoadingStates = {};
  final Map<String, bool> _videoCacheStates = {}; // New: track video file caching
  
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

  /// Cache a video model with metadata and pre-cache video file
  Future<void> cacheVideo(GridVideoModel video) async {
    _videoCache[video.id] = video;
    
    // Pre-cache video file for smooth playback
    _preCacheVideoFile(video.id, video.url);
    
    _notifyCacheUpdate();
    
    if (kDebugMode) {
      print('[EnhancedVideoCache] Cached video: ${video.id} (${video.title})');
    }
  }

  /// Pre-cache video file using flutter_cache_manager
  Future<void> _preCacheVideoFile(String videoId, String videoUrl) async {
    try {
      _videoCacheStates[videoId] = true; // Mark as caching
      
      // Download and cache the video file
      final fileInfo = await cacheManager.downloadFile(videoUrl);
      if (fileInfo.file.existsSync()) {
        _cachedVideoFiles[videoId] = fileInfo.file.path;
        
        if (kDebugMode) {
          print('[EnhancedVideoCache] Pre-cached video file: $videoId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[EnhancedVideoCache] Failed to pre-cache video $videoId: $e');
      }
      
      // Update video with error information
      final video = _videoCache[videoId];
      if (video != null) {
        final updatedVideo = video.copyWith(
          hasError: true,
          errorMessage: 'Failed to cache video: $e',
        );
        _videoCache[videoId] = updatedVideo;
        _notifyCacheUpdate();
      }
    } finally {
      _videoCacheStates[videoId] = false; // Mark caching complete
    }
  }

  /// Get cached video file path or original URL
  String getVideoSource(String videoId) {
    return _cachedVideoFiles[videoId] ?? _videoCache[videoId]?.url ?? '';
  }

  /// Get cached video by ID
  GridVideoModel? getCachedVideo(String videoId) {
    return _videoCache[videoId];
  }

  /// Update video state in cache with proper utilization of all parameters
  void updateVideoState(String videoId, GridVideoModel updatedVideo) {
    if (_videoCache.containsKey(videoId)) {
      // Ensure duration is captured and cached
      if (updatedVideo.duration != null) {
        _videoDurations[videoId] = updatedVideo.duration!;
      }
      
      _videoCache[videoId] = updatedVideo;
      _notifyCacheUpdate();
      
      if (kDebugMode) {
        print('[EnhancedVideoCache] Updated video state: $videoId - Playing: ${updatedVideo.isPlaying}, Visible: ${updatedVideo.isVisible}, Position: ${updatedVideo.lastPosition}s');
        
        // Log error messages when present
        if (updatedVideo.hasError && updatedVideo.errorMessage != null) {
          print('[EnhancedVideoCache] Video error for $videoId: ${updatedVideo.errorMessage}');
        }
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
      print('[EnhancedVideoCache] Cached player for video: $videoId');
    }
  }

  /// Get cached player instance
  Player? getCachedPlayer(String videoId) {
    return _playerCache[videoId];
  }

  /// Get video duration (utilizing duration parameter)
  Duration? getVideoDuration(String videoId) {
    final video = _videoCache[videoId];
    return video?.duration ?? _videoDurations[videoId];
  }

  /// Update video duration
  void updateVideoDuration(String videoId, Duration duration) {
    _videoDurations[videoId] = duration;
    
    final video = _videoCache[videoId];
    if (video != null) {
      final updatedVideo = video.copyWith(duration: duration);
      _videoCache[videoId] = updatedVideo;
      _notifyCacheUpdate();
    }
  }

  /// Add video to playing list (max 2)
  bool addToPlayingList(String videoId) {
    if (_playingVideos.contains(videoId)) {
      return true; // Already playing
    }
    
    if (_playingVideos.length >= 2) {
      if (kDebugMode) {
        print('[EnhancedVideoCache] Cannot add $videoId to playing list - max 2 videos already playing');
      }
      return false; // Max limit reached
    }
    
    _playingVideos.add(videoId);
    _playingVideosController.add(_playingVideos);
    
    if (kDebugMode) {
      print('[EnhancedVideoCache] Added $videoId to playing list. Total playing: ${_playingVideos.length}');
    }
    
    return true;
  }

  /// Remove video from playing list
  void removeFromPlayingList(String videoId) {
    if (_playingVideos.remove(videoId)) {
      _playingVideosController.add(_playingVideos);
      
      if (kDebugMode) {
        print('[EnhancedVideoCache] Removed $videoId from playing list. Total playing: ${_playingVideos.length}');
      }
    }
  }

  /// Check if video can start playing (respects max 2 limit)
  bool canVideoPlay(String videoId) {
    return _playingVideos.contains(videoId) || _playingVideos.length < 2;
  }

  /// Get priority score for video playback (improved algorithm using all parameters)
  int getPlaybackPriority(String videoId) {
    final video = _videoCache[videoId];
    if (video == null) return 0;
    
    int priority = 0;
    
    // Recently played videos get higher priority (utilizing lastPlayedAt)
    if (video.lastPlayedAt != null) {
      final timeSinceLastPlayed = DateTime.now().difference(video.lastPlayedAt!).inMinutes;
      priority += (60 - timeSinceLastPlayed).clamp(0, 60);
    }
    
    // Visible videos get highest priority
    if (video.isVisible) {
      priority += 100;
    }
    
    // Already loaded videos get priority
    if (video.isLoaded) {
      priority += 20;
    }
    
    // Videos with cached files get priority
    if (_cachedVideoFiles.containsKey(videoId)) {
      priority += 15;
    }
    
    // Videos with known duration get slight priority (utilizing duration parameter)
    if (video.duration != null || _videoDurations.containsKey(videoId)) {
      priority += 5;
    }
    
    // Videos without errors get priority
    if (!video.hasError) {
      priority += 10;
    }
    
    // Consider playback position for resuming (utilizing lastPosition)
    if (video.lastPosition > 0) {
      priority += 8; // Partially watched videos get some priority
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

  /// Check if video file is being cached
  bool isVideoCaching(String videoId) {
    return _videoCacheStates[videoId] ?? false;
  }

  /// Clear cache for specific video
  Future<void> clearVideoCache(String videoId) async {
    _videoCache.remove(videoId);
    _videoDurations.remove(videoId);
    _thumbnailLoadingStates.remove(videoId);
    _videoLoadingStates.remove(videoId);
    _videoCacheStates.remove(videoId);
    
    // Remove cached file
    final cachedPath = _cachedVideoFiles.remove(videoId);
    if (cachedPath != null) {
      try {
        await cacheManager.removeFile(cachedPath);
      } catch (e) {
        if (kDebugMode) {
          print('[EnhancedVideoCache] Failed to remove cached file: $e');
        }
      }
    }
    
    removeFromPlayingList(videoId);
    _disposePlayer(videoId);
    _notifyCacheUpdate();
    
    if (kDebugMode) {
      print('[EnhancedVideoCache] Cleared cache for video: $videoId');
    }
  }

  /// Clear entire session cache
  Future<void> clearAllCache() async {
    // Dispose all players first
    for (final videoId in _playerCache.keys.toList()) {
      _disposePlayer(videoId);
    }
    
    // Clear cached files
    try {
      await cacheManager.emptyCache();
    } catch (e) {
      if (kDebugMode) {
        print('[EnhancedVideoCache] Failed to clear cache files: $e');
      }
    }
    
    _videoCache.clear();
    _videoDurations.clear();
    _cachedVideoFiles.clear();
    _thumbnailLoadingStates.clear();
    _videoLoadingStates.clear();
    _videoCacheStates.clear();
    _playingVideos.clear();
    
    _notifyCacheUpdate();
    _playingVideosController.add(_playingVideos);
    
    if (kDebugMode) {
      print('[EnhancedVideoCache] Cleared all session cache');
    }
  }

  /// Get comprehensive cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalVideos': _videoCache.length,
      'playingVideos': _playingVideos.length,
      'cachedPlayers': _playerCache.length,
      'cachedVideoFiles': _cachedVideoFiles.length,
      'videosWithDuration': _videoDurations.length,
      'sessionDuration': DateTime.now().difference(_sessionStartTime).inMinutes,
      'loadingThumbnails': _thumbnailLoadingStates.values.where((loading) => loading).length,
      'loadingVideos': _videoLoadingStates.values.where((loading) => loading).length,
      'cachingVideos': _videoCacheStates.values.where((caching) => caching).length,
      'videosWithErrors': _videoCache.values.where((video) => video.hasError).length,
      'averagePosition': _calculateAveragePosition(),
    };
  }

  /// Calculate average playback position across all videos
  double _calculateAveragePosition() {
    if (_videoCache.isEmpty) return 0.0;
    
    final totalPosition = _videoCache.values
        .map((video) => video.lastPosition)
        .fold(0.0, (sum, position) => sum + position);
    
    return totalPosition / _videoCache.length;
  }

  /// Dispose player instance
  void _disposePlayer(String videoId) {
    final player = _playerCache.remove(videoId);
    if (player != null) {
      try {
        player.dispose();
        if (kDebugMode) {
          print('[EnhancedVideoCache] Disposed player for video: $videoId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('[EnhancedVideoCache] Error disposing player for $videoId: $e');
        }
      }
    }
  }

  /// Notify cache update listeners
  void _notifyCacheUpdate() {
    _cacheUpdatesController.add(_videoCache);
  }

  /// Dispose the cache service
  Future<void> dispose() async {
    await clearAllCache();
    _cacheUpdatesController.close();
    _playingVideosController.close();
    
    if (kDebugMode) {
      print('[EnhancedVideoCache] Disposed cache service');
    }
  }
} 