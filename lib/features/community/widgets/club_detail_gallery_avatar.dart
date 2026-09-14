part of '../screens/club_detail_screen.dart';

extension _ClubDetailGalleryAvatar on _ClubDetailScreenState {
  Widget _buildUserAvatar({
    required String? name,
    required String? avatarUrl,
    required double radius,
    required Color fallbackColor,
    int? elo,
    String? tierName,
    int matchesPlayed = 0,
  }) {
    final initial = (name?.trim().isNotEmpty == true ? name!.trim()[0] : '?')
        .toUpperCase();
    final url = avatarUrl?.trim();

    // A missing ranking entry stays neutral; a display fallback such as 1000
    // must never be treated as proof that this member is ranked.
    final hasRank =
        (elo != null && elo > 0) ||
        (tierName != null && tierName.trim().isNotEmpty) ||
        matchesPlayed > 0;
    if (hasRank) {
      return RankAvatar(
        imageUrl: url,
        name: name ?? initial,
        elo: elo ?? 0,
        tierName: tierName,
        matchesPlayed: matchesPlayed,
        size: radius * 2,
        ringWidth: radius >= 18 ? 2.5 : 2,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: fallbackColor.withValues(alpha: 0.1),
      child: url == null || url.isEmpty
          ? Text(
              initial,
              style: TextStyle(
                color: fallbackColor,
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.7,
              ),
            )
          : ClipOval(
              child: Image.network(
                url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: fallbackColor,
                      fontWeight: FontWeight.w800,
                      fontSize: radius * 0.7,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ════════════════════════════════════
  //  TAB 6: CÀI ĐẶT (Settings)
  // ════════════════════════════════════
}
