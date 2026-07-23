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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
