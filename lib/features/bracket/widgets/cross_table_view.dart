import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';

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
    final standingsAsync = ref.watch(
      standingsWithDivisionProvider((
        tournamentId: widget.tournamentId,
        divisionId: widget.divisionId,
      )),
    );

    return standingsAsync.when(
      data: (standings) {
        if (standings.isEmpty) {
          return _buildEmptyState(context, 'Chưa có dữ liệu đội thi đấu');
        }

        final groupedStandings = _groupStandings(standings);
        final matchSnapshot = ref.watch(matchesWithDivisionProvider((
          tournamentId: widget.tournamentId,
          divisionId: widget.divisionId,
        ))).maybeWhen(
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
            final maxLeg = allGroupMatches.fold<int>(widget.configuredLegs.clamp(1, 5), (currentMax, match) {
              final leg = _legForMatch(match, groupRows.length);
              return leg > currentMax ? leg : currentMax;
            });
            final currentLeg = (_groupLegs[groupName] ?? 1).clamp(1, maxLeg);
            final groupMatches = allGroupMatches
                .where((match) => _legForMatch(match, groupRows.length) == currentLeg)
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == groupNames.length - 1 ? 0 : 20,
              ),
              child: _GroupCrossTable(
                title: groupName,
                standings: groupRows,
                matches: groupMatches,
                currentLeg: currentLeg,
                maxLeg: maxLeg,
                onPrevLeg: currentLeg > 1
                    ? () => setState(() => _groupLegs[groupName] = currentLeg - 1)
                    : null,
                onNextLeg: currentLeg < maxLeg
                    ? () => setState(() => _groupLegs[groupName] = currentLeg + 1)
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.colors.error),
            const SizedBox(height: 12),
            Text(
              'Lỗi: $e',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Standing>> _groupStandings(List<Standing> standings) {
    final grouped = <String, List<Standing>>{};
    for (final standing in standings) {
      final groupName = standing.group.trim().isNotEmpty
          ? standing.group.trim()
          : 'Bảng A';
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
    return match.round < 1 ? 1 : match.round;
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
  final String title;
  final List<Standing> standings;
  final List<MatchModel> matches;
  final int currentLeg;
  final int maxLeg;
  final VoidCallback? onPrevLeg;
  final VoidCallback? onNextLeg;

  const _GroupCrossTable({
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
                    maxLeg > 1 ? '$title - VÒNG $currentLeg'.toUpperCase() : title.toUpperCase(),
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
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Vòng trước',
                    onPressed: onPrevLeg,
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: onPrevLeg != null ? AppTheme.primary : colors.textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Vòng $currentLeg / $maxLeg',
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
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Vòng tiếp theo',
                    onPressed: onNextLeg,
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: onNextLeg != null ? AppTheme.primary : colors.textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '${standings.length} đội',
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
      if (!(match.status == 'completed' || match.status == 'walkover'))
        continue;
      if (match.team1Id.isEmpty || match.team2Id.isEmpty) continue;

      final p1Result = _resultFor(match, match.team1Id);
      final p2Result = _resultFor(match, match.team2Id);
      final p1Label = '${match.score1}-${match.score2}';
      final p2Label = '${match.score2}-${match.score1}';

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
    if (match.score1 == match.score2) {
      return _MatchResult.draw;
    }
    final isTeam1 = participantId == match.team1Id;
    final participantScore = isTeam1 ? match.score1 : match.score2;
    final opponentScore = isTeam1 ? match.score2 : match.score1;
    return participantScore > opponentScore
        ? _MatchResult.win
        : _MatchResult.loss;
  }
}

class _ScoreCell {
  final String label;
  final _MatchResult result;

  const _ScoreCell(this.label, this.result);
}

enum _MatchResult { win, loss, draw }
