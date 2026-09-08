import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parses the separate club-session context without tournament fields',
    () {
      final session = ClubMatchSessionModel.fromJson({
        'id': 'session-1',
        'communityId': 'club-1',
        'resolvedName': 'Club social match session Riverside',
        'status': 'OPEN',
        'registrationMode': 'MIXED',
        'isRanked': true,
        'version': 1,
        'capabilities': {
          'canManage': true,
          'canJoin': false,
          'canWithdraw': true,
          'canCreateMatch': true,
        },
        'viewerParticipant': {'userId': 'user-me', 'status': 'ACTIVE'},
        'viewerPreferences': {
          'preferredPartnerUserIds': ['user-a'],
          'preferredOpponentUserIds': ['user-b'],
          'avoidUserIds': ['user-c'],
          'version': 3,
        },
      });

      expect(session.communityId, 'club-1');
      expect(session.status, 'OPEN');
      expect(session.isRanked, isTrue);
      expect(session.canManage, isTrue);
      expect(session.canWithdraw, isTrue);
      expect(session.canCreateMatch, isTrue);
      expect(session.viewerIsActive, isTrue);
      expect(session.preferredPartnerUserIds, ['user-a']);
      expect(session.preferredOpponentUserIds, ['user-b']);
      expect(session.avoidUserIds, ['user-c']);
      expect(session.preferenceVersion, 3);
    },
  );

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
      'scoreDetails': {
        'sets': [11, 8],
      },
      'eloDelta': {'user-a': 12, 'user-b': -12},
    });

    expect(match.sideAScore, 2);
    expect(match.sideBScore, 1);
    expect(match.revision, 4);
    expect(match.eloStatus, 'APPLIED');
    expect(match.scoreDetails, isNotEmpty);
    expect(match.eloDelta['user-a'], 12);
  });

  test('parses activity scores like the web, including legacy set keys', () {
    final current = parseClubSessionScoreDetails({
      'sets': [
        {'team1Score': 4, 'team2Score': 3, 'isFinished': false},
        {'team1Score': 8, 'team2Score': 2, 'isFinished': true},
      ],
    });
    expect(current.map((score) => [score.sideAScore, score.sideBScore]), [
      [4, 3],
      [8, 2],
    ]);

    final legacy = parseClubSessionScoreDetails({
      'set1': '11-9',
      'set2': '8-11',
    });
    expect(legacy.map((score) => [score.sideAScore, score.sideBScore]), [
      [11, 9],
      [8, 11],
    ]);
  });

  test('keeps explicit roster fallback when the first API roster is empty', () {
    final match = ClubSessionMatchModel.fromJson({
      'id': 'match-2',
      'sideAUserIds': ['user-a'],
      'sideBUserIds': ['user-b'],
      'team1MemberInfos': [],
      'team1Members': [
        {'userId': 'user-a', 'fullName': 'Người chơi A'},
      ],
      'team2MemberInfos': [
        {'userId': 'user-b', 'fullName': 'Người chơi B'},
      ],
    });

    expect(match.sideANames, ['Người chơi A']);
    expect(match.sideBNames, ['Người chơi B']);
  });
}
