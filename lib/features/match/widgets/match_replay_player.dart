import 'dart:async';

import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/features/match/widgets/match_replay_timeline.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Phát nối các segment MP4 của trận bằng một thanh thời gian toàn cục.
class MatchReplayPlayer extends StatefulWidget {
  const MatchReplayPlayer({super.key, required this.replay});

  final MatchReplay replay;

  @override
  State<MatchReplayPlayer> createState() => _MatchReplayPlayerState();
}

class _MatchReplayPlayerState extends State<MatchReplayPlayer> {
  static const _preloadThreshold = Duration(seconds: 10);

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
  int _displayedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _openSegment(0);
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
        await controller.setVolume(0);
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
      await controller.setVolume(0);
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
    if (position.segmentIndex == _segmentIndex && _controller != null) {
      final segment = widget.replay.segments[position.segmentIndex];
      await _controller!.seekTo(
        Duration(seconds: matchReplayMediaSeconds(segment, position.offsetSec)),
      );
      if (!_controller!.value.isPlaying) await _controller!.play();
      return;
    }
    _failed.remove(position.segmentIndex);
    await _openSegment(position.segmentIndex, offsetSec: position.offsetSec);
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
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
    _controller?.dispose();
    _nextController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = _controller;
    final maxDuration = widget.replay.durationSec.toDouble();
    final current = _displayedSeconds.clamp(0, widget.replay.durationSec);
    return ColoredBox(
      key: const ValueKey<String>('match-replay-player'),
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.matchReplayLabel,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: controller != null && controller.value.isInitialized
                ? VideoPlayer(controller)
                : Center(
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  key: const ValueKey<String>('match-replay-timeline'),
                  value: current.toDouble().clamp(0, maxDuration).toDouble(),
                  max: maxDuration > 0 ? maxDuration : 1,
                  onChanged: maxDuration > 0
                      ? (value) => _seekGlobal(value)
                      : null,
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Colors.white24,
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: controller?.value.isPlaying == true
                          ? l10n.matchReplayPause
                          : l10n.matchReplayPlay,
                      onPressed: _togglePlayback,
                      color: Colors.white,
                      icon: Icon(
                        controller?.value.isPlaying == true
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${_formatTime(current)} / ${_formatTime(widget.replay.durationSec)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showSkipped)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.matchReplaySkippedSegment,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
