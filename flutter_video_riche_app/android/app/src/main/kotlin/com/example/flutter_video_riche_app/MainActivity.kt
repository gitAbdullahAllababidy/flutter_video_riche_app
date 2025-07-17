package com.example.flutter_video_riche_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register dual video plugin
        flutterEngine.plugins.add(DualVideoPlugin())
    }
}
