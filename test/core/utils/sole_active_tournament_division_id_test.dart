import 'package:app_quanly_giaidau/core/utils/tournament_division_id.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:flutter_test/flutter_test.dart';

TournamentDivision _division(
  String id, {
  String matchType = 'SINGLES',
  String? status,
  String? genderRestriction,
}) => TournamentDivision(
  id: id,
  name: id,
  matchType: matchType,
  status: status,
  genderRestriction: genderRestriction,
);

void main() {
  group('soleActiveTournamentDivisionId', () {
    test('returns the id when the tournament has exactly one active division', () {
      expect(
        soleActiveTournamentDivisionId([
          _division('division-1', status: 'REGISTRATION_OPEN'),
        ]),
        'division-1',
      );
    });

    test('treats a missing status as an active division', () {
      expect(
        soleActiveTournamentDivisionId([_division('division-1')]),
        'division-1',
      );
    });

    test('ignores cancelled divisions', () {
      expect(
        soleActiveTournamentDivisionId([
          _division('division-1', status: 'REGISTRATION_OPEN'),
          _division('division-2', status: 'cancelled'),
        ]),
        'division-1',
      );
    });

    test('refuses to guess when several divisions are active', () {
      expect(
        soleActiveTournamentDivisionId([
          _division('division-1', status: 'REGISTRATION_OPEN'),
          _division('division-2', status: 'REGISTRATION_OPEN'),
        ]),
        isNull,
      );
    });

    test('never returns a synthetic default division id', () {
      expect(
        soleActiveTournamentDivisionId([_division('default_tournament-1')]),
        isNull,
      );
      expect(
        soleActiveTournamentDivisionId([
          _division('default_tournament-1'),
          _division('division-1', status: 'REGISTRATION_OPEN'),
        ]),
        'division-1',
      );
    });

    test('returns null for a tournament without divisions', () {
      expect(soleActiveTournamentDivisionId(const []), isNull);
    });
  });
}