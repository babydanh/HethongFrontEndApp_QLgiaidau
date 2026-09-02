import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/live_match_card_v2.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

class LiveTab extends StatelessWidget {
  final List<MatchModel> liveMatches;

  const LiveTab({super.key, required this.liveMatches});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (liveMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sports_tennis_rounded,
                size: 40,
                color: colors.textMuted.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hiện không có trận đấu nào đang diễn ra',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Các trận đấu trực tiếp sẽ hiển thị tại đây khi bắt đầu',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
      itemCount: liveMatches.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ĐANG DIỄN RA TRỰC TIẾP (${liveMatches.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );
        }

        final match = liveMatches[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LiveMatchCardV2(
            match: match,
            isLive: true,
            onTap: () {
              context.push(
                '/tournaments/${match.tournamentId}/matches/${match.id}/official-score',
              );
            },
          ),
        );
      },
    );
  }
}
