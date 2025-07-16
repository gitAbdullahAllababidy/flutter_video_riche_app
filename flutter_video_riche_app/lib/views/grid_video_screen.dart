import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import '../providers/grid_video_provider.dart';
import '../services/grid_video_playback_manager.dart';
import '../widgets/grid_video_item_widget.dart';

class GridVideoScreen extends ConsumerStatefulWidget {
  const GridVideoScreen({super.key});

  @override
  ConsumerState<GridVideoScreen> createState() => _GridVideoScreenState();
}

class _GridVideoScreenState extends ConsumerState<GridVideoScreen>
    with WidgetsBindingObserver {
  late ScrollController _scrollController;
  late GridVideoPlaybackManager _playbackManager;
  
  // Scroll detection state
  bool _isScrolling = false;
  Timer? _scrollTimer;
  final Duration _scrollDebounceDelay = const Duration(milliseconds: 150);
  
  // Grid configuration
  static const double _itemSpacing = 12.0;
  static const double _itemAspectRatio = 16 / 9;
  
  // Debug mode toggle
  bool _showDebugInfo = kDebugMode;
  Timer? _debugInfoTimer;

  @override
  void initState() {
    super.initState();
    _initializeMediaKit();
    _setupScrollController();
    _playbackManager = GridVideoPlaybackManager();
    WidgetsBinding.instance.addObserver(this);
    
    // Auto-hide debug info after some time in release mode
    if (!kDebugMode) {
      _startDebugInfoTimer();
    }
  }

  @override
  void dispose() {
    _debugInfoTimer?.cancel();
    _scrollTimer?.cancel();
    _scrollController.dispose();
    _playbackManager.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Initialize MediaKit for video playback
  void _initializeMediaKit() {
    MediaKit.ensureInitialized();
    if (kDebugMode) {
      print('[GridVideoScreen] MediaKit initialized');
    }
  }

  /// Setup scroll controller with scroll detection
  void _setupScrollController() {
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  /// Handle scroll events with debounce
  void _onScroll() {
    if (!_isScrolling) {
      _isScrolling = true;
      _notifyScrollStateChanged(true);
    }
    
    // Reset scroll timer on each scroll event
    _scrollTimer?.cancel();
    _scrollTimer = Timer(_scrollDebounceDelay, () {
      if (_isScrolling) {
        _isScrolling = false;
        _notifyScrollStateChanged(false);
      }
    });
  }

  /// Notify scroll state change to relevant components
  void _notifyScrollStateChanged(bool isScrolling) {
    // Notify the state provider
    ref.read(gridVideoStateProvider.notifier).onScrollStateChanged(isScrolling);
    
    // Notify the playback manager
    _playbackManager.onScrollStateChanged(isScrolling);
    
    if (kDebugMode) {
      print('[GridVideoScreen] Scroll state changed: ${isScrolling ? "scrolling" : "settled"}');
    }
  }

  /// Calculate responsive grid crossAxisCount based on screen width
  int _calculateCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) {
      return 2; // Mobile: 2 columns
    } else if (screenWidth < 900) {
      return 3; // Tablet: 3 columns  
    } else {
      return 4; // Desktop: 4 columns
    }
  }

  /// Start debug info auto-hide timer
  void _startDebugInfoTimer() {
    _debugInfoTimer?.cancel();
    _debugInfoTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showDebugInfo = false;
        });
      }
    });
  }

  /// Toggle debug info visibility
  void _toggleDebugInfo() {
    setState(() {
      _showDebugInfo = !_showDebugInfo;
    });
    
    if (_showDebugInfo && !kDebugMode) {
      _startDebugInfoTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Pause all videos when app goes to background
        _playbackManager.onScrollStateChanged(true);
        break;
      case AppLifecycleState.resumed:
        // Resume visible videos when app comes to foreground
        _playbackManager.onScrollStateChanged(false);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(gridVideoStateProvider);
    final videos = videoState.values.toList();
    
    // Watch cache stats for debug info
    final cacheStats = ref.watch(cacheStatsProvider);
    final playingVideosAsync = ref.watch(playingVideosProvider);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Grid Videos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Debug info toggle button
          IconButton(
            icon: Icon(
              _showDebugInfo ? Icons.info : Icons.info_outline,
              color: _showDebugInfo ? Colors.blue : Colors.white,
            ),
            onPressed: _toggleDebugInfo,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main grid content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Debug info banner (only when enabled)
              if (_showDebugInfo)
                SliverToBoxAdapter(
                  child: _buildDebugInfoBanner(cacheStats, playingVideosAsync),
                ),
              
              // Video grid
              SliverPadding(
                padding: const EdgeInsets.all(_itemSpacing),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = _calculateCrossAxisCount(constraints.crossAxisExtent);
                    
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: _itemAspectRatio,
                        crossAxisSpacing: _itemSpacing,
                        mainAxisSpacing: _itemSpacing,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= videos.length) return null;
                          
                          return GridVideoItemWidget(
                            key: ValueKey(videos[index].id),
                            video: videos[index],
                            aspectRatio: _itemAspectRatio,
                          );
                        },
                        childCount: videos.length,
                      ),
                    );
                  },
                ),
              ),
              
              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
          
          // Scroll indicator (only during scrolling)
          if (_isScrolling)
            Positioned(
              top: 100,
              right: 16,
              child: AnimatedOpacity(
                opacity: _isScrolling ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.pause_circle_outline,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Videos paused',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build debug information banner
  Widget _buildDebugInfoBanner(Map<String, dynamic> cacheStats, AsyncValue<List<String>> playingVideosAsync) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
                             const Icon(Icons.bug_report, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Debug Information',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'MediaKit Grid',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Cache statistics
          _buildDebugRow('Total Videos', '${cacheStats['totalVideos'] ?? 0}'),
          _buildDebugRow('Playing Videos', '${cacheStats['playingVideos'] ?? 0}/2'),
          _buildDebugRow('Cached Players', '${cacheStats['cachedPlayers'] ?? 0}'),
          _buildDebugRow('Session Duration', '${cacheStats['sessionDuration'] ?? 0}min'),
          
          // Currently playing videos
          playingVideosAsync.when(
            data: (playingVideos) {
              return _buildDebugRow(
                'Active Players',
                playingVideos.isEmpty 
                  ? 'None' 
                  : playingVideos.map((id) => id.split('_').last).join(', '),
              );
            },
            loading: () => _buildDebugRow('Active Players', 'Loading...'),
            error: (error, stack) => _buildDebugRow('Active Players', 'Error'),
          ),
          
          // Scroll state
          _buildDebugRow('Scroll State', _isScrolling ? 'Scrolling' : 'Settled'),
          
          const SizedBox(height: 8),
          
          // Performance tip
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Text(
              '💡 Max 2 videos play simultaneously for optimal performance',
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build debug information row
  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 