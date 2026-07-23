import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// Tab hiển thị thành tích thi đấu của người dùng.
class AchievementsTab extends ConsumerWidget {
  final String selectedSport;
  const AchievementsTab({super.key, this.selectedSport = 'all'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    final filteredAchievements = _sampleAchievements.where((a) {
      if (selectedSport == 'all') return true;
      return a.sportId == selectedSport;
    }).toList();

    final wins = filteredAchievements.where((a) => a.achievementLabel == 'Vô địch').length;
    final totalMatches = filteredAchievements.length * 7;
    final totalEloGain = filteredAchievements.fold<int>(0, (sum, a) => sum + a.eloNumber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Stats Row (Compact) ──────────────────────────────────────────
        _buildStatsRow(context, wins: wins, matches: totalMatches, eloGain: totalEloGain),
        const SizedBox(height: 20),

        // ─── Section Title ──────────────────────────────────────────
        _buildSectionTitle(colors, 'Thành tích gần đây'),
        const SizedBox(height: 10),

        // ─── Achievement Cards ──────────────────────────────────────
        if (filteredAchievements.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: Text(
                'Chưa có thành tích cho môn thể thao này',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else
          ...filteredAchievements.map(
            (a) => _AchievementCard(achievement: a),
          ),
      ],
    );
  }

  // ─── STATS ROW (Compact Height) ──────────────────────────────────
  Widget _buildStatsRow(
    BuildContext context, {
    required int wins,
    required int matches,
    required int eloGain,
  }) {
    final stats = [
      _StatItem(icon: Icons.emoji_events_rounded, label: 'Giải thắng', value: '$wins'),
      _StatItem(icon: Icons.sports_score_rounded, label: 'Trận đã đấu', value: '$matches'),
      _StatItem(icon: Icons.trending_up_rounded, label: 'ELO tăng', value: '+$eloGain'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: stats.map((stat) {
            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(stat.icon, color: Colors.white70, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    stat.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
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

  Widget _buildSectionTitle(AppColorsExtension colors, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

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
  final String sportId;
  final IconData icon;
  final Color cardColor;
  final String tournamentName;
  final String date;
  final int eloNumber;
  final String eloBoost;
  final String achievementLabel;

  const _AchievementData({
    required this.sportId,
    required this.icon,
    required this.cardColor,
    required this.tournamentName,
    required this.date,
    required this.eloNumber,
    required this.eloBoost,
    required this.achievementLabel,
  });
}

const _sampleAchievements = <_AchievementData>[
  _AchievementData(
    sportId: 'football',
    icon: Icons.emoji_events_rounded,
    cardColor: Color(0xFFF59E0B),
    tournamentName: 'Giải Vô Địch Bóng Đá Mùa Xuân 2026',
    date: '15/06/2026',
    eloNumber: 45,
    eloBoost: '+45 ELO',
    achievementLabel: 'Vô địch',
  ),
  _AchievementData(
    sportId: 'pickleball',
    icon: Icons.emoji_events_rounded,
    cardColor: Color(0xFFF59E0B),
    tournamentName: 'Giải Pickleball Mở Rộng 2026',
    date: '02/06/2026',
    eloNumber: 50,
    eloBoost: '+50 ELO',
    achievementLabel: 'Vô địch',
  ),
  _AchievementData(
    sportId: 'badminton',
    icon: Icons.shield_rounded,
    cardColor: Color(0xFF94A3B8),
    tournamentName: 'Cúp Các CLB Thể Thao 2026',
    date: '20/05/2026',
    eloNumber: 28,
    eloBoost: '+28 ELO',
    achievementLabel: 'Á quân',
  ),
  _AchievementData(
    sportId: 'football',
    icon: Icons.military_tech_rounded,
    cardColor: Color(0xFFCD7F32),
    tournamentName: 'Giải Bóng Đá Thanh Niên 2026',
    date: '10/04/2026',
    eloNumber: 15,
    eloBoost: '+15 ELO',
    achievementLabel: 'Hạng Ba',
  ),
  _AchievementData(
    sportId: 'tennis',
    icon: Icons.star_rounded,
    cardColor: Color(0xFF3B82F6),
    tournamentName: 'Giải Tennis Mở Rộng 2025',
    date: '22/12/2025',
    eloNumber: 12,
    eloBoost: '+12 ELO',
    achievementLabel: 'Cầu thủ xuất sắc',
  ),
];

// ─── COMPACT LOW-HEIGHT ACHIEVEMENT CARD ────────────────────────────
class _AchievementCard extends StatelessWidget {
  final _AchievementData achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  achievement.cardColor,
                  achievement.cardColor.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              achievement.icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.tournamentName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      achievement.date,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.trending_up_rounded,
                      size: 11,
                      color: colors.success,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      achievement.eloBoost,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: achievement.cardColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
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
