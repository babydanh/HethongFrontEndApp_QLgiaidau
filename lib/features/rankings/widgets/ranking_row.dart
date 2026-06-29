import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';

class RankingRow extends StatelessWidget {
  final PlayerRanking ranking; final VoidCallback? onTap;
  const RankingRow({super.key, required this.ranking, this.onTap});

  @override
  Widget build(BuildContext context) {
    final wr = ranking.winRate;
    return GestureDetector(onTap: onTap,
      child: Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: context.colors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.border)),
        child: Row(children: [
          SizedBox(width: 32, child: Text('${ranking.rank}', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
              color: ranking.rank <= 3 ? (ranking.rank == 1 ? const Color(0xFFFFD700) : ranking.rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32)) : context.colors.textSecondary))),
          const SizedBox(width: 10),
          Container(width: 36, height: 36, decoration: BoxDecoration(color: context.colors.bgSurface, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(_initials(ranking.fullName), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ranking.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
            const SizedBox(height: 2),
            Text('Thắng ${ranking.matchesWon} · Thua ${ranking.matchesLost}', style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${ranking.eloPoints}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary)),
            Text('${wr.toStringAsFixed(0)}%', style: TextStyle(fontSize: 10, color: wr >= 60 ? context.colors.success : context.colors.textMuted)),
          ]),
          const SizedBox(width: 4), Icon(Icons.chevron_right_rounded, size: 16, color: context.colors.textMuted),
        ])),
    );
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[p.length - 2][0]}${p[p.length - 1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
