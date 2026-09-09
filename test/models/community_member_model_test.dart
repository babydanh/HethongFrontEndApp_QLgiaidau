import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a joined member page item from nested API data', () {
    final member = CommunityMemberModel.fromJson({
      'id': 'membership-1',
      'userId': 'user-1',
      'communityId': 'club-1',
      'role': 'MEMBER',
      'status': 'JOINED',
      'joinedAt': '2026-09-09T08:00:00.000Z',
      'user': {
        'id': 'user-1',
        'fullName': 'Người chơi A',
        'avatarUrl': 'https://example.test/avatar.png',
      },
    });

    const page = CommunityMembersPage(
      items: [],
      nextCursor: 'opaque-cursor',
      hasMore: true,
    );

    expect(member.id, 'membership-1');
    expect(member.userId, 'user-1');
    expect(member.status, 'JOINED');
    expect(member.userFullName, 'Người chơi A');
    expect(member.userAvatarUrl, 'https://example.test/avatar.png');
    expect(page.nextCursor, 'opaque-cursor');
    expect(page.hasMore, isTrue);
  });
}
