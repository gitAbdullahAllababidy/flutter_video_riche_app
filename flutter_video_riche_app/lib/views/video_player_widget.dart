import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../services/video_provider.dart';

class VideoPlayerWidget extends ConsumerWidget {
  final int index;

  const VideoPlayerWidget({
    super.key,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoState = ref.watch(videoStateProvider);
    final controller = videoState.getController(index);
    final isInitialized = videoState.isInitialized(index);
    final hasError = videoState.hasError(index);

    return VisibilityDetector(
      key: Key('video_$index'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          if (index == videoState.currentIndex) {
            videoState.playCurrentVideo();
          }
        } else {
          if (index == videoState.currentIndex) {
            videoState.pauseCurrentVideo();
          }
        }
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            if (hasError)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else if (!isInitialized || controller == null)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CachedVideoPlayerPlus(controller),
                ),
              ),
            if (isInitialized && controller != null && !hasError)
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (index == videoState.currentIndex) {
                      videoState.togglePlayPause();
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 