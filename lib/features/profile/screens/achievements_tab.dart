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
    sportId: 'pickleball',
    icon: Icons.workspace_premium_rounded,
    cardColor: Color(0xFF8B5CF6),
    tournamentName: 'Giải Pickleball Tranh Cúp 2026',
    date: '15/03/2026',
    eloNumber: 10,
    eloBoost: '+10 ELO',
    achievementLabel: 'Hạng 4',
  ),
  _AchievementData(
    sportId: 'badminton',
    icon: Icons.workspace_premium_rounded,
    cardColor: Color(0xFF8B5CF6),
    tournamentName: 'Giải Cầu Lông Đôi Nam 2026',
    date: '01/02/2026',
    eloNumber: 8,
    eloBoost: '+8 ELO',
    achievementLabel: 'Top 8',
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

class _BadgeStyle {
  final Color bg;
  final Color text;
  final Color border;
  const _BadgeStyle({required this.bg, required this.text, required this.border});
}

_BadgeStyle _getBadgeStyle(String label) {
  final l = label.toLowerCase();
  if (l.contains('vô địch') || l.contains('quán quân') || l.contains('hạng 1')) {
    return const _BadgeStyle(
      bg: Color(0xFFFEF3C7),
      text: Color(0xFFB45309),
      border: Color(0xFFFDE68A),
    );
  } else if (l.contains('á quân') || l.contains('hạng 2')) {
    return const _BadgeStyle(
      bg: Color(0xFFF1F5F9),
      text: Color(0xFF475569),
      border: Color(0xFFE2E8F0),
    );
  } else if (l.contains('hạng ba') || l.contains('hạng 3') || l.contains('đồng')) {
    return const _BadgeStyle(
      bg: Color(0xFFFFEDD5),
      text: Color(0xFFC2410C),
      border: Color(0xFFFED7AA),
    );
  } else if (l.contains('xuất sắc') || l.contains('mvp')) {
    return const _BadgeStyle(
      bg: Color(0xFFEFF6FF),
      text: Color(0xFF1D4ED8),
      border: Color(0xFFBFDBFE),
    );
  } else {
    return const _BadgeStyle(
      bg: Color(0xFFF5F3FF),
      text: Color(0xFF6D28D9),
      border: Color(0xFFDDD6FE),
    );
  }
}

// ─── COMPACT LOW-HEIGHT ACHIEVEMENT CARD ────────────────────────────
class _AchievementCard extends StatelessWidget {
  final _AchievementData achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final badgeStyle = _getBadgeStyle(achievement.achievementLabel);

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
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: badgeStyle.bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeStyle.border),
            ),
            child: Text(
              achievement.achievementLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: badgeStyle.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
