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
}
