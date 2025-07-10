import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/axis_reel_model.dart';
import '../services/axis_reels_provider.dart';

class AxisReelsScreen extends ConsumerStatefulWidget {
  const AxisReelsScreen({super.key});

  @override
  ConsumerState<AxisReelsScreen> createState() => _AxisReelsScreenState();
}

class _AxisReelsScreenState extends ConsumerState<AxisReelsScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final axisReelsState = ref.watch(axisReelsProvider);
    final allReels = axisReelsState.allReels; // Get flattened list of all reels

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Axis Reels',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: PageView.builder(
              controller: _pageController,
              itemCount: allReels.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final reel = allReels[index];
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: reel.type == ReelType.image
                        ? _buildImageReel(reel)
                        : _buildVideoReel(reel, axisReelsState),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageReel(AxisReelModel reel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: reel.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(
                color: Colors.white54,
              ),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(
                Icons.error_outline,
                color: Colors.white54,
                size: 50,
              ),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
          // Title
          if (reel.title != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Text(
                reel.title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoReel(AxisReelModel reel, axisReelsState) {
    final isInitialized = axisReelsState.isVideoInitialized(reel.id);
    final hasError = axisReelsState.hasVideoError(reel.id);
    final controller = axisReelsState.getVideoController(reel.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!isInitialized || hasError)
            // Show thumbnail while loading
            CachedNetworkImage(
              imageUrl: reel.thumbnailUrl ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(
                  color: Colors.white54,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(
                    Icons.videocam_off,
                    color: Colors.white54,
                    size: 50,
                  ),
                ),
              ),
            )
          else if (controller != null)
            GestureDetector(
              onTap: () {
                axisReelsState.toggleVideoPlayPause(reel.id);
              },
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: CachedVideoPlayerPlus(controller),
              ),
            ),
          
          // Video controls overlay
          if (isInitialized && !hasError && controller != null)
            GestureDetector(
              onTap: () {
                axisReelsState.toggleVideoPlayPause(reel.id);
              },
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: controller.value.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
          
          // Title and play button
          if (reel.title != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      reel.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isInitialized && !hasError)
                    IconButton(
                      icon: const Icon(
                        Icons.replay,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        axisReelsState.resetVideo(reel.id);
                      },
                    ),
                ],
              ),
            ),
          
          // Loading indicator for video
          if (!isInitialized && !hasError && reel.type == ReelType.video)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white54,
              ),
            ),
        ],
      ),
    );
  }
} 