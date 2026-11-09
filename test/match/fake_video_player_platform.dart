import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// In-memory player: initialises at once and records what the app asks of it.
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final volumes = <double>[];
  final seeks = <Duration>[];
  final _events = <int, StreamController<VideoEvent>>{};
  Duration duration = const Duration(seconds: 60);

  /// Native size of the fake picture.
  Size size = const Size(1280, 720);

  /// False keeps the player "loading": no first frame yet.
  bool initializes = true;

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose(int playerId) async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = _events.length + 1;
    _events[id] = StreamController<VideoEvent>(
      onListen: () {
        if (!initializes) return;
        _events[id]!.add(
          VideoEvent(
            eventType: VideoEventType.initialized,
            duration: duration,
            size: size,
          ),
        );
      },
    );
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async =>
      volumes.add(volume);

  @override
  Future<void> seekTo(int playerId, Duration position) async =>
      seeks.add(position);

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async =>
      seeks.lastOrNull ?? Duration.zero;

  @override
  Widget buildView(int playerId) => const SizedBox.expand();
}
