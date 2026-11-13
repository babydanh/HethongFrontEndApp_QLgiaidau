import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/camera_live_status_model.dart';
import 'package:app_quanly_giaidau/data/models/camera_stream_key_model.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/camera_admin_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/stream_key_qr_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/court_camera_board.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-APP-CAM-10..: bảng camera dùng chung (thẻ sân thu gọn + popup sân).
/// Thay cho TournamentCameraPanel (TC-WP-05-01..03): thêm camera, xoá có từ
/// chối, QR stream key vẫn giữ; kéo thả và đổi sân bằng picker đã bỏ.
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

  final List<String> urlCalls = <String>[];

  @override
  Future<String?> setCourtPlaybackUrl({
    required String tournamentId,
    required String courtId,
    required String playbackUrl,
  }) async {
    urlCalls.add('$courtId=$playbackUrl');
    cameras = [
      for (final camera in cameras)
        if (camera.courtId != courtId) camera,
      if (playbackUrl.isNotEmpty)
        TournamentCameraModel(
          id: 'url-$courtId',
          name: courtId,
          mode: 'PULL',
          status: 'IDLE',
          courtId: courtId,
          playbackUrl: playbackUrl,
        ),
    ];
    return null;
  }

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

const _urlCamera = TournamentCameraModel(
  id: 'cam-9',
  name: 'Court 3 stream',
  mode: 'PULL',
  status: 'LIVE',
  courtId: 'court-3',
  playbackUrl: 'https://media.example.test/live/court3.m3u8',
);

const _pullCamera = TournamentCameraModel(
  id: 'cam-2',
  name: 'Hall cam',
  mode: 'PULL',
  status: 'IDLE',
  playbackUrl: 'https://media.example.test/live/hall.m3u8',
);

MatchModel _match(
  String id, {
  required String status,
  required String courtId,
  required int hour,
  int s1 = 0,
  int s2 = 0,
}) => MatchModel(
  updatedAt: DateTime(2026, 1, 1),
  id: id,
  round: 1,
  matchNumber: 1,
  matchCode: id,
  team1Id: '$id-a',
  team2Id: '$id-b',
  team1Name: 'Alpha $id',
  team2Name: 'Beta $id',
  status: status,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  courtId: courtId,
  scheduledTime: DateTime(2026, 11, 15, hour),
  score1: s1,
  score2: s2,
);

final _matches = [
  _match(
    'DONE1',
    status: 'COMPLETED',
    courtId: 'court-1',
    hour: 7,
    s1: 11,
    s2: 7,
  ),
  _match('SOON1', status: 'SCHEDULED', courtId: 'court-1', hour: 9),
  _match('LIVE1', status: 'ONGOING', courtId: 'court-1', hour: 8, s1: 5, s2: 4),
];

Future<AppLocalizations> _pump(
  WidgetTester tester,
  _FakeCameraServer server, {
  bool readOnly = false,
  List<MatchModel>? matches,
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
        managedMatchesWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(matches ?? _matches),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CourtCameraBoard(
              tournamentId: _tournamentId,
              readOnly: readOnly,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(CourtCameraBoard)))!;
}

Finder _courtCard(String id) => find.byKey(ValueKey('court-camera-card-$id'));
Finder _camRow(String id) => find.byKey(ValueKey('camera-card-$id'));

Future<void> _openCourt(WidgetTester tester, String id) async {
  await tester.tap(_courtCard(id));
  await tester.pumpAndSettle();
}

Future<void> _openUnattached(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('court-camera-card-none')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'TC-APP-CAM-10 collapsed court card: name and status only, no URL',
    (tester) async {
      final server = _FakeCameraServer(const [_phone, _urlCamera]);
      final l10n = await _pump(tester, server);

      expect(
        find.descendant(
          of: _courtCard('court-3'),
          matching: find.text('Court 3'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _courtCard('court-3'),
          matching: find.text(l10n.tournamentManagementCameraBadgeLive),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('media.example.test'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets('TC-APP-CAM-11 the popup keeps the URL masked until revealed', (
    tester,
  ) async {
    final server = _FakeCameraServer(const [_urlCamera]);
    final l10n = await _pump(tester, server);

    await _openCourt(tester, 'court-3');

    expect(find.text(l10n.courtCamUrlLabel), findsOneWidget);
    expect(find.textContaining('media.example.test'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('court-camera-url-reveal')));
    await tester.pumpAndSettle();
    expect(
      find.text('https://media.example.test/live/court3.m3u8'),
      findsOneWidget,
    );
  });

  testWidgets('TC-APP-CAM-12 unfinished matches sit above finished ones', (
    tester,
  ) async {
    final server = _FakeCameraServer(const []);
    await _pump(tester, server);

    await _openCourt(tester, 'court-1');

    double top(String code) =>
        tester.getTopLeft(find.byKey(ValueKey('court-match-$code'))).dy;
    expect(top('LIVE1'), lessThan(top('SOON1')));
    expect(top('SOON1'), lessThan(top('DONE1')));
  });

  testWidgets('TC-APP-CAM-13 a court without matches shows one short line', (
    tester,
  ) async {
    final server = _FakeCameraServer(const []);
    final l10n = await _pump(tester, server);

    await _openCourt(tester, 'court-3');

    expect(find.text(l10n.courtCamNoMatches), findsOneWidget);
  });

  testWidgets('TC-APP-CAM-14 tapping the URL row edits and saves the URL', (
    tester,
  ) async {
    final server = _FakeCameraServer(const []);
    final l10n = await _pump(tester, server);

    await _openCourt(tester, 'court-3');
    expect(find.byKey(const ValueKey('court-camera-url-field')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('court-camera-url-row')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('court-camera-url-field')),
      'https://cam.example.test/c3.m3u8',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.tournamentManagementSave),
    );
    await tester.pumpAndSettle();

    expect(server.urlCalls, ['court-3=https://cam.example.test/c3.m3u8']);
  });

  testWidgets('TC-APP-CAM-15 adding a PUSH camera opens its stream-key QR', (
    tester,
  ) async {
    final server = _FakeCameraServer(const []);
    await _pump(tester, server);

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
    expect(find.byType(StreamKeyQrSheet), findsOneWidget);
    expect(server.streamKeyCalls, ['cam-100']);
  });

  testWidgets('TC-APP-CAM-16 only a PUSH camera has the QR button', (
    tester,
  ) async {
    final server = _FakeCameraServer(const [_phone, _pullCamera]);
    await _pump(tester, server);

    await _openCourt(tester, 'court-1');
    expect(
      find.byKey(const ValueKey('camera-stream-key-cam-1')),
      findsOneWidget,
    );
    Navigator.of(tester.element(find.byType(CourtCameraBoard))).pop();
    await tester.pumpAndSettle();
    await _openUnattached(tester);
    expect(find.byKey(const ValueKey('camera-stream-key-cam-2')), findsNothing);
    expect(_camRow('cam-2'), findsOneWidget);
  });

  testWidgets(
    'TC-APP-CAM-17 the stream-key QR asks first; cancelling opens nothing',
    (tester) async {
      final server = _FakeCameraServer(const [_phone]);
      final l10n = await _pump(tester, server);

      await _openCourt(tester, 'court-1');
      await tester.tap(find.byKey(const ValueKey('camera-stream-key-cam-1')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.tournamentStreamKeyConfirmTitle), findsOneWidget);
      await tester.tap(
        find.widgetWithText(TextButton, l10n.tournamentManagementCancel),
      );
      await tester.pumpAndSettle();
      expect(server.streamKeyCalls, isEmpty);
      expect(find.byType(StreamKeyQrSheet), findsNothing);
    },
  );

  testWidgets(
    'TC-APP-CAM-18 a refused delete keeps the camera and shows the server message',
    (tester) async {
      final server = _FakeCameraServer(const [_phone])
        ..failWith = 'Camera is live on a match';
      final l10n = await _pump(tester, server);

      await _openCourt(tester, 'court-1');
      await tester.tap(find.byKey(const ValueKey('camera-delete-cam-1')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.tournamentManagementDelete),
      );
      await tester.pumpAndSettle();

      expect(find.text('Camera is live on a match'), findsOneWidget);
      expect(server.cameras, hasLength(1));
    },
  );

  testWidgets(
    'TC-APP-CAM-19 a confirmed delete removes the camera after re-read',
    (tester) async {
      final server = _FakeCameraServer(const [_phone]);
      final l10n = await _pump(tester, server);

      await _openCourt(tester, 'court-1');
      await tester.tap(find.byKey(const ValueKey('camera-delete-cam-1')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.tournamentManagementDelete),
      );
      await tester.pumpAndSettle();

      expect(server.cameras, isEmpty);
      expect(_camRow('cam-1'), findsNothing);
    },
  );

  testWidgets('TC-APP-CAM-20 read-only: no add button and no edit controls', (
    tester,
  ) async {
    final server = _FakeCameraServer(const [_phone]);
    await _pump(tester, server, readOnly: true);

    expect(find.byKey(const ValueKey('camera-panel-add')), findsNothing);
    await _openCourt(tester, 'court-1');
    expect(find.byKey(const ValueKey('court-camera-url-row')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('court-camera-url-row')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('court-camera-url-field')), findsNothing);
    expect(find.byKey(const ValueKey('camera-delete-cam-1')), findsNothing);
  });
}
