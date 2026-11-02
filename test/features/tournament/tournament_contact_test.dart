import 'package:app_quanly_giaidau/features/tournament/utils/tournament_contact.dart';
import 'package:flutter_test/flutter_test.dart';

// Fake contact data only.
void main() {
  test('TC-CONTACT-06: links skip phone, email and settings keys', () {
    final links = contactLinks({
      'displayMode': 'MANUAL',
      'organizerName': 'Ban to chuc',
      'hidden': false,
      'phone': '0900000001',
      'email': 'a@example.test',
      'facebook': ' https://facebook.com/example.test ',
      'zalo': '',
    });

    expect(links, {'facebook': 'https://facebook.com/example.test'});
  });

  test(
    'TC-CONTACT-07: links stay public when the profile contact is hidden',
    () {
      final contact = visibleContact({
        'phone': '0900000001',
        'zalo': '0900000009',
      }, isManager: false);

      expect(contact, isNotNull);
      expect(contact!.phone, isEmpty);
      expect(contact.links, {'zalo': '0900000009'});
    },
  );

  test(
    'TC-CONTACT-08: nothing to draw without phone, email, name or links',
    () {
      expect(
        visibleContact({'displayMode': 'MANUAL'}, isManager: true),
        isNull,
      );
      expect(visibleContact({'hidden': false}, isManager: false), isNull);
    },
  );
}
