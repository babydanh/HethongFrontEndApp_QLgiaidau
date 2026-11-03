import 'package:app_quanly_giaidau/features/tournament/utils/played_at.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parsePlayedAt', () {
    test('TC-RBR-50 reads date and time typed as dd/mm/yyyy HH:mm', () {
      final parsed = parsePlayedAt('03/11/2026 14:30');
      expect(parsed?.date, '2026-11-03');
      expect(parsed?.time, '14:30');
    });

    test('TC-RBR-51 keeps time null when only a date is typed', () {
      final parsed = parsePlayedAt('03/11/2026');
      expect(parsed?.date, '2026-11-03');
      expect(parsed?.time, isNull);
    });

    test('TC-RBR-52 pads a one-digit hour', () {
      expect(parsePlayedAt('3/1/2026 9:05')?.time, '09:05');
      expect(parsePlayedAt('3/1/2026 9:05')?.date, '2026-01-03');
    });

    test('TC-RBR-53 rejects impossible dates and times', () {
      expect(parsePlayedAt('31/02/2026'), isNull);
      expect(parsePlayedAt('03/11/2026 25:00'), isNull);
      expect(parsePlayedAt('03/11/2026 14:60'), isNull);
      expect(parsePlayedAt('abc'), isNull);
      expect(parsePlayedAt(''), isNull);
    });
  });

  group('formatPlayedAt', () {
    test('TC-RBR-54 formats stored values for the text field', () {
      expect(
        formatPlayedAt((date: '2026-11-03', time: '14:30')),
        '03/11/2026 14:30',
      );
      expect(formatPlayedAt((date: '2026-11-03', time: null)), '03/11/2026');
    });

    test('TC-RBR-55 returns an empty string for an unreadable date', () {
      expect(formatPlayedAt((date: 'oops', time: null)), '');
    });
  });

  group('seedPlayedAt', () {
    test('TC-RBR-56 uses the stored values when present', () {
      final seed = seedPlayedAt(
        playedDate: '2026-11-03',
        playedTime: '14:30',
        today: DateTime(2026, 12, 1),
      );
      expect(seed, (date: '2026-11-03', time: '14:30'));
    });

    test(
      'TC-RBR-57 falls back to today with no time, never a guessed hour',
      () {
        final seed = seedPlayedAt(
          playedDate: null,
          playedTime: null,
          today: DateTime(2026, 12, 1, 18, 45),
        );
        expect(seed, (date: '2026-12-01', time: null));
      },
    );
  });
}
