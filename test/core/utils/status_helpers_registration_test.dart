import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  group('tournament status mapping', () {
    test('only REGISTRATION_OPEN counts as open for registration', () {
      expect(
        StatusHelper.normalizeTournamentStatus('REGISTRATION_OPEN'),
        AppConstants.statusRegistration,
      );
    });

    test('does not guess registration from legacy aliases or substrings', () {
      for (final raw in [
        'PUBLISHED',
        'ACTIVE',
        'OPEN',
        'REGISTRATION',
        'REGISTER_OPEN',
        'MY_OPEN_THING',
      ]) {
        expect(
          StatusHelper.normalizeTournamentStatus(raw),
          isNot(AppConstants.statusRegistration),
          reason: raw,
        );
      }
    });

    test('keeps unknown values verbatim in lowercase and blank as upcoming', () {
      expect(
        StatusHelper.normalizeTournamentStatus('MY_OPEN_THING'),
        'my_open_thing',
      );
      expect(
        StatusHelper.normalizeTournamentStatus(null),
        AppConstants.statusUpcoming,
      );
      expect(
        StatusHelper.normalizeTournamentStatus('   '),
        AppConstants.statusUpcoming,
      );
    });

    test('labels unknown values with their raw text, not the upcoming label', () {
      expect(
        StatusHelper.getTournamentStatusLabel('REGISTRATION_OPEN', l10n: l10n),
        l10n.statusLabelRegistration,
      );
      expect(
        StatusHelper.getTournamentStatusLabel('MY_OPEN_THING', l10n: l10n),
        'my_open_thing',
      );
    });
  });
}
