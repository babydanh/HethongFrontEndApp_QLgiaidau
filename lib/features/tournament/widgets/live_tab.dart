import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
      itemCount: liveMatches.length,
      itemBuilder: (context, index) {
        final match = liveMatches[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LiveMatchCardV2(match: match),
        );
      },
    );
  }
}
