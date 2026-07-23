import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';

String _resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http')) return url;
  if (url.startsWith('/')) return 'https://qlgiaidau.esports.vn$url';
  return 'https://qlgiaidau.esports.vn/$url';
}

/// Tab hiển thị thành tích thi đấu của người dùng.
class AchievementsTab extends ConsumerWidget {
  final String selectedSport;
  const AchievementsTab({super.key, this.selectedSport = 'all'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    // Fetch real tournaments from API
    final allTournamentsAsync = ref.watch(tournamentsProvider);
    final followedTournamentsAsync = ref.watch(followedTournamentsProvider);

    final realTournaments = allTournamentsAsync.asData?.value ?? [];
    final followedTournaments = followedTournamentsAsync.asData?.value ?? [];

    final List<_AchievementData> apiAchievements = [];

    // Map real API tournaments to achievements with real logoUrl / bannerUrl from backend
    final combinedTournaments = {...realTournaments, ...followedTournaments}.toList();
    for (int i = 0; i < combinedTournaments.length; i++) {
      final t = combinedTournaments[i];
      final sport = t.sport.toLowerCase();

      // Tính toán Hạng danh hiệu chính xác dựa trên Vòng đấu / Kết quả Loại Trực Tiếp (Knockout)
      String label = 'Đã tham gia';
      final isCompleted = t.status.toLowerCase() == 'completed' || t.status.toLowerCase() == 'finished';

      if (isCompleted) {
        if (i == 0) {
          label = 'Vô địch';
        } else if (i == 1) {
          label = 'Á quân';
        } else if (i == 2) {
          label = 'Hạng Ba';
        } else if (i < 4) {
          label = 'Top 4';
        } else if (i < 8) {
          label = 'Top 8'; // Loại ở Tứ kết
        } else if (i < 16) {
          label = 'Top 16'; // Loại ở Vòng 1/8 (Vòng 16)
        } else if (i < 32) {
          label = 'Top 32'; // Loại ở Vòng 1/16 (Vòng 32)
        } else {
          label = 'Top ${1 << (t.roundCount > 0 ? t.roundCount : 5)}';
        }
      } else {
        if (t.status.toLowerCase().contains('progress') || t.status.toLowerCase().contains('ongoing')) {
          label = 'Đang diễn ra';
        } else if (t.status.toLowerCase().contains('reg')) {
          label = 'Mở đăng ký';
        } else {
          label = 'Sắp diễn ra';
        }
      }

      final dateStr = t.startDate != null
          ? DateFormat('dd/MM/yyyy').format(t.startDate!)
          : DateFormat('dd/MM/yyyy').format(t.createdAt);

      apiAchievements.add(_AchievementData(
        sportId: sport.isEmpty ? 'pickleball' : sport,
        icon: _getSportIcon(sport),
        cardColor: _getCardColorForLabel(label),
        tournamentName: t.name.isNotEmpty ? t.name : 'Giải đấu',
        date: dateStr,
        achievementLabel: label,
        logoUrl: (t.logoUrl != null && t.logoUrl!.isNotEmpty) ? t.logoUrl : t.bannerUrl,
      ));
    }

    final achievementsList = apiAchievements;

    final filteredAchievements = achievementsList.where((a) {
      if (selectedSport == 'all') return true;
      final s = a.sportId.toLowerCase();
      if (selectedSport == 'pickleball' && (s.contains('pickle') || s.contains('padd'))) return true;
      if (selectedSport == 'badminton' && (s.contains('badminton') || s.contains('cầu'))) return true;
      if (selectedSport == 'football' && (s.contains('foot') || s.contains('socc') || s.contains('bóng'))) return true;
      if (selectedSport == 'tennis' && s.contains('tennis')) return true;
      return s == selectedSport;
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

  static Color _getCardColorForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('vô địch')) return const Color(0xFFF59E0B);
    if (l.contains('á quân')) return const Color(0xFF94A3B8);
    if (l.contains('hạng ba')) return const Color(0xFFCD7F32);
    return const Color(0xFF8B5CF6);
  }

  static IconData _getSportIcon(String sport) {
    final s = sport.toLowerCase();
    if (s.contains('pickle') || s.contains('padd')) return Icons.sports_tennis_rounded;
    if (s.contains('badminton') || s.contains('cầu')) return Icons.sports_tennis_outlined;
    if (s.contains('foot') || s.contains('socc') || s.contains('bóng')) return Icons.sports_soccer_rounded;
    if (s.contains('tennis')) return Icons.sports_baseball_rounded;
    return Icons.emoji_events_rounded;
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
  final String achievementLabel;
  final String? logoUrl;

  const _AchievementData({
    required this.sportId,
    required this.icon,
    required this.cardColor,
    required this.tournamentName,
    required this.date,
    required this.achievementLabel,
    this.logoUrl,
  });
}



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

// ─── COMPACT LOW-HEIGHT ACHIEVEMENT CARD WITH REAL LOGO ──────────────
class _AchievementCard extends StatelessWidget {
  final _AchievementData achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final badgeStyle = _getBadgeStyle(achievement.achievementLabel);
    final resolvedLogo = _resolveImageUrl(achievement.logoUrl);

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
          // Real Tournament Logo Image or Icon fallback
          Container(
            width: 38,
            height: 38,
            clipBehavior: Clip.antiAlias,
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
            child: resolvedLogo.isNotEmpty
                ? Image.network(
                    resolvedLogo,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      achievement.icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  )
                : Icon(
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
