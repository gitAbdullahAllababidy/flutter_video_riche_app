import 'dart:async';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/story_model.dart';

class StoryState extends ChangeNotifier {
  final List<StoryModel> _stories = [
    StoryModel(
      id: 'story_1',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/d0df89a1-b959-4397-b71f-4f3f0b25da33.mp4',
      userName: 'Alice',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      duration: const Duration(seconds: 15),
    ),
    StoryModel(
      id: 'story_2',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/dbeef944-c64c-4b78-8e80-bdb22b60f6ad.mp4',
      userName: 'Bob',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      duration: const Duration(seconds: 12),
    ),
    StoryModel(
      id: 'story_3',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/25b57cb5-64a6-417f-b464-a024c3d73061.mp4',
      userName: 'Charlie',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      duration: const Duration(seconds: 18),
    ),
    StoryModel(
      id: 'story_4',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/20/9e4c4767-6a22-4428-8eac-2723b7167c15.mp4',
      userName: 'Diana',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      duration: const Duration(seconds: 20),
    ),
    StoryModel(
      id: 'story_5',
      url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/20/8f7e4860-7609-44c8-9a87-8296a7398275.mp4',
      userName: 'Emma',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      duration: const Duration(seconds: 14),
    ),
  ];

  final Map<int, CachedVideoPlayerPlusController> _controllers = {};
  final Map<int, bool> _isInitialized = {};
  final Map<int, bool> _hasError = {};
  final Map<int, double> _progress = {};
  
  int _currentIndex = 0;
  Timer? _debounceTimer;
  Timer? _progressTimer;
  bool _isDisposed = false;
  bool _isPaused = false;

  List<StoryModel> get stories => _stories.where((story) => !story.isExpired).toList();
  int get currentIndex => _currentIndex;
  bool get isPaused => _isPaused;
  
  CachedVideoPlayerPlusController? getController(int index) {
    return _controllers[index];
  }

  bool isInitialized(int index) => _isInitialized[index] ?? false;
  bool hasError(int index) => _hasError[index] ?? false;
  double getProgress(int index) => _progress[index] ?? 0.0;

  void onPageChanged(int index) {
    if (_isDisposed) return;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (_isDisposed) return;
      _updateCurrentIndex(index);
    });
  }

  void _updateCurrentIndex(int index) {
    if (_currentIndex == index || _isDisposed) return;
    
    pauseCurrentStory();
    _currentIndex = index;
    _progress[index] = 0.0;
    _preloadStories();
    _startProgressTimer();
    notifyListeners();
  }

  void _preloadStories() {
    if (_isDisposed) return;
    
    final preloadRange = 1;
    final startIndex = _currentIndex.clamp(0, stories.length - 1);
    final endIndex = (_currentIndex + preloadRange).clamp(0, stories.length - 1);

    for (int i = startIndex; i <= endIndex; i++) {
      if (!_controllers.containsKey(i) && _hasError[i] != true) {
        _initializeController(i);
      }
    }

    _disposeUnusedControllers();
  }

  void _initializeController(int index) {
    if (_isDisposed || _controllers.containsKey(index) || index >= stories.length) return;

    try {
      final controller = CachedVideoPlayerPlusController.networkUrl(
        Uri.parse(stories[index].url),
        invalidateCacheIfOlderThan: const Duration(days: 30),
      );

      _controllers[index] = controller;
      _isInitialized[index] = false;
      _hasError[index] = false;

      controller.initialize().then((_) {
        if (_isDisposed) return;
        _isInitialized[index] = true;
        
        if (index == _currentIndex) {
          controller.play();
          _startProgressTimer();
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
    
    final keepRange = 2;
    final startKeep = _currentIndex.clamp(0, stories.length - 1);
    final endKeep = (_currentIndex + keepRange).clamp(0, stories.length - 1);

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
      _progress.remove(index);
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    if (_isDisposed || _currentIndex >= stories.length) return;

    final story = stories[_currentIndex];
    const updateInterval = Duration(milliseconds: 100);
    final totalSteps = story.duration.inMilliseconds / updateInterval.inMilliseconds;

    _progressTimer = Timer.periodic(updateInterval, (timer) {
      if (_isDisposed || _isPaused) return;

      final currentProgress = _progress[_currentIndex] ?? 0.0;
      final increment = 1.0 / totalSteps;
      final newProgress = (currentProgress + increment).clamp(0.0, 1.0);
      
      _progress[_currentIndex] = newProgress;
      notifyListeners();

      if (newProgress >= 1.0) {
        timer.cancel();
        _nextStory();
      }
    });
  }

  void _nextStory() {
    if (_currentIndex < stories.length - 1) {
      onPageChanged(_currentIndex + 1);
    }
  }

  void pauseCurrentStory() {
    if (_isDisposed) return;
    _isPaused = true;
    _progressTimer?.cancel();
    final controller = _controllers[_currentIndex];
    if (controller != null && _isInitialized[_currentIndex] == true) {
      controller.pause();
    }
    notifyListeners();
  }

  void resumeCurrentStory() {
    if (_isDisposed) return;
    _isPaused = false;
    final controller = _controllers[_currentIndex];
    if (controller != null && _isInitialized[_currentIndex] == true) {
      controller.play();
      _startProgressTimer();
    }
    notifyListeners();
  }

  void togglePlayPause() {
    if (_isPaused) {
      resumeCurrentStory();
    } else {
      pauseCurrentStory();
    }
  }

  void stopAllStories() {
    if (_isDisposed) return;
    
    _progressTimer?.cancel();
    for (final controller in _controllers.values) {
      if (controller.value.isInitialized) {
        controller.pause();
        controller.seekTo(Duration.zero);
      }
    }
  }

  void initialize() {
    if (_isDisposed) return;
    _preloadStories();
    _startProgressTimer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _progressTimer?.cancel();
    
    stopAllStories();
    
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _isInitialized.clear();
    _hasError.clear();
    _progress.clear();
    
    super.dispose();
  }
} 