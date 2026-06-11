import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/core/widgets/score_stepper.dart';

class TeamScoreCard extends ConsumerWidget {
  final String tournamentId;
  final String matchId;
  final bool isTeam1;
  final bool isLive;
  final bool isCompleted;

  const TeamScoreCard({
    super.key,
    required this.tournamentId,
    required this.matchId,
    required this.isTeam1,
    required this.isLive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Chỉ lắng nghe sự thay đổi của score, name, winnerId của đội này
    final match = ref.watch(singleMatchProvider((tournamentId: tournamentId, matchId: matchId)).select((asyncVal) => asyncVal.value));
    
    if (match == null) return const SizedBox.shrink();

    final name = isTeam1 ? match.team1Name : match.team2Name;
    final score = isTeam1 ? match.score1 : match.score2;
    final isWinner = isCompleted && match.winnerId == (isTeam1 ? match.team1Id : match.team2Id);
    final controller = ref.read(matchControllerProvider((tournamentId: tournamentId, matchId: matchId)));

    return Column(
      children: [
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isWinner ? AppTheme.accent : context.colors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),

        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: isWinner
                ? context.colors.success.withValues(alpha: 0.1)
                : context.colors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isWinner ? context.colors.success : context.colors.border,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: isWinner
                    ? context.colors.success
                    : context.colors.textPrimary,
              ),
            ),
          ),
        ),

        if (isLive) ...[
          const SizedBox(height: 16),
          ScoreStepper(
            currentScore: score,
            onDecrement: () => _addScore(context, controller, match.maxScore, isTeam1, -1),
            onIncrement: () => _addScore(context, controller, match.maxScore, isTeam1, 1),
          ),
          const SizedBox(height: 16),
          // Các nút thẻ vàng/đỏ được thiết kế theo giao diện cơ bản (hoặc rút gọn nếu môn thể thao có cấu hình riêng)
          // Để tối giản, chúng ta đã có Toolbar bên dưới nên ở đây chỉ hiển thị điểm.
        ],
      ],
    );
  }

  Future<void> _addScore(
    BuildContext context,
    MatchController controller,
    int? maxScore,
    bool isTeam1,
    int points,
  ) async {
    try {
      await controller.addScore(isTeam1, points);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi: Bạn không có quyền sửa điểm.'),
          ),
        );
      }
    }
  }
}
