import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../models/grid_video_model.dart';
import '../providers/grid_video_provider.dart';
import '../services/grid_video_cache_service.dart';

class GridVideoItemWidget extends ConsumerStatefulWidget {
  final GridVideoModel video;
  final double aspectRatio;

  const GridVideoItemWidget({
    super.key,
    required this.video,
    this.aspectRatio = 16 / 9,
  });

  @override
  ConsumerState<GridVideoItemWidget> createState() => _GridVideoItemWidgetState();
}

class _GridVideoItemWidgetState extends ConsumerState<GridVideoItemWidget> {
  Player? _player;
  VideoController? _videoController;
  late GridVideoCacheService _cacheService;
  
  bool _isPlayerInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _showThumbnail = true;
  Timer? _thumbnailTransitionTimer;

  @override
  void initState() {
    super.initState();
    _cacheService = ref.read(gridVideoCacheServiceProvider);
    _initializePlayer();
  }

  @override
  void dispose() {
    _thumbnailTransitionTimer?.cancel();
    _disposePlayer();
    super.dispose();
  }

  /// Initialize media_kit player
  void _initializePlayer() {
    try {
      // Check if player already exists in cache
      _player = _cacheService.getCachedPlayer(widget.video.id);
      
      if (_player == null) {
        // Create new player with optimal configuration
        _player = Player(
          configuration: const PlayerConfiguration(
            // Optimize for mobile video streaming
            bufferSize: 32 * 1024 * 1024, // 32MB buffer
            logLevel: kDebugMode ? MPVLogLevel.info : MPVLogLevel.error,
          ),
        );
        
        // Cache the player
        _cacheService.cachePlayer(widget.video.id, _player!);
        
        if (kDebugMode) {
          print('[GridVideoItem] Created new player for ${widget.video.id}');
        }
      } else {
        if (kDebugMode) {
          print('[GridVideoItem] Using cached player for ${widget.video.id}');
        }
      }

      // Create video controller
      _videoController = VideoController(_player!);
      
      // Configure player settings
      _configurePlayer();
      
      // Set up listeners
      _setupPlayerListeners();
      
      // Load video
      _loadVideo();
      
    } catch (e) {
      _handlePlayerError('Failed to initialize player: $e');
    }
  }

  /// Configure player with required settings
  void _configurePlayer() {
    if (_player == null) return;
    
    try {
      // Mute audio by default (requirement)
      _player!.setVolume(0.0);
      
      // Set to loop indefinitely (requirement)
      _player!.setPlaylistMode(PlaylistMode.loop);
      
      if (kDebugMode) {
        print('[GridVideoItem] Configured player settings for ${widget.video.id}');
      }
    } catch (e) {
      _handlePlayerError('Failed to configure player: $e');
    }
  }

  /// Set up player event listeners
  void _setupPlayerListeners() {
    if (_player == null) return;

    // Listen to buffering state for loading indicators
    _player!.stream.buffering.listen((isBuffering) {
      if (mounted && isBuffering) {
        // Only show loading during actual buffering (requirement)
        if (kDebugMode) {
          print('[GridVideoItem] Buffering: ${widget.video.id}');
        }
      }
    });

    // Listen to playback completion for seamless looping
    _player!.stream.completed.listen((isCompleted) {
      if (mounted && isCompleted) {
        // Seamless loop handling
        _player!.seek(Duration.zero);
        if (_shouldBePlayingNow()) {
          _player!.play();
        }
        
        if (kDebugMode) {
          print('[GridVideoItem] Video completed, looping: ${widget.video.id}');
        }
      }
    });

    // Listen to error events
    _player!.stream.error.listen((error) {
      if (mounted) {
        _handlePlayerError('Playback error: $error');
      }
    });

    // Listen to position for caching
    _player!.stream.position.listen((position) {
      if (mounted) {
        // Update position in cache for session persistence
        final video = _cacheService.getCachedVideo(widget.video.id);
        if (video != null) {
          final updatedVideo = video.copyWith(lastPosition: position.inSeconds.toDouble());
          _cacheService.updateVideoState(widget.video.id, updatedVideo);
        }
      }
    });
  }

  /// Load video and handle thumbnail transition
  void _loadVideo() async {
    if (_player == null) return;
    
    try {
      _cacheService.setVideoLoading(widget.video.id, true);
      
      // Open video URL
      await _player!.open(Media(widget.video.url));
      
      // Wait for video to be ready
      await _player!.stream.duration.first;
      
      if (mounted) {
        setState(() {
          _isPlayerInitialized = true;
        });
        
        // Update cache state
        ref.read(gridVideoStateProvider.notifier).updateVideoLoaded(widget.video.id, true);
        
        // Start smooth thumbnail-to-video transition after brief delay
        _scheduleHideThumbnail();
        
        // Start playing if visible and allowed
        _checkAndUpdatePlaybackState();
        
        if (kDebugMode) {
          print('[GridVideoItem] Video loaded successfully: ${widget.video.id}');
        }
      }
    } catch (e) {
      _handlePlayerError('Failed to load video: $e');
    } finally {
      _cacheService.setVideoLoading(widget.video.id, false);
    }
  }

  /// Schedule hiding thumbnail for smooth transition
  void _scheduleHideThumbnail() {
    _thumbnailTransitionTimer?.cancel();
    _thumbnailTransitionTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _isPlayerInitialized) {
        setState(() {
          _showThumbnail = false;
        });
        
        if (kDebugMode) {
          print('[GridVideoItem] Thumbnail hidden for ${widget.video.id}');
        }
      }
    });
  }

  /// Check if video should be playing now
  bool _shouldBePlayingNow() {
    final videoState = ref.read(gridVideoStateProvider)[widget.video.id];
    return videoState?.isPlaying == true && videoState?.isVisible == true;
  }

  /// Check and update playback state based on current conditions
  void _checkAndUpdatePlaybackState() {
    if (!_isPlayerInitialized || _player == null) return;
    
    final shouldPlay = _shouldBePlayingNow();
    
    if (shouldPlay) {
      _player!.play();
    } else {
      _player!.pause();
    }
  }

  /// Handle player errors
  void _handlePlayerError(String error) {
    if (kDebugMode) {
      print('[GridVideoItem] Error for ${widget.video.id}: $error');
    }
    
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = error;
      });
      
      // Update error state in provider
      ref.read(gridVideoStateProvider.notifier).updateVideoError(
        widget.video.id,
        true,
        error,
      );
    }
  }

  /// Dispose player resources
  void _disposePlayer() {
    _thumbnailTransitionTimer?.cancel();
    
    // Don't dispose cached players immediately - let cache service manage lifecycle
    _videoController = null;
    _player = null;
    
    if (kDebugMode) {
      print('[GridVideoItem] Disposed resources for ${widget.video.id}');
    }
  }

  /// Handle visibility changes
  void _onVisibilityChanged(VisibilityInfo info) {
    // Delegate to provider for centralized management
    ref.read(gridVideoStateProvider.notifier)
        .onVideoVisibilityChanged(widget.video.id, info);
  }

  @override
  Widget build(BuildContext context) {
    // Watch video state for reactive updates
    final videoState = ref.watch(gridVideoStateProvider)[widget.video.id];
    
    // Update playback state when video state changes
    if (_isPlayerInitialized && videoState != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndUpdatePlaybackState();
      });
    }

    return VisibilityDetector(
      key: Key('grid_video_${widget.video.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: Stack(
              children: [
                // Video player layer
                if (_isPlayerInitialized && _videoController != null && !_showThumbnail)
                  Positioned.fill(
                    child: Video(
                      controller: _videoController!,
                      controls: NoVideoControls, // No controls (requirement)
                    ),
                  ),
                
                // Thumbnail layer (shows during loading and transitions)
                if (_showThumbnail || !_isPlayerInitialized)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: widget.video.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Error overlay
                if (_hasError)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black87,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Video Error',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (kDebugMode && _errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // Video info overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.video.title != null)
                          Text(
                            widget.video.title!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (widget.video.description != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.video.description!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Debug indicators (only in debug mode)
                if (kDebugMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Playing indicator
                          Icon(
                            videoState?.isPlaying == true ? Icons.play_arrow : Icons.pause,
                            color: videoState?.isPlaying == true ? Colors.green : Colors.orange,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          // Visibility indicator
                          Icon(
                            videoState?.isVisible == true ? Icons.visibility : Icons.visibility_off,
                            color: videoState?.isVisible == true ? Colors.blue : Colors.grey,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 