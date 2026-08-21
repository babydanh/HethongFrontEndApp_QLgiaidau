import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/draw_service.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class AutoDrawScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final bool isEmbedded;

  const AutoDrawScreen({
    super.key,
    required this.tournamentId,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<AutoDrawScreen> createState() => _AutoDrawScreenState();
}

class _AutoDrawScreenState extends ConsumerState<AutoDrawScreen> {
  bool _isDrawing = false;
  List<MatchModel> _previewMatches = [];
  bool _hasSaved = false;
  
  bool _isManualDrawMode = false;
  Set<String> _revealedTeamIds = {};
  List<String> _unrevealedTeamIds = [];

  void _generatePreview(List<Team> teams, String bracketType, int roundCount, {bool isManual = false}) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isDrawing = true;
    });

    try {
      // Simulate slight delay for UX
      await Future.delayed(const Duration(milliseconds: 600));
      
      final drawService = DrawService();
      final generated = drawService.generatePreviewMatches(
        tournamentId: widget.tournamentId,
        teams: teams,
        bracketType: bracketType,
        roundCount: roundCount,
      );

      if (mounted) {
        setState(() {
          _previewMatches = generated;
          _isDrawing = false;
          _hasSaved = false;
          
          if (isManual) {
            _isManualDrawMode = true;
            _revealedTeamIds.clear();
            _unrevealedTeamIds = teams.where((t) => t.id != 'BYE').map((t) => t.id).toList()
              ..shuffle(); // Randomize pick order
          } else {
            _isManualDrawMode = false;
            _revealedTeamIds = teams.map((t) => t.id).toSet();
            _unrevealedTeamIds.clear();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDrawing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.autoDraw_error(e.toString())), backgroundColor: context.colors.error),
        );
      }
    }
  }

  Future<void> _saveMatches(List<MatchModel> matches) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isDrawing = true);
    try {
      await ref.read(publishTournamentDrawUseCaseProvider).call(
            widget.tournamentId,
            matches,
          );

      if (mounted) {
        setState(() {
          _isDrawing = false;
          _hasSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.autoDraw_saved)),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDrawing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.autoDraw_error(e.toString))),
        );
      }
    }
  }

  Future<void> _clearDraw() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isDrawing = true);
    try {
      await ref.read(resetTournamentDrawUseCaseProvider).call(
            widget.tournamentId,
          );
      if (mounted) {
        setState(() {
          _isDrawing = false;
          _previewMatches = [];
          _hasSaved = false;
          _isManualDrawMode = false;
          _revealedTeamIds.clear();
          _unrevealedTeamIds.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.autoDraw_redraw)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDrawing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.autoDraw_error(e.toString))),
        );
      }
    }
  }

  @override
    Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teamsAsync = ref.watch(teamsProvider(widget.tournamentId));
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));
    final matchesAsync = ref.watch(matchesProvider(widget.tournamentId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.colors.bgDark,
        leading: widget.isEmbedded ? const SizedBox.shrink() : IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin/tournament/${widget.tournamentId}'),
        ),
        title: Text(l10n.autoDraw_title),
      ),
      backgroundColor: context.colors.bgDark,
      body: teamsAsync.when(
        data: (teams) {
          return tournamentAsync.when(
            data: (tournament) {
              if (tournament == null) return Center(child: Text(l10n.autoDraw_tournamentError));

              final bracketType = tournament.bracketType;
              final r1Matches = _previewMatches.where((m) {
                if (m.round != 1) return false;
                // Nếu là Double Elimination, ẩn các trận vòng 1 của nhánh thua (losers)
                if (m.bracketPosition.bracket == 'losers') return false;
                
                // Ẩn các trận rác sau khi bốc thăm (không phải cả 2 đều là TBD/BYE)
                final isTbdOrBye1 = m.team1Id.isEmpty || m.team1Id == 'BYE' || m.team1Name == 'TBD' || m.team1Name == 'BYE';
                final isTbdOrBye2 = m.team2Id.isEmpty || m.team2Id == 'BYE' || m.team2Name == 'TBD' || m.team2Name == 'BYE';
                
                // Nếu đang bốc thủ công và chưa bốc xong, VẪN hiển thị TBD để người dùng biết vị trí trống
                if (_isManualDrawMode && _unrevealedTeamIds.isNotEmpty) return true;
                
                // Nếu đã bốc xong (hoặc auto), ẩn các trận trống rỗng
                if (isTbdOrBye1 && isTbdOrBye2) return false;
                return true;
              }).toList();

              return matchesAsync.when(
                data: (matches) {
                  final hasSavedMatches = matches.isNotEmpty;
                  final hasStartedMatches = matches.any((m) => 
                      m.status == AppConstants.matchLive || 
                      m.status == AppConstants.matchCompleted ||
                      m.score1 > 0 || m.score2 > 0);
                  
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        color: context.colors.bgCard,
                        child: Column(
                          children: [
                            Text(l10n.autoDraw_teamCount(teams.length),
                                style: TextStyle(fontSize: 18, color: context.colors.textPrimary)),
                            const SizedBox(height: 8),
                            Text(l10n.autoDraw_format(bracketType),
                                style: TextStyle(fontSize: 14, color: context.colors.textSecondary)),
                            const SizedBox(height: 20),
                            if (hasStartedMatches)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.colors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  l10n.autoDraw_startedLocked,
                                  style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else if (hasSavedMatches)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: context.colors.error),
                                icon: const Icon(Icons.delete_forever),
                                label: Text(l10n.autoDraw_redraw),
                                onPressed: _isDrawing ? null : _clearDraw,
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.casino),
                                    label: Text(l10n.autoDraw_auto),
                                    onPressed: _isDrawing || _hasSaved
                                        ? null
                                        : () => _generatePreview(teams, bracketType, tournament.roundCount, isManual: false),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                                    icon: const Icon(Icons.pan_tool_alt),
                                    label: Text(l10n.autoDraw_manual),
                                    onPressed: _isDrawing || _hasSaved
                                        ? null
                                        : () => _generatePreview(teams, bracketType, tournament.roundCount, isManual: true),
                                  ),
                                ],
                              ),
                              if (_isManualDrawMode && _previewMatches.isNotEmpty && _unrevealedTeamIds.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Text(
                                  l10n.autoDraw_remaining(_unrevealedTeamIds.length),
                                  style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                                      icon: const Icon(Icons.touch_app),
                                      label: Text(l10n.autoDraw_oneTeam),
                                      onPressed: () {
                                        if (_unrevealedTeamIds.isNotEmpty) {
                                          setState(() {
                                            _revealedTeamIds.add(_unrevealedTeamIds.removeLast());
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 16),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _revealedTeamIds.addAll(_unrevealedTeamIds);
                                          _unrevealedTeamIds.clear();
                                        });
                                      },
                                      child: Text(l10n.autoDraw_revealAll, style: TextStyle(color: context.colors.textMuted)),
                                    ),
                                  ],
                                ),
                              ],
                          ],
                        ),
                      ),
                  if (_isDrawing)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      ),
                    )
                  else if (_previewMatches.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: r1Matches.length,
                        itemBuilder: (context, index) {
                          final match = r1Matches[index];
                          final hasBye = match.team1Name == 'BYE' || match.team2Name == 'BYE';
                          final realTeamId = match.team1Name == 'BYE' ? match.team2Id : match.team1Id;
                          final realTeamName = match.team1Name == 'BYE' ? match.team2Name : match.team1Name;
                          final isRevealed = _revealedTeamIds.contains(realTeamId);

                          return Card(
                            color: context.colors.bgSurface,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: hasBye
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          isRevealed ? realTeamName : '???',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: context.colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: context.colors.success.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: context.colors.success.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          l10n.autoDraw_bye,
                                          style: TextStyle(
                                            color: context.colors.success,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          (_revealedTeamIds.contains(match.team1Id) || match.team1Id == 'BYE') ? match.team1Name : '???',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: match.team1Name == 'BYE'
                                                  ? context.colors.textMuted
                                                  : context.colors.textPrimary),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(l10n.autoDraw_vs, style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold)),
                                      ),
                                      Expanded(
                                        child: Text(
                                          (_revealedTeamIds.contains(match.team2Id) || match.team2Id == 'BYE') ? match.team2Name : '???',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: match.team2Name == 'BYE'
                                                  ? context.colors.textMuted
                                                  : context.colors.textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: Center(
                        child: Text(l10n.autoDraw_previewHint,
                            style: TextStyle(color: context.colors.textMuted)),
                      ),
                    ),
                  if (_previewMatches.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: context.colors.success),
                        onPressed: (_isDrawing || _hasSaved || _unrevealedTeamIds.isNotEmpty)
                                    ? null
                                    : () => _saveMatches(_previewMatches),
                            child: Text(l10n.autoDraw_saveStart),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l10n.autoDraw_matchLoadError(e.toString))),
          );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l10n.autoDraw_error(e.toString))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.autoDraw_error(e.toString))),
      ),
    );
  }
}
