import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:flutter_test/flutter_test.dart';

Tournament _tournament({Map<String, dynamic>? contactInfo}) =>
    Tournament.fromJson({
      'name': 'Founder visibility',
      'sport': 'badminton',
      'format': 'SINGLES',
      'bracketType': 'single_elimination',
      'status': 'in_progress',
      'creatorId': 'creator-1',
      'maxTeams': 16,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': '2026-01-01T00:00:00.000Z',
      'contactInfo': ?contactInfo,
    }, 'tournament-1');

void main() {
  group('Tournament.showFounder (mirrors Web isFounderHidden)', () {
    test('is hidden when contactInfo is absent', () {
      expect(_tournament().showFounder, isFalse);
    });

    test('is hidden when hidden flag is missing', () {
      expect(_tournament(contactInfo: {'phone': '0900'}).showFounder, isFalse);
    });

    test('is hidden when hidden is true', () {
      expect(_tournament(contactInfo: {'hidden': true}).showFounder, isFalse);
    });

    test('is shown only when hidden is exactly false', () {
      expect(_tournament(contactInfo: {'hidden': false}).showFounder, isTrue);
      expect(
        _tournament(contactInfo: {'hidden': 'false'}).showFounder,
        isFalse,
      );
    });

    test('is hidden in MANUAL display mode even when hidden is false', () {
      final t = _tournament(
        contactInfo: {'hidden': false, 'displayMode': 'MANUAL'},
      );
      expect(t.showFounder, isFalse);
    });

    test('is shown in PROFILE display mode when hidden is false', () {
      final t = _tournament(
        contactInfo: {'hidden': false, 'displayMode': 'PROFILE'},
      );
      expect(t.showFounder, isTrue);
    });
  });
}
