# Instagram Dual Video Implementation Example

This document demonstrates how the Instagram-style dual video concept is applied in this Flutter implementation.

## Core Concept Application

### 1. Hardware-Aware Video Decoding

**Instagram's Approach:**
- Probes chipset decoder capabilities
- Uses native video surfaces (SurfaceView/AVPlayerLayer)
- Gracefully degrades when hardware is limited

**Our Implementation:**
```dart
// Detect hardware capabilities
final strategy = await HardwareDetectionService().getOptimalPlaybackStrategy();

switch (strategy) {
  case PlaybackStrategy.dualNative:
    // Use native surfaces for 2 videos (optimal)
    await _startNativeVideoPlayback(video1, video2);
    break;
  case PlaybackStrategy.dualTexture:
    // Use Flutter textures for 2 videos (fallback)
    await _startTextureVideoPlayback(video1, video2);
    break;
  case PlaybackStrategy.singlePlayer:
    // Single video only (hardware limitation)
    await _startSingleVideoPlayback(mostVisibleVideo);
    break;
}
```

### 2. Native Surface Integration

**Instagram's Implementation:**
- Embeds native video surfaces directly in the UI
- Bypasses Flutter's texture rendering for better performance
- Reduces CPU/GPU usage and improves battery life

**Our Implementation:**
```dart
// iOS: AVPlayerLayer integration
UiKitView(
  viewType: 'native_video_view',
  creationParams: {'playerId': playerId},
  onPlatformViewCreated: (id) => _setupVideoPlayer(id),
)

// Android: SurfaceView integration
PlatformViewLink(
  viewType: 'native_video_view',
  surfaceFactory: (context, controller) => AndroidViewSurface(
    controller: controller,
    hitTestBehavior: PlatformViewHitTestBehavior.opaque,
  ),
)
```

### 3. Intelligent Video Selection

**Instagram's Logic:**
- Prioritizes videos based on viewport visibility
- Uses debouncing to prevent rapid switching during scrolls
- Maintains exactly 2 concurrent players when possible

**Our Implementation:**
```dart
// Visibility detection with 50% threshold
VisibilityDetector(
  onVisibilityChanged: (info) {
    final isVisible = info.visibleFraction > 0.5;
    _updateVideoVisibility(videoId, isVisible);
  },
)

// Priority-based selection
void _updatePlaybackState() {
  final sortedVisible = _visibleVideos.toList()
    ..sort((a, b) => _priorities[b].compareTo(_priorities[a]));
  
  final videosToPlay = sortedVisible.take(maxConcurrentVideos);
  
  // Start/stop videos based on priority
  for (final videoId in videosToPlay) {
    if (!_currentlyPlaying.contains(videoId)) {
      await _startVideo(videoId);
    }
  }
}
```

## Real-World Usage Example

### Video Feed Implementation

```dart
class InstagramStyleVideoFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 9 / 16, // Instagram aspect ratio
        ),
        itemBuilder: (context, index) {
          return VisibilityDetector(
            key: Key('video_$index'),
            onVisibilityChanged: (info) {
              // Update visibility with Instagram's logic
              _handleVisibilityChange(index, info.visibleFraction > 0.5);
            },
            child: VideoTile(
              video: videos[index],
              isPlaying: _playingVideos.contains(index),
              useNativePlayer: _strategy.usesNativeSurfaces,
            ),
          );
        },
      ),
    );
  }
}
```

### Hardware Detection Example

```dart
class HardwareCapabilityDemo extends StatefulWidget {
  @override
  _HardwareCapabilityDemoState createState() => _HardwareCapabilityDemoState();
}

class _HardwareCapabilityDemoState extends State<HardwareCapabilityDemo> {
  String _chipsetInfo = 'Detecting...';
  int _maxDecoders = 0;
  PlaybackStrategy _strategy = PlaybackStrategy.singlePlayer;

  @override
  void initState() {
    super.initState();
    _detectCapabilities();
  }

  Future<void> _detectCapabilities() async {
    final service = HardwareDetectionService();
    
    final chipset = await service.getChipsetInfo();
    final maxDecoders = await service.getMaxConcurrentDecoders();
    final strategy = await service.getOptimalPlaybackStrategy();
    
    setState(() {
      _chipsetInfo = chipset;
      _maxDecoders = maxDecoders;
      _strategy = strategy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device Capabilities', style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 8),
            Text('Chipset: $_chipsetInfo'),
            Text('Max Decoders: $_maxDecoders'),
            Text('Strategy: ${_strategy.description}'),
            SizedBox(height: 16),
            _buildStrategyIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyIndicator() {
    Color color;
    IconData icon;
    String description;

    switch (_strategy) {
      case PlaybackStrategy.dualNative:
        color = Colors.green;
        icon = Icons.hardware;
        description = 'Optimal: Native dual video';
        break;
      case PlaybackStrategy.dualTexture:
        color = Colors.orange;
        icon = Icons.texture;
        description = 'Good: Texture dual video';
        break;
      case PlaybackStrategy.singlePlayer:
        color = Colors.red;
        icon = Icons.videocam;
        description = 'Limited: Single video only';
        break;
    }

    return Row(
      children: [
        Icon(icon, color: color),
        SizedBox(width: 8),
        Text(description, style: TextStyle(color: color)),
      ],
    );
  }
}
```

## Performance Comparison

### Traditional Flutter Video vs Native Surface

```dart
// Traditional approach (higher resource usage)
class FlutterTextureVideo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VideoPlayer(_controller); // Uses Flutter texture
  }
}

// Instagram-style approach (optimized)
class NativeSurfaceVideo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NativeVideoSurfaceWidget(
      playerId: _nativePlayerId, // Direct native rendering
    );
  }
}
```

### Resource Usage Benefits

| Aspect | Flutter Texture | Native Surface |
|--------|----------------|----------------|
| CPU Usage | Higher (texture copying) | Lower (direct rendering) |
| GPU Usage | Higher (texture processing) | Lower (hardware acceleration) |
| Battery Life | Shorter | Longer |
| Memory | More (texture buffers) | Less (direct surfaces) |
| Smoothness | Good | Excellent |

## Integration with Existing Video Systems

### Extending Current MediaKit Implementation

```dart
class HybridVideoPlayer extends StatelessWidget {
  final bool useNativeWhenPossible;
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlaybackStrategy>(
      future: HardwareDetectionService().getOptimalPlaybackStrategy(),
      builder: (context, snapshot) {
        final strategy = snapshot.data ?? PlaybackStrategy.singlePlayer;
        
        if (useNativeWhenPossible && strategy.usesNativeSurfaces) {
          return NativeVideoSurfaceWidget(playerId: _nativePlayerId);
        } else {
          return Video(controller: _mediaKitController); // Fallback
        }
      },
    );
  }
}
```

## Testing the Implementation

### Manual Testing Steps

1. **Launch the app** and navigate to "Instagram Dual Videos"
2. **Scroll through the grid** and observe:
   - Maximum 2 videos playing simultaneously
   - Smooth transitions when videos enter/exit viewport
   - Visual indicators showing playing/visible status
3. **Check debug panel** (info icon) to see:
   - Current hardware strategy
   - Real-time playback status
   - Device capabilities

### Expected Behaviors

- **High-end devices**: Should use `dualNative` strategy with green indicators
- **Mid-range devices**: May use `dualTexture` strategy with orange indicators  
- **Low-end devices**: Falls back to `singlePlayer` with red indicators
- **Scrolling**: 150ms debounce prevents rapid video switching
- **Visibility**: Only videos >50% visible are considered for playback

## Customization Options

### Adjusting Playback Parameters

```dart
// Modify in DualVideoPlaybackManager
static const int maxConcurrentVideos = 2; // Change to 1 or 3
static const Duration visibilityDebounce = Duration(milliseconds: 150);

// Modify in DualVideoScreen
final isVisible = info.visibleFraction > 0.5; // Change threshold
```

### Custom Hardware Detection

```dart
class CustomHardwareDetection extends HardwareDetectionService {
  @override
  Future<int> getMaxConcurrentDecoders() async {
    // Custom logic for specific devices
    final deviceModel = await getDeviceModel();
    
    if (deviceModel.contains('iPhone15')) {
      return 4; // Force 4 decoders for iPhone 15
    }
    
    return super.getMaxConcurrentDecoders();
  }
}
```

This implementation demonstrates how Instagram's sophisticated video playback system can be recreated in Flutter while maintaining optimal performance and user experience.
