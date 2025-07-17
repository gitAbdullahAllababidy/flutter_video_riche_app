import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to detect device hardware capabilities for video decoding
class HardwareDetectionService {
  static final HardwareDetectionService _instance = HardwareDetectionService._internal();
  factory HardwareDetectionService() => _instance;
  HardwareDetectionService._internal();

  static const MethodChannel _channel = MethodChannel('dual_video_hardware');
  
  // Cached values to avoid repeated platform calls
  int? _maxDecoders;
  bool? _supportsNativePlayback;
  String? _chipsetInfo;
  
  /// Get maximum number of concurrent video decoders supported by the device
  Future<int> getMaxConcurrentDecoders() async {
    if (_maxDecoders != null) return _maxDecoders!;
    
    try {
      // Try platform-specific detection first
      final result = await _channel.invokeMethod<int>('getMaxDecoders');
      if (result != null && result > 0) {
        _maxDecoders = result;
        if (kDebugMode) {
          print('[HardwareDetection] Platform reported max decoders: $result');
        }
        return result;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[HardwareDetection] Platform call failed: $e');
      }
    }
    
    // Fallback to heuristic detection
    _maxDecoders = await _detectMaxDecodersHeuristic();
    if (kDebugMode) {
      print('[HardwareDetection] Heuristic max decoders: $_maxDecoders');
    }
    
    return _maxDecoders!;
  }
  
  /// Check if device supports native video surface rendering
  Future<bool> supportsNativeVideoSurfaces() async {
    if (_supportsNativePlayback != null) return _supportsNativePlayback!;
    
    try {
      final result = await _channel.invokeMethod<bool>('supportsNativeSurfaces');
      _supportsNativePlayback = result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('[HardwareDetection] Native surface check failed: $e');
      }
      _supportsNativePlayback = false;
    }
    
    if (kDebugMode) {
      print('[HardwareDetection] Native surfaces supported: $_supportsNativePlayback');
    }
    
    return _supportsNativePlayback!;
  }
  
  /// Get chipset information for debugging
  Future<String> getChipsetInfo() async {
    if (_chipsetInfo != null) return _chipsetInfo!;
    
    try {
      final result = await _channel.invokeMethod<String>('getChipsetInfo');
      _chipsetInfo = result ?? 'Unknown';
    } catch (e) {
      if (kDebugMode) {
        print('[HardwareDetection] Chipset info failed: $e');
      }
      _chipsetInfo = 'Unknown';
    }
    
    if (kDebugMode) {
      print('[HardwareDetection] Chipset: $_chipsetInfo');
    }
    
    return _chipsetInfo!;
  }
  
  /// Determine optimal playback strategy based on hardware capabilities
  Future<PlaybackStrategy> getOptimalPlaybackStrategy() async {
    final maxDecoders = await getMaxConcurrentDecoders();
    final supportsNative = await supportsNativeVideoSurfaces();
    
    if (maxDecoders >= 2 && supportsNative) {
      return PlaybackStrategy.dualNative;
    } else if (maxDecoders >= 2) {
      return PlaybackStrategy.dualTexture;
    } else {
      return PlaybackStrategy.singlePlayer;
    }
  }
  
  /// Heuristic detection based on platform and device characteristics
  Future<int> _detectMaxDecodersHeuristic() async {
    if (Platform.isIOS) {
      return await _detectIOSDecoders();
    } else if (Platform.isAndroid) {
      return await _detectAndroidDecoders();
    } else {
      return 1; // Conservative fallback
    }
  }
  
  /// iOS-specific decoder detection
  Future<int> _detectIOSDecoders() async {
    try {
      // iOS devices generally support multiple hardware decoders
      // iPhone 12 and newer: 4+ decoders
      // iPhone X-11: 2-3 decoders
      // Older devices: 1-2 decoders
      
      final deviceInfo = await _getIOSDeviceInfo();
      
      if (deviceInfo.contains('iPhone14') || deviceInfo.contains('iPhone15') || deviceInfo.contains('iPhone16')) {
        return 4; // Latest iPhones
      } else if (deviceInfo.contains('iPhone13') || deviceInfo.contains('iPhone12')) {
        return 3; // Recent iPhones
      } else if (deviceInfo.contains('iPhone11') || deviceInfo.contains('iPhoneX')) {
        return 2; // Older but capable iPhones
      } else {
        return 2; // Conservative for older devices
      }
    } catch (e) {
      return 2; // Safe default for iOS
    }
  }
  
  /// Android-specific decoder detection
  Future<int> _detectAndroidDecoders() async {
    try {
      // Android decoder support varies widely by chipset
      // Snapdragon 8xx series: 4+ decoders
      // Snapdragon 7xx series: 2-3 decoders
      // MediaTek Dimensity: 2-4 decoders
      // Exynos: 2-3 decoders
      // Lower-end chipsets: 1-2 decoders
      
      final chipset = await _getAndroidChipsetInfo();
      
      if (chipset.contains('Snapdragon 8') || chipset.contains('Dimensity 9')) {
        return 4; // High-end chipsets
      } else if (chipset.contains('Snapdragon 7') || chipset.contains('Dimensity 8')) {
        return 3; // Mid-high chipsets
      } else if (chipset.contains('Snapdragon 6') || chipset.contains('Exynos')) {
        return 2; // Mid-range chipsets
      } else {
        return 1; // Conservative for unknown/low-end
      }
    } catch (e) {
      return 1; // Conservative default for Android
    }
  }
  
  /// Get iOS device information
  Future<String> _getIOSDeviceInfo() async {
    try {
      return await _channel.invokeMethod<String>('getDeviceModel') ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
  
  /// Get Android chipset information
  Future<String> _getAndroidChipsetInfo() async {
    try {
      return await _channel.invokeMethod<String>('getChipsetModel') ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }
  
  /// Reset cached values (useful for testing)
  void resetCache() {
    _maxDecoders = null;
    _supportsNativePlayback = null;
    _chipsetInfo = null;
  }
}

/// Enum representing different playback strategies
enum PlaybackStrategy {
  /// Single video player (fallback)
  singlePlayer,
  
  /// Dual video players using Flutter textures
  dualTexture,
  
  /// Dual video players using native surfaces (optimal)
  dualNative,
}

extension PlaybackStrategyExtension on PlaybackStrategy {
  String get description {
    switch (this) {
      case PlaybackStrategy.singlePlayer:
        return 'Single player (hardware limitation)';
      case PlaybackStrategy.dualTexture:
        return 'Dual players with Flutter textures';
      case PlaybackStrategy.dualNative:
        return 'Dual players with native surfaces';
    }
  }

  bool get supportsDualPlayback {
    return this != PlaybackStrategy.singlePlayer;
  }

  bool get usesNativeSurfaces {
    return this == PlaybackStrategy.dualNative;
  }
}
