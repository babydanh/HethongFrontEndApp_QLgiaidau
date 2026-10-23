import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:app_quanly_giaidau/features/register/utils/division_selection.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
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

    test(
      'auto-selects the only active division and ignores cancelled ones',
      () {
        final divisions = [
          _division('cancelled', status: 'CANCELLED'),
          _division('active', status: 'ACTIVE'),
        ];

        expect(resolveRegistrationDivisionId(divisions), 'active');
        expect(activeRegistrationDivisions(divisions), [divisions.last]);
      },
    );

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
    test('TC-APP-LIFECYCLE-01: cancelled division never opens', () {
      final division = TournamentDivisionOption(
        id: 'cancelled',
        name: 'Cancelled',
        status: 'CANCELLED',
        registrationOpen: true,
      );

      expect(isRegistrationDivisionActive(division), isFalse);
      expect(registrationDivisionOptions([division]), isEmpty);
    });

    test(
      'TC-APP-LIFECYCLE-02: open division remains open during tournament',
      () {
        final openDivision = TournamentDivisionOption(
          id: 'open',
          name: 'Open',
          status: 'ACTIVE',
          registrationOpen: true,
        );
        final closedDivision = TournamentDivisionOption(
          id: 'closed',
          name: 'Closed',
          status: 'ACTIVE',
          registrationOpen: false,
        );

        expect(activeRegistrationDivisions([openDivision, closedDivision]), [
          openDivision,
        ]);
        expect(resolveRegistrationDivisionId([openDivision]), 'open');
      },
    );

    test(
      'TC-APP-LIFECYCLE-03: server without registrationOpen uses deadline fallback',
      () {
        final open = TournamentDivisionOption(
          id: 'legacy-open',
          name: 'Legacy open',
          effectiveRegistrationEndDate: DateTime(2099),
        );
        final closed = TournamentDivisionOption(
          id: 'legacy-closed',
          name: 'Legacy closed',
          effectiveRegistrationEndDate: DateTime(2000),
        );

        expect(isRegistrationDivisionActive(open), isTrue);
        expect(isRegistrationDivisionActive(closed), isFalse);
      },
    );
    test('shows a localized explanation for closed divisions', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('vi'));
      final division = TournamentDivisionOption(
        id: 'locked',
        name: 'Locked',
        registrationOpen: false,
        registrationClosedReason: 'DIVISION_LOCKED',
      );

      expect(
        registrationDivisionClosedReasonLabel(l10n, division),
        l10n.registerDivisionLocked,
      );
    });
  });
}
