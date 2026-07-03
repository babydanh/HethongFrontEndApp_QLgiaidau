import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/tier_theme.dart';

/// Trang xem hồ sơ công khai của người dùng khác.
///
/// Gọi API GET /users/:id/public — hiển thị:
/// - Cover photo + Avatar + Tên + Bio + Giới tính + Xác thực
/// - ELO + Thống kê theo từng môn
/// - (Tương lai) CLB đang tham gia, Lịch sử giải đấu
class UserProfileScreen extends ConsumerWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userPublicProfileProvider(userId));
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

  Widget _buildBody(BuildContext context, UserPublicProfile profile, AppColorsExtension colors) {
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
              child: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 20),
            ),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildCoverSection(context, profile, colors),
          ),
        ),
      ],
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + Thông tin cơ bản
            _buildUserInfoHeader(context, profile, colors),
            const SizedBox(height: 20),

            // Thống kê tổng quan
            _buildStatsOverview(context, profile, colors),
            const SizedBox(height: 24),

            // Xếp hạng theo môn
            _sectionTitle(colors, 'Xếp hạng theo bộ môn'),
            const SizedBox(height: 12),
            if (profile.ranks.isEmpty)
              _buildNoRank(colors)
            else
              ...profile.ranks.map((rank) => _buildRankCard(context, rank, colors)),

            const SizedBox(height: 24),

            // CLB đang tham gia (placeholder)
            _sectionTitle(colors, 'Câu lạc bộ'),
            const SizedBox(height: 12),
            _buildEmptyPlaceholder(colors, Icons.people_outline_rounded, 'Chưa tham gia câu lạc bộ'),

            const SizedBox(height: 24),

            // Lịch sử giải đấu (placeholder)
            _sectionTitle(colors, 'Giải đấu đã tham gia'),
            const SizedBox(height: 12),
            _buildEmptyPlaceholder(colors, Icons.emoji_events_outlined, 'Chưa có dữ liệu giải đấu'),
          ],
        ),
      ),
    );
  }

  // ─── COVER ──────────────────────────────────────────────────
  Widget _buildCoverSection(BuildContext context, UserPublicProfile profile, AppColorsExtension colors) {
    final hasCover = profile.coverUrl != null && profile.coverUrl!.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: hasCover
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: hasCover
              ? Image.network(profile.coverUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _coverGradient(),
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
                colors: [Colors.transparent, colors.bgDark.withValues(alpha: 0.9)],
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

  // ─── USER INFO HEADER ───────────────────────────────────────
  Widget _buildUserInfoHeader(BuildContext context, UserPublicProfile profile, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
              boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF161616)),
                child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(37),
                        child: Image.network(profile.avatarUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _avatarFallback(profile.fullName, colors),
                        ),
                      )
                    : _avatarFallback(profile.fullName, colors),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name + Bio + Thông tin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.fullName,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: colors.textPrimary, letterSpacing: -0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF22C55E)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (profile.gender != null && profile.gender!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(profile.gender == 'Nam' ? Icons.male_rounded : Icons.female_rounded, size: 14, color: colors.textMuted),
                        const SizedBox(width: 4),
                        Text(profile.gender!, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                      ],
                    ),
                  ),
                if (profile.bio != null && profile.bio!.isNotEmpty)
                  Text(
                    profile.bio!,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATS OVERVIEW ─────────────────────────────────────────
  Widget _buildStatsOverview(BuildContext context, UserPublicProfile profile, AppColorsExtension colors) {
    final totalMatches = profile.ranks.fold<int>(0, (sum, r) => sum + r.matchesPlayed);
    final totalWins = profile.ranks.fold<int>(0, (sum, r) => sum + r.matchesWon);
    final totalLosses = totalMatches - totalWins;
    final winRate = totalMatches > 0 ? (totalWins / totalMatches * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _statItem(colors, '${profile.ranks.length}', 'Bộ môn'),
          _statDivider(colors),
          _statItem(colors, '$totalMatches', 'Tổng trận'),
          _statDivider(colors),
          _statItem(colors, '$totalWins', 'Thắng'),
          _statDivider(colors),
          _statItem(colors, '$totalLosses', 'Thua'),
          _statDivider(colors),
          _statItem(colors, '$winRate%', 'Tỉ lệ'),
        ],
      ),
    );
  }

  Widget _statItem(AppColorsExtension colors, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statDivider(AppColorsExtension colors) {
    return Container(width: 1, height: 32, color: colors.border.withValues(alpha: 0.5));
  }

  // ─── RANK CARD ──────────────────────────────────────────────
  Widget _buildRankCard(BuildContext context, UserPublicRank rank, AppColorsExtension colors) {
    final tier = TierPalette.matchTier(rank.eloPoints, []);
    final palette = TierPalette.from(tier);
    final wr = rank.matchesPlayed > 0 ? (rank.matchesWon / rank.matchesPlayed * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.bgCard, colors.bgSurface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.sports_tennis_rounded, size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(rank.categoryName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: palette.soft, borderRadius: BorderRadius.circular(8), border: Border.all(color: palette.color.withValues(alpha: 0.3))),
                child: Text(rank.tierName ?? 'Chưa xếp hạng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: palette.color)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ELO', style: TextStyle(fontSize: 10, color: colors.textMuted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${rank.eloPoints}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: palette.color)),
                  ],
                ),
              ),
              _statBox('Trận', '${rank.matchesPlayed}', colors),
              _statBox('Thắng', '${rank.matchesWon}', colors),
              _statBox('Tỉ lệ', '$wr%', colors),
            ],
          ),
          if (rank.matchesPlayed > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (wr / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(wr >= 60 ? colors.success : palette.color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.textPrimary)),
          Text(label, style: TextStyle(fontSize: 9, color: colors.textMuted, fontWeight: FontWeight.w600)),
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
            Icon(Icons.emoji_events_outlined, size: 48, color: colors.textMuted),
            const SizedBox(height: 12),
            Text('Chưa có dữ liệu xếp hạng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(AppColorsExtension colors, IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(AppTheme.radiusLarge), border: Border.all(color: colors.border)),
      child: Column(
        children: [
          Icon(icon, size: 32, color: colors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(fontSize: 13, color: colors.textMuted)),
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
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textSecondary, letterSpacing: 0.3),
      ),
    );
  }

  Widget _avatarFallback(String name, AppColorsExtension colors) {
    return Center(
      child: Text(
        _initials(name),
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: colors.textSecondary),
      ),
    );
  }

  Widget _buildError(BuildContext context, AppColorsExtension colors, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded, size: 48, color: colors.textMuted),
            const SizedBox(height: 16),
            Text('Không thể tải thông tin', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => context.go('/home'), child: const Text('Về trang chủ')),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[p.length - 2][0]}${p[p.length - 1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
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
                      Container(width: 80, height: 80, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 160, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                          const SizedBox(height: 8),
                          Container(width: 100, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                  const SizedBox(height: 24),
                  Container(width: 120, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 12),
                  Container(height: 160, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                  const SizedBox(height: 24),
                  Container(width: 120, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 12),
                  Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
