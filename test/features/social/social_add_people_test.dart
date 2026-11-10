import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/features/social/logic/social_add_people.dart';
import 'package:flutter_test/flutter_test.dart';

SocialPerson p(String id, String name, {String? avatar}) => SocialPerson(
  userId: id,
  fullName: name,
  avatarUrl: avatar,
  sources: const {},
);

void main() {
  group('mergeSocialPeople', () {
    test('gộp một tài khoản có ở bạn bè và CLB, giữ thứ tự, bù avatar', () {
      final merged = mergeSocialPeople([
        (
          source: SocialPersonSource.friend,
          items: [p('a', 'An'), p('b', 'Bình')],
        ),
        (
          source: SocialPersonSource.club,
          items: [p('b', 'Bình', avatar: 'https://x/b.png'), p('c', 'Cường')],
        ),
      ]);
      expect(merged.map((e) => e.userId), ['a', 'b', 'c']);
      expect(merged[1].sources, {
        SocialPersonSource.friend,
        SocialPersonSource.club,
      });
      expect(merged[1].avatarUrl, 'https://x/b.png');
      expect(merged[0].sources, {SocialPersonSource.friend});
    });

    test('bỏ dòng thiếu id hoặc tên', () {
      final merged = mergeSocialPeople([
        (source: SocialPersonSource.club, items: [p('', 'X'), p('d', '  ')]),
      ]);
      expect(merged, isEmpty);
    });
  });

  group('isSearchableSocialTerm', () {
    test('tên cần >= 3 ký tự, email có @ tìm được', () {
      expect(isSearchableSocialTerm('An'), isFalse);
      expect(isSearchableSocialTerm(' ANH '), isTrue);
      expect(isSearchableSocialTerm('a@'), isTrue);
      expect(isSearchableSocialTerm('@'), isFalse);
    });
  });

  group('previewParticipants', () {
    SocialParticipantModel part(String id, {String role = 'PLAYER'}) =>
        SocialParticipantModel(
          id: id,
          userId: id,
          fullName: 'N$id',
          role: role,
          joinedAt: DateTime(2026, 11, 9),
        );

    test('host đứng đầu, cắt theo max, overflow là số người thật còn lại', () {
      final participants = [
        part('1'),
        part('2'),
        part('h', role: 'HOST'),
        part('3'),
      ];
      final preview = previewParticipants(participants, max: 3);
      expect(preview.shown.map((e) => e.id), ['h', '1', '2']);
      expect(preview.overflow, 1);
    });

    test('không có ai thì rỗng, không bịa ô trống', () {
      final preview = previewParticipants(const [], max: 5);
      expect(preview.shown, isEmpty);
      expect(preview.overflow, 0);
    });
  });

  group('canAddSocialPeople', () {
    final startAt = DateTime(2026, 11, 9, 19, 30);
    final end = startAt.add(const Duration(minutes: 120));
    SocialSessionModel session(String status) => SocialSessionModel(
      id: 's1',
      hostUserId: 'h',
      title: 'Giao lưu',
      playFormat: 'Giao lưu',
      startAt: startAt,
      durationMinutes: 120,
      venueName: 'Sân A',
      venueAddress: '1 Đường B',
      sport: 'PICKLEBALL',
      sportName: 'Pickleball',
      status: status,
    );

    test('OPEN và FULL thêm được lúc nào cũng được', () {
      final during = end.subtract(const Duration(hours: 1));
      expect(canAddSocialPeople(session('OPEN'), now: during), isTrue);
      expect(canAddSocialPeople(session('FULL'), now: during), isTrue);
    });

    test('CANCELLED không bao giờ thêm được', () {
      expect(canAddSocialPeople(session('CANCELLED'), now: end), isFalse);
    });

    test('COMPLETED thêm được tới 2 ngày sau giờ kết thúc, từ mốc đó thì không', () {
      final s = session('completed');
      expect(canAddSocialPeople(s, now: end.add(const Duration(hours: 1))), isTrue);
      expect(
        canAddSocialPeople(
          s,
          now: end.add(const Duration(days: 2)).subtract(const Duration(milliseconds: 1)),
        ),
        isTrue,
      );
      expect(
        canAddSocialPeople(s, now: end.add(const Duration(days: 2))),
        isFalse,
      );
    });
  });
}
