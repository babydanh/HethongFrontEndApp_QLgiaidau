import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/camera_stream_key_model.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/camera_admin_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/stream_key_qr_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// TC-WP-05-04/05/06 (task 5.2): stream-key QR sheet of a PUSH camera.
/// Every credential below is an obviously fake fixture.
const _camera = TournamentCameraModel(
  id: 'cam-1',
  name: 'Court 1 phone',
  mode: 'PUSH',
  status: 'IDLE',
);

const _noKey = CameraStreamKeyModel(cameraId: 'cam-1', streamName: 'court-1');

const _forgotten = CameraStreamKeyModel(
  cameraId: 'cam-1',
  streamName: 'court-1',
  streamKeyId: 'key-1',
);

CameraStreamKeyModel _withKey(String key) => CameraStreamKeyModel(
  cameraId: 'cam-1',
  streamName: 'court-1',
  streamKeyId: 'key-1',
  status: 'READY',
  qrPayloadString: 'fake-qr-$key',
  rtmpServer: 'rtmp://fake.invalid/live',
  rtmpStreamKey: key,
);

DioException _refusal(String message) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: 409,
      data: {'message': message},
    ),
  );
}

class _FakeKeys implements ICameraAdminRepository {
  _FakeKeys(this.state);

  CameraStreamKeyModel state;
  int getCalls = 0;
  int createCalls = 0;
  int rotateCalls = 0;
  final List<String> renameCalls = <String>[];
  String? createFailure;
  String? getFailure;

  /// When set, create/rotate wait for it so a test can look at the busy state.
  Completer<void>? gate;

  @override
  Future<CameraStreamKeyModel> getStreamKey(String cameraId) async {
    getCalls++;
    final message = getFailure;
    if (message != null) throw _refusal(message);
    return state;
  }

  @override
  Future<CameraStreamKeyModel> createStreamKey(String cameraId) async {
    createCalls++;
    await gate?.future;
    final message = createFailure;
    if (message != null) throw _refusal(message);
    return state = _withKey('fake-key');
  }

  @override
  Future<CameraStreamKeyModel> renameStreamKey(
    String cameraId,
    String stream,
  ) async {
    renameCalls.add(stream);
    return state = CameraStreamKeyModel(
      cameraId: cameraId,
      streamName: stream,
      streamKeyId: state.streamKeyId,
    );
  }

  @override
  Future<CameraStreamKeyModel> rotateStreamKey(String cameraId) async {
    rotateCalls++;
    await gate?.future;
    return state = _withKey('fake-key-2');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<AppLocalizations> _pump(WidgetTester tester, _FakeKeys repo) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [cameraAdminRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const ValueKey('open-sheet'),
              onPressed: () => StreamKeyQrSheet.show(context, camera: _camera),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  return AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('open-sheet')));
  await tester.pumpAndSettle();
}

Future<void> _close(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('tournament-manage-sheet-close')));
  await tester.pumpAndSettle();
}

final _keyText = find.byKey(const ValueKey('stream-key-value'));
const _mask = '••••••••';

String? _shownKey(WidgetTester tester) => tester.widget<Text>(_keyText).data;

/// The sheet keys its QR by a digest of the payload, never the payload.
Finder _qrOf(String payload) =>
    find.byKey(ValueKey('stream-key-qr-${payload.hashCode}'));

Future<void> _confirmRotate(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('stream-key-rotate')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    ),
  );
}

void main() {
  testWidgets(
    'opening a PUSH camera without a key issues one and shows its QR',
    (tester) async {
      final repo = _FakeKeys(_noKey);
      await _pump(tester, repo);

      await _open(tester);

      expect(repo.createCalls, 1);
      expect(_qrOf('fake-qr-fake-key'), findsOneWidget);
    },
  );

  testWidgets('rebuilding the open sheet does not issue a second key', (
    tester,
  ) async {
    final repo = _FakeKeys(_noKey);
    await _pump(tester, repo);

    await _open(tester);
    await tester.pump(const Duration(seconds: 1));
    tester.binding.handleMetricsChanged();
    await tester.pumpAndSettle();

    expect(repo.createCalls, 1);
  });

  testWidgets(
    'a failed auto-issue shows the server message and a manual button, with no retry loop',
    (tester) async {
      final repo = _FakeKeys(_noKey)..createFailure = 'AQP is unreachable';
      final l10n = await _pump(tester, repo);

      await _open(tester);
      await tester.pump(const Duration(seconds: 2));

      expect(repo.createCalls, 1);
      expect(find.text('AQP is unreachable'), findsOneWidget);
      expect(find.text(l10n.tournamentStreamKeyIssue), findsOneWidget);

      repo.createFailure = null;
      await tester.tap(find.byKey(const ValueKey('stream-key-issue')));
      await tester.pumpAndSettle();

      expect(repo.createCalls, 2);
      expect(find.byType(QrImageView), findsOneWidget);
    },
  );

  testWidgets(
    'a forgotten key is not auto-issued and offers an explicit re-issue',
    (tester) async {
      final repo = _FakeKeys(_forgotten);
      final l10n = await _pump(tester, repo);

      await _open(tester);

      expect(repo.createCalls, 0);
      expect(find.text(l10n.tournamentStreamKeyReissue), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('stream-key-issue')));
      await tester.pumpAndSettle();

      expect(repo.createCalls, 1);
      expect(find.byType(QrImageView), findsOneWidget);
    },
  );

  testWidgets(
    'the key is masked by default, revealed by the toggle and masked again after re-opening',
    (tester) async {
      final repo = _FakeKeys(_withKey('fake-key'));
      await _pump(tester, repo);
      await _open(tester);

      expect(_shownKey(tester), _mask);
      expect(find.text('fake-key'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('stream-key-toggle')));
      await tester.pump();
      expect(_shownKey(tester), 'fake-key');

      await tester.tap(find.byKey(const ValueKey('stream-key-toggle')));
      await tester.pump();
      expect(_shownKey(tester), _mask);

      await tester.tap(find.byKey(const ValueKey('stream-key-toggle')));
      await tester.pump();
      await _close(tester);
      await _open(tester);

      expect(_shownKey(tester), _mask);
    },
  );

  testWidgets('rename is disabled while a key exists', (tester) async {
    final repo = _FakeKeys(_withKey('fake-key'));
    await _pump(tester, repo);
    await _open(tester);

    final button = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('stream-key-rename')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets(
    'rename rejects invalid characters locally and sends a valid name',
    (tester) async {
      final repo = _FakeKeys(_forgotten);
      final l10n = await _pump(tester, repo);
      await _open(tester);

      await tester.tap(find.byKey(const ValueKey('stream-key-rename')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('stream-key-rename-field')),
        'bad name!',
      );
      await tester.tap(find.byKey(const ValueKey('stream-key-rename-save')));
      await tester.pump();

      expect(repo.renameCalls, isEmpty);
      expect(find.text(l10n.tournamentStreamKeyRenameInvalid), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('stream-key-rename-field')),
        '  court-2 ',
      );
      await tester.tap(find.byKey(const ValueKey('stream-key-rename-save')));
      await tester.pumpAndSettle();

      expect(repo.renameCalls, ['court-2']);
      expect(find.text('court-2'), findsOneWidget);
    },
  );

  testWidgets('cancelling the rotate confirmation calls nothing', (
    tester,
  ) async {
    final repo = _FakeKeys(_withKey('fake-key'));
    final l10n = await _pump(tester, repo);
    await _open(tester);

    await tester.tap(find.byKey(const ValueKey('stream-key-rotate')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tournamentStreamKeyRotateConfirm), findsOneWidget);
    await tester.tap(
      find.widgetWithText(TextButton, l10n.tournamentManagementCancel),
    );
    await tester.pumpAndSettle();

    expect(repo.rotateCalls, 0);
  });

  testWidgets(
    'confirming the rotate shows the new QR with the key masked again',
    (tester) async {
      final repo = _FakeKeys(_withKey('fake-key'));
      await _pump(tester, repo);
      await _open(tester);
      await tester.tap(find.byKey(const ValueKey('stream-key-toggle')));
      await tester.pump();
      expect(_shownKey(tester), 'fake-key');

      await _confirmRotate(tester);
      await tester.pumpAndSettle();

      expect(repo.rotateCalls, 1);
      expect(_qrOf('fake-qr-fake-key-2'), findsOneWidget);
      expect(_qrOf('fake-qr-fake-key'), findsNothing);
      expect(_shownKey(tester), _mask);
    },
  );

  testWidgets('a rotate in flight blocks a second tap and closing the sheet', (
    tester,
  ) async {
    final repo = _FakeKeys(_withKey('fake-key'))..gate = Completer<void>();
    await _pump(tester, repo);
    await _open(tester);
    await _confirmRotate(tester);
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('stream-key-rotate')),
      warnIfMissed: false,
    );
    await tester.tap(
      find.byKey(const ValueKey('tournament-manage-sheet-close')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(repo.rotateCalls, 1);
    expect(find.byType(StreamKeyQrSheet), findsOneWidget);

    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(repo.rotateCalls, 1);
  });

  testWidgets(
    'a rotate in flight keeps the sheet open on barrier tap and back, until it finishes',
    (tester) async {
      final repo = _FakeKeys(_withKey('fake-key'))..gate = Completer<void>();
      await _pump(tester, repo);
      await _open(tester);
      await _confirmRotate(tester);
      await tester.pump();

      // y = 20 is above the sheet (92% of 2400), i.e. on the modal barrier.
      // The busy spinner never settles, so pump a fixed duration instead.
      await tester.tapAt(const Offset(450, 20));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(StreamKeyQrSheet), findsOneWidget);

      repo.gate!.complete();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(StreamKeyQrSheet), findsNothing);
    },
  );

  testWidgets('renaming to the current name closes the editor without a call', (
    tester,
  ) async {
    final repo = _FakeKeys(_forgotten);
    await _pump(tester, repo);
    await _open(tester);

    await tester.tap(find.byKey(const ValueKey('stream-key-rename')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('stream-key-rename-field')),
      ' court-1 ',
    );
    await tester.tap(find.byKey(const ValueKey('stream-key-rename-save')));
    await tester.pumpAndSettle();

    expect(repo.renameCalls, isEmpty);
    expect(find.byKey(const ValueKey('stream-key-rename-field')), findsNothing);
  });

  testWidgets(
    'retry after a failed load auto-issues once for a camera without a key',
    (tester) async {
      final repo = _FakeKeys(_noKey)..getFailure = 'Not allowed';
      await _pump(tester, repo);
      await _open(tester);
      expect(repo.createCalls, 0);

      repo.getFailure = null;
      await tester.tap(find.byKey(const ValueKey('stream-key-retry')));
      await tester.pumpAndSettle();

      expect(repo.createCalls, 1);
      expect(_qrOf('fake-qr-fake-key'), findsOneWidget);
    },
  );

  testWidgets('retry after a failed load never auto-issues a forgotten key', (
    tester,
  ) async {
    final repo = _FakeKeys(_forgotten)..getFailure = 'Not allowed';
    await _pump(tester, repo);
    await _open(tester);

    repo.getFailure = null;
    await tester.tap(find.byKey(const ValueKey('stream-key-retry')));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 0);
    expect(find.byKey(const ValueKey('stream-key-issue')), findsOneWidget);
  });

  testWidgets('a failed load shows the server message and retry reloads', (
    tester,
  ) async {
    final repo = _FakeKeys(_withKey('fake-key'))..getFailure = 'Not allowed';
    await _pump(tester, repo);
    await _open(tester);

    expect(find.text('Not allowed'), findsOneWidget);

    repo.getFailure = null;
    await tester.tap(find.byKey(const ValueKey('stream-key-retry')));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(repo.createCalls, 0);
  });
}
