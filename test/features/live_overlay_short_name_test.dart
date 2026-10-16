import 'package:app_quanly_giaidau/features/match/utils/overlay_team_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shortenSinglePerson', () {
    test('one-word name is uppercased', () {
      expect(shortenSinglePerson('Minh'), 'MINH');
    });

    test('multi-word name keeps first initial and last word', () {
      expect(shortenSinglePerson('Trịnh Quang Minh'), 'T. MINH');
      expect(shortenSinglePerson('Nguyễn Văn An'), 'N. AN');
    });

    test('blank name stays blank', () {
      expect(shortenSinglePerson('   '), '');
    });
  });

  group('shortTeamName', () {
    test('doubles pair separated by a dot keeps both players', () {
      expect(shortTeamName('Việt Mỹ 2 · Việt Mỹ'), 'V. 2 / V. MỸ');
    });

    test('doubles pair separated by a slash keeps both players', () {
      expect(shortTeamName('Nguyễn Văn An / Trần Văn Bình'), 'N. AN / T. BÌNH');
    });

    test('doubles pair separated by a spaced hyphen keeps both players', () {
      expect(shortTeamName('VNDC 1 - VNDC 2'), 'V. 1 / V. 2');
    });

    test('single player is shortened like a person name', () {
      expect(shortTeamName('Trịnh Quang Minh'), 'T. MINH');
    });

    test('blank team stays blank', () {
      expect(shortTeamName('  '), '');
    });
  });
}
