import 'package:app_quanly_giaidau/domain/services/football_rules.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the Football cases of
/// openspec/changes/cach-bam-diem-cac-mon/reference/scoring-engine.test.js.
List<String> _types(FootballLiveState s, {required bool isTeam1}) => [
  for (final e in s.events)
    if (e.isTeam1 == isTeam1) e.type,
];

FootballLiveState _redCards(int count, {required bool isTeam1}) {
  var s = const FootballLiveState();
  for (var shirt = 1; shirt <= count; shirt++) {
    s = footballApplyCard(s, isTeam1: isTeam1, shirt: shirt, red: true);
  }
  return s;
}

void main() {
  group('football rules', () {
    test('TC-CBD-FB-01 goals are allowed only while the ball is in play', () {
      for (final phase in const [
        'FIRST_HALF',
        'SECOND_HALF',
        'STOPPAGE_TIME',
        'EXTRA_TIME_FIRST_HALF',
        'EXTRA_TIME_SECOND_HALF',
      ]) {
        expect(footballGoalAllowed(phase), isTrue, reason: phase);
      }
      for (final phase in const [
        'HALFTIME',
        'FULL_TIME',
        'EXTRA_TIME_BREAK',
        'PENALTY_SHOOTOUT',
        'COMPLETED',
        'UNKNOWN',
      ]) {
        expect(footballGoalAllowed(phase), isFalse, reason: phase);
      }
    });

    test('TC-CBD-FB-02 a yellow card keeps the shirt number on the event', () {
      final s = footballApplyCard(
        const FootballLiveState(minute: 23, addedMinute: 2),
        isTeam1: true,
        shirt: 7,
        red: false,
      );

      expect(s.events, hasLength(1));
      expect(s.events.single.type, 'YELLOW_CARD');
      expect(s.events.single.isTeam1, isTrue);
      expect(s.events.single.shirt, 7);
      expect(s.events.single.minute, 23);
      expect(s.events.single.addedMinute, 2);
      expect(footballPlayersOnField(s, true), 11);
    });

    test('TC-CBD-FB-03 second yellow of the same shirt adds a red, in order', () {
      var s = const FootballLiveState();
      s = footballApplyCard(s, isTeam1: true, shirt: 7, red: false);
      s = footballApplyCard(s, isTeam1: true, shirt: 7, red: false);

      expect(_types(s, isTeam1: true), [
        'YELLOW_CARD',
        'YELLOW_CARD',
        'RED_CARD',
      ]);
      expect(s.events.last.shirt, 7);
      expect(footballPlayersOnField(s, true), 10);
      expect(footballPlayersOnField(s, false), 11);
    });

    test('TC-CBD-FB-04 yellows of different shirts or teams never add a red', () {
      var s = const FootballLiveState();
      s = footballApplyCard(s, isTeam1: true, shirt: 7, red: false);
      s = footballApplyCard(s, isTeam1: true, shirt: 8, red: false);
      s = footballApplyCard(s, isTeam1: false, shirt: 7, red: false);
      // Unknown shirt numbers cannot be tracked: counted as plain cards.
      s = footballApplyCard(s, isTeam1: true, shirt: null, red: false);
      s = footballApplyCard(s, isTeam1: true, shirt: null, red: false);

      expect(s.events.where((e) => e.type == 'RED_CARD'), isEmpty);
      expect(footballPlayersOnField(s, true), 11);
    });

    test('TC-CBD-FB-05 a direct red removes a player, unknown shirt too', () {
      var s = const FootballLiveState();
      s = footballApplyCard(s, isTeam1: false, shirt: 4, red: true);
      s = footballApplyCard(s, isTeam1: false, shirt: null, red: true);

      expect(footballPlayersOnField(s, false), 9);
      expect(footballPlayersOnField(s, true), 11);
      expect(s.stoppedWinnerTeam, 0);
    });

    test('TC-CBD-FB-06 fewer than 7 players stops the match, other team wins', () {
      final seven = _redCards(4, isTeam1: true);
      expect(footballPlayersOnField(seven, true), 7);
      expect(seven.stoppedWinnerTeam, 0);

      final stopped = footballApplyCard(
        seven,
        isTeam1: true,
        shirt: 5,
        red: true,
      );
      expect(footballPlayersOnField(stopped, true), 6);
      expect(stopped.stoppedWinnerTeam, 2);
      expect(stopped.winnerTeam, 2);
      expect(stopped.isMatchComplete, isTrue);

      // The decision beats the goal count (team 1 leads 3-0 but is stopped).
      expect(stopped.copyWith(team1Goals: 3).winnerTeam, 2);

      // Once stopped, further cards change nothing.
      final after = footballApplyCard(
        stopped,
        isTeam1: false,
        shirt: 2,
        red: true,
      );
      expect(identical(after, stopped), isTrue);

      final team2Stopped = footballApplyCard(
        _redCards(4, isTeam1: false),
        isTeam1: false,
        shirt: 5,
        red: true,
      );
      expect(team2Stopped.stoppedWinnerTeam, 1);
    });

    test('TC-CBD-FB-07 substitutions are limited per team', () {
      var s = const FootballLiveState();
      for (var i = 0; i < 5; i++) {
        expect(footballCanSubstitute(s, true), isTrue, reason: 'sub ${i + 1}');
        s = s.copyWith(
          events: [
            ...s.events,
            const FootballEvent(
              type: 'SUBSTITUTION',
              isTeam1: true,
              minute: 60,
            ),
          ],
        );
      }

      expect(footballSubsUsed(s, true), 5);
      expect(footballCanSubstitute(s, true), isFalse);
      expect(footballCanSubstitute(s, false), isTrue);
      expect(footballCanSubstitute(s, true, subsLimit: 6), isTrue);
    });

    test('TC-CBD-FB-08 old data without the new fields still works', () {
      const old = FootballLiveState(
        team1Goals: 1,
        events: [FootballEvent(type: 'RED_CARD', isTeam1: true, minute: 10)],
      );

      expect(old.events.single.shirt, isNull);
      expect(old.stoppedWinnerTeam, 0);
      expect(footballPlayersOnField(old, true), 10);
      expect(footballSubsUsed(old, true), 0);
      final next = footballApplyCard(old, isTeam1: true, shirt: 7, red: false);
      expect(next.events, hasLength(2));
      final copy = old.copyWith(minute: 11);
      expect(copy.team1Goals, 1);
      expect(copy.stoppedWinnerTeam, 0);
    });

    test('a card for a shirt already sent off is ignored', () {
      var s = const FootballLiveState();
      s = footballApplyCard(s, isTeam1: true, shirt: 7, red: true);
      final again = footballApplyCard(s, isTeam1: true, shirt: 7, red: false);

      expect(identical(again, s), isTrue);
    });
  });
}
