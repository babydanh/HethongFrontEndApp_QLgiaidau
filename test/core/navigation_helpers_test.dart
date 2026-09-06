import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';

void main() {
  test('live match route preserves tournament context', () {
    expect(
      NavigationHelper.getLiveMatchRoute('tournament-1', 'match-1'),
      '/live/match-1?tournamentId=tournament-1',
    );
  });

  test('live match route omits empty tournament context', () {
    expect(NavigationHelper.getLiveMatchRoute('', 'match-1'), '/live/match-1');
  });
}
