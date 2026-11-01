import 'dart:async';

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
import 'package:app_quanly_giaidau/features/tournament/widgets/results_board_palette.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _BoardFilter { all, live, upcoming, finished }

/// Round name only: the match code already sits in the row's first column, so
/// the label must not repeat it ("Bán kết", not "Bán kết - #BK02").
String _roundLabel(
  MatchModel match,
  List<MatchModel> all,
  AppLocalizations l10n,
) => MatchRoundLabel.formatRound(
  match: match,
  allMatches: all,
  l10n: l10n,
  includeMatchCode: false,
);

bool _passes(_BoardFilter filter, MatchModel match) => switch (filter) {
  _BoardFilter.all => true,
  _BoardFilter.live => isLiveMatch(match),
  _BoardFilter.upcoming => !isMatchClosed(match) && !isLiveMatch(match),
  _BoardFilter.finished => isMatchClosed(match),
};

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
  static const _searchDebounce = Duration(milliseconds: 250);

  _BoardFilter _filter = _BoardFilter.all;
  // Normalised search text; updated after a short pause, not on every key.
  String _needle = '';
  Timer? _searchTimer;
  final Map<String, GlobalKey> _roundKeys = {};

  // Everything below is derived from the match list, the division and the
  // locale. It is rebuilt only when one of them changes, so typing in the
  // search box or switching a filter chip never recomputes round labels.
  List<MatchModel>? _source;
  String? _derivedDivisionId;
  String? _derivedLocale;
  List<MatchModel> _all = const [];
  List<ResultsRound> _rounds = const [];
  List<MatchModel> _live = const [];
  Map<String, String> _liveRoundLabels = const {};
  Map<_BoardFilter, int> _counts = const {};
  final Map<String, (String?, String?)> _waiting = {};
  final Map<String, String> _haystack = {};

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  List<MatchModel> _sourceMatches() {
    // `value` keeps the last data when a refresh fails.
    final async = ref.watch(
      widget.isLite
          ? liteBracketMatchesProvider(widget.tournamentId)
          : matchesProvider(widget.tournamentId),
    );
    return async.value ?? const <MatchModel>[];
  }

  void _refreshDerived(List<MatchModel> source, AppLocalizations l10n) {
    final divisionId = widget.divisionId;
    if (identical(source, _source) &&
        divisionId == _derivedDivisionId &&
        l10n.localeName == _derivedLocale) {
      return;
    }
    _source = source;
    _derivedDivisionId = divisionId;
    _derivedLocale = l10n.localeName;
    final all = divisionId == null
        ? source
        : source.where((m) => matchDivisionId(m) == divisionId).toList();
    final real = all.where((m) => !m.isBye).toList();
    _all = all;
    _rounds = buildResultsRounds(all, (m) => _roundLabel(m, all, l10n));
    _live = splitResultsMatches(all).live;
    _liveRoundLabels = {for (final m in _live) m.id: _roundLabel(m, all, l10n)};
    _counts = {
      for (final f in _BoardFilter.values)
        f: real.where((m) => _passes(f, m)).length,
    };
    _waiting.clear();
    _haystack.clear();
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
    if (_needle.isEmpty) return true;
    final haystack = _haystack.putIfAbsent(
      match.id,
      () => [1, 2]
          .map(
            (side) => participantLabel(
              teamName: matchSideTeamName(match, side),
              players: matchSidePlayers(match, side),
              teamOnly: isFootballMatch(match),
            ).toLowerCase(),
          )
          .join('|'),
    );
    return haystack.contains(_needle);
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      final needle = normalizeParticipantText(value).toLowerCase();
      if (needle != _needle) setState(() => _needle = needle);
    });
  }

  String _rowLabel(MatchModel match, int index) {
    final code = widget.canManage ? matchCodeOrNull(match) : null;
    return code == null ? '${index + 1}' : '#$code';
  }

  ResultsMatchRow _row(
    MatchModel match,
    int index,
    List<MatchModel> all, {
    String? roundLabel,
  }) => ResultsMatchRow(
    key: ValueKey('results-row-${match.id}'),
    match: match,
    label: _rowLabel(match, index),
    roundLabel: roundLabel,
    waitingFor: _waiting.putIfAbsent(
      match.id,
      () => (waitingForCode(match, 1, all), waitingForCode(match, 2, all)),
    ),
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
    _refreshDerived(_sourceMatches(), l10n);
    final all = _all;
    final rounds = _rounds;
    final live = _live;
    if (rounds.isEmpty && live.isEmpty) return _empty(context, l10n);

    final showLive =
        (_filter == _BoardFilter.all || _filter == _BoardFilter.live) &&
        live.any(_matchesQuery);
    final boxes = [
      if (showLive)
        _MatchBox(
          key: const ValueKey('results-box-live'),
          title: l10n.resultsBoard_filterLive,
          isLive: true,
          rows: [
            for (final (i, m) in live.where(_matchesQuery).indexed)
              _row(m, i, all, roundLabel: _liveRoundLabels[m.id]),
          ],
        ),
      for (final round in rounds) ?_roundBox(round, all),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _filterChips(l10n),
        _searchRow(l10n, rounds),
        const SizedBox(height: 9),
        if (boxes.isEmpty)
          _message(context, l10n.resultsBoard_noMatch)
        else
          ...boxes,
      ],
    );
  }

  Widget? _roundBox(ResultsRound round, List<MatchModel> all) {
    final matches = round.matches
        .where(
          (m) => !isLiveMatch(m) && _passes(_filter, m) && _matchesQuery(m),
        )
        .toList();
    if (matches.isEmpty) return null;
    return _MatchBox(
      key: _roundKeys.putIfAbsent(round.key, GlobalKey.new),
      title: round.label,
      rows: [for (final (i, m) in matches.indexed) _row(m, i, all)],
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
            _FilterChip(
              filterName: entry.key.name,
              label: entry.value,
              count: entry.key == _BoardFilter.all
                  ? null
                  : _counts[entry.key],
              selected: entry.key == _filter,
              onTap: () => setState(() => _filter = entry.key),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _searchRow(AppLocalizations l10n, List<ResultsRound> rounds) {
    final palette = ResultsBoardPalette.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: palette.chipLine),
    );
    final hint = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: palette.faint,
    );
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('results-search'),
            onChanged: _onSearchChanged,
            style: TextStyle(fontSize: 12, color: palette.text),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: palette.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 9,
              ),
              hintText: l10n.resultsBoard_searchHint,
              hintStyle: hint,
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 14,
                color: palette.faint,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 30,
                minHeight: 14,
              ),
              border: border,
              enabledBorder: border,
              focusedBorder: border,
            ),
          ),
        ),
        const SizedBox(width: 6),
        PopupMenuButton<String>(
          key: const ValueKey('results-jump'),
          tooltip: l10n.resultsBoard_jumpToRound,
          onSelected: _jumpTo,
          itemBuilder: (_) => [
            for (final round in rounds)
              PopupMenuItem(value: round.key, child: Text(round.label)),
          ],
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: palette.chipLine),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.resultsBoard_jumpToRound,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: palette.muted,
                ),
              ],
            ),
          ),
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

/// Mockup `.ch`: 11.5px / 700 pill chip; the optional count is `<b>` at 70%
/// opacity. The hit area is 44dp high while the pill keeps the mockup size.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filterName,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String filterName;
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ResultsBoardPalette.of(context);
    final foreground = selected ? Colors.white : palette.chipText;
    final style = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: foreground,
    );
    return InkWell(
      key: ValueKey('results-filter-$filterName'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: selected ? ResultsBoardPalette.chipOn : palette.chipBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? ResultsBoardPalette.chipOn : palette.chipLine,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: style),
                if (count != null) ...[
                  const SizedBox(width: 3),
                  Text(
                    '$count',
                    key: ValueKey('results-filter-count-$filterName'),
                    style: style.copyWith(
                      color: foreground.withValues(alpha: .7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mockup `.box`: white, 1px border, 12px radius; the `.bh` head holds a pill
/// with the title and a "N trận" chip. Blue head for rounds, red for [isLive].
class _MatchBox extends StatelessWidget {
  const _MatchBox({
    super.key,
    required this.title,
    required this.rows,
    this.isLive = false,
  });

  final String title;
  final List<Widget> rows;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final palette = ResultsBoardPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: isLive ? palette.headLiveBg : palette.headBg,
            child: Row(
              children: [
                _HeadChip(
                  label: title,
                  background: isLive ? palette.pillLiveBg : palette.pillBg,
                  border: isLive ? palette.pillLiveLine : palette.pillLine,
                  color: isLive ? palette.pillLiveText : palette.pillText,
                  fontSize: 11.5,
                  weight: FontWeight.w800,
                ),
                const SizedBox(width: 8),
                _HeadChip(
                  label: l10n.resultsBoard_matchCount(rows.length),
                  background: palette.countBg,
                  border: palette.chipLine,
                  color: palette.chipText,
                  fontSize: 11,
                  weight: FontWeight.w400,
                ),
              ],
            ),
          ),
          for (final row in rows) ...[
            Divider(height: 1, color: palette.rowLine),
            row,
          ],
        ],
      ),
    );
  }
}

/// `.pill` / `.cnt` of a box head: a 1px bordered, fully rounded label.
class _HeadChip extends StatelessWidget {
  const _HeadChip({
    required this.label,
    required this.background,
    required this.border,
    required this.color,
    required this.fontSize,
    required this.weight,
  });

  final String label;
  final Color background;
  final Color border;
  final Color color;
  final double fontSize;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: weight,
            color: color,
          ),
        ),
      ),
    );
  }
}
