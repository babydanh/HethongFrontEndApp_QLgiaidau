import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';

class TournamentStatsRow extends StatelessWidget {
  final int totalTeams;
  final int totalMatches;
  final int completedMatches;
  final int liveMatches;

  const TournamentStatsRow({
    super.key,
    required this.totalTeams,
    required this.totalMatches,
    required this.completedMatches,
    required this.liveMatches,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(
          context,
          icon: Icons.group_rounded,
          value: totalTeams,
          label: "Tổng đội",
          color: const Color(0xFF2979FF),
        ),
        _buildStatCard(
          context,
          icon: Icons.emoji_events_rounded,
          value: totalMatches,
          label: "Trận đấu",
          color: const Color(0xFFFFD700),
        ),
        _buildStatCard(
          context,
          icon: Icons.check_circle_rounded,
          value: completedMatches,
          label: "Đã hoàn thành",
          color: context.colors.success,
        ),
        _buildStatCard(
          context,
          icon: Icons.play_circle_rounded,
          value: liveMatches,
          label: "Đang diễn ra",
          color: context.colors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required int value,
    required String label,
    required Color color,
  }) {
    final colors = context.colors;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              "$value",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
