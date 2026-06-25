import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/features/match/widgets/admin_edit_score_dialog.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_event_model.dart';
import 'package:app_quanly_giaidau/features/match/widgets/match_settings_dialog.dart';
import 'package:app_quanly_giaidau/features/match/widgets/match_event_renderer.dart';
import 'package:app_quanly_giaidau/features/match/widgets/team_score_card.dart';
import 'package:app_quanly_giaidau/features/match/widgets/penalty_input_dialog.dart';
import 'package:app_quanly_giaidau/features/match/widgets/injury_input_dialog.dart';
import 'package:app_quanly_giaidau/core/utils/date_formatter_utils.dart';

class ScoreInputScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String matchId;
  const ScoreInputScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
  });

  @override
  ConsumerState<ScoreInputScreen> createState() => _ScoreInputScreenState();
}

class _ScoreInputScreenState extends ConsumerState<ScoreInputScreen> {
  late MatchControlParams _controlParams;

  @override
  void initState() {
    super.initState();
    _controlParams = (
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(singleMatchProvider(_controlParams));

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        title: const Text('Điều khiển trận đấu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              final auth = ref.read(authProvider);
              if (auth.role == UserRole.referee) {
                context.go('/referee');
              } else {
                context.go('/admin/tournament/${widget.tournamentId}');
              }
            }
          },
        ),
      ),
      body: matchAsync.when(
        data: (match) {
          if (match == null) {
            return const Center(child: Text('Trận đấu không tồn tại'));
          }
          return _buildScoreBoard(context, match);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildScoreBoard(BuildContext context, MatchModel match) {
    final isLive = match.status == AppConstants.matchLive;
    final isCompleted = match.status == AppConstants.matchCompleted;
    final isScheduled = match.status == AppConstants.matchScheduled;
    final controller = ref.read(matchControllerProvider(_controlParams));

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: context.liveGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fiber_manual_record,
                          size: 10,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'ĐANG THI ĐẤU',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.colors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '✅ ĐÃ KẾT THÚC',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.colors.success,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                if (match.maxScore != null || match.timeLimitMinutes != null)
                  Text(
                    '${match.maxScore != null ? 'Điểm tối đa: ${match.maxScore}' : ''}'
                    '${match.maxScore != null && match.timeLimitMinutes != null ? ' | ' : ''}'
                    '${match.timeLimitMinutes != null ? 'Thời gian: ${match.timeLimitMinutes}p' : ''}',
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 12,
                    ),
                  ),

                if (isCompleted && ref.watch(authProvider).role == UserRole.admin) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (ctx) => AdminEditScoreDialog(match: match),
                      );
                      if (result != null) {
                        try {
                          await controller.updateMatchResultByAdmin(
                            score1: result['score1'] as int,
                            score2: result['score2'] as int,
                            winnerId: result['winnerId'] as String,
                            loserId: result['loserId'] as String,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: const Text('Cập nhật kết quả thành công!'), backgroundColor: context.colors.success),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e'), backgroundColor: context.colors.error),
                            );
                          }
                        }
                      }
                    },
                    icon: Icon(Icons.edit, color: context.colors.warning, size: 18),
                    label: Text('Sửa kết quả (Admin)', style: TextStyle(color: context.colors.warning)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.colors.warning),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TeamScoreCard(
                        tournamentId: widget.tournamentId,
                        matchId: widget.matchId,
                        isTeam1: true,
                        isLive: isLive,
                        isCompleted: isCompleted,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 32,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: context.colors.textMuted.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${match.score1} - ${match.score2}',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: TeamScoreCard(
                        tournamentId: widget.tournamentId,
                        matchId: widget.matchId,
                        isTeam1: false,
                        isLive: isLive,
                        isCompleted: isCompleted,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                if (isScheduled && match.hasTeams) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _startMatch(controller),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'Bắt đầu trận đấu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],

                if (isLive) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showInjuryDialog(context, match, controller),
                          icon: const Icon(Icons.medical_services, color: Colors.blue, size: 20),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Chấn thương', style: TextStyle(color: context.colors.textPrimary)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.colors.border),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showPenaltyDialog(context, match, controller),
                          icon: Icon(Icons.style, color: context.colors.error, size: 20),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Thẻ phạt', style: TextStyle(color: context.colors.textPrimary)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.colors.border),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _showEndMatchDialog(match, controller),
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text(
                        'Kết thúc trận đấu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.error,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (match.events.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => controller.undoLastEvent(),
                      icon: const Icon(Icons.undo),
                      label: const Text('Hoàn tác sự kiện cuối'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.colors.warning,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),

        if (match.events.isNotEmpty) _buildTimeline(context, match),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context, MatchModel match) {
    final recentEvents = match.events.reversed.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Lịch sử sự kiện (Gần nhất)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...recentEvents.map((e) {
            final isTeam1 = e.teamId == match.team1Id;
            final teamName = isTeam1 ? match.team1Name : match.team2Name;
            final timeStr = DateFormatterUtils.formatTime(e.timestamp);

            final renderer = MatchEventRendererFactory.getRenderer(e.type);
            final icon = renderer.getIcon(e);
            final color = renderer.getColor(context, e);
            final action = renderer.getActionText(e);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, color: color, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '[$teamName] $action',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }



  void _showInjuryDialog(BuildContext context, MatchModel match, MatchController controller) {
    showDialog(
      context: context,
      builder: (_) => InjuryInputDialog(
        team1Name: match.team1Name,
        team2Name: match.team2Name,
        onSubmit: (teamName, description) {
          final isTeam1 = teamName == match.team1Name;
          controller.addFoul(isTeam1, MatchEventType.injury, description);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã ghi nhận sự kiện y tế.'), backgroundColor: context.colors.success),
            );
          }
        },
      ),
    );
  }

  void _showPenaltyDialog(BuildContext context, MatchModel match, MatchController controller) {
    final tournamentAsync = ref.read(tournamentProvider(widget.tournamentId));
    final sport = tournamentAsync.value?.sport ?? 'other';
    
    showDialog(
      context: context,
      builder: (_) => PenaltyInputDialog(
        sportType: sport,
        team1Name: match.team1Name,
        team2Name: match.team2Name,
        onSubmit: (teamName, option, reason) {
          final isTeam1 = teamName == match.team1Name;
          controller.addPenalty(isTeam1, sport, option.id, option.name, reason);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã ghi nhận ${option.name}.'), backgroundColor: context.colors.success),
            );
          }
        },
      ),
    );
  }

  Future<void> _startMatch(MatchController controller) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const MatchSettingsDialog(),
    );

    if (result == null) return;

    final maxScore = result['maxScore'] as int?;
    final timeLimit = result['timeLimit'] as int?;
    final refereeName = result['refereeName'] as String?;

    try {
      await controller.startMatch(
        maxScore: maxScore,
        timeLimitMinutes: timeLimit,
        refereeName: refereeName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi: Không thể bắt đầu (Giải đấu cũ hoặc không có quyền).',
            ),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  Future<void> _showEndMatchDialog(
    MatchModel match,
    MatchController controller,
  ) async {
    final winnerId = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colors.bgCard,
        title: Text(
          'Kết thúc trận đấu',
          style: TextStyle(color: context.colors.textPrimary),
        ),
        content: Text(
          'Chọn đội thắng:',
          style: TextStyle(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, match.team1Id),
            child: Text(
              match.team1Name,
              style: const TextStyle(color: AppTheme.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, match.team2Id),
            child: Text(
              match.team2Name,
              style: const TextStyle(color: AppTheme.secondary),
            ),
          ),
        ],
      ),
    );

    if (winnerId != null) {
      final loserId = winnerId == match.team1Id ? match.team2Id : match.team1Id;
      try {
        await controller.endMatch(winnerId, loserId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi: Bạn không có quyền kết thúc (hoặc giải đấu cũ).',
              ),
            ),
          );
        }
        return;
      }

      // Advance winner to next match if exists
      if (match.nextMatchId.isNotEmpty) {
        final winnerName = winnerId == match.team1Id
            ? match.team1Name
            : match.team2Name;
        await controller.advanceWinner(
          nextMatchId: match.nextMatchId,
          winnerId: winnerId,
          winnerName: winnerName,
          isTeam1: match.matchNumber.isOdd,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🏆 Trận đấu đã kết thúc!'),
            backgroundColor: context.colors.success,
          ),
        );
      }
    }
  }
}
