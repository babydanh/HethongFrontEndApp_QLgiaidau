import 'package:app_quanly_giaidau/data/models/standalone_match_owner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StandaloneMatchOwner', () {
    test('buổi gắn CLB gửi communityId, không gửi socialSessionId', () {
      final owner = StandaloneMatchOwner.forSession(
        communityId: ' c1 ',
        sessionId: 's1',
      );
      expect(owner.communityId, 'c1');
      expect(owner.socialSessionId, isNull);
      expect(owner.toJson(), {'communityId': 'c1'});
      expect(owner.isPersonalSession, isFalse);
    });

    test('buổi cá nhân (communityId null/rỗng) gửi socialSessionId', () {
      for (final cid in <String?>[null, '', '  ']) {
        final owner = StandaloneMatchOwner.forSession(
          communityId: cid,
          sessionId: 's1',
        );
        expect(owner.toJson(), {'socialSessionId': 's1'});
        expect(owner.isPersonalSession, isTrue);
      }
    });

    test('đúng một owner: cả hai hoặc không có đều lỗi', () {
      expect(
        () => StandaloneMatchOwner(communityId: 'c', socialSessionId: 's'),
        throwsArgumentError,
      );
      expect(() => StandaloneMatchOwner(), throwsArgumentError);
      expect(() => StandaloneMatchOwner(communityId: ' '), throwsArgumentError);
    });
  });
}
