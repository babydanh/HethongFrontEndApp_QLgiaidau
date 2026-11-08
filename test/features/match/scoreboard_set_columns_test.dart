import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/scoreboard_set_columns.dart';
import 'package:flutter_test/flutter_test.dart';

SetScoreData _set(int a, int b, {bool finished = false}) =>
    SetScoreData(score1: a, score2: b, isFinished: finished);

void main() {
  group('activeSetIndex', () {
    test('TC-SETCOL-01 first unfinished set, else the last one', () {
      expect(activeSetIndex([_set(11, 5, finished: true), _set(3, 2)]), 1);
      expect(
        activeSetIndex([
          _set(11, 5, finished: true),
          _set(9, 11, finished: true),
        ]),
        1,
      );
      expect(activeSetIndex(const []), 0);
    });
  });

  group('scoreboardSetColumns', () {
    test('TC-SETCOL-02 one set keeps the original single-score look', () {
      expect(scoreboardSetColumns([_set(3, 2)], 0), isEmpty);
      expect(scoreboardSetColumns(const [], 0), isEmpty);
    });

    test(
      'TC-SETCOL-03 shows every set up to the current one, oldest first',
      () {
        final columns = scoreboardSetColumns([
          _set(11, 5, finished: true),
          _set(8, 11, finished: true),
          _set(4, 3),
        ], 2);

        expect(columns.map((c) => c.setNumber), [1, 2, 3]);
        expect(columns.map((c) => c.state), [
          SetColumnState.finished,
          SetColumnState.finished,
          SetColumnState.current,
        ]);
        expect(columns.map((c) => c.winner), [1, 2, null]);
        expect(columns.last.team1, 4);
        expect(columns.last.team2, 3);
      },
    );

    test('TC-SETCOL-04 sets after the current one are not drawn', () {
      final columns = scoreboardSetColumns([
        _set(11, 5, finished: true),
        _set(2, 1),
        _set(0, 0),
      ], 1);

      expect(columns.map((c) => c.setNumber), [1, 2]);
    });

    test('TC-SETCOL-05 a tied finished set has no winner', () {
      final columns = scoreboardSetColumns([
        _set(6, 6, finished: true),
        _set(1, 0),
      ], 1);

      expect(columns.first.winner, isNull);
    });

    test('TC-SETCOL-06 keeps only the newest ten columns', () {
      final sets = [for (var i = 0; i < 12; i++) _set(11, i, finished: i < 11)];
      final columns = scoreboardSetColumns(sets, 11);

      expect(columns, hasLength(10));
      expect(columns.first.setNumber, 3);
      expect(columns.last.setNumber, 12);
    });
  });
}
