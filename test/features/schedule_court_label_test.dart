import 'package:app_quanly_giaidau/features/tournament/utils/schedule_court_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatCourtShortName', () {
    test('strips the leading "Sân" word', () {
      expect(formatCourtShortName('Sân 1'), '1');
      expect(formatCourtShortName('  sân   12 '), '12');
      expect(formatCourtShortName('SÂN A'), 'A');
    });

    test('keeps names without the prefix unchanged', () {
      expect(formatCourtShortName('Trung tâm'), 'Trung tâm');
      expect(formatCourtShortName('Court 4'), 'Court 4');
      expect(formatCourtShortName('Sânvườn'), 'Sânvườn');
    });

    test('falls back to the trimmed original when nothing is left', () {
      expect(formatCourtShortName('Sân'), 'Sân');
      expect(formatCourtShortName('  '), '');
      expect(formatCourtShortName(null), '');
    });
  });

  group('courtChipColors', () {
    test('wraps around after the eighth court', () {
      expect(courtChipColors(8), courtChipColors(0));
      expect(courtChipColors(9), courtChipColors(1));
    });

    test('gives the first eight courts distinct tints', () {
      final tints = {for (var i = 0; i < 8; i++) courtChipColors(i).background};
      expect(tints.length, 8);
    });

    test('accepts a negative index without throwing', () {
      expect(courtChipColors(-1), courtChipColors(7));
    });
  });
}
