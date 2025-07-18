import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dual_video_clip_model.dart';
import '../providers/dual_video_provider.dart';
import '../providers/global_video_provider.dart';
import '../services/enhanced_video_cache_manager.dart';
import '../widgets/enhanced_video_widget.dart';

class DualVideoScreen extends ConsumerStatefulWidget {
  const DualVideoScreen({super.key});

  @override
  ConsumerState<DualVideoScreen> createState() => _DualVideoScreenState();
}

class _DualVideoScreenState extends ConsumerState<DualVideoScreen> {
  @override
  void initState() {
    super.initState();
    _initializeCacheManager();
  }

  Future<void> _initializeCacheManager() async {
    try {
      await EnhancedVideoCacheManager.instance.initialize();
      print('[DualVideoScreen] Cache manager initialized');
    } catch (e) {
      print('[DualVideoScreen] Error initializing cache manager: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenState = ref.watch(dualVideoScreenProvider);
    final globalStatsAsync = ref.watch(videoPlaybackStatsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Videos', style: TextStyle(color: Colors.white, fontSize: 18)),
            globalStatsAsync.when(
              data: (stats) => Text(
                'Global: ${stats['playingVideos']}/2 playing • ${stats['visibleVideos']} visible',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              loading: () => const Text('Loading...', style: TextStyle(color: Colors.white70, fontSize: 12)),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: screenState.error != null
          ? const Center(child: Text('Error loading videos', style: TextStyle(color: Colors.white)))
          : !screenState.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Global video limit info banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Colors.blue[900],
                      child: const Text(
                        '🎯 Global Video Management Active: Only 2 videos play at a time across the entire app',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(child: _buildVideoGrid(screenState)),
                  ],
                ),
    );
  }

  Widget _buildVideoGrid(DualVideoScreenState screenState) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 9 / 16,
      ),
      itemCount: screenState.videos.length,
      itemBuilder: (context, index) {
        final video = screenState.videos[index];
        return _buildVideoItem(video, screenState);
      },
    );
  }

  Widget _buildVideoItem(DualVideoClipModel video, DualVideoScreenState screenState) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: ref.watch(globalVideoManagerProvider).isVideoPlaying(video.id)
            ? Colors.green
            : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: EnhancedVideoWidget(
        video: video,
        onVisibilityChanged: (videoId, isVisible) {
          // Optional: Still notify the dual video provider for state tracking
          ref.read(dualVideoScreenProvider.notifier).updateVideoVisibility(
            videoId,
            isVisible,
          );
          print('[DualVideoScreen] 📱 Video $videoId visibility: $isVisible');
        },
        autoPlay: true,
        showControls: false,
        fit: BoxFit.cover,
      ),
    );
  }


}
