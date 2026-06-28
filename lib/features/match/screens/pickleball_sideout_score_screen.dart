import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/sport_rule_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/core/widgets/score_display.dart';

/// Pickleball Side-Out Score Screen
/// - Chỉ 1 game duy nhất đến 11 (cách 2)
/// - Server indicator (1st serve / 2nd serve)
/// - Side-out scoring: chỉ ghi điểm khi giao bóng
class PickleballSideOutScoreScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String matchId;
  const PickleballSideOutScoreScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
  });

  @override
  ConsumerState<PickleballSideOutScoreScreen> createState() => _PickleballSideOutScoreScreenState();
}

class _PickleballSideOutScoreScreenState extends ConsumerState<PickleballSideOutScoreScreen> {
  static const _log = AppLogger('PickleballScore');
  late MatchControlParams _controlParams;

  int _team1Score = 0;
  int _team2Score = 0;
  bool _isTeam1Serving = true;
  int _serveNumber = 1; // 1 or 2
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controlParams = (tournamentId: widget.tournamentId, matchId: widget.matchId);
  }

  void _awardPoint(bool isTeam1) {
    setState(() {
      if (isTeam1) _team1Score++; else _team2Score++;
      _errorMessage = null;
      // Rally point scoring: server changes on side-out
      _serveNumber = 1;
    });
  }

  void _sideOut() {
    // Side-out: đổi giao bóng, reset serve number
    setState(() {
      _isTeam1Serving = !_isTeam1Serving;
      _serveNumber = 1;
      _errorMessage = null;
    });
  }

  void _switchServer() {
    // 1st serve → 2nd serve (partner serves)
    setState(() {
      if (_serveNumber == 1) {
        _serveNumber = 2;
      } else {
        // Side-out after 2nd serve
        _isTeam1Serving = !_isTeam1Serving;
        _serveNumber = 1;
      }
      _errorMessage = null;
    });
  }

  Future<void> _finishGame() async {
    if (_team1Score == 0 && _team2Score == 0) return;

    setState(() => _isSaving = true);
    try {
      final sportRules = <String, dynamic>{
        'kind': 'PICKLEBALL_SIDE_OUT',
        'scoringModel': 'PICKLEBALL_SIDE_OUT',
        'setsToWin': 1,
        'maxPoints': 11,
        'mustWinByTwo': true,
      };

      final sets = [
        SetScoreData(score1: _team1Score, score2: _team2Score, isFinished: true).toJson(),
      ];

      final dio = ref.read(dioProvider);
      await dio.patch('/matches/${widget.matchId}/score', data: {
        'scoreDetails': {'sets': sets},
        'isCompleted': true,
        'winnerParticipant': _team1Score > _team2Score ? 'P1' : 'P2',
      });

      _log.success('Trận pickleball side-out kết thúc');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trận đấu kết thúc!'), backgroundColor: Color(0xFF059669)),
        );
        context.pop();
      }
    } catch (e, stack) {
      _log.error('Lỗi kết thúc trận', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(singleMatchProvider(_controlParams));
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        title: const Text('Pickleball · Side-Out Scoring'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: matchAsync.when(
        data: (match) {
          if (match == null) return const Center(child: Text('Trận đấu không tồn tại'));
          return _buildScoreBoard(colors);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildScoreBoard(AppColorsExtension colors) {
    final diff = (_team1Score - _team2Score).abs();
    final maxScore = _team1Score > _team2Score ? _team1Score : _team2Score;

    // Check if game is complete
    final gameComplete = maxScore >= 11 && diff >= 2;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ─── Info badge ───
          PickleballServerIndicator(
            isTeam1Serving: _isTeam1Serving,
            serveNumber: _serveNumber,
          ),
          const SizedBox(height: 8),
          Text(
            'Một game đến 11 · Cách 2 · Bên giao bóng ghi điểm',
            style: TextStyle(fontSize: 10, color: colors.textMuted),
          ),
          const SizedBox(height: 24),

          // ─── Main score ───
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTeamDisplay('Đội 1', _team1Score, true, _isTeam1Serving, colors),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('-', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: colors.textSecondary)),
                  ),
                  _buildTeamDisplay('Đội 2', _team2Score, false, !_isTeam1Serving, colors),
                ],
              ),
            ),
          ),

          // ─── Buttons ───
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSaving || gameComplete ? null : () => _awardPoint(true),
                  icon: const Icon(Icons.add_rounded),
                  label: Text('+1 Đội 1', style: const TextStyle(fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2979FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSaving || gameComplete ? null : () => _awardPoint(false),
                  icon: const Icon(Icons.add_rounded),
                  label: Text('+1 Đội 2', style: const TextStyle(fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _switchServer,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Giao bóng tiếp', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _sideOut,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('Side-Out', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: (_team1Score == 0 && _team2Score == 0) || _isSaving
                  ? null
                  : gameComplete ? _finishGame : null,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(gameComplete ? Icons.emoji_events_rounded : Icons.info_outline, size: 18),
              label: Text(
                _isSaving
                    ? 'Đang lưu...'
                    : gameComplete
                        ? 'Kết thúc trận (${_team1Score}-${_team2Score})'
                        : 'Đạt ${11 + (_team1Score + _team2Score >= 20 ? 1 : 0)} và cách 2 để thắng',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: gameComplete ? AppTheme.accent : colors.bgElevated,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDisplay(String name, int score, bool isTeam1, bool isServing, AppColorsExtension colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isServing)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.volunteer_activism_rounded, size: 14, color: AppTheme.primary),
              ),
            Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$score',
          style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900,
            color: isTeam1 ? const Color(0xFF2979FF) : const Color(0xFFEA580C)),
        ),
        const SizedBox(height: 4),
        Text(isServing ? 'Đang giao' : 'Đỡ', style: TextStyle(fontSize: 10, color: colors.textMuted)),
      ],
    );
  }
}
