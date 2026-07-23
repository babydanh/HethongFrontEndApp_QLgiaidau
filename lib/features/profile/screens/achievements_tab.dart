import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

/// Tab hiển thị thành tích thi đấu của người dùng.
/// Hỗ trợ lọc đa môn thể thao (Pickleball, Cầu lông, Bóng đá, Tennis...).
class AchievementsTab extends ConsumerStatefulWidget {
  const AchievementsTab({super.key});

  @override
  ConsumerState<AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends ConsumerState<AchievementsTab> {
  String _selectedSport = 'all';

  final List<Map<String, String>> _sports = const [
    {'id': 'all', 'label': 'Tất cả'},
    {'id': 'pickleball', 'label': '🏓 Pickleball'},
    {'id': 'badminton', 'label': '🏸 Cầu lông'},
    {'id': 'football', 'label': '⚽ Bóng đá'},
    {'id': 'tennis', 'label': '🎾 Tennis'},
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final filteredAchievements = _sampleAchievements.where((a) {
      if (_selectedSport == 'all') return true;
      return a.sportId == _selectedSport;
    }).toList();

    final wins = filteredAchievements.where((a) => a.achievementLabel == 'Vô địch').length;
    final totalMatches = filteredAchievements.length * 7;
    final totalEloGain = filteredAchievements.fold<int>(0, (sum, a) => sum + a.eloNumber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── SPORT FILTER CHIPS ──────────────────────────────────────
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _sports.length,
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final sport = _sports[index];
              final isSelected = _selectedSport == sport['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedSport = sport['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : colors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : colors.border,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    sport['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : colors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // ─── STATS ROW ──────────────────────────────────────────────
        _buildStatsRow(context, wins: wins, matches: totalMatches, eloGain: totalEloGain),
        const SizedBox(height: 24),

        // ─── SECTION TITLE ──────────────────────────────────────────
        _buildSectionTitle(colors, 'Thành tích gần đây'),
        const SizedBox(height: 12),

        // ─── ACHIEVEMENT CARDS ──────────────────────────────────────
        if (filteredAchievements.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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

  // ─── STATS ROW ──────────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: stats.map((stat) {
            return Expanded(
              child: Column(
                children: [
                  Icon(stat.icon, color: Colors.white70, size: 20),
                  const SizedBox(height: 6),
                  Text(
                    stat.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  achievement.cardColor,
                  achievement.cardColor.withValues(alpha: 0.65),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: achievement.cardColor.withValues(alpha: 0.28),
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
