import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/sport_rule_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/domain/services/score_validator.dart';
import 'package:app_quanly_giaidau/core/widgets/score_display.dart';

/// Màn hình nhập điểm cho rally-point sports:
/// Badminton (21), Table Tennis (11), Pickleball Rally (11)
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
  static const _log = AppLogger('ScoreInput');
  late MatchControlParams _controlParams;

  // Current set editing
  int _currentP1 = 0;
  int _currentP2 = 0;
  final List<SetScoreData> _finishedSets = [];
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controlParams = (
      tournamentId: widget.tournamentId,
      matchId: widget.matchId,
    );
  }

  void _addPoint(bool isTeam1) {
    setState(() {
      if (isTeam1) _currentP1++; else _currentP2++;
      _errorMessage = null;
    });
  }

  void _subtractPoint(bool isTeam1) {
    setState(() {
      if (isTeam1 && _currentP1 > 0) _currentP1--;
      if (!isTeam1 && _currentP2 > 0) _currentP2--;
      _errorMessage = null;
    });
  }

  Future<void> _finishSet(SportConfig config) async {
    final currentSet = SetScoreData(score1: _currentP1, score2: _currentP2);

    // Validate set
    try {
      validateRallyPointSet(currentSet, config, label: 'Hiệp ${_finishedSets.length + 1}');
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('FormatException: ', ''));
      return;
    }

    final completed = currentSet.copyWith(isFinished: true);
    final newFinished = [..._finishedSets, completed];

    // Check match complete
    final matchComplete = isMatchComplete(config, newFinished);

    setState(() {
      _finishedSets.add(completed);
      _currentP1 = 0;
      _currentP2 = 0;
      _errorMessage = null;
    });

    if (matchComplete) {
      await _saveAndFinish(config, newFinished);
    } else {
      await _saveSets(config, newFinished);
    }
  }

  Future<void> _saveSets(SportConfig config, List<SetScoreData> sets) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/matches/${widget.matchId}/score', data: {
        'scoreDetails': {
          'sets': sets.map((s) => s.toJson()).toList(),
        },
        'setsToWin': config.setsToWin,
      });
      _log.success('Đã lưu sets');
    } catch (e, stack) {
      _log.error('Lỗi lưu sets', e, stack);
    }
  }

  Future<void> _saveAndFinish(SportConfig config, List<SetScoreData> sets) async {
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      final (t1, _) = computeMatchSetsWon(sets);
      final winnerId = t1 > config.setsToWin / 2 ? 'team1' : 'team2';
      final winnerParticipant = t1 > config.setsToWin / 2 ? 'P1' : 'P2';

      await dio.patch('/matches/${widget.matchId}/score', data: {
        'scoreDetails': {
          'sets': sets.map((s) => s.toJson()).toList(),
        },
        'isCompleted': true,
        'winnerParticipant': winnerParticipant,
        'setsToWin': config.setsToWin,
      });

      _log.success('Trận đấu kết thúc');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trận đấu kết thúc!'), backgroundColor: Color(0xFF059669)),
        );
        ref.invalidate(tournamentsProvider);
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
        title: const Text('Nhập điểm'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) context.pop();
            else context.go('/home');
          },
        ),
      ),
      body: matchAsync.when(
        data: (match) {
          if (match == null) return const Center(child: Text('Trận đấu không tồn tại'));
          final config = ref.watch(matchSportConfigProvider(match));
          return _buildScoreBoard(context, match, config);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildScoreBoard(BuildContext context, MatchModel match, SportConfig config) {
    final colors = context.colors;
    final totalSets = _finishedSets.length;
    final (t1Won, t2Won) = computeMatchSetsWon(_finishedSets);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ─── Thông tin config ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getSportLabel(config),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Set history ───
          if (_finishedSets.isNotEmpty) ...[
            Row(
              children: [
                Text('HIỆP ĐÃ CHỐT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: colors.textMuted, letterSpacing: 0.5)),
                const SizedBox(width: 8),
                Text('$t1Won - $t2Won', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colors.textPrimary)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _finishedSets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final s = _finishedSets[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.colors.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Text(
                      'H${i + 1}: ${s.score1}-${s.score2}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.textPrimary),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ─── Current set input ───
          Expanded(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTeamScore('${match.team1Name}', _currentP1, true, colors),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('-', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
                  ),
                  _buildTeamScore('${match.team2Name}', _currentP2, false, colors),
                ],
              ),
            ),
          ),

          // ─── Error message ───
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
            ),

          // ─── Current set label ───
          Text(
            'Hiệp ${_finishedSets.length + 1} · BO${config.bestOf} · ${config.pointsPerSet} điểm${config.mustWinByTwo ? ' (cách 2)' : ''}',
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
          const SizedBox(height: 12),

          // ─── Finish set button ───
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isSaving || _currentP1 + _currentP2 == 0
                  ? null
                  : () => _finishSet(config),
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded),
              label: Text(
                _isSaving
                    ? 'Đang lưu...'
                    : 'Chốt hiệp ${_finishedSets.length + 1} (${_currentP1}-${_currentP2})',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Cancel/finish match buttons ───
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() { _currentP1 = 0; _currentP2 = 0; _errorMessage = null; }),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: colors.border),
                  ),
                  child: Text('Đặt lại', style: TextStyle(color: colors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _finishedSets.isEmpty ? null : () => _saveAndFinish(config, _finishedSets),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                    foregroundColor: colors.error,
                  ),
                  child: const Text('Kết thúc trận'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScore(String name, int score, bool isTeam1, AppColorsExtension colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 12),
        Row(
          children: [
            GestureDetector(
              onTap: () => _subtractPoint(isTeam1),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: colors.bgSurface, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.remove_rounded, size: 20),
              ),
            ),
            SizedBox(
              width: 70,
              child: Center(
                child: Text(
                  '$score',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: isTeam1 ? const Color(0xFF2979FF) : const Color(0xFFEA580C)),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _addPoint(isTeam1),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isTeam1 ? const Color(0xFF2979FF).withValues(alpha: 0.1) : const Color(0xFFEA580C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getSportLabel(SportConfig config) {
    switch (config.kind) {
      case SportRuleKind.badminton: return '🏸 CẦU LÔNG · BO3 · 21 điểm';
      case SportRuleKind.tableTennis: return '🏓 BÓNG BÀN · BO5 · 11 điểm';
      case SportRuleKind.pickleball: return '🏓 PICKLEBALL · BO3 · 11 điểm';
      case SportRuleKind.tennis: return '🎾 TENNIS';
    }
  }
}
