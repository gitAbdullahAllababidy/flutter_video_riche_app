import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../models/dual_video_clip_model.dart';
import '../providers/global_video_provider.dart';
import '../services/enhanced_video_cache_manager.dart';

/// Enhanced video widget with thumbnail support and no loading spinners
/// Only shows buffering indicators when actually buffering
class EnhancedVideoWidget extends ConsumerStatefulWidget {
  final DualVideoClipModel video;
  final Function(String videoId, bool isVisible)? onVisibilityChanged;
  final bool autoPlay;
  final bool showControls;
  final BoxFit fit;

  const EnhancedVideoWidget({
    super.key,
    required this.video,
    this.onVisibilityChanged,
    this.autoPlay = true,
    this.showControls = false,
    this.fit = BoxFit.cover,
  });

  @override
  ConsumerState<EnhancedVideoWidget> createState() => _EnhancedVideoWidgetState();
}

class _EnhancedVideoWidgetState extends ConsumerState<EnhancedVideoWidget> {
  Player? _player;
  VideoController? _controller;
  bool _isInitialized = false;
  bool _isBuffering = false;
  bool _showThumbnail = true;
  bool _hasError = false;
  String? _errorMessage;

  // Global video visibility manager (accessed via provider)

  @override
  void initState() {
    super.initState();

    // Register this video with global manager via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final globalManager = ref.read(globalVideoManagerProvider);
      globalManager.registerVideo(
        widget.video.id,
        onPlay: _playVideo,
        onPause: _pauseVideo,
      );
    });

    _initializePlayer();
  }

  /// Play video (called by global manager)
  void _playVideo() {
    if (_isInitialized && _player != null && mounted) {
      _player!.play();
      print('[EnhancedVideo] 🎯 GLOBAL MANAGER: Playing video ${widget.video.id}');
    }
  }

  /// Pause video (called by global manager)
  void _pauseVideo() {
    if (_isInitialized && _player != null && mounted) {
      _player!.pause();
      print('[EnhancedVideo] 🎯 GLOBAL MANAGER: Pausing video ${widget.video.id}');
    }
  }

  Future<void> _initializePlayer() async {
    try {
      print('[EnhancedVideo] 🎬 Initializing player for video: ${widget.video.id}');
      print('[EnhancedVideo] 🔗 Video URL: ${widget.video.videoUrl}');

      // Check cache status first
      final cacheManager = EnhancedVideoCacheManager.instance;
      final isCached = await cacheManager.isVideoCached(widget.video.videoUrl);

      print('[EnhancedVideo] ${isCached ? '🎯 Will REPLAY from CACHE' : '📡 Will stream from NETWORK'}');

      // Get cached video URL (this will either return cached or start caching)
      final cachedUrl = await cacheManager.getCachedVideoUrl(widget.video.videoUrl);

      _player = Player();
      _controller = VideoController(_player!);

      // Listen to player state changes
      _player!.stream.buffering.listen((isBuffering) {
        if (mounted) {
          print('[EnhancedVideo] ${isBuffering ? '⏳ BUFFERING' : '✅ READY'} - ${widget.video.id}');
          setState(() {
            _isBuffering = isBuffering;
          });
        }
      });

      _player!.stream.playing.listen((isPlaying) {
        if (mounted && isPlaying) {
          print('[EnhancedVideo] ▶️ PLAYING ${isCached ? 'from CACHE' : 'from NETWORK'} - ${widget.video.id}');
          // Hide thumbnail when video starts playing
          setState(() {
            _showThumbnail = false;
          });
        }
      });

      _player!.stream.error.listen((error) {
        if (mounted) {
          print('[EnhancedVideo] ❌ ERROR: $error - ${widget.video.id}');
          setState(() {
            _hasError = true;
            _errorMessage = error;
          });
        }
      });

      // Configure player
      await _player!.setVolume(0.0); // Muted by default
      await _player!.setPlaylistMode(PlaylistMode.loop);

      print('[EnhancedVideo] 🔧 Player configured, opening media...');

      // Open media
      await _player!.open(Media(cachedUrl));

      print('[EnhancedVideo] 🎥 Media opened successfully - ${widget.video.id}');

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

    } catch (e) {
      print('[EnhancedVideo] ⚠️ Initialization error: $e - ${widget.video.id}');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Widget _buildThumbnail() {
    // Determine which image to show
    String? imageUrl = widget.video.thumbnail;

    // Use placeholder if thumbnail is not available
    if (imageUrl.isEmpty && widget.video.placeholderUrl != null) {
      imageUrl = widget.video.placeholderUrl;
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      // Fallback to a simple colored container
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.video_library,
            size: 48,
            color: Colors.grey,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: widget.fit,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.image,
            size: 48,
            color: Colors.grey,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.broken_image,
            size: 48,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isInitialized || _controller == null) {
      return _buildThumbnail();
    }

    return Video(
      controller: _controller!,
      fit: widget.fit,
      controls: widget.showControls ? AdaptiveVideoControls : NoVideoControls,
    );
  }

  Widget _buildBufferingIndicator() {
    if (!_isBuffering) return const SizedBox.shrink();

    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.red[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 8),
            Text(
              'Video Error',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('video_${widget.video.id}'),
      onVisibilityChanged: (info) async {
        final isVisible = info.visibleFraction > 0.5;
        widget.onVisibilityChanged?.call(widget.video.id, isVisible);

        print('[EnhancedVideo] 👁️ Visibility changed: ${isVisible ? 'VISIBLE' : 'HIDDEN'} (${(info.visibleFraction * 100).toStringAsFixed(1)}%) - ${widget.video.id}');

        // Update global manager with visibility (it will handle play/pause decisions)
        if (widget.autoPlay) {
          final globalManager = ref.read(globalVideoManagerProvider);
          globalManager.updateVideoVisibility(widget.video.id, isVisible);

          if (isVisible) {
            // Check cache status for logging
            final cacheManager = EnhancedVideoCacheManager.instance;
            final isCached = await cacheManager.isVideoCached(widget.video.videoUrl);
            print('[EnhancedVideo] 📊 Video visible ${isCached ? 'with CACHE' : 'without CACHE'} - ${widget.video.id}');
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: widget.video.isPlaying
            ? Border.all(color: Colors.green, width: 3)
            : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Show thumbnail or video based on state
            if (_hasError)
              _buildErrorWidget()
            else if (_showThumbnail || !_isInitialized)
              _buildThumbnail()
            else
              _buildVideoPlayer(),

            // Only show buffering indicator when actually buffering
            _buildBufferingIndicator(),

            // Video info overlay (optional)
            if (widget.video.title != null)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.video.title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Unregister from global manager
    try {
      final globalManager = ref.read(globalVideoManagerProvider);
      globalManager.unregisterVideo(widget.video.id);
    } catch (e) {
      // Provider might be disposed already
      print('[EnhancedVideo] Warning: Could not unregister video ${widget.video.id}: $e');
    }

    _player?.dispose();
    super.dispose();
  }
}
