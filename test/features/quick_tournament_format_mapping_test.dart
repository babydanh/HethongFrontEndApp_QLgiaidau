import 'package:app_quanly_giaidau/features/tournament/screens/quick_tournament_format_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quick tournament flexible formats', () {
    test('offers flexible singles and doubles for racket sports only', () {
      final racketFormats = quickTournamentFormatOptions(isFootball: false);
      final footballFormats = quickTournamentFormatOptions(isFootball: true);

      expect(racketFormats, containsAll(['OPEN_SINGLES', 'OPEN_DOUBLES']));
      expect(footballFormats, isNot(contains('OPEN_SINGLES')));
      expect(footballFormats, isNot(contains('OPEN_DOUBLES')));
    });

    test('keeps the pre-existing first options as the defaults', () {
      expect(
        quickTournamentFormatOptions(isFootball: false).first,
        'MALE_SINGLES',
      );
      expect(
        quickTournamentFormatOptions(isFootball: true).first,
        'FOOTBALL_MALE',
      );
    });

    test('maps open singles to the singles API contract without gender fields', () {
      expect(quickTournamentApiFormatFields('OPEN_SINGLES'), {
        'format': 'singles',
      });
      expect(quickTournamentDivisionFormatFields('OPEN_SINGLES'), {
        'matchType': 'SINGLES',
      });
    });

    test('maps open doubles to the doubles API contract without gender fields', () {
      expect(quickTournamentApiFormatFields('OPEN_DOUBLES'), {
        'format': 'doubles',
      });
      expect(quickTournamentDivisionFormatFields('OPEN_DOUBLES'), {
        'matchType': 'DOUBLES',
      });
    });

    test('never sends OPEN or MIXED as a flexible division payload', () {
      for (final key in ['OPEN_SINGLES', 'OPEN_DOUBLES']) {
        final payload = {
          ...quickTournamentApiFormatFields(key),
          ...quickTournamentDivisionFormatFields(key),
        };
        expect(payload.containsKey('genderRestriction'), isFalse);
        expect(payload.values, isNot(contains('OPEN')));
        expect(payload.values, isNot(contains('MIXED_DOUBLES')));
      }
    });

    test('keeps the restricted racket formats on their previous contract', () {
      expect(quickTournamentApiFormatFields('MALE_SINGLES'), {
        'format': 'singles',
        'genderRestriction': 'MALE',
      });
      expect(quickTournamentApiFormatFields('FEMALE_SINGLES'), {
        'format': 'singles',
        'genderRestriction': 'FEMALE',
      });
      expect(quickTournamentApiFormatFields('MALE_DOUBLES'), {
        'format': 'doubles',
        'genderRestriction': 'MALE',
      });
      expect(quickTournamentApiFormatFields('FEMALE_DOUBLES'), {
        'format': 'doubles',
        'genderRestriction': 'FEMALE',
      });
      expect(quickTournamentApiFormatFields('MIXED_DOUBLES'), {
        'format': 'doubles',
        'genderRestriction': 'MIXED',
      });

      expect(quickTournamentDivisionFormatFields('MALE_SINGLES'), {
        'matchType': 'SINGLES',
        'genderRestriction': 'MALE',
      });
      expect(quickTournamentDivisionFormatFields('MIXED_DOUBLES'), {
        'matchType': 'MIXED_DOUBLES',
        'genderRestriction': 'MIXED',
      });
    });

    test('keeps the football formats on their previous contract', () {
      for (final entry in {
        'FOOTBALL_MALE': 'MALE',
        'FOOTBALL_FEMALE': 'FEMALE',
        'FOOTBALL_MIXED': 'MIXED',
      }.entries) {
        expect(quickTournamentApiFormatFields(entry.key), {
          'format': 'doubles',
          'genderRestriction': entry.value,
        });
        expect(quickTournamentDivisionFormatFields(entry.key), {
          'matchType': 'DOUBLES',
          'genderRestriction': entry.value,
        });
      }
    });
  });
}