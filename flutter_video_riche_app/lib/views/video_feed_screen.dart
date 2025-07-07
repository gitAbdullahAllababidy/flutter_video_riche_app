import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/video_provider.dart';
import 'video_player_widget.dart';

class VideoFeedScreen extends ConsumerWidget {
  const VideoFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoState = ref.watch(videoStateProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: videoState.videos.length,
          onPageChanged: (index) {
            videoState.onPageChanged(index);
          },
          itemBuilder: (context, index) {
            return VideoPlayerWidget(index: index);
          },
        ),
      ),
    );
  }
} 