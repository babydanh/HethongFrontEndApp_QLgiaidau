import 'package:app_quanly_giaidau/core/utils/contact_identity.dart';
import 'package:app_quanly_giaidau/domain/entities/add_athlete_candidate.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_lite.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/permission_rows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classifyIdentifier', () {
    test('TC-APP-PHONE-01 input with @ and a domain is an email', () {
      expect(classifyIdentifier('  An@Example.com '), ContactKind.email);
      // No TLD length cap (the old login regex stopped at 4 letters).
      expect(classifyIdentifier('a@club.sports'), ContactKind.email);
    });

    test('TC-APP-PHONE-02 Vietnamese mobile numbers in any written form', () {
      for (final raw in [
        '0987654321',
        '+84987654321',
        '84987654321',
        '098 765 4321',
        '098.765.4321',
        '(098) 765-4321',
      ]) {
        expect(classifyIdentifier(raw), ContactKind.phone, reason: raw);
      }
    });

    test('TC-APP-PHONE-03 anything else is invalid', () {
      for (final raw in [
        '',
        '   ',
        'abc',
        'a@b',
        '@example.com',
        '0123456789', // landline-style prefix
        '098765432', // too short
        '09876543210', // too long
        '+1 415 555 0100',
      ]) {
        expect(classifyIdentifier(raw), ContactKind.invalid, reason: raw);
      }
    });
  });

  group('normalizeVnPhone', () {
    test('TC-APP-PHONE-04 returns E.164 +84 or null', () {
      expect(normalizeVnPhone('098 765 4321'), '+84987654321');
      expect(normalizeVnPhone('84987654321'), '+84987654321');
      expect(normalizeVnPhone('0123456789'), isNull);
      expect(normalizeVnPhone(null), isNull);
    });
  });

  group('maskPhone', () {
    test('TC-APP-PHONE-05 keeps country code, 2 first and 3 last digits', () {
      expect(maskPhone('+84987654321'), '+84 98• ••• 321');
      expect(maskPhone('0987654321'), '+84 98• ••• 321');
    });

    test('TC-APP-PHONE-06 null/empty stay null, unparseable never echoed', () {
      expect(maskPhone(null), isNull);
      expect(maskPhone(''), isNull);
      expect(maskPhone('12345'), '•••');
    });

    test('TC-APP-PHONE-07 a value already masked by the API is kept', () {
      expect(maskPhone('+84 98• ••• 321'), '+84 98• ••• 321');
    });
  });

  group('maskEmail', () {
    test('TC-APP-PHONE-08 keeps first letter and domain', () {
      expect(maskEmail('abc@gmail.com'), 'a••@gmail.com');
      expect(maskEmail('a••@gmail.com'), 'a••@gmail.com');
    });

    test('TC-APP-PHONE-09 null/empty stay null, no @ never echoed', () {
      expect(maskEmail(null), isNull);
      expect(maskEmail(''), isNull);
      expect(maskEmail('not-an-email'), '•••');
      expect(maskEmail('@gmail.com'), '•••');
    });
  });

  group('displayContact', () {
    test('TC-APP-PHONE-10 prefers the masked email, then the masked phone', () {
      expect(
        displayContact(email: 'abc@gmail.com', phone: '0987654321'),
        'a••@gmail.com',
      );
      expect(
        displayContact(email: null, phone: '0987654321'),
        '+84 98• ••• 321',
      );
      expect(
        displayContact(email: '  ', phone: '0987654321'),
        '+84 98• ••• 321',
      );
      expect(displayContact(), '');
    });
  });

  group('UserProfile.fromJson', () {
    test(
      'TC-APP-PHONE-11 reads a phone-only account (email null, login phone)',
      () {
        final user = UserProfile.fromJson({
          'id': 'u1',
          'email': null,
          'phone': '+84987654321',
          'isPhoneVerified': false,
          'profile': {'fullName': 'An', 'phoneNumber': '0987654321'},
        });

        expect(user.email, isNull);
        expect(user.loginPhone, '+84987654321');
        expect(user.phoneNumber, '0987654321');
        expect(user.toJson()['phone'], '+84987654321');
        expect(user.copyWith(fullName: 'B').loginPhone, '+84987654321');
      },
    );
  });

  group('entities without an email', () {
    test('TC-APP-PHONE-12 a missing or blank email parses as null, not ""', () {
      final referee = OrganizerLiteReferee.fromJson({
        'id': 'r1',
        'email': null,
      });
      final candidate = AddAthleteSearchCandidate.fromJson({
        'userId': 'u1',
        'fullName': 'An',
        'email': '',
      });
      final team = Team.fromJson({'name': 'Team A'}, 't1');
      final rows = buildPermissionRows(
        [
          {'userId': 'u1', 'fullName': 'An', 'role': 'CO_ORGANIZER'},
        ],
        [
          {'id': 'r1', 'userId': 'u2', 'fullName': 'Bo', 'email': ' '},
        ],
      );

      expect(referee.email, isNull);
      expect(candidate.email, isNull);
      expect(team.contactEmail, isNull);
      expect(rows.map((row) => row.email), [isNull, isNull]);
    });
  });
}
