import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/elo_history_screen.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:app_quanly_giaidau/core/widgets/rank_tier_badge.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_profile_bottom_sheet.dart';
import 'package:app_quanly_giaidau/features/community/widgets/member_tag_chip.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';

/// Trang xem hồ sơ công khai của người dùng khác.
///
/// Gọi API GET /users/:id/public — hiển thị:
/// - Cover photo + Avatar + Tên + Bio + Giới tính + Xác thực
/// - ELO + Thống kê theo từng môn
/// - Tab Thành tích (Quán quân, Á quân, Hạng ba)
/// - Biểu đồ ELO history
class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  /// Ngữ cảnh CLB (khi mở hồ sơ từ bảng tin/chat CLB) — hiển thị thêm
  /// section "Danh hiệu CLB" (tag preset) như popup profile của web.
  final String? communityId;

  const UserProfileScreen({super.key, required this.userId, this.communityId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userPublicProfileProvider(widget.userId));
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      body: profileAsync.when(
        data: (profile) => _buildBody(context, profile, colors),
        loading: () => const _ProfileShimmer(),
        error: (err, _) => _buildError(context, colors, err.toString()),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    UserPublicProfile profile,
    AppColorsExtension colors,
  ) {
    final eligibleRanks = profile.ranks
        .where((rank) => rank.isLeaderboardEligible)
        .toList();
    final canMessage = ref
        .watch(userDirectMessagePolicyProvider(profile.id))
        .asData
        ?.value
        .canMessage ==
        true;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          pinned: true,
          expandedHeight: 240,
          elevation: 0,
          backgroundColor: colors.bgDark,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.bgCard.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: colors.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (canMessage)
              IconButton(
                tooltip: l10n.userProfileMessage,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.bgCard.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_rounded,
                  color: colors.textPrimary,
                  size: 20,
                ),
              ),
                onPressed: () {
                  UserProfileBottomSheet.show(
                    context,
                    userId: profile.id,
                    communityId: widget.communityId,
                    initialFullName: profile.fullName,
                    initialAvatarUrl: profile.avatarUrl,
                  );
                },
              ),
            IconButton(
              tooltip: l10n.publicProfileShareSubtitle,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.bgCard.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.share_rounded,
                  color: colors.textPrimary,
                  size: 20,
                ),
              ),
              onPressed: () {
                AppShareModal.show(
                  context: context,
                  title: profile.fullName,
                  subtitle: profile.bio ?? l10n.publicProfileShareSubtitle,
                  webUrl: 'https://sporto.asia/profile/user/${widget.userId}',
                  imageUrl: profile.avatarUrl,
                  badgeText: l10n.publicProfileShareBadge,
                );
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildCoverSection(context, profile, colors),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: colors.bgDark,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppTheme.primary,
                unselectedLabelColor: colors.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: l10n.publicProfileTabOverview),
                  Tab(text: l10n.publicProfileTabMatches),
                  Tab(text: l10n.publicProfileTabAchievements),
                ],
              ),
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── TAB 1: THÔNG TIN ─────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + Thông tin cơ bản
                _buildUserInfoHeader(context, profile, colors),
                const SizedBox(height: 20),
                // Danh hiệu CLB (tag preset) — chỉ khi mở từ ngữ cảnh CLB
                if (widget.communityId != null) _buildClubTitlesSection(colors),
                // Thống kê tổng quan
                _buildStatsOverview(context, profile, colors),
                const SizedBox(height: 24),
                // Xếp hạng theo môn
                _sectionTitle(colors, l10n.publicProfileRankBySport),
                const SizedBox(height: 12),
                if (eligibleRanks.isEmpty)
                  _buildNoRank(colors)
                else
                  ...eligibleRanks.map(
                    (rank) =>
                        _buildStandardRankCard(context, profile, rank, colors),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _buildMatchesTab(context, profile, colors),
          // ─── TAB 3: DANH HIỆU ─────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thành tích Quán quân / Á quân / Hạng ba
                _buildAchievementsSection(context, profile, colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Danh hiệu CLB" — toàn bộ tag của thành viên, chip màu preset + chấm màu
  /// (khớp popup profile web: UserProfilePopover "Danh hiệu CLB").
  Widget _buildClubTitlesSection(AppColorsExtension colors) {
    final communityId = widget.communityId!;
    final directory = ref
        .watch(communityMemberDirectoryProvider(communityId))
        .asData
        ?.value;
    final presets = ref
        .watch(communityTagPresetsProvider(communityId))
        .asData
        ?.value;
    final tags = directory?[widget.userId]?.tags ?? const <String>[];
    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.bgSurface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.publicProfileClubTitles,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${tags.length} ${l10n.publicProfileTagUnit}',
                  style: TextStyle(fontSize: 10, color: colors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map(
                    (tag) => PresetTagChip(
                      label: tag,
                      color: presets == null
                          ? null
                          : resolvePresetColor(presets, tag),
                      showDot: true,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesTab(
    BuildContext context,
    UserPublicProfile profile,
    AppColorsExtension colors,
  ) {
    final matchesAsync = ref.watch(publicUserMatchesProvider(profile.id));
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: matchesAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, stack) => _buildEmptyPlaceholder(
          colors,
          Icons.sports_tennis_outlined,
          l10n.publicProfileMatchesLoadError,
        ),
        data: (matches) => matches.isEmpty
            ? _buildEmptyPlaceholder(
                colors,
                Icons.sports_tennis_outlined,
                l10n.publicProfileNoPublicMatches,
              )
            : Column(
                children: matches
                    .map((match) => _buildPublicMatchCard(match, colors))
                    .toList(),
              ),
      ),
    );
  }

  Widget _buildPublicMatchCard(MatchModel match, AppColorsExtension colors) {
    final completed =
        match.status.toLowerCase() == 'completed' || match.completedAt != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_circle_outline_rounded
                : Icons.schedule_rounded,
            color: completed ? Colors.green : AppTheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${match.team1Name} ${l10n.matchVsLabel} ${match.team2Name}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${match.tournamentName ?? l10n.publicProfileTournamentFallback}  •  ${completed ? l10n.publicProfileMatchCompleted : l10n.publicProfileMatchUpcoming}',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            '${match.score1} - ${match.score2}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACHIEVEMENTS SECTION ──────────────────────────────────────────
  Widget _buildAchievementsSection(
    BuildContext context,
    UserPublicProfile profile,
    AppColorsExtension colors,
  ) {
    final achievements = List<UserPublicAchievement>.from(profile.achievements)
      ..sort((a, b) => a.rank.compareTo(b.rank));

    final championCategories = achievements.where((a) => a.rank == 1).toList();
    final runnerUpCategories = achievements.where((a) => a.rank == 2).toList();
    final thirdCategories = achievements.where((a) => a.rank == 3).toList();

    // If no real achievements, find categories with most wins
    final hasAchievements =
        championCategories.isNotEmpty ||
        runnerUpCategories.isNotEmpty ||
        thirdCategories.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 20,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.publicProfileAchievementsTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasAchievements)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 40,
                      color: colors.textMuted.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.publicProfileNoAchievements,
                      style: TextStyle(fontSize: 13, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Quán quân
            if (championCategories.isNotEmpty) ...[
              _buildMedalItem(
                colors: colors,
                medal: '🥇',
                title: l10n.publicProfileChampion,
                count: championCategories.length,
                categories: championCategories
                    .map((a) => a.tournamentName)
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Á quân
            if (runnerUpCategories.isNotEmpty) ...[
              _buildMedalItem(
                colors: colors,
                medal: '🥈',
                title: l10n.publicProfileRunnerUp,
                count: runnerUpCategories.length,
                categories: runnerUpCategories
                    .map((a) => a.tournamentName)
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Hạng ba
            if (thirdCategories.isNotEmpty) ...[
              _buildMedalItem(
                colors: colors,
                medal: '🥉',
                title: l10n.publicProfileThirdPlace,
                count: thirdCategories.length,
                categories: thirdCategories
                    .map((a) => a.tournamentName)
                    .toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMedalItem({
    required AppColorsExtension colors,
    required String medal,
    required String title,
    required int count,
    required List<String> categories,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count ${l10n.publicProfileCategoryUnit} · ${categories.take(2).join(', ')}${categories.length > 2 ? '...' : ''}',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── INFO HEADER ────────────────────────────────────────────

  // ─── COVER ──────────────────────────────────────────────────
  Widget _buildCoverSection(
    BuildContext context,
    UserPublicProfile profile,
    AppColorsExtension colors,
  ) {
    final hasCover = profile.coverUrl != null && profile.coverUrl!.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: hasCover
                ? null
                : const LinearGradient(
                    colors: [
                      Color(0xFF1A1A2E),
                      Color(0xFF16213E),
                      Color(0xFF0F3460),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: hasCover
              ? Image.network(
                  profile.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => _coverGradient(),
                )
              : _coverGradient(),
        ),
        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  colors.bgDark.withValues(alpha: 0.9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _coverGradient() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  String _formatUserRole(String? role) {
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

  // ─── USER INFO HEADER ───────────────────────────────────────
  Widget _buildUserInfoHeader(
    BuildContext context,
    UserPublicProfile profile,
    AppColorsExtension colors,
  ) {
    final roleText = _formatUserRole(profile.role);
    final featuredRank = profile.ranks.isEmpty
        ? null
        : (profile.ranks.where((r) => r.isLeaderboardEligible).isNotEmpty
            ? profile.ranks.where((r) => r.isLeaderboardEligible).reduce((a, b) => a.eloPoints > b.eloPoints ? a : b)
            : profile.ranks.reduce((a, b) => a.eloPoints > b.eloPoints ? a : b));
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          RankAvatar(
            imageUrl: profile.avatarUrl,
            name: profile.fullName,
            elo: featuredRank?.eloPoints ?? 0,
            tierName: featuredRank?.tierName,
            matchesPlayed: featuredRank?.matchesPlayed ?? 0,
            size: 80,
            ringWidth: 3,
          ),
          const SizedBox(width: 16),
          // Name + Role + Bio + Gender
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.fullName,
                        style: TextStyle(
                          fontSize: 20,
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
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        roleText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    if (profile.gender != null &&
                        profile.gender!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        profile.gender == 'Nam'
                            ? Icons.male_rounded
                            : Icons.female_rounded,
                        size: 14,
                        color: colors.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        profile.gender!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    profile.bio!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATS OVERVIEW ─────────────────────────────────────────
  Widget _buildStatsOverview(
    BuildContext context,
    UserPublicProfile profile,
    AppColorsExtension colors,
  ) {
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _statItem(colors, '${profile.ranks.length}', l10n.filterSport),
          _statDivider(colors),
          _statItem(colors, '$totalMatches', l10n.publicProfileTotalMatches),
          _statDivider(colors),
          _statItem(colors, '$totalWins', l10n.infoWin),
          _statDivider(colors),
          _statItem(colors, '$totalLosses', l10n.infoLoss),
          _statDivider(colors),
          _statItem(colors, '$winRate%', l10n.publicProfileWinRateShort),
        ],
      ),
    );
  }

  Widget _statItem(AppColorsExtension colors, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider(AppColorsExtension colors) {
    return Container(
      width: 1,
      height: 32,
      color: colors.border.withValues(alpha: 0.5),
    );
  }

  // ─── RANK CARD ──────────────────────────────────────────────
  Widget _buildStandardRankCard(
    BuildContext context,
    UserPublicProfile profile,
    UserPublicRank rank,
    AppColorsExtension colors,
  ) {
    final palette = TierPalette.fromElo(rank.eloPoints, rank.tierName);
    final winRate = rank.matchesPlayed > 0
        ? (rank.matchesWon / rank.matchesPlayed * 100).round()
        : 0;
    final isDoubles = rank.isDoubles;
    final streakType = rank.currentStreakType?.toUpperCase();
    final streakColor = streakType == 'WIN'
        ? const Color(0xFF2563EB)
        : streakType == 'LOSS'
        ? const Color(0xFFDC2626)
        : colors.textMuted;
    final streakText = streakType == 'WIN'
        ? l10n.publicProfileWinStreak(rank.currentStreakCount)
        : streakType == 'LOSS'
        ? l10n.publicProfileLossStreak(rank.currentStreakCount)
        : l10n.publicProfileNoStreak;
    final userName = profile.fullName.isNotEmpty
        ? profile.fullName
        : l10n.publicProfileUserFallback;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.bgCard, colors.bgSurface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EloHistoryScreen(
                  userId: profile.id,
                  userName: userName,
                  avatarUrl: profile.avatarUrl,
                  currentElo: rank.eloPoints,
                  tierName: rank.tierName,
                  categoryId: rank.categoryId,
                  categoryName: rank.categoryName,
                  initialScope: 'PUBLIC',
                  matchType: rank.matchType,
                  genderRestriction: rank.genderRestriction ?? '__NONE__',
                  partnerId: rank.partnerId,
                  lockRatingScope: true,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDoubles
                            ? Icons.people_alt_rounded
                            : Icons.person_rounded,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rank.categoryName.isEmpty
                                ? l10n.publicProfileUserFallback
                                : rank.categoryName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _scopeLabel(rank),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RankTierBadge(
                      tierName: rank.tierName,
                      elo: rank.eloPoints,
                      sportName: rank.categoryName,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: colors.textMuted,
                    ),
                  ],
                ),
                if (isDoubles &&
                    rank.partnerName != null &&
                    rank.partnerName!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.handshake_rounded,
                        size: 15,
                        color: colors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${l10n.publicProfilePartner}: ${rank.partnerName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ELO',
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${rank.eloPoints}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: palette.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statBox(
                      l10n.publicProfileMatchesShort,
                      '${rank.matchesPlayed}',
                      colors,
                    ),
                    _statBox(l10n.infoWin, '${rank.matchesWon}', colors),
                    _statBox(
                      l10n.publicProfileWinRateShort,
                      '$winRate%',
                      colors,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (winRate / 100).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: colors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      winRate >= 60 ? colors.success : palette.color,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: streakColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: streakColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        streakType == 'NONE'
                            ? Icons.remove_circle_outline_rounded
                            : Icons.local_fire_department_rounded,
                        size: 18,
                        color: streakColor,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${l10n.publicProfileCurrentStreak}: $streakText',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: streakColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _scopeLabel(UserPublicRank rank) {
    switch (rank.matchType) {
      case 'DOUBLES':
        return l10n.publicProfileScopeDoubles;
      case 'MIXED_DOUBLES':
        return l10n.publicProfileScopeMixedDoubles;
      default:
        return l10n.publicProfileScopeSingles;
    }
  }

  Widget _statBox(String label, String value, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY / PLACEHOLDER ────────────────────────────────────

  Widget _buildNoRank(AppColorsExtension colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: colors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.publicProfileNoRankData,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(
    AppColorsExtension colors,
    IconData icon,
    String message,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: colors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ────────────────────────────────────────────────
  Widget _sectionTitle(AppColorsExtension colors, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: colors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    AppColorsExtension colors,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              l10n.publicProfileLoadError,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: Text(l10n.publicProfileHomeButton),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SHIMMER ───────────────────────────────────────────────────
class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.border,
      highlightColor: colors.bgSurface,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            flexibleSpace: Container(color: colors.border),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 160,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 100,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
