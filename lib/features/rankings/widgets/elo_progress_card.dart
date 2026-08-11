import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/elo_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:flutter/material.dart';

/// Card ELO nổi bật dùng lại cho Home/Dashboard/Profile.
///
/// Giữ style hiện tại của app (dark premium card), chỉ bổ sung thông tin web có:
/// rank nổi bật, progress tier, peak ELO, loại đánh và trạng thái khiên.
class EloProgressCard extends StatefulWidget {
  final String userName;
  final String? userEmail;
  final String? avatarUrl;
  final List<PlayerRanking> rankings;
  final VoidCallback? onTapProfile;

  const EloProgressCard({
    super.key,
    required this.userName,
    this.userEmail,
    this.avatarUrl,
    required this.rankings,
    this.onTapProfile,
  });

  @override
  State<EloProgressCard> createState() => _EloProgressCardState();
}

class _EloProgressCardState extends State<EloProgressCard> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categoryOptions = <String, String>{
      for (final rank in widget.rankings)
        if (rank.categoryId != null && rank.categoryName != null)
          rank.categoryId!: rank.categoryName!,
    };
    final activeRanks = _selectedCategoryId == null
        ? widget.rankings
        : widget.rankings.where((rank) => rank.categoryId == _selectedCategoryId).toList();
    final activeRank = EloHelpers.getBestRankForCategory(activeRanks);
    final hasRank = activeRank != null && activeRank.matchesPlayed > 0;
    final eloPoints = activeRank?.eloPoints ?? 1000;
    final matchesPlayed = activeRank?.matchesPlayed ?? 0;
    final matchesWon = activeRank?.matchesWon ?? 0;
    final winRate = EloHelpers.getRankWinRate(activeRank);
    final peakElo = activeRank?.peakElo ?? eloPoints;
    final progress = EloHelpers.getEloProgressInfo(eloPoints);
    final currentThreshold = EloHelpers.thresholds[progress.currentIndex];
    final nextThreshold = progress.nextIndex == null
        ? null
        : EloHelpers.thresholds[progress.nextIndex!];
    final shield = EloHelpers.getShieldStatus(activeRank);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: widget.userName, avatarUrl: widget.avatarUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName.isNotEmpty ? widget.userName : 'Người dùng',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.userEmail?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.userEmail!,
                        style: TextStyle(
                          color: context.colors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.onTapProfile != null)
                IconButton(
                  onPressed: widget.onTapProfile,
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.textMuted,
                  ),
                  tooltip: 'Trang cá nhân',
                ),
            ],
          ),
          if (categoryOptions.length > 1) ...[
            const SizedBox(height: 10),
            Text(
              'Môn xếp hạng',
              style: TextStyle(
                color: context.colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...categoryOptions.entries.map(
                  (entry) => ChoiceChip(
                    label: Text(entry.value),
                    selected: _selectedCategoryId == entry.key,
                    onSelected: (_) => setState(() => _selectedCategoryId = entry.key),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TIẾN TRÌNH ELO NỔI BẬT',
                            style: TextStyle(
                              color: context.colors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeRank == null
                                ? 'Môn thi đấu • Tổng quan'
                                : EloHelpers.getRankDisplayName(activeRank),
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$eloPoints ELO',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hasRank ? currentThreshold.name : '1000',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        hasRank
                            ? progress.label
                            : EloHelpers.getOnboardingCopy(),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: context.colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: hasRank ? progress.percent / 100 : 0,
                    minHeight: 6,
                    backgroundColor: context.colors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${currentThreshold.minElo}',
                      style: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      nextThreshold == null ? 'MAX' : '${nextThreshold.minElo}',
                      style: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ShieldRow(status: shield),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatChip(label: 'Trận', value: '$matchesPlayed'),
              const SizedBox(width: 8),
              _StatChip(label: 'Thắng', value: '$matchesWon'),
              const SizedBox(width: 8),
              _StatChip(label: 'Tỉ lệ', value: '$winRate%'),
              const SizedBox(width: 8),
              _StatChip(label: 'Peak', value: '$peakElo'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const _Avatar({required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppTheme.primary.withValues(alpha: 0.20),
      backgroundImage: avatarUrl?.isNotEmpty == true
          ? NetworkImage(avatarUrl!)
          : null,
      child: avatarUrl?.isNotEmpty == true
          ? null
          : Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}

class _ShieldRow extends StatelessWidget {
  final ShieldStatus status;

  const _ShieldRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = switch (status.state) {
      ShieldState.active => (
        icon: Icons.verified_user_rounded,
        color: context.colors.success,
        bg: context.colors.success.withValues(alpha: 0.13),
      ),
      ShieldState.broken => (
        icon: Icons.shield_outlined,
        color: context.colors.warning,
        bg: context.colors.warning.withValues(alpha: 0.13),
      ),
      ShieldState.onboarding => (
        icon: Icons.shield_outlined,
        // This card is rendered on the light surface used by “Của tôi”.
        // White onboarding text was effectively invisible there.
        color: context.colors.textSecondary,
        bg: context.colors.bgCard,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: config.color, size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              status.copy,
              style: TextStyle(
                color: config.color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: context.colors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: context.colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
