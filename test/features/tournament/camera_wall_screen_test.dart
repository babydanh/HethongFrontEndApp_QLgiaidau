import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_player.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_wall_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tid = 'tournament-1';

/// Đếm mọi lần gọi Backend để chứng minh công tắc xem thử không gửi gì lên.
class _Cameras implements ICourtCameraRepository {
  _Cameras(this.cameras);

  final List<TournamentCameraModel> cameras;
  int calls = 0;

  @override
  Future<List<TournamentCameraModel>> listCameras(String tournamentId) async {
    calls++;
    return cameras;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Catalog implements IMatchRecordingCatalogRepository {
  _Catalog(this.rows);

  final List<MatchLivestreamSummary> rows;
  int calls = 0;

  @override
  Future<List<MatchLivestreamSummary>> listTournamentMatchLivestreams(
    String tournamentId,
  ) async {
    calls++;
    return rows;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TournamentCameraModel _camera(
  int index, {
  String status = 'LIVE',
  String? courtId,
}) => TournamentCameraModel(
  id: 'c$index',
  name: 'Cam $index',
  mode: 'PULL',
  status: status,
  courtId: courtId,
  playbackUrl: 'https://cdn.example/$index.m3u8',
);

MatchModel _match(
  String id, {
  required String code,
  String status = 'SCHEDULED',
  String? courtId,
}) => MatchModel(
  id: id,
  round: 1,
  matchNumber: 1,
  matchCode: code,
  status: status,
  courtId: courtId,
  team1Id: 'a-$id',
  team2Id: 'b-$id',
  team1Name: 'Đội A',
  team2Name: 'Đội B',
  score1: 21,
  score2: 3,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026, 11, 12),
);

Finder _tile(int index) => find.byKey(ValueKey('camera-wall-tile-c$index'));

Future<({_Cameras cameras, _Catalog catalog})> _pump(
  WidgetTester tester, {
  required List<TournamentCameraModel> cameras,
  List<MatchModel> matches = const [],
  List<MatchLivestreamSummary> streams = const [],
  Size size = const Size(390, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final cameraRepo = _Cameras(cameras);
  final catalogRepo = _Catalog(streams);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        courtCameraRepositoryProvider.overrideWithValue(cameraRepo),
        matchRecordingCatalogRepositoryProvider.overrideWithValue(catalogRepo),
        managedMatchesWithDivisionProvider.overrideWith(
          (ref, args) => Stream.value(matches),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: const CameraWallScreen(tournamentId: _tid),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (cameras: cameraRepo, catalog: catalogRepo);
}

Future<void> _pickLayout(WidgetTester tester, int n) async {
  await tester.tap(find.text('$n×$n'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-APP-CAMWALL-10 mở với lưới 2×2: chỉ 4 camera đầu', (
    tester,
  ) async {
    await _pump(tester, cameras: [for (var i = 1; i <= 6; i++) _camera(i)]);

    for (var i = 1; i <= 4; i++) {
      expect(_tile(i), findsOneWidget);
    }
    expect(_tile(5), findsNothing);
    expect(find.text('Tường camera'), findsOneWidget);
    expect(find.text('Trang 1/2'), findsOneWidget);
  });

  testWidgets(
    'TC-APP-CAMWALL-11 20 camera ở lưới 4×4: trang 1 có 16, trang 2 có 4',
    (tester) async {
      await _pump(tester, cameras: [for (var i = 1; i <= 20; i++) _camera(i)]);

      await _pickLayout(tester, 4);
      expect(find.byKey(const ValueKey('camera-wall-tile-c1')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w.key.toString().contains('camera-wall-tile-'),
        ),
        findsNWidgets(16),
      );

      await tester.tap(find.byTooltip('Trang sau'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w.key.toString().contains('camera-wall-tile-'),
        ),
        findsNWidgets(4),
      );
      expect(_tile(17), findsOneWidget);
      expect(find.text('Trang 2/2'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-APP-CAMWALL-12 camera OFFLINE không có LiveVideoPlayer, hiện huy hiệu',
    (tester) async {
      await _pump(
        tester,
        cameras: [
          _camera(1),
          _camera(2, status: 'OFFLINE'),
        ],
      );

      expect(
        find.descendant(of: _tile(1), matching: find.byType(LiveVideoPlayer)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _tile(2), matching: find.byType(LiveVideoPlayer)),
        findsNothing,
      );
      expect(
        find.descendant(of: _tile(2), matching: find.text('Không có hình')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'TC-APP-CAMWALL-13 tắt xem thử gỡ LiveVideoPlayer và không gọi Backend',
    (tester) async {
      final repos = await _pump(tester, cameras: [_camera(1)]);
      final cameraCalls = repos.cameras.calls;
      final catalogCalls = repos.catalog.calls;

      await tester.tap(
        find.descendant(of: _tile(1), matching: find.byType(Switch)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LiveVideoPlayer), findsNothing);
      expect(repos.cameras.calls, cameraCalls);
      expect(repos.catalog.calls, catalogCalls);
    },
  );

  testWidgets(
    'TC-APP-CAMWALL-14 chạm đúp một ô chuyển sang 1×1 đúng camera đó',
    (tester) async {
      await _pump(tester, cameras: [for (var i = 1; i <= 4; i++) _camera(i)]);

      await tester.tap(
        find.descendant(of: _tile(3), matching: find.text('Cam 3')).first,
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(
        find.descendant(of: _tile(3), matching: find.text('Cam 3')).first,
      );
      await tester.pumpAndSettle();

      expect(_tile(3), findsOneWidget);
      expect(_tile(1), findsNothing);
      expect(_tile(4), findsNothing);
      expect(find.text('Trang 3/4'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-APP-CAMWALL-15 ô hiện #mã trận và hai bên, không tỉ số; thiếu trận thì Chưa có trận',
    (tester) async {
      await _pump(
        tester,
        cameras: [_camera(1), _camera(2)],
        matches: [_match('m1', code: 'CK01')],
        streams: const [
          MatchLivestreamSummary(
            matchId: 'm1',
            cameraId: 'c1',
            streamStatus: MatchStreamStatus.live,
          ),
        ],
      );

      expect(
        find.descendant(
          of: _tile(1),
          matching: find.text('#CK01 Đội A – Đội B'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('21'), findsNothing);
      expect(
        find.descendant(of: _tile(2), matching: find.text('Chưa có trận')),
        findsOneWidget,
      );
    },
  );

  for (final size in const [Size(360, 640), Size(1024, 768)]) {
    testWidgets(
      'TC-APP-CAMWALL-16 lưới 4×4 không tràn ở ${size.width.toInt()}×${size.height.toInt()}',
      (tester) async {
        await _pump(
          tester,
          size: size,
          cameras: [
            for (var i = 1; i <= 16; i++)
              _camera(
                i,
                status: i.isEven ? 'OFFLINE' : 'LIVE',
                courtId: 'court$i',
              ),
          ],
          matches: [
            for (var i = 1; i <= 16; i++)
              _match('m$i', code: 'CODE-$i', courtId: 'court$i'),
          ],
        );

        await _pickLayout(tester, 4);

        expect(tester.takeException(), isNull);
        expect(_tile(16), findsOneWidget);
      },
    );
  }
}
