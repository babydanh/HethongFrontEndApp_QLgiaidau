import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/match/utils/live_bracket_scope.dart';

MatchModel _match(String id, int round, [String? stageType]) {
  return MatchModel.fromJson({
    'id': id,
    'round': round,
    'status': 'LIVE',
    'stageType': ?stageType,
  }, id);
}

void main() {
  test('keeps only matches of the live match stage, so group and knockout never share columns', () {
    final matches = [
      _match('group-1', 1, 'ROUND_ROBIN'),
      _match('knockout-1', 1, 'SINGLE_ELIMINATION'),
      _match('knockout-2', 2, 'SINGLE_ELIMINATION'),
    ];

    final scoped = liveBracketScope(
      matches,
      _match('current', 1, 'single_elimination'),
    );

    expect(scoped.map((m) => m.id), ['knockout-1', 'knockout-2']);
  });

  test('keeps the whole list when the live match has no stage', () {
    final matches = [
      _match('group-1', 1, 'ROUND_ROBIN'),
      _match('knockout-1', 1, 'SINGLE_ELIMINATION'),
    ];

    final scoped = liveBracketScope(matches, _match('current', 1));

    expect(scoped.map((m) => m.id), ['group-1', 'knockout-1']);
  });

  test('keeps the whole list when no bracket match carries a stage (legacy payload)', () {
    final matches = [_match('a', 1), _match('b', 2)];

    final scoped = liveBracketScope(
      matches,
      _match('current', 1, 'SINGLE_ELIMINATION'),
    );

    expect(scoped.map((m) => m.id), ['a', 'b']);
  });

  test('returns empty when no bracket match shares the live match stage', () {
    final matches = [_match('group-1', 1, 'ROUND_ROBIN')];

    final scoped = liveBracketScope(
      matches,
      _match('current', 1, 'DOUBLE_ELIMINATION'),
    );

    expect(scoped, isEmpty);
  });
}
