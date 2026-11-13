import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/camera_admin_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_camera_section.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAMLIST-01..04: the Camera tab lists every camera of the tournament
/// (also the ones without a court) and lets the organizer delete one.
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

  @override
  Future<List<TournamentCameraModel>> listCameras(String tournamentId) async =>
      cameras;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Admin implements ICameraAdminRepository {
  final calls = <String>[];

  @override
  Future<void> deleteCamera(String cameraId) async =>
      calls.add('delete:$cameraId');

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

const _onCourt = TournamentCameraModel(
  id: 'cam-1',
  name: 'Camera sân chính',
  mode: 'PULL',
  status: 'LIVE',
  courtId: 'court-1',
  playbackUrl: 'https://p.example/1.m3u8',
);

const _loose = TournamentCameraModel(
  id: 'cam-2',
  name: 'Camera dự phòng',
  mode: 'PUSH',
  status: 'OFFLINE',
);

Future<_Admin> _pump(
  WidgetTester tester,
  List<TournamentCameraModel> cameras, {
  bool readOnly = false,
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final admin = _Admin();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentManagementRepositoryProvider.overrideWithValue(_Venues()),
        courtCameraRepositoryProvider.overrideWithValue(_Cameras(cameras)),
        cameraAdminRepositoryProvider.overrideWithValue(admin),
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
  return admin;
}

const _list = ValueKey('camera-list-section');

void main() {
  testWidgets('TC-CAMLIST-01 list shows every camera and its court', (
    tester,
  ) async {
    await _pump(tester, [_onCourt, _loose]);

    final list = find.byKey(_list);
    Finder inList(Finder f) => find.descendant(of: list, matching: f);
    expect(list, findsOneWidget);
    expect(inList(find.text('Camera · 2')), findsOneWidget);
    expect(inList(find.text('Camera sân chính')), findsOneWidget);
    expect(inList(find.text('Camera dự phòng')), findsOneWidget);
    expect(inList(find.textContaining('Sân 1')), findsOneWidget);
    // A camera that no court uses is still listed, marked as such.
    expect(inList(find.textContaining('Chưa gắn sân')), findsOneWidget);
  });

  testWidgets('TC-CAMLIST-02 delete asks first, then deletes the camera', (
    tester,
  ) async {
    final admin = await _pump(tester, [_onCourt, _loose]);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('camera-list-row-cam-2')),
        matching: find.byTooltip('Xoá camera'),
      ),
    );
    await tester.pumpAndSettle();
    expect(admin.calls, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(admin.calls, ['delete:cam-2']);
  });

  testWidgets('TC-CAMLIST-03 read-only: listed but no delete button', (
    tester,
  ) async {
    await _pump(tester, [_onCourt, _loose], readOnly: true);

    expect(find.byKey(_list), findsOneWidget);
    expect(find.byTooltip('Xoá camera'), findsNothing);
  });

  testWidgets('TC-CAMLIST-04 no camera yet: says so instead of staying blank', (
    tester,
  ) async {
    await _pump(tester, const []);

    expect(
      find.descendant(
        of: find.byKey(_list),
        matching: find.text('Giải chưa có camera.'),
      ),
      findsOneWidget,
    );
  });
}
