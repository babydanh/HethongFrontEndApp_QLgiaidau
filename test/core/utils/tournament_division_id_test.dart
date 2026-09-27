import 'package:app_quanly_giaidau/core/utils/tournament_division_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('persistedTournamentDivisionId', () {
    test('omits synthetic default division identifiers', () {
      expect(persistedTournamentDivisionId('default_tournament-1'), isNull);
    });

    test('preserves a persisted division identifier exactly', () {
      expect(persistedTournamentDivisionId('division-42'), 'division-42');
    });

    test('omits missing division identifiers', () {
      expect(persistedTournamentDivisionId(null), isNull);
      expect(persistedTournamentDivisionId(''), isNull);
    });
  });
}
