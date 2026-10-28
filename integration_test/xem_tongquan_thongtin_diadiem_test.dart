import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/camera_live_status_model.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_section_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_venues_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/overview_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/court_camera_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/xem.dart';

/// Overview contact block, grouped information page and venues & courts, on
/// fake data only (no Backend, no network).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initXem);

  testWidgets('xem: tong quan co khoi lien he', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      xemApp(
        overrides: [authProvider.overrideWith(_UnauthenticatedNotifier.new)],
        home: Scaffold(
          body: OverviewTab(
            tournament: _overviewTournament(),
            teamCount: 12,
            resolveImageUrl: (_) => '',
            onToggleFounderHidden: null,
          ),
        ),
      ),
    );
    await shooter.snap('tong-quan-dau');
    await scrollBy(tester, 900);
    await shooter.snap('tong-quan-lien-he');
  });

  testWidgets('xem: thong tin giai gom nhom', (tester) async {
    final tournament = _settingsTournament();
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      xemApp(
        overrides: [
          tournamentRepositoryProvider.overrideWithValue(
            _SettingsRepository(tournament),
          ),
          tournamentManagementRepositoryProvider.overrideWithValue(
            _InfoManagementRepository(),
          ),
        ],
        home: Scaffold(
          body: TournamentManagementSectionScreen(
            tournament: tournament,
            section: TournamentManagementSection.information,
            opsWorkspaceRoute: '/organizer/ops/tournament-1',
            actionRouteBase: '/organizer/tournaments/tournament-1/manage',
          ),
        ),
      ),
    );
    await shooter.snap('thong-tin-giai-nhom-dau');

    final l10n = AppLocalizations.of(
      tester.element(find.byType(TournamentManagementSectionScreen)),
    )!;
    await scrollTo(tester, find.text(l10n.manageInfoGroupContact));
    await tester.tap(find.text(l10n.manageInfoGroupContact));
    await settle(tester);
    await scrollBy(tester, 300);
    await shooter.snap('thong-tin-giai-nhom-lien-he');
  });

  testWidgets('xem: dia diem va san', (tester) async {
    final shooter = XemShooter(tester, binding);
    await shooter.pump(
      xemApp(
        overrides: [
          tournamentManagementRepositoryProvider.overrideWithValue(
            _VenuesRepository(),
          ),
          courtCameraRepositoryProvider.overrideWithValue(_CameraRepository()),
        ],
        home: const Scaffold(
          body: TournamentManagementVenuesSection(tournamentId: 'tournament-1'),
        ),
      ),
    );
    await shooter.snap('dia-diem-va-san');
  });
}

class _UnauthenticatedNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _overviewTournament() => Tournament.fromJson({
  'contactInfo': {
    'displayMode': 'MANUAL',
    'organizerName': 'Ban to chuc Sporto',
    'phone': '0900000000',
    'email': 'contact@example.test',
  },
  'name': 'Giai Pickleball Mo Rong',
  'sport': 'pickleball',
  'category': {'name': 'Pickleball', 'slug': 'pickleball'},
  'format': 'SINGLES',
  'bracketType': 'single_elimination',
  'status': 'in_progress',
  'creator': {'id': 'creator-1', 'fullName': 'Organizer Name'},
  'maxTeams': 16,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
  'registrationStartDate': '2026-09-01T00:00:00.000Z',
  'registrationEndDate': '2026-09-29T00:00:00.000Z',
  'startDate': '2026-10-01T00:00:00.000Z',
}, 'tournament-contact');

Tournament _settingsTournament() => Tournament.fromJson({
  'name': 'City Pickleball Cup',
  'sport': 'pickleball',
  'format': 'singles',
  'bracketType': 'single_elimination',
  'status': 'REGISTRATION_OPEN',
  'visibility': 'PUBLIC',
  'tournamentConfig': {
    'hideFeaturedCardText': true,
    'registrationMode': 'OPEN',
    'location': {'venueName': 'North Court', 'address': '12 Lake Road'},
    'mode': 'FREE',
  },
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

class _SettingsRepository implements ITournamentRepository {
  _SettingsRepository(this.tournament);

  final Tournament tournament;

  @override
  Future<Tournament?> getById(String id, {String? inviteCode}) async =>
      tournament;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _InfoManagementRepository implements TournamentManagementRepository {
  @override
  Future<List<String>> getGallery(String id) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VenuesRepository implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    {
      'id': 'venue-1',
      'name': 'North Hall',
      'locationAddress': '12 Lake Road',
      'isDefault': true,
      'courts': [
        {'id': 'court-1', 'name': 'Court 1'},
        {'id': 'court-2', 'name': 'Court 2'},
      ],
    },
    {
      'id': 'venue-2',
      'name': 'South Hall',
      'locationAddress': '8 River Street',
      'courts': [
        {'id': 'court-3', 'name': 'Court 3'},
      ],
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CameraRepository implements ICourtCameraRepository {
  @override
  Future<List<TournamentCameraModel>> listCameras(String tournamentId) async =>
      const [
        TournamentCameraModel(
          id: 'camera-1',
          name: 'Camera 1',
          mode: 'PULL',
          status: 'ACTIVE',
          courtId: 'court-1',
          playbackUrl: 'rtsp://camera.example.test/stream',
        ),
      ];

  @override
  Future<CameraLiveStatusModel> getCameraLiveStatus(String cameraId) =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
