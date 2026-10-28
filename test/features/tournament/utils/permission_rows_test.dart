import 'package:app_quanly_giaidau/features/tournament/utils/permission_rows.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _referee(String status, {String id = 'r1'}) => {
  'id': id,
  'userId': 'u-$id',
  'status': status,
  'fullName': 'Trong Tai',
  'email': 'ref@example.test',
};

void main() {
  group('buildPermissionRows', () {
    test('maps referee status to the action offered', () {
      final rows = buildPermissionRows(const [], [
        _referee('INVITED', id: 'a'),
        _referee('DECLINED', id: 'b'),
        _referee('ACCEPTED', id: 'c'),
        _referee('WEIRD', id: 'd'),
      ]);
      expect(rows.map((r) => r.action), [
        RefereeAction.revoke,
        RefereeAction.resend,
        RefereeAction.none,
        RefereeAction.none,
      ]);
      expect(rows.every((r) => r.role == 'REFEREE'), isTrue);
      expect(rows.first.refereeId, 'a');
      expect(rows.first.email, 'ref@example.test');
    });

    test('staff rows keep their role and carry no status or action', () {
      final rows = buildPermissionRows([
        {'userId': 'u1', 'fullName': 'An', 'role': 'CO_ORGANIZER'},
        {'userId': 'u2', 'name': 'Binh', 'role': 'SPECTATOR'},
      ], const []);
      expect(rows.map((r) => r.role), ['CO_ORGANIZER', 'SPECTATOR']);
      expect(rows.every((r) => r.status == null), isTrue);
      expect(rows.every((r) => r.action == RefereeAction.none), isTrue);
      expect(rows.first.userId, 'u1');
    });

    test('empty lists give empty result', () {
      expect(buildPermissionRows(const [], const []), isEmpty);
    });

    test('missing name does not throw and yields empty name', () {
      final rows = buildPermissionRows(
        [
          {'userId': 'u1', 'role': 'SPECTATOR'},
        ],
        [
          {'id': 'r1', 'status': 'INVITED'},
        ],
      );
      expect(rows.map((r) => r.name), ['', '']);
    });

    test('reads nested user object for name and id', () {
      final rows = buildPermissionRows([
        {
          'role': 'SPECTATOR',
          'user': {'id': 'u9', 'fullName': 'Chi'},
        },
      ], const []);
      expect(rows.single.name, 'Chi');
      expect(rows.single.userId, 'u9');
    });
  });
}
