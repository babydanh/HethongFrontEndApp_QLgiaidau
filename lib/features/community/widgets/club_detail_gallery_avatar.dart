part of '../screens/club_detail_screen.dart';

extension _ClubDetailGalleryAvatar on _ClubDetailScreenState {
  /// The club member avatar. Rendering and tapping both belong to
  /// [UserAvatarTap] so a member row leads to the profile exactly like every
  /// other avatar in the app; the club stays the profile's context.
  Widget _buildUserAvatar({
    required String userId,
    required String? name,
    required String? avatarUrl,
    required double radius,
    int? elo,
    String? tierName,
    int matchesPlayed = 0,
  }) {
    final displayName = name?.trim() ?? '';
    final url = avatarUrl?.trim();

    // A missing ranking entry stays neutral: the ring belongs to the shared
    // avatar, and a display fallback such as 1000 must never reach this
    // widget as proof that the member is ranked.
    return UserAvatarTap(
      userId: userId,
      communityId: widget.clubId,
      name: displayName,
      imageUrl: url == null || url.isEmpty ? null : url,
      elo: elo ?? 0,
      tierName: tierName,
      matchesPlayed: matchesPlayed,
      size: radius * 2,
      ringWidth: radius >= 18 ? 2.5 : 2,
      onFilterMatches: _filterClubMatches,
    );
  }

  // ════════════════════════════════════
  //  TAB 6: CÀI ĐẶT (Settings)
  // ════════════════════════════════════
}
