// Grid Video Solution using MediaKit
// Features: Max 2 concurrent videos, debounced visibility detection,
// session caching, muted playback, seamless looping, responsive grid
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'views/home_screen.dart';

void main() {
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
