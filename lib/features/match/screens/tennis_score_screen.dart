import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/sport_rule_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/domain/services/score_validator.dart';
import 'package:app_quanly_giaidau/core/widgets/score_display.dart';

/// Màn hình nhập điểm Tennis — game-based scoring
/// Hiển thị game points (15,30,40,Deuce,Ad) và sets
class TennisScoreScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String matchId;
  const TennisScoreScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
  });

  @override
  ConsumerState<TennisScoreScreen> createState() => _TennisScoreScreenState();
}

class _TennisScoreScreenState extends ConsumerState<TennisScoreScreen> {
  static const _log = AppLogger('TennisScore');
  late MatchControlParams _controlParams;

  // Game points (0,1,2,3 = 0,15,30,40)
  int _p1GamePoints = 0;
  int _p2GamePoints = 0;
  // Set scores
  final List<SetScoreData> _finishedSets = [];
  bool _isSaving = false;
  String? _errorMessage;
  bool _isTiebreak = false;

  @override
  void initState() {
    super.initState();
    _controlParams = (tournamentId: widget.tournamentId, matchId: widget.matchId);
  }

  void _awardPoint(bool isTeam1) {
    setState(() {
      if (isTeam1) _p1GamePoints++; else _p2GamePoints++;
      _errorMessage = null;
    });
    _checkGameEnd();
  }

  void _removePoint(bool isTeam1) {
    setState(() {
      if (isTeam1 && _p1GamePoints > 0) _p1GamePoints--;
      if (!isTeam1 && _p2GamePoints > 0) _p2GamePoints--;
      _errorMessage = null;
    });
  }

  void _checkGameEnd() {
    if (_isTiebreak) {
      // Tiebreak: ai được 7 và cách 2
      if (_p1GamePoints >= 7 && (_p1GamePoints - _p2GamePoints) >= 2) {
        _finishGameInSet(1);
      } else if (_p2GamePoints >= 7 && (_p2GamePoints - _p1GamePoints) >= 2) {
        _finishGameInSet(2);
      }
      return;
    }

    // Normal game
    if (_p1GamePoints >= 4 && _p2GamePoints >= 3) {
      // Deuce
      if ((_p1GamePoints - _p2GamePoints) >= 2) {
        _finishGameInSet(1);
      } else if ((_p2GamePoints - _p1GamePoints) >= 2) {
        _finishGameInSet(2);
      }
    } else if (_p1GamePoints >= 4 && (_p1GamePoints - _p2GamePoints) >= 2) {
      _finishGameInSet(1);
    } else if (_p2GamePoints >= 4 && (_p2GamePoints - _p1GamePoints) >= 2) {
      _finishGameInSet(2);
    }
  }

  void _finishGameInSet(int winnerTeam) {
    // Add game to current set
    final lastSet = _finishedSets.isNotEmpty ? _finishedSets.last : null;
    List<SetScoreData> newSets;

    if (lastSet != null && !lastSet.isFinished) {
      // Update last set
      final updated = winnerTeam == 1
          ? lastSet.copyWith(score1: lastSet.score1 + 1)
          : lastSet.copyWith(score2: lastSet.score2 + 1);
      newSets = [..._finishedSets.sublist(0, _finishedSets.length - 1), updated];
    } else {
      // New set
      final newSet = winnerTeam == 1
          ? SetScoreData(score1: 1, score2: 0)
          : SetScoreData(score1: 0, score2: 1);
      newSets = [..._finishedSets, newSet];
    }

    setState(() {
      _finishedSets.clear();
      _finishedSets.addAll(newSets);
      _p1GamePoints = 0;
      _p2GamePoints = 0;
    });

    // Check set completion
    _checkSetEnd();
  }

  void _checkSetEnd() {
    SportConfig config = ref.read(matchSportConfigProvider(
      // Create a mock match to get config
      ref.read(singleMatchProvider(_controlParams)).asData?.value ??
      _createMockMatch(),
    ));

    final currentSet = _finishedSets.isNotEmpty ? _finishedSets.last : null;
    if (currentSet == null) return;

    final maxScore = currentSet.score1 > currentSet.score2 ? currentSet.score1 : currentSet.score2;
    final minScore = currentSet.score1 < currentSet.score2 ? currentSet.score1 : currentSet.score2;
    final diff = maxScore - minScore;

    if (maxScore >= config.pointsPerSet && diff >= 2) {
      // Set complete, check match
      if (isMatchComplete(config, _finishedSets)) {
        _finishMatch(config);
      } else {
        // Mark set as finished, reset for new set
        setState(() {
          final idx = _finishedSets.length - 1;
          _finishedSets[idx] = _finishedSets[idx].copyWith(isFinished: true);
          _isTiebreak = false;
        });
      }
      return;
    }

    // Check tiebreak: 6-6
    if (currentSet.score1 >= config.tiebreakAt && currentSet.score2 >= config.tiebreakAt &&
        currentSet.score1 == currentSet.score2) {
      setState(() => _isTiebreak = true);
    }
  }

  Future<void> _finishMatch(SportConfig config) async {
    setState(() => _isSaving = true);
    try {
      // Mark last set as finished
      if (_finishedSets.isNotEmpty) {
        final idx = _finishedSets.length - 1;
        _finishedSets[idx] = _finishedSets[idx].copyWith(isFinished: true);
      }

      final dio = ref.read(dioProvider);
      final (t1, _) = computeMatchSetsWon(_finishedSets);
      final winnerParticipant = t1 > config.setsToWin / 2 ? 'P1' : 'P2';

      await dio.patch('/matches/${widget.matchId}/score', data: {
        'scoreDetails': {
          'sets': _finishedSets.map((s) => s.toJson()).toList(),
        },
        'isCompleted': true,
        'winnerParticipant': winnerParticipant,
      });

      _log.success('Trận tennis kết thúc');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trận đấu kết thúc!'), backgroundColor: Color(0xFF059669)),
        );
        context.pop();
      }
    } catch (e, stack) {
      _log.error('Lỗi kết thúc trận tennis', e, stack);
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
        title: const Text('Tennis · Nhập điểm'),
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
    final (t1Won, t2Won) = computeMatchSetsWon(_finishedSets);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ─── Set history ───
          if (_finishedSets.isNotEmpty) ...[
            Text('SET: $t1Won - $t2Won', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colors.textPrimary)),
            const SizedBox(height: 4),
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _finishedSets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final s = _finishedSets[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: s.isFinished ? AppTheme.accent.withValues(alpha: 0.3) : colors.border),
                    ),
                    child: Text(
                      'S${i + 1}: ${s.score1}-${s.score2}',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800,
                        color: s.isFinished ? AppTheme.accent : colors.textPrimary,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ─── Tennis game points display ───
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTeamGameScore('Đội 1', _p1GamePoints, true, colors),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('vs', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                      ),
                      _buildTeamGameScore('Đội 2', _p2GamePoints, false, colors),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TennisGamePoint(team1Points: _p1GamePoints, team2Points: _p2GamePoints),
                  if (_isTiebreak)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('TIEBREAK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.amber)),
                    ),
                ],
              ),
            ),
          ),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),

          Text(
            _isTiebreak ? 'Tiebreak · 7 điểm, cách 2' : 'Game · 40 = Deuce · Ad = Advantage',
            style: TextStyle(fontSize: 10, color: colors.textMuted),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isSaving
                  ? null
                  : _p1GamePoints > 0 || _p2GamePoints > 0
                      ? _isTiebreak ? () {
                          // In tiebreak, manually finish
                          if ((_p1GamePoints - _p2GamePoints).abs() >= 2) {
                            if (_p1GamePoints > _p2GamePoints) _finishGameInSet(1);
                            else _finishGameInSet(2);
                          }
                        } : null  // Auto-detect works
                      : null,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded),
              label: Text('Chốt game hiện tại', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _finishedSets.isEmpty ? null : () => _finishMatch(resolveSportConfig(null, SportRuleKind.tennis)),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
            ),
            child: Text('Kết thúc trận', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamGameScore(String name, int gamePoints, bool isTeam1, AppColorsExtension colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () => _removePoint(isTeam1),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: colors.bgSurface, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.remove_rounded, size: 18),
              ),
            ),
            SizedBox(
              width: 50,
              child: Center(
                child: Text(
                  '${_isTiebreak ? gamePoints : tennisPointLabel(gamePoints)}',
                  style: TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w900,
                    color: isTeam1 ? const Color(0xFF2979FF) : const Color(0xFFEA580C),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _awardPoint(isTeam1),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: (isTeam1 ? const Color(0xFF2979FF) : const Color(0xFFEA580C)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_rounded, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }

  MatchModel _createMockMatch() {
    return MatchModel(
      id: '', round: 1, matchNumber: 1,
      bracketPosition: const BracketPosition(round: 1, position: 0),
      updatedAt: DateTime.now(),
    );
  }
}
