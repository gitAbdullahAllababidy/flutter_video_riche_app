import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'story_state.dart';

final storyStateProvider = ChangeNotifierProvider.autoDispose<StoryState>((ref) {
  final storyState = StoryState();
  storyState.initialize();
  return storyState;
}); 