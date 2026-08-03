import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class CrossTableView extends ConsumerStatefulWidget {
  final List<MatchModel> matches;
  final String tournamentId;
  final String? divisionId;
  final int configuredLegs;

  const CrossTableView({
    super.key,
    required this.matches,
    required this.tournamentId,
    this.divisionId,
    this.configuredLegs = 1,
  });

  @override
  ConsumerState<CrossTableView> createState() => _CrossTableViewState();
}

class _CrossTableViewState extends ConsumerState<CrossTableView> {
  final Map<String, int> _groupLegs = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final standingsAsync = ref.watch(
      standingsWithDivisionProvider((
        tournamentId: widget.tournamentId,
        divisionId: widget.divisionId,
      )),
    );

    final loadedStandings = standingsAsync.asData?.value ?? standingsAsync.value ?? const [];
    final standings = loadedStandings.isNotEmpty
        ? loadedStandings
        : _buildFallbackStandingsFromMatches(widget.matches, l10n);

    if (standings.isEmpty) {
      if (standingsAsync.isLoading && widget.matches.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        );
      }
      return _buildEmptyState(context, l10n.crossTableEmpty);
    }

    final groupedStandings = _groupStandings(standings, l10n);
    final matchSnapshot = ref
        .watch(
          matchesWithDivisionProvider((
            tournamentId: widget.tournamentId,
            divisionId: widget.divisionId,
          )),
        )
        .maybeWhen(
          data: (matches) => matches,
          orElse: () => widget.matches,
        );
    final groupNames = groupedStandings.keys.toList()..sort();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: groupNames.length,
      itemBuilder: (context, index) {
        final groupName = groupNames[index];
        final groupRows = groupedStandings[groupName]!;
        final allGroupMatches = _matchesForGroup(
          groupRows,
          groupName,
          groupNames.length == 1,
          matchSnapshot,
        );
        final maxLeg = allGroupMatches.fold<int>(
          widget.configuredLegs.clamp(1, 5),
          (currentMax, match) {
            final leg = _legForMatch(match, groupRows.length);
            return leg > currentMax ? leg : currentMax;
          },
        );
        final currentLeg = (_groupLegs[groupName] ?? 1).clamp(1, maxLeg);
        final groupMatches = allGroupMatches
            .where(
              (match) =>
                  _legForMatch(match, groupRows.length) == currentLeg,
            )
            .toList();

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == groupNames.length - 1 ? 0 : 20,
          ),
          child: _GroupCrossTable(
            l10n: l10n,
            title: groupName,
            standings: groupRows,
            matches: groupMatches,
            currentLeg: currentLeg,
            maxLeg: maxLeg,
            onPrevLeg: currentLeg > 1
                ? () =>
                      setState(() => _groupLegs[groupName] = currentLeg - 1)
                : null,
            onNextLeg: currentLeg < maxLeg
                ? () =>
                      setState(() => _groupLegs[groupName] = currentLeg + 1)
                : null,
          ),
        );
      },
    );
  }

  List<Standing> _buildFallbackStandingsFromMatches(
    List<MatchModel> matches,
    AppLocalizations l10n,
  ) {
    final standingsMap = <String, Standing>{};
    for (final m in matches) {
      final grp = (m.groupName != null && m.groupName!.isNotEmpty)
          ? m.groupName!
          : l10n.crossTableDefaultGroup;
      if (m.team1Name.isNotEmpty && m.team1Name != 'TBD' && m.team1Name != 'BYE') {
        final key = m.team1Id.isNotEmpty ? m.team1Id : m.team1Name;
        standingsMap.putIfAbsent(
          key,
          () => Standing(
            id: key,
            teamName: m.team1Name,
            group: grp,
          ),
        );
      }
      if (m.team2Name.isNotEmpty && m.team2Name != 'TBD' && m.team2Name != 'BYE') {
        final key = m.team2Id.isNotEmpty ? m.team2Id : m.team2Name;
        standingsMap.putIfAbsent(
          key,
          () => Standing(
            id: key,
            teamName: m.team2Name,
            group: grp,
          ),
        );
      }
    }
    return standingsMap.values.toList();
  }

  Map<String, List<Standing>> _groupStandings(
    List<Standing> standings,
    AppLocalizations l10n,
  ) {
    final grouped = <String, List<Standing>>{};
    for (final standing in standings) {
      final groupName = standing.group.trim().isNotEmpty
          ? standing.group.trim()
          : l10n.crossTableDefaultGroup;
      grouped.putIfAbsent(groupName, () => []).add(standing);
    }
    return grouped;
  }

  List<MatchModel> _matchesForGroup(
    List<Standing> standings,
    String groupName,
    bool allowLegacyParticipantFallback,
    List<MatchModel> matches,
  ) {
    final participantIds = standings.map((s) => s.id).toSet();
    final normalizedGroupName = groupName.trim().toLowerCase();

    return matches.where((match) {
      if (match.isBye) return false;

      if (_isKnockoutMatch(match)) return false;

      final matchGroup = (match.groupName ?? '').trim().toLowerCase();
      final sameGroupByName = matchGroup == normalizedGroupName;
      final sameGroupByParticipant =
          participantIds.contains(match.team1Id) &&
          participantIds.contains(match.team2Id);

      return sameGroupByName ||
          (allowLegacyParticipantFallback &&
              matchGroup.isEmpty &&
              sameGroupByParticipant);
    }).toList()..sort((a, b) {
      final roundCompare = a.round.compareTo(b.round);
      return roundCompare != 0
          ? roundCompare
          : a.matchNumber.compareTo(b.matchNumber);
    });
  }

  bool _isKnockoutMatch(MatchModel match) {
    final stage = '${match.stageName ?? ''} ${match.stageType ?? ''}'
        .toLowerCase();
    return stage.contains('knockout') ||
        stage.contains('playoff') ||
        stage.contains('elimination') ||
        stage.contains('loại trực tiếp') ||
        stage.contains('nhánh thắng') ||
        stage.contains('nhánh thua') ||
        stage.contains('grand final') ||
        stage.contains('semi') ||
        stage.contains('quarter');
  }

  int _legForMatch(MatchModel match, int participantCount) {
    // Backend stores roundNumber continuously across legs (for example
    // rounds 1..3 are leg 1 and 4..6 are leg 2). Treating roundNumber as the
    // leg made the second leg reuse the first leg's matrix/score selection.
    final slots = participantCount.isOdd
        ? participantCount + 1
        : participantCount;
    final roundsPerLeg = (slots - 1).clamp(1, 1000);
    final round = match.round < 1 ? 1 : match.round;
    return ((round - 1) ~/ roundsPerLeg) + 1;
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 64,
            color: context.colors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _GroupCrossTable extends StatelessWidget {
  final AppLocalizations l10n;
  final String title;
  final List<Standing> standings;
  final List<MatchModel> matches;
  final int currentLeg;
  final int maxLeg;
  final VoidCallback? onPrevLeg;
  final VoidCallback? onNextLeg;

  const _GroupCrossTable({
    required this.l10n,
    required this.title,
    required this.standings,
    required this.matches,
    this.currentLeg = 1,
    this.maxLeg = 1,
    this.onPrevLeg,
    this.onNextLeg,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scoreCells = _buildScoreCells(matches);

    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.grid_on_rounded,
                  size: 18,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    maxLeg > 1
                        ? l10n
                              .crossTableLegTitle(title, currentLeg)
                              .toUpperCase()
                        : title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (maxLeg > 1) ...[
                  IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    tooltip: l10n.crossTablePreviousLeg,
                    onPressed: onPrevLeg,
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: onPrevLeg != null
                          ? AppTheme.primary
                          : colors.textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.crossTableLegIndicator(currentLeg, maxLeg),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    tooltip: l10n.crossTableNextLeg,
                    onPressed: onNextLeg,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: onNextLeg != null
                          ? AppTheme.primary
                          : colors.textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  l10n.crossTableTeamCount(standings.length),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildGrid(context, scoreCells),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, Map<String, _ScoreCell> scoreCells) {
    const cellWidth = 92.0;
    const rowLabelWidth = 150.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildHeaderCell(context, 'Đội', rowLabelWidth, alignLeft: true),
            ...standings.map(
              (team) => _buildHeaderCell(context, team.teamName, cellWidth),
            ),
          ],
        ),
        ...standings.asMap().entries.map((rowEntry) {
          final rowIdx = rowEntry.key;
          final rowTeam = rowEntry.value;
          final isLastRow = rowIdx == standings.length - 1;

          return Row(
            children: [
              _buildTeamCell(
                context,
                rowTeam.teamName,
                rowLabelWidth,
                isLastRow,
              ),
              ...standings.asMap().entries.map((colEntry) {
                final colIdx = colEntry.key;
                final colTeam = colEntry.value;
                final isLastCol = colIdx == standings.length - 1;
                final isSelf = rowTeam.id == colTeam.id;

                if (isSelf) {
                  return _buildSelfCell(
                    context,
                    cellWidth,
                    isLastRow,
                    isLastCol,
                  );
                }

                final score = scoreCells['${rowTeam.id}_${colTeam.id}'];
                return _buildScoreCell(
                  context,
                  score,
                  cellWidth,
                  isLastRow,
                  isLastCol,
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildHeaderCell(
    BuildContext context,
    String label,
    double width, {
    bool alignLeft = false,
  }) {
    return Container(
      width: width,
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        border: Border(
          right: BorderSide(color: context.colors.border),
          bottom: BorderSide(color: context.colors.border),
        ),
      ),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: context.colors.textPrimary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
      ),
    );
  }

  Widget _buildTeamCell(
    BuildContext context,
    String label,
    double width,
    bool isLastRow,
  ) {
    return Container(
      width: width,
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        border: Border(
          right: BorderSide(color: context.colors.border),
          bottom: BorderSide(
            color: isLastRow ? context.colors.border : Colors.transparent,
          ),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSelfCell(
    BuildContext context,
    double width,
    bool isLastRow,
    bool isLastCol,
  ) {
    return Container(
      width: width,
      height: 46,
      decoration: BoxDecoration(
        color: context.colors.bgSurface.withValues(alpha: 0.55),
        borderRadius: isLastRow && isLastCol
            ? const BorderRadius.only(
                bottomRight: Radius.circular(AppTheme.radiusXL),
              )
            : null,
        border: Border(
          right: BorderSide(color: context.colors.border),
          bottom: BorderSide(
            color: isLastRow ? context.colors.border : Colors.transparent,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.remove_rounded,
        size: 16,
        color: context.colors.textMuted.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _buildScoreCell(
    BuildContext context,
    _ScoreCell? score,
    double width,
    bool isLastRow,
    bool isLastCol,
  ) {
    final colors = context.colors;
    final bgColor = switch (score?.result) {
      _MatchResult.win => colors.success.withValues(alpha: 0.12),
      _MatchResult.loss => colors.error.withValues(alpha: 0.10),
      _MatchResult.draw => colors.warning.withValues(alpha: 0.12),
      null => Colors.transparent,
    };
    final textColor = switch (score?.result) {
      _MatchResult.win => colors.success,
      _MatchResult.loss => colors.error,
      _MatchResult.draw => colors.warning,
      null => colors.textMuted,
    };

    return Container(
      width: width,
      height: 46,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: isLastRow && isLastCol
            ? const BorderRadius.only(
                bottomRight: Radius.circular(AppTheme.radiusXL),
              )
            : null,
        border: Border(
          right: BorderSide(color: colors.border),
          bottom: BorderSide(
            color: isLastRow ? colors.border : Colors.transparent,
          ),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        score?.label ?? '-',
        style: TextStyle(
          fontSize: 12,
          fontWeight: score == null ? FontWeight.w500 : FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  Map<String, _ScoreCell> _buildScoreCells(List<MatchModel> matches) {
    final cells = <String, _ScoreCell>{};

    for (final match in matches) {
      if (!(match.status == 'completed' || match.status == 'walkover')) {
        continue;
      }
      if (match.team1Id.isEmpty || match.team2Id.isEmpty) {
        continue;
      }

      final p1Result = _resultFor(match, match.team1Id);
      final p2Result = _resultFor(match, match.team2Id);
      final goals = _footballGoals(match);
      final p1Label = goals == null
          ? '${match.score1}-${match.score2}'
          : '${goals.$1}-${goals.$2}';
      final p2Label = goals == null
          ? '${match.score2}-${match.score1}'
          : '${goals.$2}-${goals.$1}';

      cells['${match.team1Id}_${match.team2Id}'] = _ScoreCell(
        p1Label,
        p1Result,
      );
      cells['${match.team2Id}_${match.team1Id}'] = _ScoreCell(
        p2Label,
        p2Result,
      );
    }

    return cells;
  }

  _MatchResult _resultFor(MatchModel match, String participantId) {
    if (match.winnerId.isNotEmpty) {
      return match.winnerId == participantId
          ? _MatchResult.win
          : _MatchResult.loss;
    }
    final goals = _footballGoals(match);
    final score1 = goals?.$1 ?? match.score1;
    final score2 = goals?.$2 ?? match.score2;
    if (score1 == score2) {
      return _MatchResult.draw;
    }
    final isTeam1 = participantId == match.team1Id;
    final participantScore = isTeam1 ? score1 : score2;
    final opponentScore = isTeam1 ? score2 : score1;
    return participantScore > opponentScore
        ? _MatchResult.win
        : _MatchResult.loss;
  }

  (int, int)? _footballGoals(MatchModel match) {
    final football = match.scoreDetails?['football'];
    if (football is! Map) return null;
    final p1 = football['team1Goals'] ?? football['p1Goals'];
    final p2 = football['team2Goals'] ?? football['p2Goals'];
    final score1 = p1 is num ? p1.toInt() : int.tryParse(p1?.toString() ?? '');
    final score2 = p2 is num ? p2.toInt() : int.tryParse(p2?.toString() ?? '');
    if (score1 == null || score2 == null || score1 < 0 || score2 < 0)
      return null;
    return (score1, score2);
  }
}

class _ScoreCell {
  final String label;
  final _MatchResult result;

  const _ScoreCell(this.label, this.result);
}

enum _MatchResult { win, loss, draw }
