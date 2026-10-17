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

    test('never locks the whole tournament to one gender', () {
      expect(quickTournamentApiFormatFields('MALE_SINGLES'), {
        'format': 'singles',
      });
      expect(quickTournamentApiFormatFields('FEMALE_SINGLES'), {
        'format': 'singles',
      });
      expect(quickTournamentApiFormatFields('MALE_DOUBLES'), {
        'format': 'doubles',
      });
      expect(quickTournamentApiFormatFields('FEMALE_DOUBLES'), {
        'format': 'doubles',
      });
    });

    test('sends mixed doubles as mixed_doubles with MIXED tournament gender', () {
      expect(quickTournamentApiFormatFields('MIXED_DOUBLES'), {
        'format': 'mixed_doubles',
        'genderRestriction': 'MIXED',
      });
    });

    test('keeps gender restriction on the division for restricted racket formats', () {
      expect(quickTournamentDivisionFormatFields('MALE_SINGLES'), {
        'matchType': 'SINGLES',
        'genderRestriction': 'MALE',
      });
      expect(quickTournamentDivisionFormatFields('FEMALE_DOUBLES'), {
        'matchType': 'DOUBLES',
        'genderRestriction': 'FEMALE',
      });
      expect(quickTournamentDivisionFormatFields('MIXED_DOUBLES'), {
        'matchType': 'MIXED_DOUBLES',
        'genderRestriction': 'MIXED',
      });
    });

    test('maps football formats to singles at tournament level', () {
      expect(quickTournamentApiFormatFields('FOOTBALL_MALE'), {
        'format': 'singles',
      });
      expect(quickTournamentApiFormatFields('FOOTBALL_FEMALE'), {
        'format': 'singles',
      });
      expect(quickTournamentApiFormatFields('FOOTBALL_MIXED'), {
        'format': 'singles',
        'genderRestriction': 'MIXED',
      });
    });

    test('keeps football division gender while the division is singles', () {
      for (final entry in {
        'FOOTBALL_MALE': 'MALE',
        'FOOTBALL_FEMALE': 'FEMALE',
        'FOOTBALL_MIXED': 'MIXED',
      }.entries) {
        expect(quickTournamentDivisionFormatFields(entry.key), {
          'matchType': 'SINGLES',
          'genderRestriction': entry.value,
        });
      }
    });
  });
}
