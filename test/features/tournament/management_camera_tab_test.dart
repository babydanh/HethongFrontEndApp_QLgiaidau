import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_camera_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_hub_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/camera_wall_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-HUB-CAM-01..04: tab Camera trong màn Quản lý giải (nút Bắt đầu/Dừng).
const _tid = 'tournament-1';

class _Venues implements TournamentManagementRepository {
  int venueCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async {
    venueCalls++;
    return [
      {
        'name': 'Nhà thi đấu',
        'courts': [
          {'id': 'court-1', 'name': 'Sân 1'},
        ],
      },
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cameras implements ICourtCameraRepository {
  _Cameras([this.cameras = const []]);

  final List<TournamentCameraModel> cameras;

  @override
  Future<List<TournamentCameraModel>> listCameras(String tournamentId) async =>
      cameras;

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

Tournament _tournament(String status) => Tournament.fromJson({
  'name': 'City Pickleball Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': status,
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'divisions': [
    {'id': 'div-1', 'name': 'Đôi nam', 'matchType': 'DOUBLES'},
  ],
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _tid);

MatchModel _match({
  String team1Name = 'Team A1',
  String team2Name = 'Team B1',
  List<ParticipantPlayer> team1Players = const [],
  List<ParticipantPlayer> team2Players = const [],
}) => MatchModel(
  id: 'm1',
  tournamentId: _tid,
  round: 1,
  matchNumber: 1,
  bracketPosition: BracketPosition(round: 1, position: 1),
  team1Id: 'a1',
  team2Id: 'b1',
  team1Name: team1Name,
  team2Name: team2Name,
  team1Players: team1Players,
  team2Players: team2Players,
  status: 'SCHEDULED',
  divisionId: 'div-1',
  updatedAt: DateTime.utc(2026, 1, 1),
);

Future<(AppLocalizations, _Venues)> _pumpHub(
  WidgetTester tester, {
  String status = 'in_progress',
  MatchModel? match,
  List<TournamentCameraModel> cameras = const [],
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final venues = _Venues();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(
            id: 'manager-1',
            role: 'ORGANIZER',
            roles: ['ORGANIZER', 'ADMIN'],
          ),
        ),
        tournamentManagementRepositoryProvider.overrideWithValue(venues),
        courtCameraRepositoryProvider.overrideWithValue(_Cameras(cameras)),
        matchRecordingCatalogRepositoryProvider.overrideWithValue(_Catalog()),
        matchesProvider(
          _tid,
        ).overrideWith((ref) => Stream.value(const <MatchModel>[])),
        managedMatchesWithDivisionProvider.overrideWith(
          (ref, args) => Stream.value([match ?? _match()]),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: TournamentManagementHubScreen(
          tournament: _tournament(status),
          actionRouteBase: '/admin/tournament/$_tid',
          opsWorkspaceRoute: '/organizer/tournaments/$_tid/ops',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final l10n = AppLocalizations.of(
    tester.element(find.byType(TournamentManagementHubScreen)),
  )!;
  return (l10n, venues);
}

Future<void> _openTab(WidgetTester tester, String label) async {
  final tab = find.widgetWithText(Tab, label);
  await tester.ensureVisible(tab);
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-HUB-CAM-01 hub has a Camera tab right before Cài đặt', (
    tester,
  ) async {
    final (l10n, _) = await _pumpHub(tester);

    final tabs = tester
        .widgetList<Tab>(find.byType(Tab))
        .map((tab) => tab.text)
        .toList();
    expect(tabs, hasLength(8));
    expect(tabs[6], l10n.opsCamera);
    expect(tabs.last, l10n.tournamentManagementTabSettings);
  });

  testWidgets('TC-HUB-CAM-02 opening Camera shows the board with Bắt đầu', (
    tester,
  ) async {
    final (l10n, _) = await _pumpHub(tester);

    await _openTab(tester, l10n.opsCamera);

    final section = tester.widget<TournamentManagementCameraSection>(
      find.byType(TournamentManagementCameraSection),
    );
    expect(section.tournamentId, _tid);
    expect(section.readOnly, isFalse);
    expect(find.widgetWithText(OutlinedButton, 'Bắt đầu'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-HUB-CAM-03 a completed tournament opens Camera read-only', (
    tester,
  ) async {
    final (l10n, _) = await _pumpHub(tester, status: 'completed');

    await _openTab(tester, l10n.opsCamera);

    final section = tester.widget<TournamentManagementCameraSection>(
      find.byType(TournamentManagementCameraSection),
    );
    expect(section.readOnly, isTrue);
    expect(find.widgetWithText(OutlinedButton, 'Bắt đầu'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Dừng'), findsNothing);
  });

  testWidgets('TC-HUB-CAM-04 passing over Camera to Cài đặt loads nothing', (
    tester,
  ) async {
    final (l10n, venues) = await _pumpHub(tester);

    await _openTab(tester, l10n.tournamentManagementTabSettings);

    expect(find.byType(TournamentManagementCameraSection), findsNothing);
    expect(venues.venueCalls, 0);
  });

  testWidgets('TC-CAMLABEL-01 shows athlete names when the team has no name', (
    tester,
  ) async {
    final (l10n, _) = await _pumpHub(
      tester,
      match: _match(
        team1Name: '',
        team2Name: '',
        team1Players: const [
          ParticipantPlayer(slot: 1, fullName: 'Nguyễn Văn An'),
        ],
        team2Players: const [
          ParticipantPlayer(slot: 1, fullName: 'Trần Văn Bình'),
        ],
      ),
    );

    await _openTab(tester, l10n.opsCamera);

    expect(find.text('Nguyễn Văn An – Trần Văn Bình'), findsWidgets);
  });

  testWidgets('TC-CAMLABEL-02 keeps the team names when they exist', (
    tester,
  ) async {
    final (l10n, _) = await _pumpHub(tester);

    await _openTab(tester, l10n.opsCamera);

    expect(find.text('Team A1 – Team B1'), findsWidgets);
  });

  testWidgets('TC-CAMLABEL-03 an empty side reads Chưa xác định, not a dash', (
    tester,
  ) async {
    final (l10n, _) = await _pumpHub(
      tester,
      match: _match(team1Name: '', team2Name: ''),
    );

    await _openTab(tester, l10n.opsCamera);

    final label = '${l10n.matchNotDetermined} – ${l10n.matchNotDetermined}';
    expect(find.text(label), findsWidgets);
  });

  testWidgets(
    'TC-APP-CAMWALL-20 giải chưa có camera thì không có nút Xem camera',
    (tester) async {
      final (l10n, _) = await _pumpHub(tester);

      await _openTab(tester, l10n.opsCamera);

      expect(find.text(l10n.tournamentManagementCameraWallOpen), findsNothing);
    },
  );

  testWidgets('TC-APP-CAMWALL-21 bấm Xem camera mở tường camera lưới 2×2', (
    tester,
  ) async {
    final (l10n, _) = await _pumpHub(
      tester,
      cameras: const [
        TournamentCameraModel(
          id: 'cam-1',
          name: 'Camera sân 1',
          mode: 'PULL',
          status: 'OFFLINE',
          courtId: 'court-1',
        ),
      ],
    );
    await _openTab(tester, l10n.opsCamera);

    await tester.tap(find.text(l10n.tournamentManagementCameraWallOpen));
    await tester.pumpAndSettle();

    final wall = tester.widget<CameraWallScreen>(find.byType(CameraWallScreen));
    expect(wall.tournamentId, _tid);
    expect(find.text(l10n.tournamentManagementCameraWallTitle), findsOneWidget);
    final layout = tester.widget<SegmentedButton<int>>(
      find.byType(SegmentedButton<int>),
    );
    expect(layout.selected, {2});
  });
}
