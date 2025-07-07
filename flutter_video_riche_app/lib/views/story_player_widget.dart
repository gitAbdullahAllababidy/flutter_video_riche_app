import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../services/story_provider.dart';

class StoryPlayerWidget extends ConsumerWidget {
  final int index;

  const StoryPlayerWidget({
    super.key,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyState = ref.watch(storyStateProvider);
    final story = storyState.stories[index];
    final controller = storyState.getController(index);
    final isInitialized = storyState.isInitialized(index);
    final hasError = storyState.hasError(index);
    final progress = storyState.getProgress(index);

    return VisibilityDetector(
      key: Key('story_$index'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          if (index == storyState.currentIndex) {
            storyState.resumeCurrentStory();
          }
        } else {
          if (index == storyState.currentIndex) {
            storyState.pauseCurrentStory();
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
                      'Failed to load story',
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
              GestureDetector(
                onTap: () {
                  if (index == storyState.currentIndex) {
                    storyState.togglePlayPause();
                  }
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
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Row(
                    children: [
                      for (int i = 0; i < storyState.stories.length; i++)
                        Expanded(
                          child: Container(
                            height: 3,
                            margin: EdgeInsets.only(
                              right: i < storyState.stories.length - 1 ? 4 : 0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: i < storyState.currentIndex
                                  ? Colors.white
                                  : i == storyState.currentIndex
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : Colors.white.withValues(alpha: 0.3),
                            ),
                            child: i == storyState.currentIndex
                                ? LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.transparent,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    borderRadius: BorderRadius.circular(2),
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[800],
                        child: Text(
                          story.userName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              story.timeAgo,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (storyState.isPaused && index == storyState.currentIndex)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 