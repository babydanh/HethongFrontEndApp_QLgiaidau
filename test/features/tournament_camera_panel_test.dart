import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/camera_live_status_model.dart';
import 'package:app_quanly_giaidau/data/models/camera_stream_key_model.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/camera_admin_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/stream_key_qr_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_camera_panel.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-WP-05-01/02/03 (task 5.1): camera panel — add, delete refusal, drag onto
/// a court card, change court through the picker.
const _tournamentId = 'tour-1';

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

typedef _CameraCreate = ({String name, String mode, String? courtId});

/// One server-side camera list behind both camera contracts.
class _FakeCameraServer
    implements ICourtCameraRepository, ICameraAdminRepository {
  _FakeCameraServer(List<TournamentCameraModel> initial)
    : cameras = List.of(initial);

  List<TournamentCameraModel> cameras;
  String? failWith;
  final List<String> assignCalls = <String>[];
  final List<String> streamKeyCalls = <String>[];
  final List<_CameraCreate> createCalls = <_CameraCreate>[];
  var _nextId = 100;

  @override
  Future<List<TournamentCameraModel>> listCameras(String tournamentId) async =>
      List.of(cameras);

  @override
  Future<TournamentCameraModel> createCamera({
    required String tournamentId,
    required String name,
    required String mode,
    String? courtId,
    String? playbackUrl,
  }) async {
    createCalls.add((name: name, mode: mode, courtId: courtId));
    final camera = TournamentCameraModel(
      id: 'cam-${_nextId++}',
      name: name,
      mode: mode,
      status: 'IDLE',
      courtId: courtId,
      playbackUrl: playbackUrl,
    );
    cameras = [...cameras, camera];
    return camera;
  }

  @override
  Future<void> deleteCamera(String cameraId) async {
    final message = failWith;
    if (message != null) throw _refusal(message);
    cameras = cameras.where((camera) => camera.id != cameraId).toList();
  }

  @override
  Future<void> assignCameraCourt(String cameraId, String? courtId) async {
    assignCalls.add('$cameraId->$courtId');
    final message = failWith;
    if (message != null) throw _refusal(message);
    cameras = [
      for (final camera in cameras)
        if (camera.id == cameraId)
          TournamentCameraModel(
            id: camera.id,
            name: camera.name,
            mode: camera.mode,
            status: camera.status,
            courtId: courtId,
            playbackUrl: camera.playbackUrl,
          )
        else
          camera,
    ];
  }

  // Only the first read is faked (and fails): the key itself is covered by
  // stream_key_qr_sheet_test.dart. It proves the sheet is, or is not, opened.
  @override
  Future<CameraStreamKeyModel> getStreamKey(String cameraId) async {
    streamKeyCalls.add(cameraId);
    throw StateError('stream key is not available in this test');
  }

  // The other stream-key methods are covered by stream_key_qr_sheet_test.dart.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String?> setCourtPlaybackUrl({
    required String tournamentId,
    required String courtId,
    required String playbackUrl,
  }) async => null;

  @override
  Future<void> assignCamera({
    required String matchId,
    required String cameraId,
  }) async {}

  @override
  Future<CameraLiveStatusModel> getCameraLiveStatus(String cameraId) =>
      throw UnimplementedError();
}

class _FakeManagement implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    {
      'id': 'venue-1',
      'name': 'Hall',
      'courts': [
        {'id': 'court-1', 'name': 'Court 1'},
        {'id': 'court-3', 'name': 'Court 3'},
      ],
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _phone = TournamentCameraModel(
  id: 'cam-1',
  name: 'Court 1 phone',
  mode: 'PUSH',
  status: 'IDLE',
  courtId: 'court-1',
);

const _livePhone = TournamentCameraModel(
  id: 'cam-3',
  name: 'Court 3 phone',
  mode: 'PUSH',
  status: 'LIVE',
  courtId: 'court-3',
);

const _pullCamera = TournamentCameraModel(
  id: 'cam-2',
  name: 'Hall cam',
  mode: 'PULL',
  status: 'IDLE',
  playbackUrl: 'https://media.example.test/live/hall.m3u8',
);

Future<AppLocalizations> _pump(
  WidgetTester tester,
  _FakeCameraServer server, {
  bool readOnly = false,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        courtCameraRepositoryProvider.overrideWithValue(server),
        cameraAdminRepositoryProvider.overrideWithValue(server),
        tournamentManagementRepositoryProvider.overrideWithValue(
          _FakeManagement(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: TournamentCameraPanel(
              tournamentId: _tournamentId,
              readOnly: readOnly,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(
    tester.element(find.byType(TournamentCameraPanel)),
  )!;
}

/// Design screen 11: deleting goes through the row tap (menu), not a button on
/// the row.
Future<void> _openDelete(WidgetTester tester, String id) async {
  await tester.tap(_card(id));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('camera-delete-$id')));
  await tester.pumpAndSettle();
}

Finder _card(String id) => find.byKey(ValueKey('camera-card-$id'));
Finder _courtCard(String id) => find.byKey(ValueKey('camera-court-$id'));

Future<void> _drag(WidgetTester tester, Finder from, Finder to) async {
  final gesture = await tester.startGesture(tester.getCenter(from));
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
  await gesture.moveTo(tester.getCenter(to));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('adding a PUSH camera shows its card with a PUSH badge', (
    tester,
  ) async {
    final server = _FakeCameraServer(const []);
    final l10n = await _pump(tester, server);

    await tester.tap(find.byKey(const ValueKey('camera-panel-add')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('camera-editor-name')),
      'Court 1 - phone',
    );
    await tester.tap(find.byKey(const ValueKey('camera-editor-submit')));
    await tester.pumpAndSettle();

    expect(server.createCalls.single, (
      name: 'Court 1 - phone',
      mode: 'PUSH',
      courtId: null,
    ));
    // PUSH vừa tạo: popup QR mở luôn, không qua hộp xác nhận, và xin key ngay.
    expect(find.byType(StreamKeyQrSheet), findsOneWidget);
    expect(server.streamKeyCalls, ['cam-100']);
    final card = _card('cam-100');
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('Court 1 - phone')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.textContaining('PUSH')),
      findsOneWidget,
    );
    expect(
      find.text(l10n.tournamentCameraCreated('Court 1 - phone')),
      findsOneWidget,
    );
  });

  testWidgets('a PUSH camera card has a stream-key QR button and a PULL card has none', (
    tester,
  ) async {
    final server = _FakeCameraServer(const [_phone, _pullCamera]);
    await _pump(tester, server);

    expect(find.byKey(const ValueKey('camera-stream-key-cam-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('camera-stream-key-cam-2')), findsNothing);
  });

  testWidgets('a refused delete keeps the card and shows the server message', (
    tester,
  ) async {
    final server = _FakeCameraServer(const [_phone])
      ..failWith = 'Camera is live on a match';
    final l10n = await _pump(tester, server);

    await _openDelete(tester, 'cam-1');
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.tournamentManagementDelete),
    );
    await tester.pumpAndSettle();

    expect(find.text('Camera is live on a match'), findsOneWidget);
    expect(_card('cam-1'), findsOneWidget);
    expect(server.cameras, hasLength(1));
  });

  testWidgets('cancelling the delete confirmation removes nothing', (
    tester,
  ) async {
    final server = _FakeCameraServer(const [_phone]);
    final l10n = await _pump(tester, server);

    await _openDelete(tester, 'cam-1');
    await tester.tap(
      find.widgetWithText(TextButton, l10n.tournamentManagementCancel),
    );
    await tester.pumpAndSettle();

    expect(_card('cam-1'), findsOneWidget);
    expect(server.cameras, hasLength(1));
  });

  testWidgets('a confirmed delete removes the card after the list is re-read', (
    tester,
  ) async {
    final server = _FakeCameraServer(const [_phone]);
    final l10n = await _pump(tester, server);

    await _openDelete(tester, 'cam-1');
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.tournamentManagementDelete),
    );
    await tester.pumpAndSettle();

    expect(_card('cam-1'), findsNothing);
  });

  testWidgets(
    'dropping a camera on a court card assigns that court and redraws',
    (tester) async {
      final server = _FakeCameraServer(const [_phone]);
      await _pump(tester, server);

      await _drag(tester, _card('cam-1'), _courtCard('court-3'));

      expect(server.assignCalls, ['cam-1->court-3']);
      expect(
        find.descendant(
          of: _courtCard('court-3'),
          matching: find.text('Court 1 phone'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _courtCard('court-1'),
          matching: find.text('Court 1 phone'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('a refused drop shows the server message and changes nothing', (
    tester,
  ) async {
    final server = _FakeCameraServer(const [_phone])
      ..failWith = 'Camera is live on a match';
    await _pump(tester, server);

    await _drag(tester, _card('cam-1'), _courtCard('court-3'));

    expect(find.text('Camera is live on a match'), findsOneWidget);
    expect(
      find.descendant(
        of: _courtCard('court-1'),
        matching: find.text('Court 1 phone'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the header counts cameras and each row shows its status', (
    tester,
  ) async {
    final server = _FakeCameraServer(const [_phone, _livePhone, _pullCamera]);
    final l10n = await _pump(tester, server);

    expect(
      find.text(l10n.tournamentCameraListTitle(3).toUpperCase()),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _card('cam-3'),
        matching: find.text(l10n.tournamentManagementCameraBadgeLive),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _card('cam-1'),
        matching: find.text(l10n.tournamentManagementCameraBadgeReady),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: _card('cam-2'),
        matching: find.textContaining(l10n.tournamentCameraNoCourt),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the stream-key QR asks first; cancelling opens nothing', (
    tester,
  ) async {
    final server = _FakeCameraServer(const [_phone]);
    final l10n = await _pump(tester, server);

    await tester.tap(find.byKey(const ValueKey('camera-stream-key-cam-1')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.tournamentStreamKeyConfirmTitle), findsOneWidget);
    expect(find.byType(StreamKeyQrSheet), findsNothing);
    await tester.tap(find.text(l10n.tournamentManagementCancel));
    await tester.pumpAndSettle();
    expect(find.byType(StreamKeyQrSheet), findsNothing);
    expect(server.streamKeyCalls, isEmpty);
  });

  testWidgets('confirming the dialog opens the stream-key QR sheet', (
    tester,
  ) async {
    final server = _FakeCameraServer(const [_phone]);
    final l10n = await _pump(tester, server);

    await tester.tap(find.byKey(const ValueKey('camera-stream-key-cam-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tournamentStreamKeyConfirmAction));
    await tester.pumpAndSettle();

    expect(find.byType(StreamKeyQrSheet), findsOneWidget);
    expect(server.streamKeyCalls, ['cam-1']);
  });

  testWidgets('a court without camera offers Assign and picks by chip', (
    tester,
  ) async {
    final server = _FakeCameraServer(const [_phone]);
    final l10n = await _pump(tester, server);

    expect(
      find.descendant(
        of: _courtCard('court-3'),
        matching: find.text(l10n.tournamentCameraCourtNoCameras),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('camera-court-assign-court-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('camera-pick-cam-1')));
    await tester.pumpAndSettle();

    expect(server.assignCalls, ['cam-1->court-3']);
    expect(
      find.descendant(
        of: _courtCard('court-3'),
        matching: find.text('Court 1 phone'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a court with a camera offers Change and can unassign it', (
    tester,
  ) async {
    final server = _FakeCameraServer(const [_phone]);
    final l10n = await _pump(tester, server);

    final button = find.byKey(const ValueKey('camera-court-assign-court-1'));
    expect(
      find.descendant(of: button, matching: find.text(l10n.tournamentCameraChange)),
      findsOneWidget,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('camera-pick-none')));
    await tester.pumpAndSettle();

    expect(server.assignCalls, ['cam-1->null']);
  });

  testWidgets('fits a 320dp wide phone without overflow', (tester) async {
    final server = _FakeCameraServer(const [_phone, _livePhone, _pullCamera]);
    await _pump(tester, server);

    tester.view.physicalSize = const Size(320, 2400);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a read-only tournament cannot add, assign or delete cameras', (
    tester,
  ) async {
    final server = _FakeCameraServer(const [_phone]);
    await _pump(tester, server, readOnly: true);

    final add = find.descendant(
      of: find.byKey(const ValueKey('camera-panel-add')),
      matching: find.byType(OutlinedButton),
    );
    expect(tester.widget<OutlinedButton>(add).onPressed, isNull);
    // The row menu (delete) does not open on a read-only tournament.
    await tester.tap(_card('cam-1'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('camera-delete-cam-1')), findsNothing);
    final assign = find.descendant(
      of: find.byKey(const ValueKey('camera-court-assign-court-3')),
      matching: find.byType(OutlinedButton),
    );
    expect(tester.widget<OutlinedButton>(assign).onPressed, isNull);
  });
}
