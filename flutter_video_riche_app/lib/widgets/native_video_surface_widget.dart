import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Widget that displays a native video surface for optimal performance
class NativeVideoSurfaceWidget extends StatefulWidget {
  final int playerId;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const NativeVideoSurfaceWidget({
    super.key,
    required this.playerId,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  State<NativeVideoSurfaceWidget> createState() => _NativeVideoSurfaceWidgetState();
}

class _NativeVideoSurfaceWidgetState extends State<NativeVideoSurfaceWidget> {
  @override
  Widget build(BuildContext context) {
    // Platform-specific native video surface
    if (Platform.isIOS) {
      return _buildIOSVideoSurface();
    } else if (Platform.isAndroid) {
      return _buildAndroidVideoSurface();
    } else {
      return _buildFallbackWidget();
    }
  }

  Widget _buildIOSVideoSurface() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: UiKitView(
        viewType: 'native_video_view',
        creationParams: {
          'playerId': widget.playerId,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: _buildGestureRecognizers(),
      ),
    );
  }

  Widget _buildAndroidVideoSurface() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: PlatformViewLink(
        viewType: 'native_video_view',
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: _buildGestureRecognizers(),
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          return PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: 'native_video_view',
            layoutDirection: TextDirection.ltr,
            creationParams: {
              'playerId': widget.playerId,
            },
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () {
              params.onFocusChanged(true);
            },
          );
        },
      ),
    );
  }

  Widget _buildFallbackWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              color: Colors.white54,
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'Native video not supported\non this platform',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Set<Factory<OneSequenceGestureRecognizer>> _buildGestureRecognizers() {
    return {
      if (widget.onTap != null)
        Factory<TapGestureRecognizer>(
          () => TapGestureRecognizer()
            ..onTap = widget.onTap,
        ),
    };
  }

  void _onPlatformViewCreated(int id) {
    if (kDebugMode) {
      print('[NativeVideoSurface] Platform view created with ID: $id for player ${widget.playerId}');
    }
  }
}

/// Widget that provides a smooth transition between thumbnail and native video
class TransitionVideoWidget extends StatefulWidget {
  final int? playerId;
  final String thumbnailUrl;
  final bool isPlaying;
  final bool showNativePlayer;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const TransitionVideoWidget({
    super.key,
    this.playerId,
    required this.thumbnailUrl,
    required this.isPlaying,
    required this.showNativePlayer,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  State<TransitionVideoWidget> createState() => _TransitionVideoWidgetState();
}

class _TransitionVideoWidgetState extends State<TransitionVideoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(TransitionVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.showNativePlayer != oldWidget.showNativePlayer) {
      if (widget.showNativePlayer && widget.playerId != null) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          // Thumbnail layer (always present as background)
          Positioned.fill(
            child: Image.network(
              widget.thumbnailUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Native video layer (fades in when playing)
          if (widget.showNativePlayer && widget.playerId != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: NativeVideoSurfaceWidget(
                      playerId: widget.playerId!,
                      width: widget.width,
                      height: widget.height,
                      onTap: widget.onTap,
                    ),
                  );
                },
              ),
            ),
          
          // Tap detector for thumbnail when no native player
          if (!widget.showNativePlayer && widget.onTap != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          
          // Play indicator overlay
          if (widget.isPlaying)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.green.withOpacity(0.6),
                    width: 2,
                  ),
                ),
                child: const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
