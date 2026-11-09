import 'dart:async';

import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_overlay_controls.dart';
import 'package:app_quanly_giaidau/features/match/widgets/match_replay_timeline.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Phát nối các segment MP4 của trận bằng một thanh thời gian toàn cục.
class MatchReplayPlayer extends StatefulWidget {
  const MatchReplayPlayer({
    super.key,
    required this.replay,
    this.fullscreen = false,
    this.onToggleFullscreen,
    this.onControlsVisibleChanged,
  });

  final MatchReplay replay;

  /// Current fullscreen state, only used to pick the button icon.
  final bool fullscreen;

  /// Shows a fullscreen button when set (same as the live player).
  final VoidCallback? onToggleFullscreen;

  /// Reports whether the control layer is up, so overlays can make room.
  final ValueChanged<bool>? onControlsVisibleChanged;

  @override
  State<MatchReplayPlayer> createState() => _MatchReplayPlayerState();
}

class _MatchReplayPlayerState extends State<MatchReplayPlayer> {
  static const _preloadThreshold = Duration(seconds: 10);

  /// Controls fade out after this long without a touch (same as the live player).
  static const _hideDelay = Duration(seconds: 3);

  /// Same step as the Web `REPLAY_BUTTON_SKIP_SEC`.
  static const _skipSeconds = 3;

  VideoPlayerController? _controller;
  VideoPlayerController? _nextController;
  int _segmentIndex = 0;
  int? _nextIndex;
  final Set<int> _failed = <int>{};
  bool _preloading = false;
  Completer<void>? _preloadCompletion;
  bool _advancing = false;
  bool _showSkipped = false;
  bool _finished = false;
  // Playback starts when the page opens, and a phone has no autoplay block
  // for sound, so the replay opens with sound on like the Web.
  bool _muted = false;
  int _displayedSeconds = 0;
  Timer? _hideTimer;
  bool _controlsVisible = true;
  bool? _reportedVisible;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
    _openSegment(0);
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideDelay, () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  /// Brings the controls back and restarts the idle timer.
  void _revealControls() {
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  /// Tap on the picture: hide the controls when they are up, else show them.
  void _onPictureTap() {
    if (!_controlsVisible) {
      _revealControls();
      return;
    }
    _hideTimer?.cancel();
    setState(() => _controlsVisible = false);
  }

  /// Tells the page when the controls change, so overlays can make room.
  void _reportControlsVisible(bool visible) {
    if (_reportedVisible == visible) return;
    _reportedVisible = visible;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onControlsVisibleChanged?.call(visible);
    });
  }

  @override
  void didUpdateWidget(covariant MatchReplayPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replay.matchId != widget.replay.matchId ||
        !_sameReplay(oldWidget.replay, widget.replay)) {
      _resetAndOpen();
    }
  }

  bool _sameReplay(MatchReplay left, MatchReplay right) =>
      left.segments.length == right.segments.length &&
      left.segments.indexed.every(
        (entry) => entry.$2.url == right.segments[entry.$1].url,
      );

  Future<void> _resetAndOpen() async {
    final current = _controller;
    final next = _nextController;
    _controller = null;
    _nextController = null;
    _nextIndex = null;
    _segmentIndex = 0;
    _failed.clear();
    _showSkipped = false;
    await current?.dispose();
    await next?.dispose();
    if (mounted) await _openSegment(0);
  }

  int? _nextPlayableIndex(int from) {
    for (var index = from; index < widget.replay.segments.length; index++) {
      if (!_failed.contains(index)) return index;
    }
    return null;
  }

  Future<void> _openSegment(int index, {int offsetSec = 0}) async {
    if (_preloading) await _preloadCompletion?.future;
    if (!mounted) return;
    final candidate = _nextPlayableIndex(index);
    if (candidate == null) {
      final current = _controller;
      _controller = null;
      if (mounted) setState(() {});
      await current?.dispose();
      await _disposeNextController();
      return;
    }

    late final VideoPlayerController controller;
    if (_nextIndex == candidate && _nextController != null) {
      controller = _nextController!;
      _nextController = null;
      _nextIndex = null;
    } else {
      await _disposeNextController();
      controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.replay.segments[candidate].url),
      );
      try {
        await controller.initialize();
        await controller.setLooping(false);
        await controller.setVolume(_muted ? 0 : 1);
      } catch (_) {
        await controller.dispose();
        _failed.add(candidate);
        _showSkipped = true;
        if (mounted) await _openSegment(candidate + 1);
        return;
      }
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }
    final previous = _controller;
    _controller = controller;
    _segmentIndex = candidate;
    _finished = false;
    _displayedSeconds = widget.replay.segments[candidate].offsetSec + offsetSec;
    controller.addListener(() => _onControllerUpdate(controller));
    setState(() {});
    try {
      await controller.seekTo(
        Duration(
          seconds: matchReplayMediaSeconds(
            widget.replay.segments[candidate],
            offsetSec,
          ),
        ),
      );
      await controller.play();
    } catch (_) {
      if (_controller == controller) {
        _failed.add(candidate);
        _showSkipped = true;
        await _openSegment(candidate + 1);
      }
    }
    if (previous != null && previous != controller) await previous.dispose();
  }

  void _onControllerUpdate(VideoPlayerController controller) {
    if (!mounted ||
        controller != _controller ||
        !controller.value.isInitialized) {
      return;
    }
    final segment = widget.replay.segments[_segmentIndex];
    final position = controller.value.position;
    final elapsed = matchReplayElapsedSeconds(segment, position.inSeconds);
    final global = matchReplayGlobalSeconds(
      MatchReplayPosition(segmentIndex: _segmentIndex, offsetSec: elapsed),
      widget.replay.segments,
    );
    if (global != _displayedSeconds) {
      setState(
        () => _displayedSeconds = global
            .clamp(0, widget.replay.durationSec)
            .toInt(),
      );
    }
    if (controller.value.hasError) {
      _failed.add(_segmentIndex);
      _showSkipped = true;
      _advanceToNext();
      return;
    }
    if (controller.value.isCompleted ||
        matchReplaySegmentReachedEnd(segment, position.inSeconds)) {
      _advanceToNext();
      return;
    }
    if (Duration(seconds: segment.durationSec - elapsed) <= _preloadThreshold) {
      _preloadNext();
    }
  }

  Future<void> _preloadNext() async {
    if (_preloading || _nextController != null || _controller == null) return;
    final index = _nextPlayableIndex(_segmentIndex + 1);
    if (index == null) return;
    final preloadCompletion = Completer<void>();
    _preloadCompletion = preloadCompletion;
    _preloading = true;
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.replay.segments[index].url),
    );
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(_muted ? 0 : 1);
      if (!mounted || index <= _segmentIndex) {
        await controller.dispose();
      } else {
        _nextController = controller;
        _nextIndex = index;
      }
    } catch (_) {
      _failed.add(index);
      _showSkipped = true;
      await controller.dispose();
      if (mounted) setState(() {});
    } finally {
      _preloading = false;
      preloadCompletion.complete();
      if (identical(_preloadCompletion, preloadCompletion)) {
        _preloadCompletion = null;
      }
    }
  }

  Future<void> _advanceToNext() async {
    if (_advancing) return;
    _advancing = true;
    try {
      final next = _nextPlayableIndex(_segmentIndex + 1);
      if (next == null) {
        final current = _controller;
        _controller = null;
        _finished = _failed.length < widget.replay.segments.length;
        if (mounted) setState(() {});
        await current?.dispose();
        await _disposeNextController();
        return;
      }
      await _openSegment(next);
    } finally {
      _advancing = false;
    }
  }

  Future<void> _disposeNextController() async {
    final next = _nextController;
    _nextController = null;
    _nextIndex = null;
    await next?.dispose();
  }

  Future<void> _seekGlobal(double value) async {
    final target = value.round().clamp(0, widget.replay.durationSec).toInt();
    final position = matchReplayPositionAt(widget.replay.segments, target);
    if (position == null) return;
    _finished = false;
    final controller = _controller;
    if (position.segmentIndex == _segmentIndex && controller != null) {
      final segment = widget.replay.segments[position.segmentIndex];
      // Seeking to the very end can finish the segment and drop
      // [_controller] meanwhile, so keep a local reference.
      await controller.seekTo(
        Duration(seconds: matchReplayMediaSeconds(segment, position.offsetSec)),
      );
      if (_controller == controller && !controller.value.isPlaying) {
        await controller.play();
      }
      return;
    }
    _failed.remove(position.segmentIndex);
    await _openSegment(position.segmentIndex, offsetSec: position.offsetSec);
  }

  /// Skip by [delta] seconds on the whole-match timeline; [_seekGlobal] keeps
  /// it inside [0, duration] and crosses segment boundaries.
  Future<void> _skipBy(int delta) {
    _revealControls();
    return _seekGlobal((_displayedSeconds + delta).toDouble());
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null) return;
    _revealControls();
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleMute() async {
    setState(() => _muted = !_muted);
    _scheduleHide();
    await _controller?.setVolume(_muted ? 0 : 1);
  }

  String _formatTime(int seconds) {
    final safeSeconds = seconds.clamp(0, 359999);
    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final remaining = safeSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = remaining.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.dispose();
    _nextController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = _controller;
    _reportControlsVisible(_controlsVisible);
    return ColoredBox(
      key: const ValueKey<String>('match-replay-player'),
      color: Colors.black,
      // The picture is the whole player: controls float over it like the live
      // player, instead of a black strip underneath. A tap anywhere on the
      // picture shows or hides them.
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onPictureTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (controller != null && controller.value.isInitialized)
                VideoPlayer(controller)
              else
                Center(
                  child: _failed.length >= widget.replay.segments.length
                      ? Text(
                          l10n.matchReplayUnableToPlay,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        )
                      : _finished
                      ? Text(
                          l10n.matchReplayFinished,
                          style: const TextStyle(color: Colors.white70),
                        )
                      : const CircularProgressIndicator(),
                ),
              Center(child: _buildCenterControls(l10n, controller)),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _fadeWhenIdle(_buildControls(l10n, controller)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fades [child] out and lets taps through while the controls are hidden.
  Widget _fadeWhenIdle(Widget child) {
    return IgnorePointer(
      ignoring: !_controlsVisible,
      child: AnimatedOpacity(
        opacity: _controlsVisible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: child,
      ),
    );
  }

  /// Small frosted pill in the middle of the picture: back 3s, play/pause,
  /// forward 3s.
  Widget _buildCenterControls(
    AppLocalizations l10n,
    VideoPlayerController? controller,
  ) {
    final playing = controller?.value.isPlaying == true;
    final ready = controller != null;
    Widget button(
      Key key,
      String tooltip,
      VoidCallback? onPressed,
      Widget icon,
    ) => IconButton(
      key: key,
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
      color: Colors.white,
      icon: icon,
    );
    return _fadeWhenIdle(
      ClipRRect(
        key: const ValueKey<String>('replay-center-controls'),
        borderRadius: BorderRadius.circular(32),
        child: liveGlassBackdrop(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF0B1B3A).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  button(
                    const ValueKey<String>('replay-skip-back'),
                    l10n.matchReplaySkipBack,
                    ready ? () => _skipBy(-_skipSeconds) : null,
                    const _SkipIcon(Icons.replay_rounded),
                  ),
                  button(
                    const ValueKey<String>('replay-play-pause'),
                    playing ? l10n.matchReplayPause : l10n.matchReplayPlay,
                    ready ? _togglePlayback : null,
                    Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 34,
                    ),
                  ),
                  button(
                    const ValueKey<String>('replay-skip-forward'),
                    l10n.matchReplaySkipForward,
                    ready ? () => _skipBy(_skipSeconds) : null,
                    const _SkipIcon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(
    AppLocalizations l10n,
    VideoPlayerController? controller,
  ) {
    final maxDuration = widget.replay.durationSec.toDouble();
    final current = _displayedSeconds.clamp(0, widget.replay.durationSec);
    final playing = controller?.value.isPlaying == true;
    Widget button(IconData icon, String tooltip, VoidCallback? onPressed) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          visualDensity: VisualDensity.compact,
          iconSize: 22,
          color: Colors.white,
          icon: Icon(icon),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showSkipped)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n.matchReplaySkippedSegment,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: SizedBox(
              height: 24,
              child: Slider(
                key: const ValueKey<String>('match-replay-timeline'),
                value: current.toDouble().clamp(0, maxDuration).toDouble(),
                max: maxDuration > 0 ? maxDuration : 1,
                onChanged: maxDuration > 0
                    ? (value) {
                        _revealControls();
                        _seekGlobal(value);
                      }
                    : null,
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Colors.white24,
              ),
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 4),
              button(
                playing ? Icons.pause : Icons.play_arrow,
                playing ? l10n.matchReplayPause : l10n.matchReplayPlay,
                _togglePlayback,
              ),
              button(
                _muted ? Icons.volume_off : Icons.volume_up,
                _muted ? 'Bật tiếng' : 'Tắt tiếng',
                _toggleMute,
              ),
              Expanded(
                child: Text(
                  '${_formatTime(current)} / ${_formatTime(widget.replay.durationSec)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              if (widget.onToggleFullscreen != null)
                button(
                  widget.fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  widget.fullscreen
                      ? l10n.liveExitFullscreen
                      : l10n.liveEnterFullscreen,
                  widget.onToggleFullscreen,
                ),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thin circular arrow with the skip step ("3") in its middle.
class _SkipIcon extends StatelessWidget {
  const _SkipIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(icon, size: 30),
        const Text(
          '3',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}
