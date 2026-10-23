import 'package:app_quanly_giaidau/domain/services/live_control_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canControlTournamentLive', () {
    test('hides the button when there is no user and no backend grant', () {
      expect(
        canControlTournamentLive(
          userId: null,
          isAdmin: false,
          createdBy: 'u1',
          refereeId: 'u1',
          scoreAccess: null,
        ),
        isFalse,
      );
    });

    test('follows the backend grant while the profile id is still missing', () {
      expect(
        canControlTournamentLive(
          userId: null,
          isAdmin: false,
          createdBy: 'u1',
          scoreAccess: true,
        ),
        isTrue,
      );
      expect(
        canControlTournamentLive(
          userId: null,
          isAdmin: true,
          createdBy: 'u1',
          scoreAccess: true,
        ),
        isFalse,
      );
    });

    test('shows it to the tournament creator without score-access', () {
      expect(
        canControlTournamentLive(
          userId: 'u1',
          isAdmin: false,
          createdBy: 'u1',
          scoreAccess: null,
        ),
        isTrue,
      );
    });

    test('shows it to an admin who is the creator', () {
      expect(
        canControlTournamentLive(
          userId: 'u1',
          isAdmin: true,
          createdBy: 'u1',
          scoreAccess: null,
        ),
        isTrue,
      );
    });

    test('shows it to the referee assigned to this match', () {
      expect(
        canControlTournamentLive(
          userId: 'u2',
          isAdmin: false,
          createdBy: 'u1',
          refereeId: 'u2',
          scoreAccess: false,
        ),
        isTrue,
      );
    });

    test('hides it from an admin of another tournament even if score-access is true', () {
      expect(
        canControlTournamentLive(
          userId: 'admin',
          isAdmin: true,
          createdBy: 'u1',
          refereeId: 'u2',
          scoreAccess: true,
        ),
        isFalse,
      );
    });

    test('follows score-access for other signed-in users', () {
      bool run(bool? access) => canControlTournamentLive(
        userId: 'u3',
        isAdmin: false,
        createdBy: 'u1',
        refereeId: 'u2',
        scoreAccess: access,
      );
      expect(run(true), isTrue);
      expect(run(false), isFalse);
      expect(run(null), isFalse);
    });

    test('does not match empty ids against each other', () {
      expect(
        canControlTournamentLive(
          userId: 'u3',
          isAdmin: false,
          createdBy: null,
          refereeId: null,
          scoreAccess: null,
        ),
        isFalse,
      );
    });
  });
}
