import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';

void main() {
  test('MatchModel keeps signed ELO deltas returned by the API', () {
    final match = MatchModel.fromJson({
      'id': 'match-1',
      'status': 'COMPLETED',
      'updatedAt': '2026-09-08T00:00:00.000Z',
      'eloStatus': 'APPLIED',
      'eloDelta': {'user-a': 12, 'user-b': -12},
    }, 'match-1');

    expect(match.eloDelta, {'user-a': 12, 'user-b': -12});
    expect(match.eloStatus, 'APPLIED');
  });

  test('club activity does not manufacture a fixed ELO delta', () {
    final source = File(
      'lib/features/community/widgets/club_activity_tab.dart',
    ).readAsStringSync();

    expect(source, contains('eloDelta: sm.eloDelta'));
    expect(source, isNot(contains('?? 16')));
    expect(source, isNot(contains('ELO Delta calculation')));
  });
}
