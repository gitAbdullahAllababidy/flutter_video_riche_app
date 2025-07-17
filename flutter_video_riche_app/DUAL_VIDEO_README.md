# Instagram-Style Dual Video Implementation

This implementation recreates Instagram's "two videos at once" functionality using native video surfaces and hardware-aware capabilities detection.

## Features

### ✅ Hardware-Aware Dual Playback
- **Native Surface Rendering**: Uses `AVPlayerLayer` on iOS and `SurfaceView` on Android instead of Flutter textures
- **Chipset Detection**: Probes device decoder capabilities to determine maximum concurrent video players
- **Graceful Degradation**: Falls back to single player when hardware limitations are detected
- **Optimal Performance**: Prioritizes native video surfaces for better performance and battery life

### ✅ Smart Video Management
- **Viewport Visibility Detection**: Uses `VisibilityDetector` with 50% threshold for accurate visibility tracking
- **150ms Debounce**: Prevents rapid switching during scrolling (configurable)
- **Priority System**: Most recently visible videos get playback priority
- **Pre-caching**: Background caching of video files for smooth playback
- **Automatic Muting**: All videos are muted by default with looping enabled

### ✅ Instagram-Style UI
- **Grid Layout**: 2-column grid with 9:16 aspect ratio tiles
- **Visual Indicators**: Shows playing, visible, and native player status
- **Smooth Animations**: Scale and opacity animations when playback starts/stops
- **Debug Information**: Real-time status display and debug panel

## Architecture

### Core Components

1. **`DualVideoPlaybackManager`** - Central orchestrator for video playback
2. **`HardwareDetectionService`** - Detects device capabilities and optimal strategy
3. **`NativeVideoPlatform`** - Platform channel interface for native video surfaces
4. **`DualVideoScreen`** - Main UI with grid layout and visibility detection
5. **`DualVideoItemWidget`** - Individual video tile with state indicators

### Platform Integration

#### iOS (`DualVideoPlugin.swift`)
- Uses `AVPlayer` and `AVPlayerLayer` for native video rendering
- Implements hardware decoder detection
- Provides platform view factory for Flutter integration

#### Android (`DualVideoPlugin.kt`)
- Uses `ExoPlayer` with `SurfaceView` for native video rendering
- Detects MediaCodec capabilities
- Implements platform view factory for Flutter integration

### Playback Strategies

1. **`PlaybackStrategy.dualNative`** - Optimal: 2 videos with native surfaces
2. **`PlaybackStrategy.dualTexture`** - Fallback: 2 videos with Flutter textures
3. **`PlaybackStrategy.singlePlayer`** - Degraded: 1 video when hardware is limited

## Usage

### Navigation
From the home screen, tap **"Instagram Dual Videos"** to access the feature.

### Video Data
The implementation uses the provided video clips with the following structure:
```dart
{
  "videoUrl": "https://example.com/video.mp4",
  "clipUrl": "https://example.com/clip.mp4", // Used for faster loading
  "thumbnail": "https://example.com/thumb.jpg"
}
```

### State Management
Uses Riverpod for reactive state management:
- `dualVideoClipsProvider` - Provides video data
- `dualVideoManagerProvider` - Manages playback lifecycle
- `dualVideoScreenProvider` - Handles UI state and visibility updates

## Technical Implementation

### Hardware Detection
```dart
// Detect optimal strategy
final strategy = await HardwareDetectionService().getOptimalPlaybackStrategy();

// Get max concurrent decoders
final maxDecoders = await HardwareDetectionService().getMaxConcurrentDecoders();
```

### Visibility Tracking
```dart
VisibilityDetector(
  key: Key('dual_video_${video.id}'),
  onVisibilityChanged: (info) {
    final isVisible = info.visibleFraction > 0.5; // 50% threshold
    manager.updateVideoVisibility(video.id, isVisible);
  },
  child: VideoWidget(),
)
```

### Native Player Creation
```dart
// Create native player
final playerId = await NativeVideoPlatform.createNativePlayer(
  videoUrl: video.clipUrl,
  autoPlay: true,
  muted: true,
  looping: true,
);
```

## Configuration

### Adjustable Parameters
- `maxConcurrentVideos`: Maximum videos playing simultaneously (default: 2)
- `visibilityDebounce`: Delay before processing visibility changes (default: 150ms)
- Visibility threshold: Percentage of widget visible to trigger playback (default: 50%)

### Platform Requirements
- **iOS**: iOS 12.0+, AVFoundation framework
- **Android**: API 21+, ExoPlayer 2.19.1

## Testing

Run the test suite:
```bash
flutter test test/dual_video_test.dart
```

Tests cover:
- Model serialization/deserialization
- Hardware detection service
- Playback manager functionality
- Strategy selection logic

## Debug Features

### Status Indicators
- 🟢 Green: Currently playing
- 🟠 Orange: Visible but not playing
- 🔵 Blue: Using native player
- ⚙️ Hardware: Native surface rendering

### Debug Panel
Tap the info icon in the app bar to view:
- Current playback strategy
- Number of visible/playing videos
- Hardware capabilities
- Real-time status updates

## Performance Considerations

### Optimizations
- Native video surfaces reduce CPU/GPU usage
- Pre-caching minimizes loading delays
- Debounced visibility prevents excessive switching
- Automatic disposal of unused players

### Memory Management
- Players are automatically disposed when not needed
- Cache size limits prevent memory bloat
- Background pre-caching is throttled

## Known Limitations

1. **Platform Channel Setup**: Requires proper iOS/Android configuration
2. **Hardware Variance**: Performance varies significantly across devices
3. **Network Dependency**: Requires stable internet for video streaming
4. **Testing Environment**: Some features may not work in Flutter test environment

## Future Enhancements

- [ ] Adaptive bitrate streaming based on network conditions
- [ ] Background video pre-loading queue
- [ ] Custom video controls overlay
- [ ] Analytics and performance monitoring
- [ ] Offline video caching support
