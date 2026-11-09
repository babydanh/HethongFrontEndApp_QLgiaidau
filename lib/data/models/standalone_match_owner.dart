/// Chủ sở hữu của trận đấu riêng (standalone): đúng MỘT trong hai khoá
/// `communityId` (CLB) hoặc `socialSessionId` (buổi Social cá nhân không gắn
/// CLB). Backend có CHECK XOR cho cặp này.
class StandaloneMatchOwner {
  final String? communityId;
  final String? socialSessionId;

  factory StandaloneMatchOwner({String? communityId, String? socialSessionId}) {
    final c = communityId?.trim();
    final s = socialSessionId?.trim();
    final hasC = c != null && c.isNotEmpty;
    final hasS = s != null && s.isNotEmpty;
    if (hasC == hasS) {
      throw ArgumentError(
        'Cần đúng một trong communityId hoặc socialSessionId.',
      );
    }
    return StandaloneMatchOwner._(hasC ? c : null, hasS ? s : null);
  }

  const StandaloneMatchOwner._(this.communityId, this.socialSessionId);

  /// Buổi có CLB -> theo CLB; buổi không CLB -> theo chính buổi đó (giống Web).
  factory StandaloneMatchOwner.forSession({
    required String? communityId,
    required String sessionId,
  }) {
    final hasClub = (communityId ?? '').trim().isNotEmpty;
    return hasClub
        ? StandaloneMatchOwner(communityId: communityId)
        : StandaloneMatchOwner(socialSessionId: sessionId);
  }

  bool get isPersonalSession => socialSessionId != null;

  /// Dùng làm query lọc danh sách và làm phần owner của body tạo trận.
  Map<String, String> toJson() => {
    'communityId': ?communityId,
    'socialSessionId': ?socialSessionId,
  };
}
