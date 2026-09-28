import 'package:app_quanly_giaidau/features/register/doubles_registration_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoublesRegistrationMember.fromParticipantJson', () {
    test('returns both roster names and roles in server order', () {
      final members = DoublesRegistrationMember.fromParticipantJson({
        'members': [
          {'userId': 'captain', 'fullName': '  Lan Nguyen ', 'role': 'MAIN'},
          {'userId': 'partner', 'fullName': 'Minh Tran', 'role': 'SUB'},
        ],
      });

      expect(members.map((member) => member.fullName), [
        'Lan Nguyen',
        'Minh Tran',
      ]);
      expect(members.map((member) => member.role), ['MAIN', 'SUB']);
    });

    test(
      'falls back to legacy teamMembers when members is absent or empty',
      () {
        final members = DoublesRegistrationMember.fromParticipantJson({
          'members': const [],
          'teamMembers': [
            {'fullName': 'Player One', 'role': 'MAIN'},
            {'fullName': 'Player Two', 'role': 'SUB'},
          ],
        });

        expect(members.map((member) => member.fullName), [
          'Player One',
          'Player Two',
        ]);
      },
    );

    test('ignores invalid rows and blank names', () {
      final members = DoublesRegistrationMember.fromParticipantJson({
        'members': [
          {'fullName': '   ', 'role': 'SUB'},
          {'role': 'MAIN'},
          'not-a-roster-row',
        ],
      });

      expect(members, isEmpty);
    });
  });
}
