import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/camera_device_model.dart';
import 'package:app_quanly_giaidau/data/models/camera_live_status_model.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/live_session_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_sponsor.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/camera_admin_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/live_session_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_hub_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_livestream_section.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_sponsors_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_camera_panel.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:app_quanly_giaidau/providers/live_session_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/xem.dart';

const _tournamentId = 'tournament-1';
const _communityId = 'community-1';

/// Sponsors, livestream and the "confirm tournament results" sheet, on fake
/// data only (no Backend, no network).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initXem);

  testWidgets('xem: nha tai tro', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      xemApp(
        overrides: [
          tournamentManagementRepositoryProvider.overrideWithValue(
            _SponsorRepository(_sponsors),
          ),
        ],
        home: const Scaffold(
          body: TournamentManagementSponsorsSection(
            tournamentId: _tournamentId,
          ),
        ),
      ),
    );
    await shooter.snap('tai-tro-danh-sach');
  });

  testWidgets('xem: livestream va camera', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      xemApp(
        overrides: [
          liveSessionRepositoryProvider.overrideWithValue(_LiveRepository()),
          courtCameraRepositoryProvider.overrideWithValue(_cameraServer),
          cameraAdminRepositoryProvider.overrideWithValue(_cameraServer),
          tournamentManagementRepositoryProvider.overrideWithValue(
            _VenueRepository(),
          ),
        ],
        home: const Scaffold(
          body: TournamentManagementLivestreamSection(
            tournamentId: _tournamentId,
            communityId: _communityId,
          ),
        ),
      ),
    );
    await shooter.snap('livestream-camera');

    await scrollTo(tester, find.byType(TournamentCameraPanel));
    await shooter.snap('livestream-khoi-camera');
    await scrollBy(tester, 420);
    await shooter.snap('livestream-khoi-san');
  });

  testWidgets('xem: sheet xac nhan ket qua giai', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      xemApp(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) async => const UserProfile(
              id: 'organizer-1',
              role: 'ORGANIZER',
              roles: ['ORGANIZER'],
            ),
          ),
          tournamentManagementRepositoryProvider.overrideWithValue(
            _EndRepository(),
          ),
          matchesProvider(_tournamentId).overrideWith(
            (ref) => Stream.value([
              _match('m-1', 'COMPLETED', 'Team A', 'Team B'),
              _match('m-2', 'COMPLETED', 'Team C', 'Team D'),
              _match('m-3', 'ONGOING', 'Team E', 'Team F'),
            ]),
          ),
          tournamentResultProvider((
            tournamentId: _tournamentId,
            divisionId: null,
          )).overrideWith((ref) => Stream.value({'awards': const []})),
        ],
        home: TournamentManagementHubScreen(
          tournament: _tournament(),
          actionRouteBase: '/organizer/tournaments/$_tournamentId/manage',
          opsWorkspaceRoute: '/organizer/tournaments/$_tournamentId/ops',
        ),
      ),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(TournamentManagementHubScreen)),
    )!;
    await tester.tap(find.byIcon(Icons.more_vert));
    await settle(tester);
    await tester.tap(find.text(l10n.endTournament));
    await settle(tester);
    await shooter.snap('xac-nhan-ket-qua-giai');
  });
}

// --- Sponsors -------------------------------------------------------------

TournamentSponsor _sponsor(
  String id,
  String name,
  String tier, {
  String status = 'PUBLISHED',
  bool? isPublic,
  int order = 0,
}) => TournamentSponsor(
  id: id,
  displayName: name,
  tier: tier,
  logoUrl: '', // empty logo keeps the screen offline (initial-letter avatar)
  displayOrder: order,
  status: status,
  isPublic: isPublic,
);

final _sponsors = [
  _sponsor('1', 'Sporto Gold Partner', 'GOLD'),
  _sponsor('2', 'Court Silver Co', 'SILVER', order: 1),
  _sponsor('3', 'Bronze Paddle Shop', 'BRONZE', order: 2, isPublic: false),
  _sponsor('4', 'Old Sponsor 2025', 'GOLD', status: 'ARCHIVED', order: 3),
];

class _SponsorRepository implements TournamentManagementRepository {
  _SponsorRepository(this.sponsors);

  final List<TournamentSponsor> sponsors;

  @override
  Future<List<TournamentSponsor>> getSponsors(String id) async => sponsors;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --- Livestream -----------------------------------------------------------

const _cameras = [
  TournamentCameraModel(
    id: 'cam-1',
    name: 'Camera san 1',
    mode: 'PUSH',
    status: 'LIVE',
    courtId: 'court-1',
    playbackUrl: 'rtsp://camera.example.test/stream',
  ),
  TournamentCameraModel(
    id: 'cam-2',
    name: 'Camera san 2',
    mode: 'PUSH',
    status: 'IDLE',
    courtId: 'court-2',
  ),
  TournamentCameraModel(
    id: 'cam-3',
    name: 'Camera du phong',
    mode: 'PUSH',
    status: 'IDLE',
  ),
];

final _cameraServer = _CameraServer();

/// One fake behind both camera contracts; reads only.
class _CameraServer implements ICourtCameraRepository, ICameraAdminRepository {
  @override
  Future<List<TournamentCameraModel>> listCameras(String tournamentId) async =>
      _cameras;

  @override
  Future<CameraLiveStatusModel> getCameraLiveStatus(String cameraId) =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VenueRepository implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    {
      'id': 'venue-1',
      'name': 'Nha thi dau Sporto',
      'courts': [
        {'id': 'court-1', 'name': 'San 1'},
        {'id': 'court-2', 'name': 'San 2'},
      ],
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LiveRepository implements ILiveSessionRepository {
  @override
  Future<List<CameraDeviceModel>> listDevices(String communityId) async => [
    const CameraDeviceModel(
      id: 'device-1',
      communityId: _communityId,
      name: 'Dien thoai A',
      status: CameraDeviceStatus.online,
    ),
  ];

  @override
  Future<List<LiveSessionModel>> listSessions(String tournamentId) async => [
    const LiveSessionModel(
      id: 'session-1',
      tournamentId: _tournamentId,
      matchId: 'match-1',
      provider: LiveSessionProvider.facebook,
      status: LiveSessionStatus.live,
      replayProvider: ReplayProvider.none,
      title: 'Court 1 semi-final',
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// --- End-of-tournament sheet ----------------------------------------------

class _EndRepository
    implements TournamentManagementRepository, TournamentLifecycleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament() => Tournament.fromJson({
  'name': 'City Pickleball Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'IN_PROGRESS',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'divisions': [
    {'id': 'div-1', 'name': 'Doi Nam', 'matchType': 'DOUBLES'},
  ],
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _tournamentId);

MatchModel _match(String id, String status, String team1, String team2) =>
    MatchModel(
      id: id,
      round: 1,
      matchNumber: 1,
      team1Name: team1,
      team2Name: team2,
      status: status,
      bracketPosition: const BracketPosition(round: 1, position: 1),
      updatedAt: DateTime(2026, 1, 1),
      divisionId: 'div-1',
    );
