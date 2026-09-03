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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.bgSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.radio_outlined,
                size: 26,
                color: colors.textMuted.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Không có trận nào đang diễn ra',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Các trận trực tiếp sẽ hiện ở đây khi bắt đầu',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
      itemCount: liveMatches.length + 1,
      itemBuilder: (context, index) {
        // ── Header Banner ──
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _LiveHeaderBanner(count: liveMatches.length),
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

// Header banner đỏ chuẩn web: icon pulse + title + count
class _LiveHeaderBanner extends StatefulWidget {
  final int count;
  const _LiveHeaderBanner({required this.count});

  @override
  State<_LiveHeaderBanner> createState() => _LiveHeaderBannerState();
}

class _LiveHeaderBannerState extends State<_LiveHeaderBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
      ),
      child: Row(
        children: [
          // Pulse dot icon
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  const Color(0xFFEF4444),
                  const Color(0xFFF87171),
                  _pulse.value,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(
                      alpha: _pulse.value * 0.35,
                    ),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Đang diễn ra trực tiếp',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.count}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ấn vào từng trận để xem chi tiết',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
