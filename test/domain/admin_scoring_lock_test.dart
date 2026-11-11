import 'package:app_quanly_giaidau/domain/services/live_control_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isAdminScoringLocked', () {
    test('TC-ADMLOCK-01 locks an admin who did not create the tournament', () {
      expect(
        isAdminScoringLocked(userId: 'a1', isAdmin: true, createdBy: 'c1'),
        isTrue,
      );
    });

    test('TC-ADMLOCK-02 keeps scoring for the admin who created it', () {
      expect(
        isAdminScoringLocked(userId: 'a1', isAdmin: true, createdBy: 'a1'),
        isFalse,
      );
    });

    test('TC-COORG-LOCK-01 never locks an admin who is invited staff', () {
      expect(
        isAdminScoringLocked(
          userId: 'a1',
          isAdmin: true,
          createdBy: 'c1',
          isTournamentStaff: true,
        ),
        isFalse,
      );
    });

    test('TC-ADMLOCK-03 never locks a non-admin', () {
      expect(
        isAdminScoringLocked(userId: 'u1', isAdmin: false, createdBy: 'c1'),
        isFalse,
      );
    });

    test('TC-ADMLOCK-04 locks an admin while the creator is unknown', () {
      expect(
        isAdminScoringLocked(userId: 'a1', isAdmin: true, createdBy: null),
        isTrue,
      );
    });

    test('TC-ADMLOCK-05 does not lock when nobody is signed in', () {
      expect(
        isAdminScoringLocked(userId: null, isAdmin: true, createdBy: 'c1'),
        isFalse,
      );
    });

    test('TC-APP-STAFF-SCORE-03 does not lock an admin who is invited staff', () {
      expect(
        isAdminScoringLocked(
          userId: 'a1',
          isAdmin: true,
          createdBy: 'c1',
          isTournamentStaff: true,
        ),
        isFalse,
      );
    });
  });
}
