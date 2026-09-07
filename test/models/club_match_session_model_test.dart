import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the separate club-session context without tournament fields', () {
    final session = ClubMatchSessionModel.fromJson({
      'id': 'session-1',
      'communityId': 'club-1',
      'resolvedName': 'Club social match session Riverside',
      'status': 'OPEN',
      'registrationMode': 'MIXED',
      'isRanked': true,
      'version': 1,
      'capabilities': {'canManage': true},
    });

    expect(session.communityId, 'club-1');
    expect(session.status, 'OPEN');
    expect(session.isRanked, isTrue);
    expect(session.canManage, isTrue);
  });

  test('parses score revision and explicit ELO state for REST resync', () {
    final match = ClubSessionMatchModel.fromJson({
      'id': 'match-1',
      'status': 'COMPLETED',
      'sideAUserIds': ['user-a'],
      'sideBUserIds': ['user-b'],
      'p1SetsWon': 2,
      'p2SetsWon': 1,
      'revision': 4,
      'eloStatus': 'APPLIED',
    });

    expect(match.sideAScore, 2);
    expect(match.sideBScore, 1);
    expect(match.revision, 4);
    expect(match.eloStatus, 'APPLIED');
  });
}
