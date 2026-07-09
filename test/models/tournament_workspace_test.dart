// Tests for TournamentWorkspace entity
// Covers: DASH-001, FLUTTER-24, FLUTTER-25

import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';

Tournament _makeTournament(String id, {String name = 'Giai Test'}) {
  return Tournament(
    id: id,
    name: name,
    sport: 'badminton',
    format: 'SINGLES',
    bracketType: 'single_elimination',
    creatorId: 'user-1',
    adminToken: 'ADM-XXX',
    refereeToken: 'REF-XXX',
    viewerToken: 'VWR-XXX',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('TC-FLUTTER-DASH-001: TournamentWorkspace', () {
    test('should create empty workspace', () {
      final ws = TournamentWorkspace.empty;
      expect(ws.organizedTournaments, []);
      expect(ws.participatingTournaments, []);
      expect(ws.coOrganizerTournaments, []);
      expect(ws.refereeInvites, []);
      expect(ws.refereeMatches, []);
      expect(ws.activeRoleCount, 0);
    });

    test('should have activeRoleCount 0 when empty', () {
      final ws = TournamentWorkspace.empty;
      expect(ws.activeRoleCount, 0);
    });
  });

  group('TC-FLUTTER-24: visibleTournaments dedup', () {
    test('should deduplicate tournaments by id', () {
      final t1 = _makeTournament('t1');
      final ws = TournamentWorkspace(
        organizedTournaments: [t1],
        participatingTournaments: [t1],
      );
      expect(ws.visibleTournaments.length, 1);
    });

    test('should include organized, coOrganizer, and participating', () {
      final ws = TournamentWorkspace(
        organizedTournaments: [_makeTournament('t1')],
        coOrganizerTournaments: [_makeTournament('t2')],
        participatingTournaments: [_makeTournament('t3')],
      );
      expect(ws.visibleTournaments.length, 3);
    });

    test('should handle empty lists', () {
      final ws = TournamentWorkspace.empty;
      expect(ws.visibleTournaments, []);
    });
  });

  group('TC-FLUTTER-25: activeRoleCount', () {
    test('should count organized as 1 role', () {
      final ws = TournamentWorkspace(
        organizedTournaments: [_makeTournament('t1')],
      );
      expect(ws.activeRoleCount, 1);
    });

    test('should count organized, referee, participating', () {
      final ws = TournamentWorkspace(
        organizedTournaments: [_makeTournament('t1')],
        refereeTournaments: [
          TournamentRefereeInvite(
            refereeId: 'r1',
            tournamentId: 't3',
            tournamentName: 'Giai 3',
            tournamentStatus: 'in_progress',
            categoryName: '',
            assignedAt: DateTime.now(),
            status: 'ACCEPTED',
          ),
        ],
        participatingTournaments: [_makeTournament('t2')],
      );
      expect(ws.activeRoleCount, 3);
    });

    test('should count organized and coOrganizer as 2', () {
      final ws = TournamentWorkspace(
        organizedTournaments: [_makeTournament('t1')],
        coOrganizerTournaments: [_makeTournament('t2')],
      );
      expect(ws.activeRoleCount, 2);
    });
  });
}
