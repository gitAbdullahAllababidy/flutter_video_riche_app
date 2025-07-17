import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../models/dual_video_clip_model.dart';
import '../providers/dual_video_provider.dart';
import '../widgets/dual_video_item_widget.dart';

class DualVideoScreen extends ConsumerStatefulWidget {
  const DualVideoScreen({super.key});

  @override
  ConsumerState<DualVideoScreen> createState() => _DualVideoScreenState();
}

class _DualVideoScreenState extends ConsumerState<DualVideoScreen> {
  @override
  Widget build(BuildContext context) {
    final screenState = ref.watch(dualVideoScreenProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Videos', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: screenState.error != null
          ? const Center(child: Text('Error loading videos', style: TextStyle(color: Colors.white)))
          : !screenState.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : _buildVideoGrid(screenState),
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
    final isPlaying = screenState.playingVideos.contains(video.id);
    final isVisible = screenState.visibleVideos.contains(video.id);
    
    return VisibilityDetector(
      key: Key('dual_video_${video.id}'),
      onVisibilityChanged: (info) {
        final isNowVisible = info.visibleFraction > 0.5; // 50% visibility threshold
        ref.read(dualVideoScreenProvider.notifier).updateVideoVisibility(
          video.id,
          isNowVisible,
        );
      },
      child: DualVideoItemWidget(
        video: video,
        isPlaying: isPlaying,
        isVisible: isVisible,
      ),
    );
  }


}
