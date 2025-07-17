// Grid Video Solution using MediaKit + Flutter Cache Manager
// ✅ UPDATED FEATURES:
// - MediaKit video playback with flutter_cache_manager for optimal caching
// - Exact 150ms settling time for visibility detection (main objective)
// - Max 2 videos play simultaneously when visible after 150ms settling
// - All model parameters utilized: duration, lastPosition, lastPlayedAt, errorMessage
// - Enhanced priority system with file caching consideration
// - Pre-caching of video files for smoother playback
// - Comprehensive error handling with detailed error messages
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'views/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Video Feed App',

      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
  
}
