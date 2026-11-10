import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/group_stage_config.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_match_sheet.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_stage_data.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_bone_loading.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Mode { matrix, standings, rounds }

const double _sttWidth = 40;
const double _nameWidth = 140;
const double _cellWidth = 64;
const double _statWidth = 48;
const double _headerHeight = 36;
const double _minRowHeight = 44;

/// Public group stage: one edge-to-edge card per group with a cross matrix
/// (default), a standings table and a by-round list; tapping a match opens a
/// detail sheet. Mirrors the Web `PagedRoundRobinView`.
///
/// Edit mode (both [editableConfig] and [onConfigChanged] set, not
/// [editLocked]): long-press a team and drop it on another group card to move
/// it; [onConfigChanged] receives the new config and must handle its own
/// errors. Without them the view stays read-only.
class GroupStageView extends ConsumerStatefulWidget {
  const GroupStageView({
    super.key,
    required this.matches,
    required this.tournamentId,
    this.canScoreMatch = false,
    this.divisionId,
    this.bracketType,
    this.configuredLegs = 1,
    this.editableConfig,
    this.onConfigChanged,
    this.editLocked = false,
  });

  final List<MatchModel> matches;
  final String tournamentId;
  final bool canScoreMatch;
  final String? divisionId;
  final String? bracketType;
  final int configuredLegs;
  final GroupStageConfig? editableConfig;
  final Future<void> Function(GroupStageConfig next)? onConfigChanged;

  /// True once a group match started or has a result: teams can no longer move.
  final bool editLocked;

  @override
  ConsumerState<GroupStageView> createState() => _GroupStageViewState();
}

class _GroupStageViewState extends ConsumerState<GroupStageView> {
  final Map<String, _Mode> _modes = {};
  final Map<String, int> _legs = {};
  bool _saving = false;

  /// Moves [participantId] into config group [groupIndex]; ignored while a
  /// previous move is still being saved or when it is already in that group.
  Future<void> _drop(String participantId, int groupIndex) async {
    final config = widget.editableConfig;
    final save = widget.onConfigChanged;
    if (_saving || config == null || save == null) return;
    if (config.groups[groupIndex].participantIds.contains(participantId)) {
      return;
    }
    final next = config.moveParticipant(participantId, groupIndex: groupIndex);
    // Unknown id (e.g. unapproved team): nothing moved, so do not save/regenerate.
    if (identical(next, config)) return;
    _saving = true;
    try {
      await save(next);
    } finally {
      _saving = false;
    }
  }

  /// Teams that belong to no group, resolved by name from the tournament teams.
  List<Standing> _unassignedStandings(List<String> ids) {
    if (ids.isEmpty) return const [];
    final teams = ref.watch(teamsProvider(widget.tournamentId)).value;
    if (teams == null) return const [];
    final byId = {for (final team in teams) team.id: team};
    return [
      for (final id in ids)
        if (byId[id] case final team?)
          Standing(id: id, teamName: team.name, players: team.players),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final standingsAsync = ref.watch(
      standingsWithDivisionProvider((
        tournamentId: widget.tournamentId,
        divisionId: widget.divisionId,
      )),
    );
    final loaded = standingsAsync.asData?.value ?? const <Standing>[];
    final standings = loaded.isNotEmpty
        ? loaded
        : buildFallbackStandingsFromMatches(
            widget.matches,
            l10n.crossTableDefaultGroup,
          );

    if (standings.isEmpty) {
      if (standingsAsync.isLoading && widget.matches.isEmpty) {
        return const BoneStandingsLoading();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(child: Text(l10n.crossTableEmpty)),
      );
    }

    final matchSnapshot = ref
        .watch(
          matchesWithDivisionProvider((
            tournamentId: widget.tournamentId,
            divisionId: widget.divisionId,
          )),
        )
        .maybeWhen(data: (matches) => matches, orElse: () => widget.matches);
    final grouped = groupStandings(standings, l10n.crossTableDefaultGroup);
    final groupNames = grouped.keys.toList()..sort();
    final config = widget.editableConfig;
    final editing =
        config != null && widget.onConfigChanged != null && !widget.editLocked;
    int? groupIndexOf(String name) {
      if (config == null) return null;
      final prefix = l10n.groupStage_groupPrefix;
      String key(String raw) => groupDisplayName(raw, prefix).toLowerCase();
      final matching = [
        for (var i = 0; i < config.groups.length; i++)
          if (key(config.groups[i].name) == key(name)) i,
      ];
      // Ambiguous names would drop the team into the wrong group: stay off.
      return matching.length == 1 ? matching.first : null;
    }

    final isGsknockout =
        (widget.bracketType ?? '').trim().toLowerCase() ==
        AppConstants.bracketGroupStageKnockout;

    // Edit mode: configured groups that hold no team yet still need a drop
    // card, and teams outside every group are listed so they can be dragged in.
    final prefix = l10n.groupStage_groupPrefix;
    final shownIndexes = {for (final name in groupNames) groupIndexOf(name)};
    // Name -> config index of the groups to render as empty drop cards.
    final emptyIndexByName = {
      if (editing)
        for (var i = 0; i < config.groups.length; i++)
          if (!shownIndexes.contains(i)) config.groups[i].name: i,
    };
    final allNames = [...groupNames, ...emptyIndexByName.keys];
    if (emptyIndexByName.isNotEmpty) {
      allNames.sort(
        (a, b) =>
            groupDisplayName(a, prefix).compareTo(groupDisplayName(b, prefix)),
      );
    }
    final unassignedTeams = editing
        ? _unassignedStandings(config.unassignedParticipantIds)
        : const <Standing>[];

    return Column(
      children: [
        if (unassignedTeams.isNotEmpty) _UnassignedLane(teams: unassignedTeams),
        for (final name in allNames)
          if (!grouped.containsKey(name))
            _EmptyGroupCard(
              title: groupDisplayName(name, prefix),
              onDrop: (id) => _drop(id, emptyIndexByName[name]!),
            )
          else
            _GroupCard(
              tournamentId: widget.tournamentId,
              canScoreMatch: widget.canScoreMatch,
              name: name,
              title: groupDisplayName(name, l10n.groupStage_groupPrefix),
              standings: grouped[name]!,
              allMatches: matchesForGroup(
                grouped[name]!,
                name,
                groupNames.length == 1,
                matchSnapshot,
              ),
              configuredLegs: widget.configuredLegs,
              advancingCount: isGsknockout
                  ? (grouped[name]!.length / 2).ceil()
                  : 0,
              mode: _modes[name] ?? _Mode.matrix,
              leg: _legs[name] ?? 1,
              onMode: (mode) => setState(() => _modes[name] = mode),
              onLeg: (leg) => setState(() => _legs[name] = leg),
              dragEnabled: editing,
              onDrop: editing && groupIndexOf(name) != null
                  ? (id) => _drop(id, groupIndexOf(name)!)
                  : null,
            ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.tournamentId,
    this.canScoreMatch = false,
    required this.name,
    required this.title,
    required this.standings,
    required this.allMatches,
    required this.configuredLegs,
    required this.advancingCount,
    required this.mode,
    required this.leg,
    required this.onMode,
    required this.onLeg,
    this.dragEnabled = false,
    this.onDrop,
  });

  final String tournamentId;
  final bool canScoreMatch;
  final String name;
  final String title;
  final List<Standing> standings;
  final List<MatchModel> allMatches;
  final int configuredLegs;
  final int advancingCount;
  final _Mode mode;
  final int leg;
  final ValueChanged<_Mode> onMode;
  final ValueChanged<int> onLeg;
  final bool dragEnabled;
  final ValueChanged<String>? onDrop;

  @override
  Widget build(BuildContext context) {
    final onDrop = this.onDrop;
    if (onDrop == null) return _card(context, false);
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, _) =>
          _card(context, candidates.isNotEmpty),
    );
  }

  Widget _card(BuildContext context, bool highlighted) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final count = standings.length;
    final maxLeg = allMatches.fold<int>(
      configuredLegs.clamp(1, 5),
      (max, m) => legForMatch(m, count) > max ? legForMatch(m, count) : max,
    );
    final currentLeg = leg.clamp(1, maxLeg);
    final legMatches = allMatches
        .where((m) => legForMatch(m, count) == currentLeg)
        .toList(growable: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border.symmetric(
          horizontal: BorderSide(
            color: highlighted ? AppTheme.primary : colors.border,
            width: highlighted ? 2 : 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.primary.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  l10n.standings_groupTeams(count),
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
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ModeChip(
                  label: l10n.groupStage_modeMatrix,
                  selected: mode == _Mode.matrix,
                  onTap: () => onMode(_Mode.matrix),
                ),
                ModeChip(
                  label: l10n.groupStage_modeStandings,
                  selected: mode == _Mode.standings,
                  onTap: () => onMode(_Mode.standings),
                ),
                ModeChip(
                  label: l10n.groupStage_modeRounds,
                  selected: mode == _Mode.rounds,
                  onTap: () => onMode(_Mode.rounds),
                ),
              ],
            ),
          ),
          if (maxLeg > 1)
            _LegSwitch(current: currentLeg, max: maxLeg, onChanged: onLeg),
          switch (mode) {
            _Mode.matrix => _MatrixTable(
              tournamentId: tournamentId,
              canScoreMatch: canScoreMatch,
              title: title,
              standings: standings,
              matches: legMatches,
              dragEnabled: dragEnabled,
            ),
            _Mode.standings => _StandingsTable(
              standings: standings,
              football: allMatches.any(isFootballMatch),
              advancingCount: advancingCount,
              dragEnabled: dragEnabled,
            ),
            _Mode.rounds => _LegMatchList(
              tournamentId: tournamentId,
              canScoreMatch: canScoreMatch,
              title: title,
              leg: currentLeg,
              matches: legMatches,
            ),
          },
        ],
      ),
    );
  }
}

/// Pill used to switch views; shared with the playoff view.
class ModeChip extends StatelessWidget {
  const ModeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppTheme.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Drop card of a configured group that has no team yet (edit mode only).
class _EmptyGroupCard extends StatelessWidget {
  const _EmptyGroupCard({required this.title, required this.onDrop});

  final String title;
  final ValueChanged<String> onDrop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, _) {
        final highlighted = candidates.isNotEmpty;
        return Container(
          key: ValueKey('group-empty-$title'),
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.bgCard,
            border: Border.symmetric(
              horizontal: BorderSide(
                color: highlighted ? AppTheme.primary : colors.border,
                width: highlighted ? 2 : 1,
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 18,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                l10n.groupStage_emptyGroupDrop,
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Teams outside every group; each row can be dragged onto a group card.
class _UnassignedLane extends StatelessWidget {
  const _UnassignedLane({required this.teams});

  final List<Standing> teams;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Container(
      key: const ValueKey('group-unassigned-lane'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border.symmetric(horizontal: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: colors.textMuted.withValues(alpha: 0.08),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.groupAssignmentUnassigned,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  l10n.standings_groupTeams(teams.length),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          for (final team in teams)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _sideLines(context, team, draggable: true),
            ),
        ],
      ),
    );
  }
}

class _LegSwitch extends StatelessWidget {
  const _LegSwitch({
    required this.current,
    required this.max,
    required this.onChanged,
  });

  final int current;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    Widget arrow(IconData icon, String tooltip, int? target) => IconButton(
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: tooltip,
      onPressed: target == null ? null : () => onChanged(target),
      icon: Icon(
        icon,
        color: target == null
            ? colors.textMuted.withValues(alpha: 0.3)
            : AppTheme.primary,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          arrow(
            Icons.chevron_left_rounded,
            l10n.crossTablePreviousLeg,
            current > 1 ? current - 1 : null,
          ),
          Text(
            l10n.crossTableLegIndicator(current, max),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
          ),
          arrow(
            Icons.chevron_right_rounded,
            l10n.crossTableNextLeg,
            current < max ? current + 1 : null,
          ),
        ],
      ),
    );
  }
}

/// Table whose first columns stay put while the rest scrolls sideways.
/// Every row (and both headers) share [rowHeight], so the halves line up.
class _SplitTable extends StatelessWidget {
  const _SplitTable({
    required this.leftWidth,
    required this.leftHeader,
    required this.leftRows,
    required this.rightHeader,
    required this.rightRows,
    required this.rowHeight,
  });

  final double leftWidth;
  final List<Widget> leftHeader;
  final List<List<Widget>> leftRows;
  final List<Widget> rightHeader;
  final List<List<Widget>> rightRows;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: leftWidth,
          child: Column(
            children: [
              Row(children: leftHeader),
              for (final row in leftRows) Row(children: row),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                Row(children: rightHeader),
                for (final row in rightRows) Row(children: row),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _cell(
  BuildContext context, {
  required double width,
  required double height,
  required Widget child,
  Color? color,
  AlignmentGeometry alignment = Alignment.center,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 6),
  VoidCallback? onTap,
}) {
  final colors = context.colors;
  final box = Container(
    width: width,
    height: height,
    padding: padding,
    alignment: alignment,
    decoration: BoxDecoration(
      color: color,
      border: Border(
        right: BorderSide(color: colors.border),
        bottom: BorderSide(color: colors.border),
      ),
    ),
    child: child,
  );
  return onTap == null ? box : InkWell(onTap: onTap, child: box);
}

Widget _headerCell(
  BuildContext context,
  String text,
  double width, {
  AlignmentGeometry alignment = Alignment.center,
}) {
  return _cell(
    context,
    width: width,
    height: _headerHeight,
    color: context.colors.bgSurface,
    alignment: alignment,
    child: Text(
      text,
      maxLines: 1,
      softWrap: false,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: context.colors.textPrimary,
      ),
    ),
  );
}

Widget _sideLines(
  BuildContext context,
  Standing team, {
  bool teamOnly = false,
  bool draggable = false,
}) {
  Widget lines({double opacity = 1}) => Opacity(
    opacity: opacity,
    child: Align(
      alignment: Alignment.centerLeft,
      child: ParticipantSideLines(
        teamName: team.teamName.isEmpty ? null : team.teamName,
        players: team.players,
        teamOnly: teamOnly,
      ),
    ),
  );
  if (!draggable) return lines();
  return LongPressDraggable<String>(
    key: ValueKey('group-team-drag-${team.id}'),
    data: team.id,
    delay: bracketDragDelay,
    feedback: Material(
      color: context.colors.bgCard,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(width: _nameWidth, child: lines()),
    ),
    childWhenDragging: lines(opacity: 0.35),
    child: lines(),
  );
}

class _MatrixTable extends StatelessWidget {
  const _MatrixTable({
    required this.tournamentId,
    this.canScoreMatch = false,
    required this.title,
    required this.standings,
    required this.matches,
    this.dragEnabled = false,
  });

  final String tournamentId;
  final bool canScoreMatch;
  final String title;
  final List<Standing> standings;
  final List<MatchModel> matches;
  final bool dragEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final cells = buildMatrixCells(matches);
    final teamOnly = matches.any(isFootballMatch);
    final maxLines = cells.values.fold<int>(
      1,
      (max, c) => c.lines.length > max ? c.lines.length : max,
    );
    final doubles = !teamOnly && standings.any((s) => s.players.length > 1);
    final rowHeight = [
      _minRowHeight,
      if (doubles) 56.0,
      maxLines * 16.0 + 12,
    ].reduce((a, b) => a > b ? a : b);

    Widget scoreCell(Standing row, Standing col) {
      if (row.id == col.id) {
        return _cell(
          context,
          width: _cellWidth,
          height: rowHeight,
          color: colors.bgSurface.withValues(alpha: 0.7),
          child: const SizedBox.shrink(),
        );
      }
      final cell = cells['${row.id}_${col.id}'];
      return _cell(
        context,
        width: _cellWidth,
        height: rowHeight,
        onTap: cell == null
            ? null
            : () => showGroupMatchSheet(
                context,
                match: cell.match,
                tournamentId: tournamentId,
                canScore: canScoreMatch,
                title: l10n.groupStage_sheetTitle(
                  title,
                  legForMatch(cell.match, standings.length),
                ),
              ),
        child: cell == null || cell.lines.isEmpty
            ? Text('-', style: TextStyle(color: colors.textMuted))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final line in cell.lines)
                    Text(
                      line,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                ],
              ),
      );
    }

    return _SplitTable(
      leftWidth: _sttWidth + _nameWidth,
      rowHeight: rowHeight,
      leftHeader: [
        _headerCell(context, l10n.groupStage_stt, _sttWidth),
        _headerCell(
          context,
          l10n.groupStage_participantHeader,
          _nameWidth,
          alignment: Alignment.centerLeft,
        ),
      ],
      leftRows: [
        for (var i = 0; i < standings.length; i++)
          [
            _cell(
              context,
              width: _sttWidth,
              height: rowHeight,
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
            ),
            _cell(
              context,
              width: _nameWidth,
              height: rowHeight,
              alignment: Alignment.centerLeft,
              child: _sideLines(
                context,
                standings[i],
                teamOnly: teamOnly,
                draggable: dragEnabled,
              ),
            ),
          ],
      ],
      rightHeader: [
        for (var i = 0; i < standings.length; i++)
          _headerCell(context, '${i + 1}', _cellWidth),
        _headerCell(context, l10n.groupStage_wl, _cellWidth),
      ],
      rightRows: [
        for (final row in standings)
          [
            for (final col in standings) scoreCell(row, col),
            _cell(
              context,
              width: _cellWidth,
              height: rowHeight,
              child: Text(
                '${row.won} / ${row.lost}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ],
      ],
    );
  }
}

class _StandingsTable extends StatelessWidget {
  const _StandingsTable({
    required this.standings,
    required this.football,
    required this.advancingCount,
    this.dragEnabled = false,
  });

  final List<Standing> standings;
  final bool football;
  final int advancingCount;
  final bool dragEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final rowHeight = standings.any((s) => s.players.length > 1 && !football)
        ? 56.0
        : _minRowHeight;
    String signed(int v) => v > 0 ? '+$v' : '$v';

    final columns = football
        ? [
            (l10n.standings_playedShort, (Standing s) => '${s.played}'),
            (l10n.standings_wonShort, (Standing s) => '${s.won}'),
            (l10n.standings_drawnShort, (Standing s) => '${s.drawn}'),
            (l10n.standings_lostShort, (Standing s) => '${s.lost}'),
            (l10n.standings_pointsForShort, (Standing s) => '${s.pointsFor}'),
            (
              l10n.standings_pointsAgainstShort,
              (Standing s) => '${s.pointsAgainst}',
            ),
            (
              l10n.standings_differenceShort,
              (Standing s) => signed(s.pointDifference),
            ),
            (l10n.standings_pointsShort, (Standing s) => '${s.totalPoints}'),
          ]
        : [
            (l10n.standings_matches, (Standing s) => '${s.played}'),
            (l10n.standings_winsShort, (Standing s) => '${s.won}'),
            (l10n.standings_lossesShort, (Standing s) => '${s.lost}'),
            (l10n.standings_points, (Standing s) => '${s.totalPoints}'),
            (
              l10n.standings_difference,
              (Standing s) => signed(s.pointDifference),
            ),
          ];
    final statWidth = football ? _statWidth : 56.0;

    Color? tint(int i) =>
        i < advancingCount ? colors.success.withValues(alpha: 0.06) : null;

    return _SplitTable(
      leftWidth: _sttWidth + _nameWidth,
      rowHeight: rowHeight,
      leftHeader: [
        _headerCell(context, l10n.standings_rank, _sttWidth),
        _headerCell(
          context,
          l10n.groupStage_participantHeader,
          _nameWidth,
          alignment: Alignment.centerLeft,
        ),
      ],
      leftRows: [
        for (var i = 0; i < standings.length; i++)
          [
            _cell(
              context,
              width: _sttWidth,
              height: rowHeight,
              color: tint(i),
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: i < advancingCount
                      ? colors.success
                      : colors.textSecondary,
                ),
              ),
            ),
            _cell(
              context,
              width: _nameWidth,
              height: rowHeight,
              color: tint(i),
              alignment: Alignment.centerLeft,
              child: _sideLines(
                context,
                standings[i],
                teamOnly: football,
                draggable: dragEnabled,
              ),
            ),
          ],
      ],
      rightHeader: [
        for (final c in columns) _headerCell(context, c.$1, statWidth),
      ],
      rightRows: [
        for (var i = 0; i < standings.length; i++)
          [
            for (final c in columns)
              _cell(
                context,
                width: statWidth,
                height: rowHeight,
                color: tint(i),
                child: Text(
                  c.$2(standings[i]),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
          ],
      ],
    );
  }
}

/// Matches of the selected leg, in play order. The Web names group matches by
/// leg only ("Bảng A • Lượt 1"); the internal round number is never shown.
class _LegMatchList extends StatelessWidget {
  const _LegMatchList({
    required this.tournamentId,
    this.canScoreMatch = false,
    required this.title,
    required this.leg,
    required this.matches,
  });

  final String tournamentId;
  final bool canScoreMatch;
  final String title;
  final int leg;
  final List<MatchModel> matches;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        children: [
          for (final m in matches)
            RoundMatchCard(
              match: m,
              onTap: () => showGroupMatchSheet(
                context,
                match: m,
                tournamentId: tournamentId,
                canScore: canScoreMatch,
                title: l10n.groupStage_sheetTitle(title, leg),
              ),
            ),
        ],
      ),
    );
  }
}

class RoundMatchCard extends StatelessWidget {
  const RoundMatchCard({super.key, required this.match, required this.onTap});

  final MatchModel match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final status = groupMatchStatus(context, match);

    Widget side(int s) {
      final scores = groupSideScores(match, s);
      final won =
          match.isCompleted &&
          match.winnerId.isNotEmpty &&
          match.winnerId == (s == 1 ? match.team1Id : match.team2Id);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ParticipantSideLines(
                  teamName: matchSideTeamName(match, s),
                  players: matchSidePlayers(match, s),
                  teamOnly: isFootballMatch(match),
                  won: won,
                ),
              ),
            ),
            if (scores.isNotEmpty)
              Text(
                scores.join('  '),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: won ? AppTheme.primary : colors.textPrimary,
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: status.color,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      groupMatchPlace(context, match),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              side(1),
              side(2),
            ],
          ),
        ),
      ),
    );
  }
}
