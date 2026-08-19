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

  const UserProfileBottomSheet({
    super.key,
    required this.userId,
    this.communityId,
    this.initialFullName,
    this.initialAvatarUrl,
  });

  /// Hiển thị UserProfileBottomSheet dạng Modal BottomSheet.
  static Future<void> show(
    BuildContext context, {
    required String userId,
    String? communityId,
    String? initialFullName,
    String? initialAvatarUrl,
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

  String _formatSystemRole(String? role) {
    if (role == null || role.trim().isEmpty) return 'Vận động viên';
    final r = role.trim().toUpperCase();
    switch (r) {
      case 'ADMIN':
      case 'SUPER_ADMIN':
        return 'Quản trị viên';
      case 'ORGANIZER':
        return 'Ban tổ chức';
      case 'REFEREE':
        return 'Trọng tài';
      case 'LEADER':
      case 'CAPTAIN':
        return 'Trưởng nhóm';
      case 'COACH':
        return 'Huấn luyện viên';
      case 'MEMBER':
      case 'USER':
      case 'PLAYER':
      case 'ATHLETE':
      default:
        return 'Vận động viên';
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
          content: Text('Không thể mở cuộc trò chuyện: $e'),
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
          content: Text('Lỗi khi mở gán danh hiệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
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
                  loading: () => _buildLoadingContent(colors),
                  error: (err, _) => _buildErrorContent(colors, err.toString()),
                  data: (profile) => _buildProfileContent(
                    context,
                    profile,
                    memberTags,
                    tagPresets,
                    clubRole,
                    isViewerAdmin,
                    colors,
                    l10n,
                  ),
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
    AppColorsExtension colors,
    AppLocalizations? l10n,
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
      clubRoleLabel = 'Chủ nhiệm CLB';
      clubRoleColor = const Color(0xFFF59E0B);
    } else if (clubRole == 'MODERATOR' || clubRole == 'ADMIN') {
      clubRoleLabel = 'Ban quản trị';
      clubRoleColor = const Color(0xFF3B82F6);
    } else if (clubRole == 'MEMBER') {
      clubRoleLabel = 'Thành viên CLB';
      clubRoleColor = const Color(0xFF64748B);
    }

    final systemRoleText = _formatSystemRole(null);
    final systemRoleColor = _systemRoleColor(null);

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
                    : (widget.initialFullName ?? 'User'),
                elo: featuredRank?.eloPoints ?? 0,
                tierName: featuredRank?.tierName,
                matchesPlayed: featuredRank?.matchesPlayed ?? 0,
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
                          : (widget.initialFullName ?? 'Người dùng'),
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

        // ─── 3. ELO & MATCH STATS CARD ────────────────────────────
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
              // ELO & Tier banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        featuredRank != null
                            ? '${featuredRank.categoryName} (${featuredRank.tierName ?? 'Xếp hạng'})'
                            : 'Điểm ELO khởi điểm',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    featuredRank != null
                        ? '${featuredRank.eloPoints} ELO'
                        : '1,000 ELO',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: colors.borderLight),
              const SizedBox(height: 10),
              // Match Counts
              Row(
                children: [
                  _statItem(colors, '$totalMatches', 'Tổng trận'),
                  _statItem(
                    colors,
                    '$totalWins',
                    'Thắng',
                    valueColor: const Color(0xFF10B981),
                  ),
                  _statItem(
                    colors,
                    '$totalLosses',
                    'Thua',
                    valueColor: const Color(0xFFEF4444),
                  ),
                  _statItem(
                    colors,
                    '$winRate%',
                    'Tỉ lệ thắng',
                    valueColor: const Color(0xFF3B82F6),
                  ),
                ],
              ),
            ],
          ),
        ),

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
                          'DANH HIỆU CLB',
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
                                    ? 'Sửa nhãn'
                                    : '+ Gán nhãn',
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
                    'Chưa có danh hiệu trong CLB',
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
                  _isOpeningChat ? 'Đang mở...' : 'Nhắn tin',
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
                  Navigator.pop(context);
                  final uri = widget.communityId != null
                      ? '/profile/user/${widget.userId}?communityId=${widget.communityId}'
                      : '/profile/user/${widget.userId}';
                  context.push(uri);
                },
                icon: const Icon(Icons.person_rounded, size: 16),
                label: const Text(
                  'Xem hồ sơ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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

  Widget _buildLoadingContent(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 12),
            Text(
              'Đang tải hồ sơ...',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(AppColorsExtension colors, String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 36, color: colors.error),
          const SizedBox(height: 8),
          Text(
            'Không tải được hồ sơ người dùng',
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
