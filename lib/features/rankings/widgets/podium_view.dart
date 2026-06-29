import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';

class PodiumView extends StatelessWidget {
  final List<PlayerRanking> rankings;
  const PodiumView({super.key, required this.rankings});

  @override
  Widget build(BuildContext context) {
    if (rankings.length < 3) return const SizedBox.shrink();
    final colors = context.colors;
    return Container(padding: const EdgeInsets.symmetric(vertical: 20), child: Column(children: [
      SizedBox(height: 110, child: Column(children: [
        const Text('👑', style: TextStyle(fontSize: 24)), const SizedBox(height: 4),
        Container(width: 60, height: 60, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]), shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.3), blurRadius: 12)]),
          child: Center(child: Text(_initials(rankings[0].fullName), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)))),
        const SizedBox(height: 6), Text(rankings[0].fullName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('${rankings[0].eloPoints} ELO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary)),
      ])),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _mini(context, rankings[1], '🥈', const Color(0xFFC0C0C0), colors),
        const SizedBox(width: 24),
        _mini(context, rankings[2], '🥉', const Color(0xFFCD7F32), colors),
      ]),
    ]));
  }

  Widget _mini(BuildContext context, PlayerRanking r, String emoji, Color medalColor, AppColorsExtension colors) => SizedBox(width: 100, child: Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 20)), const SizedBox(height: 4),
    Container(width: 46, height: 46, decoration: BoxDecoration(color: medalColor.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: medalColor.withValues(alpha: 0.4), width: 2)),
      child: Center(child: Text(_initials(r.fullName), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)))),
    const SizedBox(height: 4), Text(r.fullName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
    Text('${r.eloPoints}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.textSecondary)),
  ]));

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[p.length - 2][0]}${p[p.length - 1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
