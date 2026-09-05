import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/elo_tier_badge.dart';
import 'package:app_quanly_giaidau/features/community/providers/user_club_rank_provider.dart';
import 'package:app_quanly_giaidau/features/community/widgets/member_tag_chip.dart';
import 'package:app_quanly_giaidau/features/community/widgets/tag_assign_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Bottom sheet xem nhanh hồ sơ người dùng & thành viên CLB (tương đương UserProfilePopover trên Web).
/// Cho phép xem nhanh thông tin, ELO, Danh hiệu CLB, gán tag (nếu là BQT) và nút nhắn tin / xem hồ sơ chi tiết.
class UserProfileBottomSheet extends ConsumerStatefulWidget {
  final String userId;
  final String? communityId;
  final String? initialFullName;
  final String? initialAvatarUrl;
  final void Function(String query)? onFilterMatches;

  const UserProfileBottomSheet({
    super.key,
    required this.userId,
    this.communityId,
    this.initialFullName,
    this.initialAvatarUrl,
    this.onFilterMatches,
  });

  /// Hiển thị UserProfileBottomSheet dạng Modal BottomSheet.
  static Future<void> show(
    BuildContext context, {
    required String userId,
    String? communityId,
    String? initialFullName,
    String? initialAvatarUrl,
    void Function(String query)? onFilterMatches,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserProfileBottomSheet(
        userId: userId,
        communityId: communityId,
        initialFullName: initialFullName,
        initialAvatarUrl: initialAvatarUrl,
        onFilterMatches: onFilterMatches,
      ),
    );
  }

  @override
  ConsumerState<UserProfileBottomSheet> createState() =>
      _UserProfileBottomSheetState();
}

class _UserProfileBottomSheetState
    extends ConsumerState<UserProfileBottomSheet> {
  bool _isOpeningChat = false;

  String _formatSystemRole(AppLocalizations l10n, String? role) {
    if (role == null || role.trim().isEmpty) return l10n.infoPlayer;
    final r = role.trim().toUpperCase();
    switch (r) {
      case 'ADMIN':
      case 'SUPER_ADMIN':
        return l10n.infoAdmin;
      case 'ORGANIZER':
        return l10n.infoOrganizer;
      case 'REFEREE':
        return l10n.infoReferee;
      case 'LEADER':
      case 'CAPTAIN':
        return l10n.infoLeader;
      case 'COACH':
        return l10n.infoCoach;
      case 'MEMBER':
      case 'USER':
      case 'PLAYER':
      case 'ATHLETE':
      default:
        return l10n.infoPlayer;
    }
  }

  Color _systemRoleColor(String? role) {
    final r = (role ?? '').trim().toUpperCase();
    switch (r) {
      case 'ADMIN':
      case 'SUPER_ADMIN':
        return const Color(0xFF8B5CF6); // Purple
      case 'ORGANIZER':
        return const Color(0xFF6366F1); // Indigo
      case 'REFEREE':
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFF0EA5E9); // Sky
    }
  }

  Future<void> _handleDirectChat(BuildContext context, String fullName) async {
    if (_isOpeningChat) return;
    setState(() => _isOpeningChat = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final policyResponse = await dio.get(
        '/chat/direct-policy/${widget.userId}',
      );
      final policyEnvelope = policyResponse.data is Map
          ? Map<String, dynamic>.from(policyResponse.data as Map)
          : <String, dynamic>{};
      final policyData = policyEnvelope['data'] is Map
          ? Map<String, dynamic>.from(policyEnvelope['data'] as Map)
          : policyEnvelope;
      if (policyData['canMessage'] != true) {
        final reasonCode = policyData['reasonCode']?.toString();
        final reason = switch (reasonCode) {
          'BLOCKED' =>
            'Không thể nhắn tin vì một trong hai người đã chặn nhau.',
          'STRANGER_MESSAGES_DISABLED' =>
            'Người dùng này không nhận tin nhắn từ người lạ.',
          'SELF' => 'Bạn không thể tự nhắn tin cho chính mình.',
          _ => 'Không thể mở cuộc trò chuyện lúc này.',
        };
        throw Exception(reason);
      }

      final res = await dio.post(
        '/chat/rooms',
        data: {
          'type': 'DIRECT',
          'memberIds': [widget.userId],
        },
      );
      final roomData = res.data is Map ? (res.data['data'] ?? res.data) : null;
      if (roomData == null || roomData['id'] == null || !context.mounted) {
        return;
      }
      Navigator.pop(context); // Close bottom sheet
      final name = Uri.encodeComponent(fullName);
      context.push('/chat/${roomData['id']}?name=$name');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.userProfileOpenChatError(e.toString()),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  Future<void> _handleOpenTagAssign(
    BuildContext context,
    String memberName,
    List<String> currentTags,
  ) async {
    if (widget.communityId == null) return;
    final communityId = widget.communityId!;
    final repo = ref.read(communityRepositoryProvider);
    try {
      final presets = await repo.getTagPresets(communityId);
      if (!context.mounted) return;
      await TagAssignSheet.show(
        context,
        memberName: memberName,
        currentTags: currentTags,
        presets: presets,
        onSave: (tags) async {
          await repo.updateMemberTags(communityId, widget.userId, tags);
          ref.invalidate(communityMembersProvider(communityId));
          ref.invalidate(communityMemberDirectoryProvider(communityId));
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.userProfileOpenTagError(e.toString()),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(userPublicProfileProvider(widget.userId));

    // Lấy thông tin thành viên CLB nếu có communityId
    final communityId = widget.communityId;
    final memberDirectory = communityId != null
        ? ref.watch(communityMemberDirectoryProvider(communityId)).asData?.value
        : null;
    final tagPresets = communityId != null
        ? ref.watch(communityTagPresetsProvider(communityId)).asData?.value
        : null;
    final myMembership = communityId != null
        ? ref.watch(myCommunityMembershipProvider(communityId)).asData?.value
        : null;

    final memberData = memberDirectory?[widget.userId];
    final memberTags = memberData?.tags ?? const <String>[];
    final clubRole = memberData?.role;

    final isViewerAdmin =
        myMembership != null &&
        (myMembership.role == 'OWNER' || myMembership.role == 'MODERATOR');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── 1. COVER PHOTO & HEADER BAR ──────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Cover Image / Gradient
                  _buildCover(profileAsync.asData?.value.coverUrl, colors),

                  // Drag indicator
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  // Close button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ─── 2. AVATAR & BASIC DETAILS ────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: profileAsync.when(
                  loading: () => _buildLoadingContent(colors, l10n),
                  error: (err, _) =>
                      _buildErrorContent(colors, err.toString(), l10n),
                  data: (profile) {
                    final clubRankInfo = communityId != null
                        ? ref.watch(userClubRankProvider((userId: widget.userId, communityId: communityId))).asData?.value
                        : null;
                    return _buildProfileContent(
                      context,
                      profile,
                      memberTags,
                      tagPresets,
                      clubRole,
                      isViewerAdmin,
                      clubRankInfo,
                      colors,
                      l10n,
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(String? coverUrl, AppColorsExtension colors) {
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: hasCover
            ? null
            : const LinearGradient(
                colors: [
                  Color(0xFF1E1B4B),
                  Color(0xFF312E81),
                  Color(0xFF1E3A8A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: hasCover
          ? Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1E1B4B),
                      Color(0xFF312E81),
                      Color(0xFF1E3A8A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    UserPublicProfile profile,
    List<String> memberTags,
    List<CommunityTagPreset>? tagPresets,
    String? clubRole,
    bool isViewerAdmin,
    UserClubRankInfo? clubRankInfo,
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    final featuredRank = profile.ranks
        .where((r) => r.matchesPlayed > 0)
        .fold<UserPublicRank?>(
          null,
          (best, r) => best == null || r.eloPoints > best.eloPoints ? r : best,
        );

    final totalMatches = profile.ranks.fold<int>(
      0,
      (sum, r) => sum + r.matchesPlayed,
    );
    final totalWins = profile.ranks.fold<int>(
      0,
      (sum, r) => sum + r.matchesWon,
    );
    final totalLosses = totalMatches - totalWins;
    final winRate = totalMatches > 0
        ? (totalWins / totalMatches * 100).round()
        : 0;

    // Community role text
    String? clubRoleLabel;
    Color clubRoleColor = Colors.blue;
    if (clubRole == 'OWNER') {
      clubRoleLabel = l10n.userProfileClubOwnerRole;
      clubRoleColor = const Color(0xFFF59E0B);
    } else if (clubRole == 'MODERATOR' || clubRole == 'ADMIN') {
      clubRoleLabel = l10n.userProfileClubAdminRole;
      clubRoleColor = const Color(0xFF3B82F6);
    } else if (clubRole == 'MEMBER') {
      clubRoleLabel = l10n.userProfileClubMemberRole;
      clubRoleColor = const Color(0xFF64748B);
    }

    final systemRoleText = _formatSystemRole(l10n, null);
    final systemRoleColor = _systemRoleColor(null);

    final inClubContext = widget.communityId != null;
    final clubElo = clubRankInfo?.eloPoints ?? 1000;
    final clubTier = clubRankInfo?.tierName ?? 'Low Tier D';
    final clubMatchesPlayed = clubRankInfo?.matchesPlayed ?? 0;
    final clubMatchesWon = clubRankInfo?.matchesWon ?? 0;
    final clubWinRate = clubMatchesPlayed > 0 ? (clubMatchesWon / clubMatchesPlayed * 100).round() : 0;
    final clubCategory = clubRankInfo?.categoryName ?? 'Pickleball';

    final effectiveElo = inClubContext ? (clubMatchesPlayed > 0 ? clubElo : 1000) : (featuredRank?.eloPoints ?? 1000);
    final effectiveTier = inClubContext ? (clubMatchesPlayed > 0 ? clubTier : 'Low Tier D') : (featuredRank?.tierName ?? 'Low Tier D');
    final effectiveMatchesPlayed = inClubContext ? clubMatchesPlayed : (featuredRank?.matchesPlayed ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar + Badges row
        Transform.translate(
          offset: const Offset(0, -32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RankAvatar(
                imageUrl: profile.avatarUrl ?? widget.initialAvatarUrl,
                name: profile.fullName.isNotEmpty
                    ? profile.fullName
                    : (widget.initialFullName ??
                          l10n.publicProfileUserFallback),
                elo: effectiveElo,
                tierName: effectiveTier,
                matchesPlayed: effectiveMatchesPlayed,
                size: 72,
                ringWidth: 3,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Club role badge
                      if (clubRoleLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: clubRoleColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: clubRoleColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            clubRoleLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: clubRoleColor,
                            ),
                          ),
                        ),

                      // System role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: systemRoleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: systemRoleColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          systemRoleText,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: systemRoleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Name + Verified + Gender
        Transform.translate(
          offset: const Offset(0, -20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      profile.fullName.isNotEmpty
                          ? profile.fullName
                      : (widget.initialFullName ??
                            l10n.publicProfileUserFallback),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (profile.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: Color(0xFF22C55E),
                    ),
                  ],
                  if (profile.gender != null && profile.gender!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(
                      profile.gender == 'Nam'
                          ? Icons.male_rounded
                          : Icons.female_rounded,
                      size: 16,
                      color: colors.textMuted,
                    ),
                  ],
                ],
              ),

              // Bio
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  profile.bio!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // ─── 3. ELO & MATCH STATS CARD (IN CLUB OR WORLD) ────────────
        if (inClubContext) ...[
          // Club Standing HUD (Đồng bộ 100% Web)
          Container(
            margin: const EdgeInsets.only(top: 0, bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgSurface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Badge + ELO points + Streak
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        EloTierBadge(
                          elo: clubElo,
                          tierName: clubTier,
                          categoryName: clubCategory,
                          scale: 0.95,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$clubElo ELO',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (clubRankInfo != null && clubRankInfo.streakCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: clubRankInfo.streakType == 'WIN'
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: clubRankInfo.streakType == 'WIN'
                                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                : const Color(0xFFEF4444).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 13,
                              color: clubRankInfo.streakType == 'WIN'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              clubRankInfo.streakType == 'WIN'
                                  ? 'W${clubRankInfo.streakCount}'
                                  : 'L${clubRankInfo.streakCount}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: clubRankInfo.streakType == 'WIN'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Telemetry 2 columns
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'TRẬN THẮNG',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: colors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$clubMatchesWon / $clubMatchesPlayed',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: colors.borderLight,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'TỶ LỆ THẮNG',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: colors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$clubWinRate%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Nút CTA: Xem các trận trong CLB
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      final name = profile.fullName.isNotEmpty ? profile.fullName : (widget.initialFullName ?? '');
                      if (widget.onFilterMatches != null && name.isNotEmpty) {
                        widget.onFilterMatches!(name);
                      }
                    },
                    icon: const Icon(Icons.emoji_events_rounded, size: 15, color: Color(0xFF3B82F6)),
                    label: const Text(
                      'Xem các trận trong CLB',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colors.bgCard,
                      side: BorderSide(color: colors.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // World Standing Card
          Container(
            margin: const EdgeInsets.only(top: 0, bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgSurface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderLight),
            ),
            child: Column(
              children: [
                if (profile.ranks.isNotEmpty) ...[
                  for (int i = 0; i < profile.ranks.length; i++) ...[
                    if (i > 0) const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            EloTierBadge(
                              elo: profile.ranks[i].eloPoints,
                              tierName: profile.ranks[i].tierName,
                              categoryName: profile.ranks[i].categoryName,
                              scale: 0.9,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              profile.ranks[i].categoryName.isNotEmpty
                                  ? profile.ranks[i].categoryName
                                  : 'Thể thao',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${profile.ranks[i].eloPoints} ${l10n.userProfileElo}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          EloTierBadge(
                            elo: featuredRank?.eloPoints ?? 1000,
                            tierName: featuredRank?.tierName ?? 'Low Tier D',
                            categoryName: featuredRank?.categoryName,
                            scale: 0.9,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            featuredRank?.categoryName ?? l10n.userProfileEloStarting,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${featuredRank?.eloPoints ?? 1000} ${l10n.userProfileElo}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Divider(height: 1, color: colors.borderLight),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statItem(
                      colors,
                      '$totalMatches',
                      l10n.userProfileTotalMatches,
                    ),
                    _statItem(
                      colors,
                      '$totalWins',
                      l10n.userProfileWins,
                      valueColor: const Color(0xFF10B981),
                    ),
                    _statItem(
                      colors,
                      '$totalLosses',
                      l10n.userProfileLosses,
                      valueColor: const Color(0xFFEF4444),
                    ),
                    _statItem(
                      colors,
                      '$winRate%',
                      l10n.userProfileWinRate,
                      valueColor: const Color(0xFF3B82F6),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // ─── 4. CLUB TITLES / TAGS SECTION ─────────────────────────
        if (widget.communityId != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgSurface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.sell_rounded,
                          size: 14,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.userProfileClubTagsTitle,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: colors.textSecondary,
                          ),
                        ),
                        if (memberTags.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${memberTags.length})',
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isViewerAdmin)
                      GestureDetector(
                        onTap: () => _handleOpenTagAssign(
                          context,
                          profile.fullName,
                          memberTags,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.edit_rounded,
                                size: 11,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                memberTags.isNotEmpty
                                    ? l10n.userProfileEditTag
                                    : l10n.userProfileAssignTag,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (memberTags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: memberTags
                        .map(
                          (tag) => PresetTagChip(
                            label: tag,
                            color: tagPresets == null
                                ? null
                                : resolvePresetColor(tagPresets, tag),
                            showDot: true,
                          ),
                        )
                        .toList(growable: false),
                  )
                else
                  Text(
                    l10n.userProfileNoClubTags,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: colors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],

        // ─── 5. ACTION BUTTONS ────────────────────────────────────
        Row(
          children: [
            // Direct Message Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isOpeningChat
                    ? null
                    : () => _handleDirectChat(context, profile.fullName),
                icon: _isOpeningChat
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.chat_bubble_rounded, size: 16),
                label: Text(
                  _isOpeningChat
                      ? l10n.userProfileOpeningChat
                      : l10n.userProfileMessage,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // View Full Profile Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Capture the router before dismissing the modal. Using the
                  // sheet context to push immediately after Navigator.pop can
                  // reuse a disposed route element on the next profile open.
                  final router = GoRouter.of(context);
                  final uri = widget.communityId != null
                      ? '/users/${widget.userId}?communityId=${widget.communityId}'
                      : '/users/${widget.userId}';
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    router.push(uri);
                  });
                },
                icon: const Icon(Icons.person_rounded, size: 16),
                label: Text(
                  l10n.userProfileViewProfile,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(color: colors.border),
                  backgroundColor: colors.bgSurface,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statItem(
    AppColorsExtension colors,
    String value,
    String label, {
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: valueColor ?? colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent(
    AppColorsExtension colors,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 12),
            Text(
              l10n.userProfileLoading,
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(
    AppColorsExtension colors,
    String error,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 36, color: colors.error),
          const SizedBox(height: 8),
          Text(
            l10n.userProfileLoadError,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(fontSize: 11, color: colors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
