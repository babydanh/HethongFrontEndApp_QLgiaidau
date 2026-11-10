import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:app_quanly_giaidau/features/social/widgets/match_tab/social_match_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

ClubSessionMatchModel _match({
  String sportKey = '',
  Map<String, dynamic> sportRules = const {},
  Map<String, dynamic> tournamentConfig = const {},
  Map<String, dynamic> scoreDetails = const {},
  String status = 'SCHEDULED',
  int sideAScore = 0,
  int sideBScore = 0,
}) {
  return ClubSessionMatchModel(
    id: 'm1',
    status: status,
    sessionId: 'session-1',
    sportKey: sportKey,
    sideAUserIds: const ['a1'],
    sideBUserIds: const ['b1'],
    sideAScore: sideAScore,
    sideBScore: sideBScore,
    revision: 3,
    eloStatus: 'NONE',
    scoreDetails: scoreDetails,
    sportRules: sportRules,
    tournamentConfig: tournamentConfig,
    sideAMembers: const [
      ClubSessionMatchMemberModel(userId: 'a1', displayName: 'An'),
    ],
    sideBMembers: const [
      ClubSessionMatchMemberModel(userId: 'b1', displayName: 'Binh'),
    ],
    startedAt: DateTime.utc(2026, 11, 11, 1),
    completedAt: DateTime.utc(2026, 11, 11, 2),
  );
}

void main() {
  // TC-SOC-SPORT-01: the live scoring screen picks its rules from the match,
  // so a tennis session match must reach it as tennis, not as the default sport.
  test('TC-SOC-SPORT-01 carries the session sport into the match model', () {
    final model = socialSessionMatchToMatchModel(_match(sportKey: 'tennis'));
    expect(model.sportKey, 'tennis');
    expect(model.isStandaloneMatch, isTrue);
  });

  test('TC-SOC-SPORT-02 falls back to pickleball when the API sends no sport', () {
    final model = socialSessionMatchToMatchModel(_match());
    expect(model.sportKey, 'pickleball');
    expect(model.sportRules?['kind'], 'pickleball');
  });

  test('TC-SOC-SPORT-03 keeps the sport rules and tournament config from the API', () {
    final model = socialSessionMatchToMatchModel(
      _match(
        sportKey: 'badminton',
        sportRules: const {'kind': 'badminton', 'maxSets': 3, 'pointsToWin': 21},
        tournamentConfig: const {'mode': 'STRICT', 'maxSets': 3},
      ),
    );
    expect(model.sportRules?['pointsToWin'], 21);
    expect(model.sportRules?['maxSets'], 3);
    expect(model.tournamentConfig?['mode'], 'STRICT');
  });

  test('TC-SOC-SPORT-04 uses free scoring rules when the API sends none', () {
    final model = socialSessionMatchToMatchModel(_match(sportKey: 'tennis'));
    expect(model.sportRules?['kind'], 'tennis');
    expect(model.sportRules?['scoringMode'], 'FREE');
    expect(model.tournamentConfig?['scoringMode'], 'FREE');
  });

  test('TC-SOC-SPORT-05 names the winner and keeps the live timestamps', () {
    final model = socialSessionMatchToMatchModel(
      _match(status: 'COMPLETED', sideAScore: 2, sideBScore: 1),
    );
    expect(model.winnerId, 'SIDE_A');
    expect(model.loserId, 'SIDE_B');
    expect(model.startedAt, DateTime.utc(2026, 11, 11, 1));
    expect(model.completedAt, DateTime.utc(2026, 11, 11, 2));
    expect(model.revision, 3);
  });
}
