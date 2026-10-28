import 'package:app_quanly_giaidau/features/tournament/utils/tournament_contact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('visibleContact', () {
    test('null info draws nothing', () {
      expect(visibleContact(null, isManager: false), isNull);
      expect(visibleContact(null, isManager: true), isNull);
    });

    test('MANUAL shows name and phone, never email, with no hidden flag', () {
      final contact = visibleContact({
        'displayMode': 'MANUAL',
        'organizerName': 'Ban to chuc A',
        'phone': '0900000000',
        'email': 'a@example.test',
      }, isManager: false);

      expect(contact, isNotNull);
      expect(contact!.organizerName, 'Ban to chuc A');
      expect(contact.phone, '0900000000');
      expect(contact.email, isEmpty);
      expect(contact.hiddenFromViewers, isFalse);
    });

    test('PROFILE with hidden:false shows phone and email', () {
      final contact = visibleContact({
        'displayMode': 'PROFILE',
        'hidden': false,
        'phone': '0900000000',
        'email': 'a@example.test',
      }, isManager: false);

      expect(contact!.phone, '0900000000');
      expect(contact.email, 'a@example.test');
      expect(contact.hiddenFromViewers, isFalse);
    });

    test('PROFILE without the flag is hidden from viewers', () {
      final info = {'displayMode': 'PROFILE', 'phone': '0900000000'};
      expect(visibleContact(info, isManager: false), isNull);
    });

    test('a missing displayMode behaves like PROFILE', () {
      final info = {'phone': '0900000000'};
      expect(visibleContact(info, isManager: false), isNull);
      expect(
        visibleContact({...info, 'hidden': false}, isManager: false)!.phone,
        '0900000000',
      );
    });

    test('PROFILE hidden:true still shows to a manager, marked as hidden', () {
      final contact = visibleContact({
        'displayMode': 'PROFILE',
        'hidden': true,
        'phone': '0900000000',
        'email': 'a@example.test',
      }, isManager: true);

      expect(contact!.phone, '0900000000');
      expect(contact.email, 'a@example.test');
      expect(contact.hiddenFromViewers, isTrue);
    });

    test('displayMode is case-insensitive', () {
      final contact = visibleContact({
        'displayMode': 'manual',
        'organizerName': 'Ban to chuc A',
        'phone': '0900000000',
      }, isManager: false);
      expect(contact, isNotNull);
    });

    test('blank and wrongly typed values count as empty', () {
      expect(
        visibleContact({
          'hidden': false,
          'phone': '   ',
          'email': 12345,
        }, isManager: true),
        isNull,
      );
      expect(
        visibleContact({
          'displayMode': 'MANUAL',
          'organizerName': true,
          'phone': const <String>[],
        }, isManager: false),
        isNull,
      );
    });

    test('values are trimmed', () {
      final contact = visibleContact({
        'hidden': false,
        'phone': ' 0900000000 ',
      }, isManager: false);
      expect(contact!.phone, '0900000000');
    });
  });
}
