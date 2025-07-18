import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../models/axis_reel_model.dart';
import '../services/axis_reels_provider.dart';

class AxisReelsExploreScreen extends ConsumerStatefulWidget {
  const AxisReelsExploreScreen({super.key});

  @override
  ConsumerState<AxisReelsExploreScreen> createState() => _AxisReelsExploreScreenState();
}

class _AxisReelsExploreScreenState extends ConsumerState<AxisReelsExploreScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final axisReelsState = ref.watch(axisReelsProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    
    // Calculate available height for content
    final availableHeight = screenHeight - appBarHeight - statusBarHeight - bottomPadding;
    
    // Calculate item height to show exactly 2 rows with padding
    final itemHeight = (availableHeight - 32) / 2 - 8; // 32 for padding, 8 for spacing between rows

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
          'Explore Reels',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: axisReelsState.reelRows.length,
            itemBuilder: (context, rowIndex) {
              final row = axisReelsState.reelRows[rowIndex];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    // First item (Image)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: _buildReelItem(row[0], axisReelsState, itemHeight),
                      ),
                    ),
                    // Second item (Video)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: _buildReelItem(row[1], axisReelsState, itemHeight),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReelItem(AxisReelModel reel, axisReelsState, double itemHeight) {
    return VisibilityDetector(
      key: Key(reel.id),
      onVisibilityChanged: (info) {
        if (reel.type == ReelType.video) {
          final isVisible = info.visibleFraction > 0.9; // 60% visibility threshold
          axisReelsState.onVideoVisibilityChanged(reel.id, isVisible);
        }
      },
      child: Container(
        height: itemHeight,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: reel.type == ReelType.image
              ? _buildImageItem(reel)
              : _buildVideoItem(reel, axisReelsState),
        ),
      ),
    );
  }

  Widget _buildImageItem(AxisReelModel reel) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: reel.url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[800],
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[800],
            child: const Center(
              child: Icon(
                Icons.error_outline,
                color: Colors.white54,
                size: 40,
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
                Colors.black.withOpacity(0.6),
              ],
              stops: const [0.6, 1.0],
            ),
          ),
        ),
        // Title
        if (reel.title != null)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              reel.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildVideoItem(AxisReelModel reel, axisReelsState) {
    final isInitialized = axisReelsState.isVideoInitialized(reel.id);
    final hasError = axisReelsState.hasVideoError(reel.id);
    final controller = axisReelsState.getVideoController(reel.id);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player or thumbnail
        if (!isInitialized || hasError)
          // Show thumbnail while loading or on error
          CachedNetworkImage(
            imageUrl: reel.thumbnailUrl ?? '',
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[800],
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[800],
              child: const Center(
                child: Icon(
                  Icons.videocam_off,
                  color: Colors.white54,
                  size: 40,
                ),
              ),
            ),
          )
        else if (controller != null)
          GestureDetector(
            onTap: () {
              axisReelsState.toggleVideoPlayPause(reel.id);
            },
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: CachedVideoPlayerPlus(controller),
                ),
              ),
            ),
          ),

        // Play button overlay (only show when paused)
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
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
                Colors.black.withOpacity(0.6),
              ],
              stops: const [0.6, 1.0],
            ),
          ),
        ),

        // Video indicator
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            child: const Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),

        // Title and controls
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  reel.title ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isInitialized && !hasError)
                GestureDetector(
                  onTap: () {
                    axisReelsState.resetVideo(reel.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.replay,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Loading indicator for video initialization
        if (!isInitialized && !hasError && reel.type == ReelType.video)
          Container(
            color: Colors.black38,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }
} 