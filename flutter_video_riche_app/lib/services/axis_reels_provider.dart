import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'axis_reels_state.dart';

final axisReelsProvider = ChangeNotifierProvider.autoDispose<AxisReelsState>((ref) {
  final state = AxisReelsState();
  state.initialize();
  return state;
}); 