import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/story_provider.dart';
import 'story_player_widget.dart';

class StoriesScreen extends ConsumerStatefulWidget {
  const StoriesScreen({super.key});

  @override
  ConsumerState<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends ConsumerState<StoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final storyState = ref.watch(storyStateProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PageView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: storyState.stories.length,
          onPageChanged: (index) {
            storyState.onPageChanged(index);
          },
          itemBuilder: (context, index) {
            return StoryPlayerWidget(index: index);
          },
        ),
      ),
    );
  }
} 