import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'video_state.dart';

final videoStateProvider = ChangeNotifierProvider.autoDispose<VideoState>((ref) {
  final videoState = VideoState();
  videoState.initialize();
  return videoState;
}); 