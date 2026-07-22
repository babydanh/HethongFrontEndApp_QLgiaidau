import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// Tab hiển thị thành tích thi đấu của người dùng.
/// Gồm thống kê tổng quan và danh sách các giải đã đạt thành tích.
class AchievementsTab extends ConsumerWidget {
  const AchievementsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Stats Row ──────────────────────────────────────────────
        _buildStatsRow(context),
        const SizedBox(height: 24),

        // ─── Section Title ──────────────────────────────────────────
        _buildSectionTitle(colors, 'Thành tích gần đây'),
        const SizedBox(height: 12),

        // ─── Achievement Cards ──────────────────────────────────────
        ..._sampleAchievements.map(
          (a) => _AchievementCard(achievement: a),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ─── STATS ROW ──────────────────────────────────────────────────
  Widget _buildStatsRow(BuildContext context) {
    final stats = [
      _StatItem(icon: Icons.emoji_events_rounded, label: 'Giải thắng', value: '3'),
      _StatItem(icon: Icons.sports_soccer_rounded, label: 'Trận đã đá', value: '28'),
      _StatItem(icon: Icons.trending_up_rounded, label: 'ELO tăng', value: '+185'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: stats.map((stat) {
            return Expanded(
              child: Column(
                children: [
                  Icon(stat.icon, color: Colors.white70, size: 22),
                  const SizedBox(height: 8),
                  Text(
                    stat.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── SECTION TITLE ──────────────────────────────────────────────
  Widget _buildSectionTitle(AppColorsExtension colors, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DATA CLASSES ─────────────────────────────────────────────────
class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _AchievementData {
  final IconData icon;
  final Color cardColor;
  final String tournamentName;
  final String date;
  final String eloBoost;
  final String achievementLabel;

  const _AchievementData({
    required this.icon,
    required this.cardColor,
    required this.tournamentName,
    required this.date,
    required this.eloBoost,
    required this.achievementLabel,
  });
}

// Sample data — replace with real API data when backend is ready.
const _sampleAchievements = <_AchievementData>[
  _AchievementData(
    icon: Icons.emoji_events_rounded,
    cardColor: Color(0xFFF59E0B),
    tournamentName: 'Giải Vô Địch Bóng Đá Mùa Xuân 2026',
    date: '15/06/2026',
    eloBoost: '+45 ELO',
    achievementLabel: 'Vô địch',
  ),
  _AchievementData(
    icon: Icons.shield_rounded,
    cardColor: Color(0xFF94A3B8),
    tournamentName: 'Cúp Các CLB Thể Thao 2026',
    date: '20/05/2026',
    eloBoost: '+28 ELO',
    achievementLabel: 'Á quân',
  ),
  _AchievementData(
    icon: Icons.military_tech_rounded,
    cardColor: Color(0xFFCD7F32),
    tournamentName: 'Giải Bóng Đá Thanh Niên 2026',
    date: '10/04/2026',
    eloBoost: '+15 ELO',
    achievementLabel: 'Hạng Ba',
  ),
  _AchievementData(
    icon: Icons.star_rounded,
    cardColor: Color(0xFF3B82F6),
    tournamentName: 'Giải Giao Hữu Mở Rộng 2025',
    date: '22/12/2025',
    eloBoost: '+12 ELO',
    achievementLabel: 'Cầu thủ xuất sắc',
  ),
];

// ─── ACHIEVEMENT CARD ────────────────────────────────────────────
class _AchievementCard extends StatelessWidget {
  final _AchievementData achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          // Icon with gradient background
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  achievement.cardColor,
                  achievement.cardColor.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: achievement.cardColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              achievement.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Tournament info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.tournamentName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      achievement.date,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.trending_up_rounded,
                      size: 12,
                      color: colors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      achievement.eloBoost,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Achievement badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: achievement.cardColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: achievement.cardColor.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              achievement.achievementLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: achievement.cardColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
