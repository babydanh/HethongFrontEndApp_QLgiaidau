import 'package:app_quanly_giaidau/data/models/social_session_model.dart';

/// Nguồn của một người trong danh sách thêm vào buổi (như `AddAthleteSource`
/// của Web: FRIENDS, CLUB; thêm `system` cho kết quả tìm toàn hệ thống).
enum SocialPersonSource { friend, club, system }

/// Một dòng người có tài khoản, đã gộp theo `userId`.
class SocialPerson {
  SocialPerson({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required Set<SocialPersonSource> sources,
  }) : sources = {...sources};

  final String userId;
  final String fullName;
  String? avatarUrl;
  final Set<SocialPersonSource> sources;
}

/// Gộp bạn bè + thành viên CLB thành mỗi tài khoản một dòng, giữ thứ tự gặp
/// đầu tiên (port của `mergeAcquaintances` trong Web
/// `src/features/tournaments/add-athlete-acquaintances.ts`). Nguồn sau chỉ
/// bù avatar còn thiếu. Dòng thiếu id hoặc tên bị bỏ.
List<SocialPerson> mergeSocialPeople(
  List<({SocialPersonSource source, List<SocialPerson> items})> lists,
) {
  final byUserId = <String, SocialPerson>{};
  for (final list in lists) {
    for (final item in list.items) {
      if (item.userId.isEmpty || item.fullName.trim().isEmpty) continue;
      final avatar = item.avatarUrl?.trim();
      final hasAvatar = avatar != null && avatar.isNotEmpty;
      final existing = byUserId[item.userId];
      if (existing != null) {
        existing.sources.add(list.source);
        if ((existing.avatarUrl ?? '').isEmpty && hasAvatar) {
          existing.avatarUrl = avatar;
        }
        continue;
      }
      byUserId[item.userId] = SocialPerson(
        userId: item.userId,
        fullName: item.fullName.trim(),
        avatarUrl: hasAvatar ? avatar : null,
        sources: {list.source},
      );
    }
  }
  return byUserId.values.toList(growable: false);
}

/// Web chỉ tìm toàn hệ thống khi tên >= 3 ký tự hoặc là email (có "@").
bool isSearchableSocialTerm(String raw) {
  final term = raw.trim();
  if (term.contains('@')) return term.length >= 2;
  return term.length >= 3;
}

/// Buổi đã kết thúc vẫn cho host thêm người trong khoảng này sau giờ kết thúc
/// dự kiến (khớp Backend `SOCIAL_ADD_PEOPLE_GRACE_MS`).
const socialAddPeopleGrace = Duration(days: 2);

/// Host thêm người được ở mọi trạng thái trừ CANCELLED; buổi COMPLETED chỉ tới
/// 2 ngày sau `startAt + durationMinutes`. Ngoài khoảng đó Backend trả
/// `SESSION_CLOSED`. Việc có phải host hay không do nơi gọi kiểm.
bool canAddSocialPeople(SocialSessionModel session, {DateTime? now}) {
  final status = session.status.toUpperCase();
  if (status == 'CANCELLED') return false;
  if (status != 'COMPLETED') return true;
  final closesAt = session.startAt
      .add(Duration(minutes: session.durationMinutes))
      .add(socialAddPeopleGrace);
  return (now ?? DateTime.now()).isBefore(closesAt);
}

/// userId của các tài khoản đã vào buổi hoặc đang chờ duyệt (không tính khách).
Set<String> joinedUserIds(SocialSessionModel session) => {
  for (final p in [...session.participants, ...session.requestedParticipants])
    if (!p.isGuest && p.userId.isNotEmpty) p.userId,
};

/// Hàng avatar chi tiết buổi: host đứng đầu, tối đa [max] người thật; phần
/// còn lại là [overflow]. Không bịa ô trống hay số "+4".
({List<SocialParticipantModel> shown, int overflow}) previewParticipants(
  List<SocialParticipantModel> participants, {
  int max = 5,
}) {
  final joined = participants
      .where((p) => p.status.toUpperCase() == 'JOINED')
      .toList();
  final ordered = [
    ...joined.where((p) => p.isHost),
    ...joined.where((p) => !p.isHost),
  ];
  final shown = ordered.take(max).toList(growable: false);
  return (shown: shown, overflow: ordered.length - shown.length);
}
