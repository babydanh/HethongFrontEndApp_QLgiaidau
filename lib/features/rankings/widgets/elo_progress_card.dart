import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/elo_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:flutter/material.dart';

/// Card ELO nổi bật dùng lại cho Home/Dashboard/Profile.
///
/// Giữ style hiện tại của app (dark premium card), chỉ bổ sung thông tin web có:
/// rank nổi bật, progress tier, peak ELO, loại đánh và trạng thái khiên.
class EloProgressCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final activeRank = EloHelpers.getBestRankForCategory(rankings);
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: userName, avatarUrl: avatarUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName.isNotEmpty ? userName : 'Người dùng',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (userEmail?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        userEmail!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.58),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (onTapProfile != null)
                IconButton(
                  onPressed: onTapProfile,
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white70,
                  ),
                  tooltip: 'Trang cá nhân',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TIẾN TRÌNH ELO NỔI BẬT',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.52),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeRank == null
                                ? 'Môn thi đấu • Tổng quan'
                                : EloHelpers.getRankDisplayName(activeRank),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
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
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppTheme.primaryLight.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$eloPoints',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
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
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 10,
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
                          color: Colors.white.withValues(alpha: 0.58),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: hasRank ? progress.percent / 100 : 0,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${currentThreshold.minElo}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      nextThreshold == null ? 'MAX' : '${nextThreshold.minElo}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
        color: Colors.white54,
        bg: Colors.white.withValues(alpha: 0.07),
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
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
