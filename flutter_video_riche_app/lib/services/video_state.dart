import 'dart:async';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/video_model.dart';

class VideoState extends ChangeNotifier {
  final List<VideoModel> _videos = [
    VideoModel(
      id: '1',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/d0df89a1-b959-4397-b71f-4f3f0b25da33.mp4',
      title: 'Video 1',
    ),
    VideoModel(
      id: '2',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/dbeef944-c64c-4b78-8e80-bdb22b60f6ad.mp4',
      title: 'Video 2',
    ),
    VideoModel(
      id: '3',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/25b57cb5-64a6-417f-b464-a024c3d73061.mp4',
      title: 'Video 3',
    ),
    VideoModel(
      id: '4',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/20/9e4c4767-6a22-4428-8eac-2723b7167c15.mp4',
      title: 'Video 4',
    ),
    VideoModel(
      id: '5',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/20/8f7e4860-7609-44c8-9a87-8296a7398275.mp4',
      title: 'Video 5',
    ),
    VideoModel(
      id: '6',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/19/db4b3a63-f3ae-4761-82b0-c287acdf4b3b.mp4',
      title: 'Video 6',
    ),
    VideoModel(
      id: '7',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/e85edcd1-57b4-401a-b380-1f9f86dd6f9f.mp4',
      title: 'Video 7',
    ),
    VideoModel(
      id: '8',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/9114dffa-2cfc-4f9f-b375-6de249bbb329.mp4',
      title: 'Video 8',
    ),
    VideoModel(
      id: '9',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/f858ae9b-e967-4ed8-bb65-d55175b8ee23.mp4',
      title: 'Video 9',
    ),
  ];

  final Map<int, CachedVideoPlayerPlusController> _controllers = {};
  final Map<int, bool> _isInitialized = {};
  final Map<int, bool> _hasError = {};
  
  int _currentIndex = 0;
  Timer? _debounceTimer;
  bool _isDisposed = false;

  List<VideoModel> get videos => _videos;
  int get currentIndex => _currentIndex;
  
  CachedVideoPlayerPlusController? getController(int index) {
    return _controllers[index];
  }

  bool isInitialized(int index) => _isInitialized[index] ?? false;
  bool hasError(int index) => _hasError[index] ?? false;

  void onPageChanged(int index) {
    if (_isDisposed) return;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isDisposed) return;
      _updateCurrentIndex(index);
    });
  }

  void _updateCurrentIndex(int index) {
    if (_currentIndex == index || _isDisposed) return;
    
    _currentIndex = index;
    _preloadVideos();
    notifyListeners();
  }

  void _preloadVideos() {
    if (_isDisposed) return;
    
    final preloadRange = 2;
    final startIndex = (_currentIndex - 1).clamp(0, _videos.length - 1);
    final endIndex = (_currentIndex + preloadRange).clamp(0, _videos.length - 1);

    for (int i = startIndex; i <= endIndex; i++) {
      if (!_controllers.containsKey(i) && _hasError[i] != true) {
        _initializeController(i);
      }
    }

    _disposeUnusedControllers();
  }

  void _initializeController(int index) {
    if (_isDisposed || _controllers.containsKey(index)) return;

    try {
      final controller = CachedVideoPlayerPlusController.networkUrl(
        Uri.parse(_videos[index].url),
        invalidateCacheIfOlderThan: const Duration(days: 30),
      );

      _controllers[index] = controller;
      _isInitialized[index] = false;
      _hasError[index] = false;

      controller.initialize().then((_) {
        if (_isDisposed) return;
        _isInitialized[index] = true;
        
        // Set video to mute by default
        controller.setVolume(0.0);
        
        if (index == _currentIndex) {
          controller.play();
        }
        
        notifyListeners();
      }).catchError((error) {
        if (_isDisposed) return;
        _hasError[index] = true;
        _controllers.remove(index);
        notifyListeners();
      });
    } catch (e) {
      _hasError[index] = true;
      notifyListeners();
    }
  }

  void _disposeUnusedControllers() {
    if (_isDisposed) return;
    
    final keepRange = 3;
    final startKeep = (_currentIndex - 1).clamp(0, _videos.length - 1);
    final endKeep = (_currentIndex + keepRange).clamp(0, _videos.length - 1);

    final toRemove = <int>[];
    for (final index in _controllers.keys) {
      if (index < startKeep || index > endKeep) {
        toRemove.add(index);
      }
    }

    for (final index in toRemove) {
      _controllers[index]?.dispose();
      _controllers.remove(index);
      _isInitialized.remove(index);
      _hasError.remove(index);
    }
  }

  void pauseCurrentVideo() {
    if (_isDisposed) return;
    final controller = _controllers[_currentIndex];
    if (controller != null && _isInitialized[_currentIndex] == true) {
      controller.pause();
    }
  }

  void playCurrentVideo() {
    if (_isDisposed) return;
    final controller = _controllers[_currentIndex];
    if (controller != null && _isInitialized[_currentIndex] == true) {
      controller.play();
    }
  }

  void togglePlayPause() {
    if (_isDisposed) return;
    final controller = _controllers[_currentIndex];
    if (controller != null && _isInitialized[_currentIndex] == true) {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
      notifyListeners();
    }
  }

  void initialize() {
    if (_isDisposed) return;
    _preloadVideos();
  }

  void pauseAllVideos() {
    if (_isDisposed) return;
    
    for (final controller in _controllers.values) {
      if (controller.value.isInitialized && controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  void stopAllVideos() {
    if (_isDisposed) return;
    
    for (final controller in _controllers.values) {
      if (controller.value.isInitialized) {
        controller.pause();
        controller.seekTo(Duration.zero);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    
    stopAllVideos();
    
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _isInitialized.clear();
    _hasError.clear();
    
    super.dispose();
  }
} 