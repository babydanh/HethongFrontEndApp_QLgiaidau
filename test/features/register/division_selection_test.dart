import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:app_quanly_giaidau/features/register/utils/division_selection.dart';
import 'package:flutter_test/flutter_test.dart';

TournamentDivisionOption _division(String id, {String? status}) =>
    TournamentDivisionOption(id: id, name: id, status: status);

void main() {
  group('registration division selection', () {
    test('keeps an explicitly selected active division', () {
      final divisions = [
        _division('active-a', status: 'ACTIVE'),
        _division('active-b', status: 'ACTIVE'),
      ];

      expect(
        resolveRegistrationDivisionId(
          divisions,
          preferredDivisionId: 'active-b',
        ),
        'active-b',
      );
    });

    test('auto-selects the only active division and ignores cancelled ones', () {
      final divisions = [
        _division('cancelled', status: 'CANCELLED'),
        _division('active', status: 'ACTIVE'),
      ];

      expect(resolveRegistrationDivisionId(divisions), 'active');
      expect(activeRegistrationDivisions(divisions), [divisions.last]);
    });

    test('requires explicit choice for multiple active divisions', () {
      final divisions = [
        _division('active-a', status: 'ACTIVE'),
        _division('active-b', status: 'ACTIVE'),
      ];

      expect(resolveRegistrationDivisionId(divisions), isNull);
    });

    test('does not choose a cancelled division', () {
      expect(
        resolveRegistrationDivisionId([
          _division('cancelled', status: 'CANCELLED'),
        ]),
        isNull,
      );
    });
  });
}
