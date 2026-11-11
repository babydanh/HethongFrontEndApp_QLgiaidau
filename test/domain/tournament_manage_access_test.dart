import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/services/tournament_manage_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canManageTournament', () {
    test('creator can manage even before the workspace has loaded', () {
      expect(
        canManageTournament(
          tournamentId: 't1',
          userId: 'u1',
          creatorId: 'u1',
          managedTournamentIds: const {},
        ),
        isTrue,
      );
    });

    test('user in the workspace organizer or co-organizer list can manage', () {
      expect(
        canManageTournament(
          tournamentId: 't1',
          userId: 'u2',
          creatorId: 'u1',
          managedTournamentIds: const {'t1'},
        ),
        isTrue,
      );
    });

    test(
      'someone else (admin or organizer role) cannot manage by role alone',
      () {
        expect(
          canManageTournament(
            tournamentId: 't1',
            userId: 'admin1',
            creatorId: 'u1',
            managedTournamentIds: const {'t2'},
          ),
          isFalse,
        );
      },
    );

    test('missing user id never matches an empty creator id', () {
      expect(
        canManageTournament(
          tournamentId: 't1',
          userId: null,
          creatorId: '',
          managedTournamentIds: const {},
        ),
        isFalse,
      );
    });
  });

  group('scoringStaffTournamentIds', () {
    test(
      'TC-APP-STAFF-SCORE-04 collects co-organizer and referee tournaments',
      () {
        final now = DateTime(2026, 11, 11);
        final workspace = TournamentWorkspace(
          coOrganizerTournaments: [
            Tournament(
              id: 't-coorg',
              name: 'Giải đồng BTC',
              sport: 'pickleball',
              format: 'knockout',
              bracketType: 'single',
              adminToken: 'a',
              refereeToken: 'r',
              viewerToken: 'v',
              creatorId: 'c1',
              status: 'IN_PROGRESS',
              createdAt: now,
              updatedAt: now,
            ),
          ],
          refereeTournaments: const [
            TournamentRefereeInvite(
              refereeId: 'ref-row',
              tournamentId: 't-ref',
              tournamentName: 'Giải trọng tài',
              tournamentStatus: 'IN_PROGRESS',
              categoryName: 'Pickleball',
              assignedAt: null,
              status: 'ACCEPTED',
            ),
          ],
        );

        expect(scoringStaffTournamentIds(workspace), {'t-coorg', 't-ref'});
      },
    );

    test('TC-APP-STAFF-SCORE-05 is empty while the workspace is not loaded', () {
      expect(scoringStaffTournamentIds(null), isEmpty);
    });
  });
}
