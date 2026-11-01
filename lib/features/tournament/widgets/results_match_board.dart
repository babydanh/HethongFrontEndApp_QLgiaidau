import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/core/utils/match_code.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_schedule_dialog.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_score_entry_chooser.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/results_rounds.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_actions.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _BoardFilter { all, live, upcoming, finished }

/// Match board shared by the "Đang diễn ra" tab and the management view, the
/// same shape as the Web `ResultsBoard`: filter chips, a player search, a
/// "Tới vòng" menu, a red "Đang đấu" box on top and one box per round.
/// Organisers see the match code and the score / schedule buttons; viewers see
/// a running number and only read.
class ResultsMatchBoard extends ConsumerStatefulWidget {
  const ResultsMatchBoard({
    super.key,
    required this.tournamentId,
    required this.isLite,
    required this.canManage,
    this.divisionId,
  });

  final String tournamentId;
  final bool isLite;
  final bool canManage;

  /// Null lists every division.
  final String? divisionId;

  @override
  ConsumerState<ResultsMatchBoard> createState() => _ResultsMatchBoardState();
}

class _ResultsMatchBoardState extends ConsumerState<ResultsMatchBoard> {
  _BoardFilter _filter = _BoardFilter.all;
  String _query = '';
  final Map<String, GlobalKey> _roundKeys = {};

  List<MatchModel> _divisionMatches() {
    // `value` keeps the last data when a refresh fails.
    final async = ref.watch(
      widget.isLite
          ? liteBracketMatchesProvider(widget.tournamentId)
          : matchesProvider(widget.tournamentId),
    );
    final all = async.value ?? const <MatchModel>[];
    final id = widget.divisionId;
    return id == null
        ? all
        : all.where((m) => matchDivisionId(m) == id).toList();
  }

  VoidCallback? _scoreAction(MatchModel match) =>
      widget.canManage && canEnterScore(match)
      ? () => MatchScoreEntryChooser.show(
          context,
          match: match,
          tournamentId: widget.tournamentId,
        )
      : null;

  Future<void> _openSchedule(MatchModel match) async {
    final saved = await showMatchScheduleDialog(
      context,
      tournamentId: widget.tournamentId,
      match: match,
    );
    if (saved != true || !mounted) return;
    ref.invalidate(
      widget.isLite
          ? liteBracketMatchesProvider(widget.tournamentId)
          : matchesProvider(widget.tournamentId),
    );
  }

  /// Organisers can schedule any real match that is not live or closed.
  VoidCallback? _scheduleAction(MatchModel match) =>
      widget.canManage && !match.isBye && !isScheduleLocked(match)
      ? () => _openSchedule(match)
      : null;

  bool _matchesQuery(MatchModel match) {
    final query = normalizeParticipantText(_query).toLowerCase();
    if (query.isEmpty) return true;
    return [1, 2].any(
      (side) => participantLabel(
        teamName: matchSideTeamName(match, side),
        players: matchSidePlayers(match, side),
        teamOnly: isFootballMatch(match),
      ).toLowerCase().contains(query),
    );
  }

  bool _passesFilter(MatchModel match) => switch (_filter) {
    _BoardFilter.all => true,
    _BoardFilter.live => isLiveMatch(match),
    _BoardFilter.upcoming => !isMatchClosed(match) && !isLiveMatch(match),
    _BoardFilter.finished => isMatchClosed(match),
  };

  String _rowLabel(MatchModel match, int index) {
    final code = widget.canManage ? matchCodeOrNull(match) : null;
    return code == null ? '${index + 1}' : '#$code';
  }

  ResultsMatchRow _row(MatchModel match, int index) => ResultsMatchRow(
    key: ValueKey('results-row-${match.id}'),
    match: match,
    label: _rowLabel(match, index),
    onTap: isLiveMatch(match)
        ? () => context.push(
            NavigationHelper.getLiveMatchRoute(widget.tournamentId, match.id),
          )
        : null,
    onScore: _scoreAction(match),
    onSchedule: _scheduleAction(match),
  );

  void _jumpTo(String roundKey) {
    final target = _roundKeys[roundKey]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final all = _divisionMatches();
    final rounds = buildResultsRounds(
      all,
      (m) => MatchRoundLabel.formatRound(match: m, allMatches: all, l10n: l10n),
    );
    final live = splitResultsMatches(all).live;
    if (rounds.isEmpty && live.isEmpty) return _empty(context, l10n);

    final showLive =
        (_filter == _BoardFilter.all || _filter == _BoardFilter.live) &&
        live.any(_matchesQuery);
    final boxes = [
      if (showLive)
        _MatchBox(
          key: const ValueKey('results-box-live'),
          title: l10n.resultsBoard_filterLive,
          tone: LavishTone.bad,
          rows: [
            for (final (i, m) in live.where(_matchesQuery).indexed) _row(m, i),
          ],
        ),
      for (final round in rounds) ?_roundBox(round),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _filterChips(l10n),
        const SizedBox(height: 8),
        _searchRow(l10n, rounds),
        const SizedBox(height: 10),
        if (boxes.isEmpty)
          _message(context, l10n.resultsBoard_noMatch)
        else
          ...boxes,
      ],
    );
  }

  Widget? _roundBox(ResultsRound round) {
    final matches = round.matches
        .where((m) => !isLiveMatch(m) && _passesFilter(m) && _matchesQuery(m))
        .toList();
    if (matches.isEmpty) return null;
    return _MatchBox(
      key: _roundKeys.putIfAbsent(round.key, GlobalKey.new),
      title: round.label,
      rows: [for (final (i, m) in matches.indexed) _row(m, i)],
    );
  }

  Widget _filterChips(AppLocalizations l10n) {
    final labels = {
      _BoardFilter.all: l10n.filterAll,
      _BoardFilter.live: l10n.resultsBoard_filterLive,
      _BoardFilter.upcoming: l10n.resultsBoard_upcoming,
      _BoardFilter.finished: l10n.resultsBoard_finished,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in labels.entries) ...[
            LavishChipButton(
              key: ValueKey('results-filter-${entry.key.name}'),
              label: entry.value,
              selected: entry.key == _filter,
              onPressed: () => setState(() => _filter = entry.key),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _searchRow(AppLocalizations l10n, List<ResultsRound> rounds) {
    final colors = LavishColors.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colors.line),
    );
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('results-search'),
            onChanged: (value) => setState(() => _query = value),
            style: TextStyle(fontSize: 13, color: colors.text),
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.resultsBoard_searchHint,
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              border: border,
              enabledBorder: border,
              focusedBorder: border,
            ),
          ),
        ),
        if (rounds.length > 1)
          PopupMenuButton<String>(
            key: const ValueKey('results-jump'),
            tooltip: l10n.resultsBoard_jumpToRound,
            icon: const Icon(Icons.format_list_numbered_rounded),
            onSelected: _jumpTo,
            itemBuilder: (_) => [
              for (final round in rounds)
                PopupMenuItem(value: round.key, child: Text(round.label)),
            ],
          ),
      ],
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: _message(context, l10n.resultsBoard_empty),
  );

  Widget _message(BuildContext context, String text) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        text,
        style: TextStyle(color: context.colors.textMuted, fontSize: 13),
      ),
    ),
  );
}

/// A bordered box with a title and a count, holding the rows of one round (or
/// the live matches when [tone] is [LavishTone.bad]).
class _MatchBox extends StatelessWidget {
  const _MatchBox({
    super.key,
    required this.title,
    required this.rows,
    this.tone = LavishTone.neutral,
  });

  final String title;
  final List<Widget> rows;
  final LavishTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = LavishColors.of(context);
    final accent = tone == LavishTone.neutral
        ? colors.muted
        : colors.solid(tone);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tone == LavishTone.neutral ? colors.line : accent,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Text(
              '$title · ${rows.length}'.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.66,
                color: accent,
              ),
            ),
          ),
          for (final row in rows) ...[
            Divider(height: 1, color: colors.rowLine),
            row,
          ],
        ],
      ),
    );
  }
}
