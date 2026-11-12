import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/camera_wall_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_camera_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_court_info.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_tab_help_dialog.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/camera_preview_provider.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAMWALL-APP-20..: đầu tab, hướng dẫn, tường camera, thẻ sân.
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

class _Catalog implements IMatchRecordingCatalogRepository {
  @override
  Future<List<MatchLivestreamSummary>> listTournamentMatchLivestreams(
    String tournamentId,
  ) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TournamentCameraModel _camera(
  int n, {
  String status = 'LIVE',
  String? courtId = 'court-1',
}) => TournamentCameraModel(
  id: 'cam-$n',
  name: 'Camera $n',
  mode: 'PULL',
  status: status,
  courtId: courtId,
  playbackUrl: 'https://p.example/$n.m3u8',
);

MatchModel _match(String id, {String status = 'SCHEDULED'}) => MatchModel(
  updatedAt: DateTime(2026, 1, 1),
  id: id,
  round: 1,
  matchNumber: 1,
  team1Id: '$id-a',
  team2Id: '$id-b',
  team1Name: 'Alpha $id',
  team2Name: 'Beta $id',
  status: status,
  bracketPosition: BracketPosition(round: 1, position: 1),
  courtId: 'court-1',
);

Widget _app(
  Widget home,
  _Cameras cameras, {
  List<MatchModel> matches = const [],
  bool disableAnimations = false,
}) => ProviderScope(
  overrides: [
    tournamentManagementRepositoryProvider.overrideWithValue(_Venues()),
    courtCameraRepositoryProvider.overrideWithValue(cameras),
    matchRecordingCatalogRepositoryProvider.overrideWithValue(_Catalog()),
    managedMatchesWithDivisionProvider.overrideWith(
      (ref, args) => Stream.value(matches),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: disableAnimations),
      child: child!,
    ),
    home: home,
  ),
);

Future<void> _size(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

const _tab = Scaffold(
  body: TournamentManagementCameraSection(tournamentId: 't1'),
);

CameraWallScreen _wall() => CameraWallScreen(
  tournamentId: 't1',
  divisionId: null,
  courtNames: const {'court-1': 'Sân 1'},
  matchLabelOf: (match) => '${match.team1Name} – ${match.team2Name}',
  playerBuilder: (context, url) => Text('player:$url', key: ValueKey(url)),
);

void main() {
  testWidgets('TC-CAMWALL-APP-20 header: title, summary, Xem camera', (
    tester,
  ) async {
    await _size(tester, const Size(390, 1600));
    final cameras = _Cameras([
      _camera(1),
      _camera(2, status: 'OFFLINE'),
      _camera(3, status: 'IDLE'),
    ]);
    await tester.pumpWidget(_app(_tab, cameras));
    await tester.pumpAndSettle();

    expect(find.text('Camera của giải'), findsOneWidget);
    expect(find.text('3 camera · 1 LIVE · 1 lỗi'), findsOneWidget);
    expect(find.text('Xem camera'), findsOneWidget);
  });

  testWidgets('TC-CAMWALL-APP-21 no cameras hides Xem camera', (tester) async {
    await _size(tester, const Size(390, 1600));
    await tester.pumpWidget(_app(_tab, _Cameras(const [])));
    await tester.pumpAndSettle();

    expect(find.text('Camera của giải'), findsOneWidget);
    expect(find.text('Xem camera'), findsNothing);
  });

  testWidgets('TC-CAMWALL-APP-22 ? opens an animated guide', (tester) async {
    await _size(tester, const Size(390, 1600));
    await tester.pumpWidget(_app(_tab, _Cameras(const [])));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hướng dẫn tab Camera'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CameraTabHelpDialog), findsOneWidget);
    AnimatedContainer step(int i) => tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(ValueKey('camera-help-step-$i')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final highlighted = [
      for (var i = 0; i < 3; i++)
        (step(i).decoration! as BoxDecoration).color != null,
    ];
    expect(highlighted.where((on) => on), hasLength(1));
    await tester.tap(find.text('Đã hiểu'));
    await tester.pumpAndSettle();
    expect(find.byType(CameraTabHelpDialog), findsNothing);
  });

  testWidgets('TC-CAMWALL-APP-23 reduced motion: guide has no highlight', (
    tester,
  ) async {
    await _size(tester, const Size(390, 1600));
    await tester.pumpWidget(
      _app(_tab, _Cameras(const []), disableAnimations: true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hướng dẫn tab Camera'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      final box = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(ValueKey('camera-help-step-$i')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect((box.decoration! as BoxDecoration).color, isNull);
    }
  });

  testWidgets('TC-CAMWALL-APP-24 phone wall: only 1×1 and 2×2, paged', (
    tester,
  ) async {
    await _size(tester, const Size(390, 800));
    final cameras = _Cameras([for (var i = 1; i <= 5; i++) _camera(i)]);
    await tester.pumpWidget(_app(_wall(), cameras));
    await tester.pumpAndSettle();

    expect(find.text('1×1'), findsOneWidget);
    expect(find.text('2×2'), findsOneWidget);
    expect(find.text('3×3'), findsNothing);
    expect(find.text('Trang 1/2'), findsOneWidget);
    expect(find.textContaining('player:'), findsNWidgets(4));

    await tester.tap(find.byTooltip('Trang sau'));
    await tester.pumpAndSettle();
    expect(find.text('Trang 2/2'), findsOneWidget);
    expect(find.textContaining('player:'), findsNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-CAMWALL-APP-25 tablet wall offers up to 4×4', (tester) async {
    await _size(tester, const Size(1000, 800));
    await tester.pumpWidget(
      _app(_wall(), _Cameras([for (var i = 1; i <= 3; i++) _camera(i)])),
    );
    await tester.pumpAndSettle();

    for (final label in ['1×1', '2×2', '3×3', '4×4']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-CAMWALL-APP-26 double tap zooms one tile, again restores', (
    tester,
  ) async {
    await _size(tester, const Size(390, 800));
    await tester.pumpWidget(
      _app(_wall(), _Cameras([for (var i = 1; i <= 3; i++) _camera(i)])),
    );
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('wall-tile-cam-2'));

    await tester.tap(tile);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.textContaining('player:'), findsOneWidget);
    expect(find.byKey(const ValueKey('wall-tile-cam-1')), findsNothing);

    await tester.tap(tile);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.textContaining('player:'), findsNWidgets(3));
  });

  testWidgets('TC-CAMWALL-APP-27 tile: player only for LIVE with preview on', (
    tester,
  ) async {
    await _size(tester, const Size(390, 800));
    final cameras = _Cameras([
      _camera(1),
      _camera(2, status: 'IDLE'),
      _camera(3, status: 'OFFLINE'),
    ]);
    await tester.pumpWidget(_app(_wall(), cameras));
    await tester.pumpAndSettle();

    expect(find.text('player:https://p.example/1.m3u8'), findsOneWidget);
    expect(find.text('player:https://p.example/2.m3u8'), findsNothing);
    expect(find.text('player:https://p.example/3.m3u8'), findsNothing);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('OFFLINE'), findsOneWidget);
    expect(find.text('Chưa phát'), findsOneWidget);

    // Công tắc xem thử tắt hình trên máy này, không gọi lại Backend.
    final listCallsBefore = cameras.listCalls;
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.text('player:https://p.example/1.m3u8'), findsNothing);
    expect(cameras.listCalls, listCallsBefore);
  });

  testWidgets('TC-CAMWALL-APP-28 offline tile: Thử lại reloads cameras', (
    tester,
  ) async {
    await _size(tester, const Size(390, 800));
    final cameras = _Cameras([_camera(1, status: 'ERROR')]);
    await tester.pumpWidget(_app(_wall(), cameras));
    await tester.pumpAndSettle();
    final before = cameras.listCalls;

    expect(find.text('ERROR'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(cameras.listCalls, before + 1);
  });

  testWidgets('TC-CAMWALL-APP-29 tile match line follows the priority', (
    tester,
  ) async {
    await _size(tester, const Size(390, 800));
    await tester.pumpWidget(
      _app(
        _wall(),
        _Cameras([_camera(1), _camera(2, courtId: 'court-9')]),
        matches: [
          _match('next'),
          _match('now', status: 'ONGOING'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alpha now – Beta now'), findsOneWidget);
    expect(find.text('Chưa có trận'), findsOneWidget);
  });

  testWidgets('TC-CAMWALL-APP-30 court card: camera line and ⏻ is local', (
    tester,
  ) async {
    await _size(tester, const Size(390, 1600));
    final cameras = _Cameras([_camera(1, status: 'IDLE')]);
    await tester.pumpWidget(
      _app(_tab, cameras, matches: [_match('now', status: 'ONGOING')]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CameraCourtInfo), findsOneWidget);
    expect(find.text('Camera: Camera 1'), findsOneWidget);
    expect(find.text('Đang chiếu: Alpha now – Beta now'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(CameraCourtInfo)),
    );
    final callsBefore = cameras.listCalls;
    await tester.tap(find.byTooltip('Bật/tắt xem thử trên máy này'));
    await tester.pump();
    expect(container.read(cameraPreviewOffProvider), {'cam-1'});
    expect(cameras.listCalls, callsBefore);
  });

  testWidgets('TC-CAMWALL-APP-31 Xem camera opens the wall, close returns', (
    tester,
  ) async {
    await _size(tester, const Size(390, 1600));
    await tester.pumpWidget(_app(_tab, _Cameras([_camera(1, status: 'IDLE')])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xem camera'));
    await tester.pumpAndSettle();
    expect(find.byType(CameraWallScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Đóng tường camera'));
    await tester.pumpAndSettle();
    expect(find.byType(CameraWallScreen), findsNothing);
  });
}
