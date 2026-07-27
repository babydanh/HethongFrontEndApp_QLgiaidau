import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses public roster top-level shape', () {
    final member = MatchMemberInfo.fromJson({
      'userId': 'user-1',
      'fullName': 'Nguyễn Văn A',
    });

    expect(member.userId, 'user-1');
    expect(member.fullName, 'Nguyễn Văn A');
  });

  test('parses nested user fallback shape', () {
    final member = MatchMemberInfo.fromJson({
      'user': {'id': 'user-2', 'fullName': 'Trần Văn B'},
    });

    expect(member.userId, 'user-2');
    expect(member.fullName, 'Trần Văn B');
  });

  test('top-level roster identity takes precedence', () {
    final member = MatchMemberInfo.fromJson({
      'userId': 'top-level',
      'fullName': 'Tên chính',
      'user': {'id': 'nested', 'fullName': 'Tên nested'},
    });

    expect(member.userId, 'top-level');
    expect(member.fullName, 'Tên chính');
  });
}
