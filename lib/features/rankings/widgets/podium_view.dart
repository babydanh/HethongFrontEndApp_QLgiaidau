import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';

/// Podium Top 3 — đẹp, có hiệu ứng
class PodiumView extends StatelessWidget {
  final List<PlayerRanking> rankings; // phải có ít nhất 3 items

  const PodiumView({super.key, required this.rankings});

  @override
  Widget build(BuildContext context) {
    if (rankings.length < 3) return const SizedBox.shrink();
    final top1 = rankings[0];
    final top2 = rankings[1];
    final top3 = rankings[2];

    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // ─── Top 1 ───
          SizedBox(
            height: 110,
            child: Column(
              children: [
                const Text('👑', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.3), blurRadius: 12),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(top1.fullName),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(top1.fullName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${top1.eloPoints} ELO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ─── Top 2 + Top 3 ───
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniPodium(top2, '🥈', const Color(0xFFC0C0C0), const Color(0xFFE8E8E8), colors),
              const SizedBox(width: 24),
              _buildMiniPodium(top3, '🥉', const Color(0xFFCD7F32), const Color(0xFFF5E6D3), colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPodium(PlayerRanking r, String emoji, Color medalColor, Color bgColor, AppColorsExtension colors) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: medalColor.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: Text(_getInitials(r.fullName), style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 4),
          Text(r.fullName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          Text('${r.eloPoints}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.textSecondary)),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[parts.length - 2][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
