import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/dual_video_clip_model.dart';

class DualVideoItemWidget extends StatefulWidget {
  final DualVideoClipModel video;
  final bool isPlaying;
  final bool isVisible;

  const DualVideoItemWidget({
    super.key,
    required this.video,
    required this.isPlaying,
    required this.isVisible,
  });

  @override
  State<DualVideoItemWidget> createState() => _DualVideoItemWidgetState();
}

class _DualVideoItemWidgetState extends State<DualVideoItemWidget> {
  Player? _player;
  VideoController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  void _initializePlayer() async {
    _player = Player();
    _controller = VideoController(_player!);

    await _player!.open(Media(widget.video.clipUrl));
    _player!.setVolume(0.0); // Muted
    _player!.setPlaylistMode(PlaylistMode.loop); // Loop

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void didUpdateWidget(DualVideoItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying && _player != null) {
        _player!.play();
      } else if (_player != null) {
        _player!.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: widget.isPlaying
            ? Border.all(color: Colors.green, width: 2)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            if (_isInitialized && _controller != null)
              Video(controller: _controller!)
            else
              CachedNetworkImage(
                imageUrl: widget.video.thumbnail,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey[800],
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),

            if (widget.isPlaying)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.play_circle, color: Colors.green, size: 24),
              ),
          ],
        ),
      ),
    );
  }


}
