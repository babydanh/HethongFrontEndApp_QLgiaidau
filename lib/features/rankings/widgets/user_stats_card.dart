import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';

class UserStatsCard extends StatelessWidget {
  final PlayerRanking ranking;
  const UserStatsCard({super.key, required this.ranking});

  @override
  Widget build(BuildContext context) {
    final wr = ranking.winRate;
    return Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Center(child: Text(_initials(ranking.fullName), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)))),
          const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ranking.fullName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Hạng #${ranking.rank} · ${ranking.tierName}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('ELO', style: TextStyle(color: Colors.white54, fontSize: 9)),
            Text('${ranking.eloPoints}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          ]),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _stat('Thắng', '${ranking.matchesWon}'), _stat('Thua', '${ranking.matchesLost}'), _stat('Tỉ lệ', '${wr.round()}%'), _stat('Tổng', '${ranking.matchesPlayed}'),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: wr / 100, minHeight: 6,
          backgroundColor: Colors.white.withValues(alpha: 0.2), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)))),
      ]),
    );
  }

  Widget _stat(String label, String value) => Expanded(child: Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
    Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.w600)),
  ]));

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[p.length - 2][0]}${p[p.length - 1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
