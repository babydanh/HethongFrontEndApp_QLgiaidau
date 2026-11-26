import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/camera_stream_key_model.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/camera_admin_repository.dart';
import 'package:app_quanly_giaidau/features/camera_bridge/camera_bridge_notifier.dart';
import 'package:app_quanly_giaidau/features/camera_bridge/camera_bridge_screen.dart';
import 'package:app_quanly_giaidau/features/camera_bridge/ffmpeg_runner.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAMBR-30..36: the "Camera IP" entry screen. Credentials below are
/// obviously fake fixtures.
class _FakeRunner implements FfmpegRunner {
  final List<({String rtsp, String rtmp})> runs = [];
  final List<StreamController<BridgeEvent>> controllers = [];

  StreamController<BridgeEvent> get current => controllers.last;

  @override
  Stream<BridgeEvent> run(String rtspUrl, String rtmpUrl) {
    runs.add((rtsp: rtspUrl, rtmp: rtmpUrl));
    final controller = StreamController<BridgeEvent>();
    controllers.add(controller);
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    if (controllers.isNotEmpty && !current.isClosed) await current.close();
  }
}

class _FakeRepo implements ICameraAdminRepository {
  final List<String> created = [];
  int keyReads = 0;

  @override
  Future<TournamentCameraModel> createCamera({
    required String tournamentId,
    required String name,
    required String mode,
    String? courtId,
    String? playbackUrl,
  }) async {
    created.add('$mode:$name');
    return TournamentCameraModel(
      id: 'cam-${created.length}',
      name: name,
      mode: mode,
      status: 'IDLE',
    );
  }

  @override
  Future<CameraStreamKeyModel> getStreamKey(String cameraId) async {
    keyReads++;
    return CameraStreamKeyModel(
      cameraId: cameraId,
      streamName: 's-$cameraId',
      streamKeyId: 'k-$cameraId',
      rtmpServer: 'rtmp://fake.invalid/live',
      rtmpStreamKey: 'key-$cameraId',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<({AppLocalizations l10n, _FakeRunner runner, _FakeRepo repo})> _pump(
  WidgetTester tester, {
  bool noRunner = false,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final runner = _FakeRunner();
  final repo = _FakeRepo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cameraAdminRepositoryProvider.overrideWithValue(repo),
        ffmpegRunnerFactoryProvider.overrideWithValue(
          noRunner ? () => throw UnimplementedError() : () => runner,
        ),
        bridgeDelayProvider.overrideWithValue((_) async {}),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CameraBridgeScreen(tournamentId: 't1'),
      ),
    ),
  );
  final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
  return (l10n: l10n, runner: runner, repo: repo);
}

Finder _field(int slot, String name) =>
    find.byKey(ValueKey('cameraBridge-$slot-$name'));

Future<void> _fill(WidgetTester tester, int slot) async {
  await tester.enterText(_field(slot, 'host'), '192.168.1.50');
  await tester.enterText(_field(slot, 'user'), 'admin');
  await tester.enterText(_field(slot, 'password'), 'secret-pass');
}

void main() {
  testWidgets('TC-CAMBR-30 camera 1 shows labelled fields, camera 2 is hidden', (
    tester,
  ) async {
    final s = await _pump(tester);

    expect(find.text(s.l10n.cameraBridge_fieldHost), findsOneWidget);
    expect(find.text(s.l10n.cameraBridge_fieldUser), findsOneWidget);
    expect(find.text(s.l10n.cameraBridge_fieldPassword), findsOneWidget);
    expect(find.text(s.l10n.cameraBridge_fieldPort), findsOneWidget);
    expect(find.text(s.l10n.cameraBridge_start), findsOneWidget);
    expect(_field(2, 'host'), findsNothing);
    expect(find.text(s.l10n.cameraBridge_addCamera2), findsOneWidget);
  });

  testWidgets('TC-CAMBR-31 password is hidden until the eye is tapped', (
    tester,
  ) async {
    await _pump(tester);
    EditableText input() => tester.widget<EditableText>(
      find.descendant(
        of: _field(1, 'password'),
        matching: find.byType(EditableText),
      ),
    );

    expect(input().obscureText, isTrue);
    await tester.tap(find.byKey(const ValueKey('cameraBridge-1-togglePassword')));
    await tester.pump();
    expect(input().obscureText, isFalse);
  });

  testWidgets('TC-CAMBR-32 blank IP shows an error and starts nothing', (
    tester,
  ) async {
    final s = await _pump(tester);

    await tester.tap(find.text(s.l10n.cameraBridge_start));
    await tester.pump();

    expect(find.text(s.l10n.cameraBridge_hostRequired), findsOneWidget);
    expect(s.repo.created, isEmpty);
    expect(s.runner.runs, isEmpty);
  });

  testWidgets('TC-CAMBR-33 start creates a PUSH camera, pushes to its key, goes live', (
    tester,
  ) async {
    final s = await _pump(tester);
    await _fill(tester, 1);

    await tester.tap(find.text(s.l10n.cameraBridge_start));
    await tester.pump();
    await tester.pump();

    expect(s.repo.created.single, startsWith('PUSH:'));
    expect(s.runner.runs, hasLength(1));
    expect(
      s.runner.runs.single.rtsp,
      'rtsp://admin:secret-pass@192.168.1.50:554/cam/realmonitor?channel=1&subtype=0',
    );
    expect(s.runner.runs.single.rtmp, 'rtmp://fake.invalid/live/key-cam-1');
    expect(find.text(s.l10n.cameraBridge_statusConnecting), findsOneWidget);

    s.runner.current.add(const BridgeLive());
    await tester.pump();
    expect(find.text(s.l10n.cameraBridge_statusLive), findsOneWidget);
    expect(find.text(s.l10n.cameraBridge_stop), findsOneWidget);
  });

  testWidgets('TC-CAMBR-34 a wrong password is explained without echoing it', (
    tester,
  ) async {
    final s = await _pump(tester);
    await _fill(tester, 1);

    await tester.tap(find.text(s.l10n.cameraBridge_start));
    await tester.pump();
    await tester.pump();
    s.runner.current.add(const BridgeFailed(BridgeFailure.auth));
    await tester.pump();
    await tester.pump();

    expect(find.text(s.l10n.cameraBridge_errorAuth), findsOneWidget);
    expect(find.textContaining('secret-pass'), findsNothing);
    expect(find.textContaining('rtsp://'), findsNothing);
  });

  testWidgets('TC-CAMBR-35 camera 2 can be added and removed', (tester) async {
    final s = await _pump(tester);

    await tester.tap(find.text(s.l10n.cameraBridge_addCamera2));
    await tester.pump();
    expect(_field(2, 'host'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cameraBridge-2-remove')));
    await tester.pump();
    expect(_field(2, 'host'), findsNothing);
  });

  testWidgets('TC-CAMBR-37 with no ffmpeg wired in, start explains it', (
    tester,
  ) async {
    final s = await _pump(tester, noRunner: true);
    await _fill(tester, 1);

    await tester.tap(find.text(s.l10n.cameraBridge_start));
    await tester.pump();
    await tester.pump();

    expect(find.text(s.l10n.cameraBridge_errorUnsupported), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-CAMBR-36 double tap on start runs a single bridge', (
    tester,
  ) async {
    final s = await _pump(tester);
    await _fill(tester, 1);

    final start = find.text(s.l10n.cameraBridge_start);
    await tester.tap(start);
    await tester.tap(start, warnIfMissed: false);
    await tester.pump();
    await tester.pump();

    expect(s.repo.created, hasLength(1));
    expect(s.runner.runs, hasLength(1));
  });
}
