import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

/// Plays one downloaded question video; a fake replaces it in tests.
abstract class TheoryVideoController {
  Future<void> initialize();
  Duration get duration;
  double get aspectRatio;

  /// Starts from the beginning; [onEnded] fires when playback reaches the end.
  Future<void> playFromStart();
  Widget view();
  Future<void> dispose();
}

typedef TheoryVideoControllerFactory =
    TheoryVideoController Function(File file, {required VoidCallback onEnded});

final theoryVideoControllerFactoryProvider =
    Provider<TheoryVideoControllerFactory>(
      (ref) => VideoPlayerTheoryController.new,
    );

class VideoPlayerTheoryController implements TheoryVideoController {
  VideoPlayerTheoryController(File file, {required VoidCallback onEnded})
    : _controller = VideoPlayerController.file(file),
      _onEnded = onEnded;

  final VideoPlayerController _controller;
  final VoidCallback _onEnded;
  bool _playing = false;

  void _listen() {
    final v = _controller.value;
    if (_playing && v.isInitialized && !v.isPlaying &&
        v.position >= v.duration) {
      _playing = false;
      _onEnded();
    }
  }

  @override
  Future<void> initialize() async {
    await _controller.initialize();
    _controller.addListener(_listen);
  }

  @override
  Duration get duration => _controller.value.duration;

  @override
  double get aspectRatio => _controller.value.aspectRatio;

  @override
  Future<void> playFromStart() async {
    await _controller.seekTo(Duration.zero);
    _playing = true;
    await _controller.play();
  }

  @override
  Widget view() => VideoPlayer(_controller);

  @override
  Future<void> dispose() async {
    _controller.removeListener(_listen);
    await _controller.dispose();
  }
}
