import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_bracket_layout.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _m(
  String id, {
  String status = 'SCHEDULED',
  String next = '',
  String loserNext = '',
  String? code,
}) => MatchModel.fromJson({
  'tournamentId': 't-1',
  'round': 1,
  'matchNumber': 1,
  'status': status,
  'nextMatchId': next,
  'loserNextMatchId': loserNext,
  'matchCode': code,
}, id);

const double _h = 80;
const double _step = _h + kBracketRowGap;

void main() {
  group('bracketWindowStart', () {
    test('TC-PLB-01 centres the active round and clamps to the ends', () {
      expect(bracketWindowStart(0, 6), 0);
      expect(bracketWindowStart(1, 6), 0);
      expect(bracketWindowStart(3, 6), 2);
      expect(bracketWindowStart(5, 6), 3);
      expect(bracketWindowStart(0, 2), 0);
      expect(bracketWindowStart(0, 0), 0);
    });
  });

  group('defaults', () {
    test('TC-PLB-02 first round with an unfinished match is the default', () {
      final rounds = [
        [_m('a', status: 'COMPLETED')],
        [_m('b', status: 'LIVE')],
        [_m('c')],
      ];
      expect(defaultActiveRound(rounds), 1);
    });

    test('TC-PLB-03 everything finished falls back to the last round', () {
      final rounds = [
        [_m('a', status: 'COMPLETED')],
        [_m('b', status: 'COMPLETED')],
      ];
      expect(defaultActiveRound(rounds), 1);
      expect(defaultActiveRound(const []), 0);
    });

    test('TC-PLB-04 losers branch is the default only when it alone is open', () {
      final done = [
        [_m('w', status: 'COMPLETED')],
      ];
      final open = [
        [_m('l')],
      ];
      expect(defaultLosersBranch(done, open), isTrue);
      expect(defaultLosersBranch(open, open), isFalse);
      expect(defaultLosersBranch(done, const []), isFalse);
    });
  });

  group('computeBracketTops', () {
    test('TC-PLB-05 first column is stacked, next sits between its feeders', () {
      final columns = [
        [_m('a', next: 'c'), _m('b', next: 'c')],
        [_m('c')],
      ];
      final tops = computeBracketTops(columns, _h);
      expect(tops['a'], 0);
      expect(tops['b'], _step);
      expect(tops['c'], _step / 2);
    });

    test('TC-PLB-06 cards never overlap even when feeders pull them together', () {
      final columns = [
        [_m('a', next: 'x'), _m('b', next: 'y')],
        [_m('x'), _m('y')],
      ];
      final tops = computeBracketTops(columns, _h);
      expect(tops['y']! - tops['x']!, greaterThanOrEqualTo(_step));
    });

    test('TC-PLB-07 matches without links are simply stacked', () {
      final columns = [
        [_m('a'), _m('b')],
        [_m('c'), _m('d')],
      ];
      final tops = computeBracketTops(columns, _h);
      expect(tops['c'], 0);
      expect(tops['d'], _step);
    });
  });

  group('computeBracketLinks', () {
    test('TC-PLB-08 links only to visible later columns, blue when finished', () {
      final columns = [
        [_m('a', status: 'COMPLETED', next: 'c', loserNext: 'zzz'), _m('b', next: 'c')],
        [_m('c')],
      ];
      final links = computeBracketLinks(columns);
      expect(links.length, 2);
      final a = links.firstWhere((l) => l.fromId == 'a');
      expect((a.fromColumn, a.toColumn, a.toId), (0, 1, 'c'));
      expect(a.completed, isTrue);
      expect(links.firstWhere((l) => l.fromId == 'b').completed, isFalse);
    });
  });

  group('buildFeeders', () {
    test('TC-PLB-09 lists who feeds a match, winner and loser links', () {
      final feeders = buildFeeders([
        _m('a', next: 'c', code: 'W1'),
        _m('b', loserNext: 'c', code: 'W2'),
        _m('c'),
      ]);
      expect(feeders['c']!.map((f) => (f.code, f.loser)).toList(), [
        ('W1', false),
        ('W2', true),
      ]);
      expect(feeders['a'], isNull);
    });
  });
}
