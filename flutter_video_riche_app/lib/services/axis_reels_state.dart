import 'dart:async';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/axis_reel_model.dart';

class AxisReelsState extends ChangeNotifier {
  // Multiple rows of content - each row has one image and one video
  final List<List<AxisReelModel>> _reelRows = [
    // Row 1: Landscape & Video
    [
      AxisReelModel(
        id: '1',
        url: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=900&auto=format&fit=crop&q=20',
        type: ReelType.image,
        title: 'Beautiful Landscape',
      ),
      AxisReelModel(
        id: '2',
        url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/af543177-374f-4947-bdbc-a3bacd65e42b_clip.mp4',
        type: ReelType.video,
        thumbnailUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=900&auto=format&fit=crop&q=20',
        title: 'Amazing Video 1',
        loopCount: 25,
      ),
    ],
    // Row 2: Ocean & Video
    [
      AxisReelModel(
        id: '3',
        url: 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=900&auto=format&fit=crop&q=20',
        type: ReelType.image,
        title: 'Ocean Waves',
      ),
      AxisReelModel(
        id: '4',
        url: 'https://d2594vc0rpodpd.cloudfront.net/vids/post/2025/06/23/1bd946af-27cd-4ff7-85a3-733010f47cd2_clip.mp4',
        type: ReelType.video,
        thumbnailUrl: 'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=900&auto=format&fit=crop&q=20',
        title: 'Adventure Video',
        loopCount: 25,
      ),
    ],
    // Row 3: City & Video
    [
      AxisReelModel(
        id: '5',
        url: 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=900&auto=format&fit=crop&q=20',
        type: ReelType.image,
        title: 'City Lights',
      ),
      AxisReelModel(
        id: '6',
        url: 'https://d2594vc0rpodpd.cloudfront.net/vids/post/2025/05/26/2a1735d7-10b4-46a3-b585-998c7f67b18f_clip.mp4',
        type: ReelType.video,
        thumbnailUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=900&auto=format&fit=crop&q=20',
        title: 'Urban Life',
        loopCount: 25,
      ),
    ],
    // Row 4: Nature & Video
    [
      AxisReelModel(
        id: '7',
        url: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=900&auto=format&fit=crop&q=20',
        type: ReelType.image,
        title: 'Forest Trail',
      ),
      AxisReelModel(
        id: '8',
        url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/f965c476-298d-4c63-99b8-555bdc68b034_clip.mp4',
        type: ReelType.video,
        thumbnailUrl: 'https://images.unsplash.com/photo-1542831371-29b0f74f9713?w=900&auto=format&fit=crop&q=20',
        title: 'Nature Walk',
        loopCount: 25,
      ),
    ],
    // Row 5: Technology & Video
    [
      AxisReelModel(
        id: '9',
        url: 'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=900&auto=format&fit=crop&q=20',
        type: ReelType.image,
        title: 'Tech World',
      ),
      AxisReelModel(
        id: '10',
        url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/19/a03a15ed-e776-4858-9247-df622b3aa1c8_clip.mp4',
        type: ReelType.video,
        thumbnailUrl: 'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=900&auto=format&fit=crop&q=20',
        title: 'Innovation',
        loopCount: 25,
      ),
    ],
    // Row 6: Space & Video
    [
      AxisReelModel(
        id: '11',
        url: 'https://images.unsplash.com/photo-1446776653964-20c1d3a81b06?w=900&auto=format&fit=crop&q=20',
        type: ReelType.image,
        title: 'Galaxy',
      ),
      AxisReelModel(
        id: '12',
        url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/cfd211b2-089e-44a3-885e-ad0cbbb30efb_clip.mp4',
        type: ReelType.video,
        thumbnailUrl: 'https://images.unsplash.com/photo-1502134249126-9f3755a50d78?w=900&auto=format&fit=crop&q=20',
        title: 'Space Exploration',
        loopCount: 25,
      ),
    ],
    // Row 7: Food & Video
    [
      AxisReelModel(
        id: '13',
        url: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900&auto=format&fit=crop&q=20',
        type: ReelType.image,
        title: 'Delicious Food',
      ),
      AxisReelModel(
        id: '14',
        url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/a4d71594-60ad-4011-a12d-e78342a37e82_clip.mp4',
        type: ReelType.video,
        thumbnailUrl: 'https://images.unsplash.com/photo-1493770348161-369560ae357d?w=900&auto=format&fit=crop&q=20',
        title: 'Cooking Show',
        loopCount: 25,
      ),
    ],
    // Row 8: Art & Video
    [
      AxisReelModel(
        id: '15',
        url: 'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=900&auto=format&fit=crop&q=20',
        type: ReelType.image,
        title: 'Modern Art',
      ),
      AxisReelModel(
        id: '16',
        url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/20/5ef3d25f-81e5-4b4a-9172-90ad4c279e05_clip.mp4',
        type: ReelType.video,
        thumbnailUrl: 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=900&auto=format&fit=crop&q=20',
        title: 'Creative Process',
        loopCount: 25,
      ),
    ],
    // Row 9: Sports & Video
    [
      AxisReelModel(
        id: '17',
        url: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=900&auto=format&fit=crop&q=20',
        type: ReelType.image,
        title: 'Sports Action',
      ),
      AxisReelModel(
        id: '18',
        url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/20/d27090f4-6e09-4bb4-917c-eb988e674a17_clip.mp4',
        type: ReelType.video,
        thumbnailUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=900&auto=format&fit=crop&q=20',
        title: 'Athletic Performance',
        loopCount: 25,
      ),
    ],
    // Row 10: Travel & Video
    [
      AxisReelModel(
        id: '19',
        url: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=900&auto=format&fit=crop&q=20',
        type: ReelType.image,
        title: 'Travel Destination',
      ),
      AxisReelModel(
        id: '20',
        url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/9bf8cb2d-0a69-47a4-8bc6-c932b9876b68_clip.mp4',
        type: ReelType.video,
        thumbnailUrl: 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=900&auto=format&fit=crop&q=20',
        title: 'Travel Journey',
        loopCount: 25,
      ),
    ],
    // Row 11: Architecture & Video
    [
      AxisReelModel(
        id: '21',
        url: 'https://images.unsplash.com/photo-1487958449943-2429e8be8625?w=900&auto=format&fit=crop&q=20',
        type: ReelType.image,
        title: 'Modern Architecture',
      ),
      AxisReelModel(
        id: '22',
        url: 'https://d2594vc0rpodpd.cloudfront.net/vids/post/2025/06/10/87ed3cd9-6c45-45c2-b8d0-d16fa4c78c72_clip.mp4',
        type: ReelType.video,
        thumbnailUrl: 'https://images.unsplash.com/photo-1448630360428-65456885c650?w=900&auto=format&fit=crop&q=20',
        title: 'Architectural Wonder',
        loopCount: 25,
      ),
    ],
    // Row 12: Animals & Video
    [
      AxisReelModel(
        id: '23',
        url: 'https://images.unsplash.com/photo-1546026423-cc4642628d2b?w=900&auto=format&fit=crop&q=20',
        type: ReelType.image,
        title: 'Wildlife',
      ),
      AxisReelModel(
        id: '24',
        url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/aec5fc11-84bf-4faa-a166-f3a5ce96819d_clip.mp4',
        type: ReelType.video,
        thumbnailUrl: 'https://images.unsplash.com/photo-1564349683136-77e08dba1ef7?w=900&auto=format&fit=crop&q=20',
        title: 'Animal Kingdom',
        loopCount: 25,
      ),
    ],
    // Row 13: Music & Video
    [
      AxisReelModel(
        id: '25',
        url: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=900&auto=format&fit=crop&q=20',
        type: ReelType.image,
        title: 'Music Vibes',
      ),
      AxisReelModel(
        id: '26',
        url: 'https://d2594vc0rpodpd.cloudfront.net/vids/post/2025/05/20/852d06a6-3fd6-4f1a-8a78-931a1d3fb8cc_clip.mp4',
        type: ReelType.video,
        thumbnailUrl: 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=900&auto=format&fit=crop&q=20',
        title: 'Musical Performance',
        loopCount: 25,
      ),
    ],
    // Row 14: Fashion & Video
    [
      AxisReelModel(
        id: '27',
        url: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=900&auto=format&fit=crop&q=20',
        type: ReelType.image,
        title: 'Fashion Style',
      ),
      AxisReelModel(
        id: '28',
        url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/05/25/6c6d90c7-2197-499c-88fe-7c97333fb7ab_clip.mp4',
        type: ReelType.video,
        thumbnailUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=900&auto=format&fit=crop&q=20',
        title: 'Style Showcase',
        loopCount: 25,
      ),
    ],
    // Row 15: Fitness & Video
    [
      AxisReelModel(
        id: '29',
        url: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=900&auto=format&fit=crop&q=20',
        type: ReelType.image,
        title: 'Fitness Goals',
      ),
      AxisReelModel(
        id: '30',
        url: 'https://d2594vc0rpodpd.cloudfront.net/vids/packages/2025/04/10/fd0004ef-a14b-464b-a24b-1b9e430ca3b5_clip.mp4',
        type: ReelType.video,
        thumbnailUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=900&auto=format&fit=crop&q=20',
        title: 'Workout Routine',
        loopCount: 25,
      ),
    ],
  ];

  final Map<String, CachedVideoPlayerPlusController> _videoControllers = {};
  final Map<String, bool> _isVideoInitialized = {};
  final Map<String, bool> _hasVideoError = {};
  final Map<String, int> _videoLoopCounts = {};
  final Map<String, Timer?> _autoplayTimers = {};
  final Set<String> _visibleVideoIds = {};
  
  Timer? _debounceTimer;
  bool _isDisposed = false;
  static const Duration _autoplayDelay = Duration(milliseconds: 800);

  List<List<AxisReelModel>> get reelRows => _reelRows;
  
  // Flatten all reels for easy access
  List<AxisReelModel> get allReels => _reelRows.expand((row) => row).toList();

  CachedVideoPlayerPlusController? getVideoController(String videoId) {
    return _videoControllers[videoId];
  }

  bool isVideoInitialized(String videoId) => _isVideoInitialized[videoId] ?? false;
  bool hasVideoError(String videoId) => _hasVideoError[videoId] ?? false;
  bool isVideoVisible(String videoId) => _visibleVideoIds.contains(videoId);

  void initialize() {
    if (_isDisposed) return;
    
    // Preload first few videos
    final videoReels = allReels.where((reel) => reel.type == ReelType.video).take(3);
    for (final reel in videoReels) {
      _initializeVideoController(reel);
    }
  }

  void onVideoVisibilityChanged(String videoId, bool isVisible) {
    if (_isDisposed) return;

    if (isVisible) {
      _visibleVideoIds.add(videoId);
      _startAutoplayTimer(videoId);
    } else {
      _visibleVideoIds.remove(videoId);
      _cancelAutoplayTimer(videoId);
      _pauseVideo(videoId);
    }
  }

  void _startAutoplayTimer(String videoId) {
    if (_isDisposed) return;

    _cancelAutoplayTimer(videoId);
    
    _autoplayTimers[videoId] = Timer(_autoplayDelay, () {
      if (_isDisposed || !_visibleVideoIds.contains(videoId)) return;
      
      final reel = allReels.firstWhere((r) => r.id == videoId);
      if (!_videoControllers.containsKey(videoId)) {
        _initializeVideoController(reel);
      } else if (_isVideoInitialized[videoId] == true) {
        _playVideo(videoId);
      }
    });
  }

  void _cancelAutoplayTimer(String videoId) {
    _autoplayTimers[videoId]?.cancel();
    _autoplayTimers[videoId] = null;
  }

  void _initializeVideoController(AxisReelModel videoReel) {
    if (_isDisposed || _videoControllers.containsKey(videoReel.id)) return;

    try {
      final controller = CachedVideoPlayerPlusController.networkUrl(
        Uri.parse(videoReel.url),
        invalidateCacheIfOlderThan: const Duration(days: 30),
      );

      _videoControllers[videoReel.id] = controller;
      _isVideoInitialized[videoReel.id] = false;
      _hasVideoError[videoReel.id] = false;
      _videoLoopCounts[videoReel.id] = 0;

      controller.initialize().then((_) {
        if (_isDisposed) return;
        
        _isVideoInitialized[videoReel.id] = true;
        _hasVideoError[videoReel.id] = false;
        
        // Set video to mute by default
        controller.setVolume(0.0);
        
        // Set up listener for finite looping
        controller.addListener(() => _handleVideoLoop(videoReel.id));
        
        // Auto-play if video is visible
        if (_visibleVideoIds.contains(videoReel.id)) {
          _playVideo(videoReel.id);
        }
        
        notifyListeners();
      }).catchError((error) {
        if (_isDisposed) return;
        
        _hasVideoError[videoReel.id] = true;
        _isVideoInitialized[videoReel.id] = false;
        _videoControllers.remove(videoReel.id);
        debugPrint('Error initializing video ${videoReel.id}: $error');
        notifyListeners();
      });
    } catch (e) {
      _hasVideoError[videoReel.id] = true;
      _isVideoInitialized[videoReel.id] = false;
      debugPrint('Error creating video controller for ${videoReel.id}: $e');
      notifyListeners();
    }
  }

  void _handleVideoLoop(String videoId) {
    if (_isDisposed || !_videoControllers.containsKey(videoId)) return;
    
    final controller = _videoControllers[videoId]!;
    final reel = allReels.firstWhere((r) => r.id == videoId);
    
    // Check if video has ended (with a small buffer for precision)
    final duration = controller.value.duration;
    final position = controller.value.position;
    
    if (duration.inMilliseconds > 0 && 
        position.inMilliseconds >= duration.inMilliseconds - 100) {
      
      final currentLoops = _videoLoopCounts[videoId] ?? 0;
      _videoLoopCounts[videoId] = currentLoops + 1;
      
      if (_videoLoopCounts[videoId]! < reel.loopCount) {
        // Restart the video for another loop
        controller.seekTo(Duration.zero);
        controller.play();
      } else {
        // Stop playing after reaching the loop count
        controller.pause();
        controller.seekTo(Duration.zero);
      }
    }
  }

  void _playVideo(String videoId) {
    if (_isDisposed || !_videoControllers.containsKey(videoId)) return;
    
    final controller = _videoControllers[videoId];
    if (controller != null && _isVideoInitialized[videoId] == true) {
      _videoLoopCounts[videoId] = 0; // Reset loop count
      controller.play();
      notifyListeners();
    }
  }

  void _pauseVideo(String videoId) {
    if (_isDisposed || !_videoControllers.containsKey(videoId)) return;
    
    final controller = _videoControllers[videoId];
    if (controller != null && _isVideoInitialized[videoId] == true) {
      controller.pause();
      notifyListeners();
    }
  }

  void toggleVideoPlayPause(String videoId) {
    if (_isDisposed || !_videoControllers.containsKey(videoId)) return;
    
    final controller = _videoControllers[videoId];
    if (controller != null && _isVideoInitialized[videoId] == true) {
      if (controller.value.isPlaying) {
        _pauseVideo(videoId);
      } else {
        _playVideo(videoId);
      }
    }
  }

  void resetVideo(String videoId) {
    if (_isDisposed || !_videoControllers.containsKey(videoId)) return;
    
    final controller = _videoControllers[videoId];
    if (controller != null && _isVideoInitialized[videoId] == true) {
      _videoLoopCounts[videoId] = 0;
      controller.seekTo(Duration.zero);
      controller.play();
      notifyListeners();
    }
  }

  void pauseAllVideos() {
    if (_isDisposed) return;
    
    for (final controller in _videoControllers.values) {
      if (controller.value.isInitialized && controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    
    // Cancel all autoplay timers
    for (final timer in _autoplayTimers.values) {
      timer?.cancel();
    }
    _autoplayTimers.clear();
    
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _isVideoInitialized.clear();
    _hasVideoError.clear();
    _videoLoopCounts.clear();
    _visibleVideoIds.clear();
    
    super.dispose();
  }
}