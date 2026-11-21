import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/camera_patch.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/camera_admin_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/facebook_camera_live_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_camera_section.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAMFB-UI-01..09: the camera list reopens the Facebook live code and
/// edits a camera's name / playback URL.
class _Venues implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    {
      'name': 'Nhà thi đấu',
      'courts': [
        {'id': 'court-1', 'name': 'Sân 1'},
      ],
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cameras implements ICourtCameraRepository {
  _Cameras(this.cameras);

  final List<TournamentCameraModel> cameras;
  int listCalls = 0;

  @override
  Future<List<TournamentCameraModel>> listCameras(String tournamentId) async {
    listCalls++;
    return cameras;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Admin implements ICameraAdminRepository {
  final patches = <Map<String, Object?>>[];
  Object? error;

  @override
  Future<void> updateCamera(String cameraId, CameraPatch patch) async {
    patches.add({'id': cameraId, ...patch.toJson()});
    final failure = error;
    if (failure != null) throw failure;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _oldLive = CreatedFacebookLive(
  providerSessionId: 'old',
  watchUrl: 'https://www.facebook.com/page/videos/1234567890',
  rtmpUrl: 'rtmps://live-api-s.facebook.com:443/rtmp',
  streamKey: 'OLD-KEY',
);

const _newLive = CreatedFacebookLive(
  providerSessionId: 'new',
  watchUrl: 'https://www.facebook.com/page/videos/9999999999',
  rtmpUrl: 'rtmps://live-api-s.facebook.com:443/rtmp',
  streamKey: 'NEW-KEY',
);

class _Live implements IFacebookCameraLiveRepository {
  final getCalls = <String>[];
  int createCalls = 0;
  Completer<CreatedFacebookLive>? gate;
  Object? getError;

  @override
  Future<CreatedFacebookLive> getCameraLive(String cameraId) {
    getCalls.add(cameraId);
    final failure = getError;
    if (failure != null) return Future.error(failure);
    return gate?.future ?? Future.value(_oldLive);
  }

  @override
  Future<CreatedFacebookLive> createLive(String tournamentId) async {
    createCalls++;
    return _newLive;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Catalog implements IMatchRecordingCatalogRepository {
  @override
  Future<List<MatchLivestreamSummary>> listTournamentMatchLivestreams(
    String tournamentId,
  ) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TournamentCameraModel _camera({
  String id = 'cam-fb',
  String name = 'Live Facebook',
  String status = 'IDLE',
  String? playbackUrl = 'https://www.facebook.com/page/videos/1234567890',
  bool editable = true,
}) => TournamentCameraModel(
  id: id,
  name: name,
  mode: 'PULL',
  status: status,
  playbackUrl: playbackUrl,
  playbackUrlEditable: editable,
);

DioException _expired() => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: 404,
    data: {'code': 'FACEBOOK_LIVE_CODE_EXPIRED', 'message': 'expired'},
  ),
);

class _Rig {
  _Rig(this.cameras);

  final _Cameras cameras;
  final admin = _Admin();
  final live = _Live();
}

Future<_Rig> _pump(
  WidgetTester tester,
  List<TournamentCameraModel> cameras, {
  bool readOnly = false,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final rig = _Rig(_Cameras(cameras));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentManagementRepositoryProvider.overrideWithValue(_Venues()),
        courtCameraRepositoryProvider.overrideWithValue(rig.cameras),
        cameraAdminRepositoryProvider.overrideWithValue(rig.admin),
        facebookCameraLiveRepositoryProvider.overrideWithValue(rig.live),
        matchRecordingCatalogRepositoryProvider.overrideWithValue(_Catalog()),
        managedMatchesWithDivisionProvider.overrideWith(
          (ref, args) => Stream.value(const <MatchModel>[]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: TournamentManagementCameraSection(
            tournamentId: 't1',
            readOnly: readOnly,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return rig;
}

Finder _menu(String id) => find.descendant(
  of: find.byKey(ValueKey('camera-list-row-$id')),
  matching: find.byTooltip('Thao tác camera'),
);

Future<void> _openMenu(WidgetTester tester, String id) async {
  await tester.tap(_menu(id));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-CAMFB-UI-01 menu offers view-code only for a Facebook link', (
    tester,
  ) async {
    await _pump(tester, [
      _camera(),
      _camera(
        id: 'cam-yt',
        name: 'YouTube',
        playbackUrl: 'https://www.youtube.com/watch?v=abcdefghijk',
      ),
    ]);

    await _openMenu(tester, 'cam-fb');
    expect(find.text('Xem mã phát'), findsOneWidget);
    expect(find.text('Sửa camera'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    await _openMenu(tester, 'cam-yt');
    expect(find.text('Xem mã phát'), findsNothing);
    expect(find.text('Sửa camera'), findsOneWidget);
  });

  testWidgets('TC-CAMFB-UI-02 read-only organizer has no camera menu', (
    tester,
  ) async {
    await _pump(tester, [_camera()], readOnly: true);

    expect(_menu('cam-fb'), findsNothing);
  });

  testWidgets('TC-CAMFB-UI-03 view-code opens the ready sheet with the code', (
    tester,
  ) async {
    final rig = await _pump(tester, [_camera()]);

    await _openMenu(tester, 'cam-fb');
    await tester.tap(find.text('Xem mã phát'));
    await tester.pumpAndSettle();

    expect(rig.live.getCalls, ['cam-fb']);
    expect(find.text('Camera đã sẵn sàng'), findsOneWidget);
    expect(find.byKey(const ValueKey('fb-live-rtmp')), findsOneWidget);
    expect(find.byKey(const ValueKey('fb-live-key')), findsOneWidget);
  });

  testWidgets('TC-CAMFB-UI-04 busy camera cannot start a second request', (
    tester,
  ) async {
    final rig = await _pump(tester, [_camera()]);
    rig.live.gate = Completer<CreatedFacebookLive>();

    await _openMenu(tester, 'cam-fb');
    await tester.tap(find.text('Xem mã phát'));
    await tester.pump();

    // The menu is replaced by a spinner while the request is in flight.
    expect(_menu('cam-fb'), findsNothing);
    expect(rig.live.getCalls, ['cam-fb']);

    rig.live.gate!.complete(_oldLive);
    await tester.pumpAndSettle();
    expect(rig.live.getCalls, ['cam-fb']);
    expect(find.text('Camera đã sẵn sàng'), findsOneWidget);
  });

  testWidgets('TC-CAMFB-UI-05 expired code: new code swaps the URL and opens', (
    tester,
  ) async {
    final rig = await _pump(tester, [_camera()]);
    rig.live.getError = _expired();
    final listCallsBefore = rig.cameras.listCalls;

    await _openMenu(tester, 'cam-fb');
    await tester.tap(find.text('Xem mã phát'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mã phát đã hết hạn'), findsOneWidget);
    expect(rig.live.createCalls, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Tạo mã mới'));
    await tester.pumpAndSettle();

    expect(rig.live.createCalls, 1);
    expect(rig.admin.patches, [
      {'id': 'cam-fb', 'playbackUrl': _newLive.watchUrl},
    ]);
    expect(rig.cameras.listCalls, greaterThan(listCallsBefore));
    expect(find.text('Camera đã sẵn sàng'), findsOneWidget);
  });

  testWidgets('TC-CAMFB-UI-06 expired code, not editable: message only', (
    tester,
  ) async {
    final rig = await _pump(tester, [_camera(editable: false)]);
    rig.live.getError = _expired();

    await _openMenu(tester, 'cam-fb');
    await tester.tap(find.text('Xem mã phát'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Tạo mã mới'), findsNothing);
    expect(find.text('Mã phát đã hết hạn.'), findsOneWidget);
    expect(rig.live.createCalls, 0);
  });

  testWidgets('TC-CAMFB-UI-07 expired code while LIVE: no new code offered', (
    tester,
  ) async {
    final rig = await _pump(tester, [_camera(status: 'LIVE')]);
    rig.live.getError = _expired();

    await _openMenu(tester, 'cam-fb');
    await tester.tap(find.text('Xem mã phát'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Tạo mã mới'), findsNothing);
    expect(rig.live.createCalls, 0);
  });

  testWidgets('TC-CAMFB-UI-08 edit sends only the renamed field', (
    tester,
  ) async {
    final rig = await _pump(tester, [_camera(editable: false)]);

    await _openMenu(tester, 'cam-fb');
    await tester.tap(find.text('Sửa camera'));
    await tester.pumpAndSettle();

    // A camera whose URL is not editable has no URL field.
    expect(find.byKey(const ValueKey('camera-edit-url')), findsNothing);
    final save = find.byKey(const ValueKey('camera-edit-submit'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('camera-edit-name')),
      'Sân chính',
    );
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(rig.admin.patches, [
      {'id': 'cam-fb', 'name': 'Sân chính'},
    ]);
    expect(find.byKey(const ValueKey('camera-edit-name')), findsNothing);
  });

  testWidgets(
    'TC-CAMFB-UI-09 edit URL: rejects http, sends https, shows error',
    (tester) async {
      final rig = await _pump(tester, [_camera()]);

      await _openMenu(tester, 'cam-fb');
      await tester.tap(find.text('Sửa camera'));
      await tester.pumpAndSettle();

      final url = find.byKey(const ValueKey('camera-edit-url'));
      final save = find.byKey(const ValueKey('camera-edit-submit'));
      await tester.enterText(url, 'http://p.example/1.m3u8');
      await tester.pump();
      expect(find.text('URL phải bắt đầu bằng https://.'), findsOneWidget);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      rig.admin.error = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 409,
          data: {'message': 'Camera đang LIVE'},
        ),
      );
      await tester.enterText(url, 'https://p.example/1.m3u8');
      await tester.pump();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(rig.admin.patches, [
        {'id': 'cam-fb', 'playbackUrl': 'https://p.example/1.m3u8'},
      ]);
      // The refusal stays on the sheet, verbatim.
      expect(find.text('Camera đang LIVE'), findsOneWidget);
    },
  );
}
