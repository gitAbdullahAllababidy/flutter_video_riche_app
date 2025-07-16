import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../models/grid_video_model.dart';
import '../services/grid_video_enhanced_cache_service.dart';

/// Sample video data provider
final gridVideoDataProvider = Provider<List<GridVideoModel>>((ref) {
  return [
    const GridVideoModel(
      id: 'grid_1',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/d0df89a1-b959-4397-b71f-4f3f0b25da33.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=400&auto=format&fit=crop&q=80',
      title: 'Mountain Adventure',
      description: 'Beautiful mountain landscape with stunning views',
    ),
    const GridVideoModel(
      id: 'grid_2',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/dbeef944-c64c-4b78-8e80-bdb22b60f6ad.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=400&auto=format&fit=crop&q=80',
      title: 'Ocean Waves',
      description: 'Relaxing ocean waves on a peaceful beach',
    ),
    const GridVideoModel(
      id: 'grid_3',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/25b57cb5-64a6-417f-b464-a024c3d73061.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&auto=format&fit=crop&q=80',
      title: 'Forest Walk',
      description: 'Walking through a lush green forest',
    ),
    const GridVideoModel(
      id: 'grid_4',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/20/9e4c4767-6a22-4428-8eac-2723b7167c15.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=400&auto=format&fit=crop&q=80',
      title: 'City Sunset',
      description: 'Urban cityscape during golden hour',
    ),
    const GridVideoModel(
      id: 'grid_5',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/20/8f7e4860-7609-44c8-9a87-8296a7398275.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=400&auto=format&fit=crop&q=80',
      title: 'River Flow',
      description: 'Gentle river flowing through the valley',
    ),
    const GridVideoModel(
      id: 'grid_6',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/19/db4b3a63-f3ae-4761-82b0-c287acdf4b3b.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=400&auto=format&fit=crop&q=80',
      title: 'Desert Dunes',
      description: 'Sand dunes in the desert landscape',
    ),
    const GridVideoModel(
      id: 'grid_7',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/e85edcd1-57b4-401a-b380-1f9f86dd6f9f.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&auto=format&fit=crop&q=80',
      title: 'Winter Snow',
      description: 'Snow-covered pine trees in winter',
    ),
    const GridVideoModel(
      id: 'grid_8',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/9114dffa-2cfc-4f9f-b375-6de249bbb329.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=400&auto=format&fit=crop&q=80',
      title: 'Tropical Beach',
      description: 'Palm trees swaying on tropical beach',
    ),
    const GridVideoModel(
      id: 'grid_9',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/f858ae9b-e967-4ed8-bb65-d55175b8ee23.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=400&auto=format&fit=crop&q=80',
      title: 'Aurora Lights',
      description: 'Northern lights dancing in the sky',
    ),
    const GridVideoModel(
      id: 'grid_10',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/d0df89a1-b959-4397-b71f-4f3f0b25da33.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=400&auto=format&fit=crop&q=80',
      title: 'Waterfall',
      description: 'Majestic waterfall in natural setting',
    ),
    const GridVideoModel(
      id: 'grid_11',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/dbeef944-c64c-4b78-8e80-bdb22b60f6ad.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&auto=format&fit=crop&q=80',
      title: 'Space Stars',
      description: 'Time-lapse of stars in night sky',
    ),
    const GridVideoModel(
      id: 'grid_12',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/25b57cb5-64a6-417f-b464-a024c3d73061.mp4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=400&auto=format&fit=crop&q=80',
      title: 'Flower Bloom',
      description: 'Beautiful flowers blooming in spring',
    ),
  ];
});

/// Grid video cache service provider
final gridVideoCacheServiceProvider = Provider<GridVideoEnhancedCacheService>((ref) {
  final service = GridVideoEnhancedCacheService();
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Grid video state notifier for managing video state
class GridVideoStateNotifier extends StateNotifier<Map<String, GridVideoModel>> {
  GridVideoStateNotifier(this._cacheService, this._videoData) : super({}) {
    _initializeVideos();
    _setupCacheListener();
  }

  final GridVideoEnhancedCacheService _cacheService;
  final List<GridVideoModel> _videoData;
  
  // Debounce timers for visibility changes
  final Map<String, Timer> _debounceTimers = {};
  
  // Scroll detection
  bool _isScrolling = false;
  Timer? _scrollDebounceTimer;
  
  // Periodic optimization timer
  Timer? _optimizationTimer;

  /// Initialize videos in cache
  void _initializeVideos() {
    final videoMap = <String, GridVideoModel>{};
    for (final video in _videoData) {
      _cacheService.cacheVideo(video);
      videoMap[video.id] = video;
    }
    state = videoMap;
    
    if (kDebugMode) {
      print('[GridVideoProvider] Initialized ${_videoData.length} videos');
    }
  }

  /// Setup cache update listener
  void _setupCacheListener() {
    _cacheService.cacheUpdates.listen((cacheData) {
      state = cacheData;
    });
  }

  /// Handle visibility change with debounce
  void onVideoVisibilityChanged(String videoId, VisibilityInfo info) {
    final isVisible = info.visibleFraction > 0.6; // 60% visibility threshold
    
    // Cancel existing timer for this video
    _debounceTimers[videoId]?.cancel();
    
    // Update visibility immediately in state
    _updateVideoVisibility(videoId, isVisible);
    
    // Debounce the playback decision (150ms settling time as per requirement)
    _debounceTimers[videoId] = Timer(const Duration(milliseconds: 150), () {
      _handleDebouncedVisibilityChange(videoId, isVisible);
    });
  }

  /// Handle scroll state changes
  void onScrollStateChanged(bool isScrolling) {
    _isScrolling = isScrolling;
    
    // Cancel scroll debounce timer
    _scrollDebounceTimer?.cancel();
    
    if (isScrolling) {
      // Pause all videos when scrolling starts
      _pauseAllVideos();
      // Cancel optimization during scrolling
      _cancelPeriodicOptimization();
          } else {
        // Restart visible videos after scroll settles (150ms settling time)
        _scrollDebounceTimer = Timer(const Duration(milliseconds: 150), () {
          _resumeVisibleVideos();
          // Schedule periodic optimization to ensure best visible videos are always playing
          _schedulePeriodicOptimization();
        });
      }
    
    if (kDebugMode) {
      print('[GridVideoProvider] Scroll state changed: ${isScrolling ? "scrolling" : "settled"}');
    }
  }

  /// Handle debounced visibility change
  void _handleDebouncedVisibilityChange(String videoId, bool isVisible) {
    if (_isScrolling) {
      if (kDebugMode) {
        print('[GridVideoProvider] Skipping playback change for $videoId - currently scrolling');
      }
      return;
    }
    
    final video = state[videoId];
    if (video == null) return;

    if (isVisible && !video.isPlaying) {
      // Re-evaluate all visible videos to ensure best 2 are playing
      _optimizeVisibleVideoPlayback();
    } else if (!isVisible && video.isPlaying) {
      _stopVideoPlayback(videoId);
      // After stopping, check if other visible videos can start playing
      _optimizeVisibleVideoPlayback();
    }
  }

  

  /// Start video playback
  void _startVideoPlayback(String videoId) {
    final video = state[videoId];
    if (video == null) return;
    
    final updatedVideo = video.copyWith(
      isPlaying: true,
      lastPlayedAt: DateTime.now(),
    );
    
    _cacheService.updateVideoState(videoId, updatedVideo);
    
    if (kDebugMode) {
      print('[GridVideoProvider] Started playback for video: $videoId');
    }
  }

  /// Stop video playback
  void _stopVideoPlayback(String videoId) {
    final video = state[videoId];
    if (video == null) return;
    
    _cacheService.removeFromPlayingList(videoId);
    
    final updatedVideo = video.copyWith(
      isPlaying: false,
    );
    
    _cacheService.updateVideoState(videoId, updatedVideo);
    
    if (kDebugMode) {
      print('[GridVideoProvider] Stopped playback for video: $videoId');
    }
  }

  /// Update video visibility state
  void _updateVideoVisibility(String videoId, bool isVisible) {
    final video = state[videoId];
    if (video == null) return;
    
    final updatedVideo = video.copyWith(isVisible: isVisible);
    _cacheService.updateVideoState(videoId, updatedVideo);
  }

  /// Pause all currently playing videos
  void _pauseAllVideos() {
    for (final videoId in _cacheService.playingVideos.toList()) {
      _stopVideoPlayback(videoId);
    }
  }

  /// Resume visible videos after scroll settles
  void _resumeVisibleVideos() {
    _optimizeVisibleVideoPlayback();
  }

  /// Optimize playback to ensure the best 2 visible videos are always playing
  void _optimizeVisibleVideoPlayback() {
    // Get all currently visible videos without errors
    final visibleVideos = state.values
        .where((video) => video.isVisible && !video.hasError)
        .toList();
    
    if (visibleVideos.isEmpty) {
      // No visible videos, stop all playback
      for (final videoId in _cacheService.playingVideos.toList()) {
        _stopVideoPlayback(videoId);
      }
      return;
    }
    
    // Sort visible videos by priority (highest first)
    visibleVideos.sort((a, b) {
      final priorityA = _cacheService.getPlaybackPriority(a.id);
      final priorityB = _cacheService.getPlaybackPriority(b.id);
      return priorityB.compareTo(priorityA);
    });
    
    // Determine which videos should be playing (top 2 visible)
    final shouldBePlaying = visibleVideos.take(2).map((v) => v.id).toList();
    final currentlyPlaying = _cacheService.playingVideos.toList();
    
    // Stop videos that shouldn't be playing
    for (final videoId in currentlyPlaying) {
      if (!shouldBePlaying.contains(videoId)) {
        _stopVideoPlayback(videoId);
        if (kDebugMode) {
          print('[GridVideoProvider] Stopped $videoId - not in top 2 visible videos');
        }
      }
    }
    
    // Start videos that should be playing but aren't
    for (final videoId in shouldBePlaying) {
      final video = state[videoId];
      if (video != null && !video.isPlaying && _cacheService.canVideoPlay(videoId)) {
        if (_cacheService.addToPlayingList(videoId)) {
          _startVideoPlayback(videoId);
          if (kDebugMode) {
            print('[GridVideoProvider] Started $videoId - top priority visible video');
          }
        }
      }
    }
    
    if (kDebugMode) {
      print('[GridVideoProvider] Optimized playback: ${shouldBePlaying.length} visible videos, playing: ${_cacheService.playingVideos.length}/2');
      print('[GridVideoProvider] Currently playing: ${_cacheService.playingVideos}');
      print('[GridVideoProvider] Should be playing: $shouldBePlaying');
    }
  }

  /// Schedule periodic optimization to ensure optimal video selection
  void _schedulePeriodicOptimization() {
    _optimizationTimer?.cancel();
    
    // Optimize every 2 seconds to ensure best visible videos are playing
    _optimizationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isScrolling) {
        _optimizeVisibleVideoPlayback();
      }
    });
    
    if (kDebugMode) {
      print('[GridVideoProvider] Scheduled periodic optimization every 2 seconds');
    }
  }

  /// Cancel periodic optimization
  void _cancelPeriodicOptimization() {
    _optimizationTimer?.cancel();
    _optimizationTimer = null;
    
    if (kDebugMode) {
      print('[GridVideoProvider] Cancelled periodic optimization');
    }
  }

  /// Update video loading state
  void updateVideoLoaded(String videoId, bool isLoaded) {
    final video = state[videoId];
    if (video == null) return;
    
    final updatedVideo = video.copyWith(isLoaded: isLoaded);
    _cacheService.updateVideoState(videoId, updatedVideo);
  }

  /// Update video error state
  void updateVideoError(String videoId, bool hasError, String? errorMessage) {
    final video = state[videoId];
    if (video == null) return;
    
    final updatedVideo = video.copyWith(
      hasError: hasError,
      errorMessage: errorMessage,
    );
    _cacheService.updateVideoState(videoId, updatedVideo);
  }

  /// Get cache statistics with visible video information
  Map<String, dynamic> getCacheStats() {
    final baseStats = _cacheService.getCacheStats();
    
    // Add visible videos information
    final visibleVideos = state.values.where((video) => video.isVisible).toList();
    final visibleVideoIds = visibleVideos.map((v) => v.id).toList();
    
    // Sort visible videos by priority to show which should be playing
    visibleVideos.sort((a, b) {
      final priorityA = _cacheService.getPlaybackPriority(a.id);
      final priorityB = _cacheService.getPlaybackPriority(b.id);
      return priorityB.compareTo(priorityA);
    });
    
    final top2VisibleIds = visibleVideos.take(2).map((v) => v.id).toList();
    
    return {
      ...baseStats,
      'visibleVideos': visibleVideoIds.length,
      'visibleVideoIds': visibleVideoIds,
      'top2VisibleIds': top2VisibleIds,
      'allVisiblePlaying': top2VisibleIds.every((id) => _cacheService.playingVideos.contains(id)),
      'optimizationActive': _optimizationTimer?.isActive ?? false,
    };
  }

  @override
  void dispose() {
    // Cancel all debounce timers
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    
    _scrollDebounceTimer?.cancel();
    _cancelPeriodicOptimization();
    
    super.dispose();
  }
}

/// Grid video state provider
final gridVideoStateProvider = StateNotifierProvider<GridVideoStateNotifier, Map<String, GridVideoModel>>((ref) {
  final cacheService = ref.watch(gridVideoCacheServiceProvider);
  final videoData = ref.watch(gridVideoDataProvider);
  
  return GridVideoStateNotifier(cacheService, videoData);
});

/// Currently playing videos provider
final playingVideosProvider = StreamProvider<List<String>>((ref) {
  final cacheService = ref.watch(gridVideoCacheServiceProvider);
  return cacheService.playingVideosStream;
});

/// Cache statistics provider
final cacheStatsProvider = Provider<Map<String, dynamic>>((ref) {
  ref.watch(gridVideoStateProvider); // Trigger rebuilds when state changes
  final cacheService = ref.watch(gridVideoCacheServiceProvider);
  return cacheService.getCacheStats();
}); 