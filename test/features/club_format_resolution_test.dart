import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/features/community/screens/create_club_tournament_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('club tournament format', () {
    test('football is always singles because the backend enforces SINGLES', () {
      expect(
        resolveClubFormat(
          sport: 'football',
          selectedFormat: AppConstants.formatDoubles,
        ),
        AppConstants.formatSingles,
      );
    });

    test('mixed doubles is kept, not forced to doubles', () {
      expect(
        resolveClubFormat(
          sport: 'pickleball',
          selectedFormat: AppConstants.formatMixedDoubles,
        ),
        AppConstants.formatMixedDoubles,
      );
    });

    test('racket sports keep the organizer selection', () {
      expect(
        resolveClubFormat(
          sport: 'pickleball',
          selectedFormat: AppConstants.formatSingles,
        ),
        AppConstants.formatSingles,
      );
    });
  });
}
