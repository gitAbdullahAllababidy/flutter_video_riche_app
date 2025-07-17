import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform interface for native video surface handling
class NativeVideoPlatform {
  static const MethodChannel _channel = MethodChannel('dual_video_native');
  static const EventChannel _eventChannel = EventChannel('dual_video_events');
  
  static final Map<int, StreamController<NativeVideoEvent>> _eventControllers = {};
  static StreamSubscription? _eventSubscription;
  
  /// Initialize the native video platform
  static Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
      _setupEventListener();
      if (kDebugMode) {
        print('[NativeVideoPlatform] Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NativeVideoPlatform] Initialization failed: $e');
      }
      rethrow;
    }
  }
  
  /// Create a native video player
  static Future<int> createNativePlayer({
    required String videoUrl,
    bool autoPlay = false,
    bool muted = true,
    bool looping = true,
  }) async {
    try {
      final playerId = await _channel.invokeMethod<int>('createPlayer', {
        'videoUrl': videoUrl,
        'autoPlay': autoPlay,
        'muted': muted,
        'looping': looping,
      });
      
      if (playerId == null) {
        throw Exception('Failed to create native player');
      }
      
      // Create event controller for this player
      _eventControllers[playerId] = StreamController<NativeVideoEvent>.broadcast();
      
      if (kDebugMode) {
        print('[NativeVideoPlatform] Created player $playerId for $videoUrl');
      }
      
      return playerId;
    } catch (e) {
      if (kDebugMode) {
        print('[NativeVideoPlatform] Failed to create player: $e');
      }
      rethrow;
    }
  }
  
  /// Play a native video player
  static Future<void> play(int playerId) async {
    try {
      await _channel.invokeMethod('play', {'playerId': playerId});
      if (kDebugMode) {
        print('[NativeVideoPlatform] Playing player $playerId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NativeVideoPlatform] Failed to play $playerId: $e');
      }
      rethrow;
    }
  }
  
  /// Pause a native video player
  static Future<void> pause(int playerId) async {
    try {
      await _channel.invokeMethod('pause', {'playerId': playerId});
      if (kDebugMode) {
        print('[NativeVideoPlatform] Paused player $playerId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NativeVideoPlatform] Failed to pause $playerId: $e');
      }
      rethrow;
    }
  }
  
  /// Dispose a native video player
  static Future<void> disposePlayer(int playerId) async {
    try {
      await _channel.invokeMethod('disposePlayer', {'playerId': playerId});
      
      // Clean up event controller
      _eventControllers[playerId]?.close();
      _eventControllers.remove(playerId);
      
      if (kDebugMode) {
        print('[NativeVideoPlatform] Disposed player $playerId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NativeVideoPlatform] Failed to dispose $playerId: $e');
      }
      rethrow;
    }
  }
  
  /// Set volume for a player
  static Future<void> setVolume(int playerId, double volume) async {
    try {
      await _channel.invokeMethod('setVolume', {
        'playerId': playerId,
        'volume': volume.clamp(0.0, 1.0),
      });
    } catch (e) {
      if (kDebugMode) {
        print('[NativeVideoPlatform] Failed to set volume for $playerId: $e');
      }
      rethrow;
    }
  }
  
  /// Seek to position in a player
  static Future<void> seekTo(int playerId, Duration position) async {
    try {
      await _channel.invokeMethod('seekTo', {
        'playerId': playerId,
        'position': position.inMilliseconds,
      });
    } catch (e) {
      if (kDebugMode) {
        print('[NativeVideoPlatform] Failed to seek $playerId: $e');
      }
      rethrow;
    }
  }
  
  /// Get current position of a player
  static Future<Duration> getCurrentPosition(int playerId) async {
    try {
      final position = await _channel.invokeMethod<int>('getCurrentPosition', {
        'playerId': playerId,
      });
      return Duration(milliseconds: position ?? 0);
    } catch (e) {
      if (kDebugMode) {
        print('[NativeVideoPlatform] Failed to get position for $playerId: $e');
      }
      return Duration.zero;
    }
  }
  
  /// Get duration of a player
  static Future<Duration> getDuration(int playerId) async {
    try {
      final duration = await _channel.invokeMethod<int>('getDuration', {
        'playerId': playerId,
      });
      return Duration(milliseconds: duration ?? 0);
    } catch (e) {
      if (kDebugMode) {
        print('[NativeVideoPlatform] Failed to get duration for $playerId: $e');
      }
      return Duration.zero;
    }
  }
  
  /// Get event stream for a specific player
  static Stream<NativeVideoEvent>? getEventStream(int playerId) {
    return _eventControllers[playerId]?.stream;
  }
  
  /// Setup event listener for all players
  static void _setupEventListener() {
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        try {
          final eventData = Map<String, dynamic>.from(event);
          final playerId = eventData['playerId'] as int?;
          final eventType = eventData['eventType'] as String?;
          
          if (playerId != null && eventType != null) {
            final videoEvent = NativeVideoEvent.fromMap(eventData);
            _eventControllers[playerId]?.add(videoEvent);
          }
        } catch (e) {
          if (kDebugMode) {
            print('[NativeVideoPlatform] Event parsing error: $e');
          }
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('[NativeVideoPlatform] Event stream error: $error');
        }
      },
    );
  }
  
  /// Cleanup all resources
  static Future<void> dispose() async {
    try {
      await _channel.invokeMethod('dispose');
      _eventSubscription?.cancel();
      
      for (final controller in _eventControllers.values) {
        controller.close();
      }
      _eventControllers.clear();
      
      if (kDebugMode) {
        print('[NativeVideoPlatform] Disposed all resources');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NativeVideoPlatform] Disposal error: $e');
      }
    }
  }
}

/// Native video event data
class NativeVideoEvent {
  final int playerId;
  final NativeVideoEventType type;
  final Map<String, dynamic> data;
  
  const NativeVideoEvent({
    required this.playerId,
    required this.type,
    required this.data,
  });
  
  factory NativeVideoEvent.fromMap(Map<String, dynamic> map) {
    return NativeVideoEvent(
      playerId: map['playerId'] as int,
      type: _parseEventType(map['eventType'] as String),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }

  static NativeVideoEventType _parseEventType(String value) {
    switch (value) {
      case 'initialized':
        return NativeVideoEventType.initialized;
      case 'playing':
        return NativeVideoEventType.playing;
      case 'paused':
        return NativeVideoEventType.paused;
      case 'ended':
        return NativeVideoEventType.ended;
      case 'error':
        return NativeVideoEventType.error;
      case 'positionChanged':
        return NativeVideoEventType.positionChanged;
      case 'durationChanged':
        return NativeVideoEventType.durationChanged;
      default:
        return NativeVideoEventType.error;
    }
  }
}

/// Native video event types
enum NativeVideoEventType {
  initialized,
  playing,
  paused,
  ended,
  error,
  positionChanged,
  durationChanged,
}


