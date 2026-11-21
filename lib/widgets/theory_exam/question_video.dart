import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:drivio/features/theory_exam/video_playback.dart';
import 'package:drivio/theme/app_theme.dart';

/// The film of a question. Plays once when [play] becomes true; with
/// [controls] the learner can watch it again, in the exam there is no way to
/// replay, as in WORD. After the end the last frame stays on screen.
class QuestionVideo extends ConsumerStatefulWidget {
  const QuestionVideo({
    super.key,
    required this.file,
    this.play = true,
    this.controls = true,
    this.onStarted,
    this.onEnded,
    this.onFailed,
  });

  final File file;
  final bool play;
  final bool controls;
  final ValueChanged<Duration>? onStarted;
  final VoidCallback? onEnded;
  final VoidCallback? onFailed;

  @override
  ConsumerState<QuestionVideo> createState() => _QuestionVideoState();
}

class _QuestionVideoState extends ConsumerState<QuestionVideo> {
  late final TheoryVideoController _controller;
  bool _ready = false;
  bool _failed = false;
  bool _started = false;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(theoryVideoControllerFactoryProvider)(
      widget.file,
      onEnded: _handleEnded,
    );
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
      if (widget.play) await _start();
    } catch (error) {
      debugPrint('Theory video failed: $error');
      if (!mounted) return;
      setState(() => _failed = true);
      widget.onFailed?.call();
    }
  }

  Future<void> _start() async {
    if (_started && !widget.controls) return;
    setState(() {
      _started = true;
      _ended = false;
    });
    await _controller.playFromStart();
    widget.onStarted?.call(_controller.duration);
  }

  void _handleEnded() {
    if (!mounted) return;
    setState(() => _ended = true);
    widget.onEnded?.call();
  }

  @override
  void didUpdateWidget(QuestionVideo old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play && _ready && !_started) _start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (_failed) {
      content = _placeholder(
        Icons.videocam_off_outlined,
        'Nie udało się odtworzyć filmu',
      );
    } else if (!_ready) {
      content = const Center(child: CircularProgressIndicator());
    } else if (!_started) {
      content = _placeholder(Icons.movie_outlined, 'Film ruszy za chwilę');
    } else {
      content = _controller.view();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ColoredBox(
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: _ready ? _controller.aspectRatio : 16 / 9,
              child: content,
            ),
          ),
        ),
        if (widget.controls && _ended)
          TextButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Odtwórz ponownie'),
          ),
      ],
    );
  }

  Widget _placeholder(IconData icon, String text) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 36),
        const SizedBox(height: 8),
        Text(
          text,
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
      ],
    ),
  );
}
