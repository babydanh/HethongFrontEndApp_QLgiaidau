import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/core/utils/match_code.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_schedule_dialog.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/final_matches.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/results_rounds.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_actions.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_board_palette.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_row.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_score_dialog.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Chips of the board. Organisers get all five; the public board only the
/// first four (same split as the Web `ResultsBoard`).
enum ResultsBoardFilter { all, live, upcoming, finished, unfinished }

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

/// [manage] switches "Đã xong" to the organiser card rule (completed and
/// cancelled, disputes excluded) so the chip count equals the progress card.
bool _passes(
  ResultsBoardFilter filter,
  MatchModel match, {
  required bool manage,
}) => switch (filter) {
  ResultsBoardFilter.all => true,
  ResultsBoardFilter.live => isLiveMatch(match),
  ResultsBoardFilter.upcoming => !isMatchClosed(match) && !isLiveMatch(match),
  ResultsBoardFilter.finished =>
    isMatchClosed(match) && !(manage && isDisputedMatch(match)),
  ResultsBoardFilter.unfinished => !isMatchClosed(match),
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
    this.initialFilter = ResultsBoardFilter.all,
    this.focusFinal = false,
  });

  final String tournamentId;
  final bool isLite;
  final bool canManage;

  /// Null lists every division.
  final String? divisionId;

  /// Chip selected when the board is first built (e.g. from a progress popup).
  final ResultsBoardFilter initialFilter;

  /// Finished division: every round stays listed, only the box holding the
  /// knockout final starts open. A bracket without a knockout final (round
  /// robin, swiss) keeps the usual default box.
  final bool focusFinal;

  @override
  ConsumerState<ResultsMatchBoard> createState() => _ResultsMatchBoardState();
}

class _ResultsMatchBoardState extends ConsumerState<ResultsMatchBoard> {
  static const _searchDebounce = Duration(milliseconds: 250);

  late ResultsBoardFilter _filter = widget.initialFilter;
  // Normalised search text; updated after a short pause, not on every key.
  String _needle = '';
  Timer? _searchTimer;
  final Map<String, GlobalKey> _roundKeys = {};
  // Boxes the viewer folded or opened by hand (or "Tới vòng" did); a missing
  // key falls back to [isRoundBoxOpen]'s default.
  Map<String, bool> _boxChoice = const {};
  // Scroll to the picked round waits for the other boxes to finish folding.
  static const _foldSettle = Duration(milliseconds: 220);
  Timer? _jumpTimer;

  // Everything below is derived from the match list, the division and the
  // locale. It is rebuilt only when one of them changes, so typing in the
  // search box or switching a filter chip never recomputes round labels.
  List<MatchModel>? _source;
  String? _derivedDivisionId;
  bool _derivedFocusFinal = false;
  Set<String>? _finalIds;
  String? _derivedLocale;
  List<MatchModel> _all = const [];
  List<ResultsRound> _rounds = const [];
  List<MatchModel> _live = const [];
  Map<String, String> _liveRoundLabels = const {};
  Map<ResultsBoardFilter, int> _counts = const {};
  final Map<String, (String?, String?)> _waiting = {};
  final Map<String, String> _haystack = {};

  @override
  void dispose() {
    _searchTimer?.cancel();
    _jumpTimer?.cancel();
    super.dispose();
  }

  List<MatchModel> _sourceMatches() {
    // `value` keeps the last data when a refresh fails. Organisers read the
    // management feed (`/manage/matches`), like the Web board, not the public
    // one.
    final AsyncValue<List<MatchModel>> async;
    if (widget.isLite) {
      async = ref.watch(liteBracketMatchesProvider(widget.tournamentId));
    } else if (widget.canManage) {
      async = ref.watch(
        managedMatchesWithDivisionProvider((
          tournamentId: widget.tournamentId,
          divisionId: null,
        )),
      );
    } else {
      async = ref.watch(matchesProvider(widget.tournamentId));
    }
    return async.value ?? const <MatchModel>[];
  }

  void _refreshDerived(List<MatchModel> source, AppLocalizations l10n) {
    final divisionId = widget.divisionId;
    final focusFinal = widget.focusFinal;
    if (identical(source, _source) &&
        divisionId == _derivedDivisionId &&
        focusFinal == _derivedFocusFinal &&
        l10n.localeName == _derivedLocale) {
      return;
    }
    _source = source;
    _derivedDivisionId = divisionId;
    _derivedFocusFinal = focusFinal;
    _derivedLocale = l10n.localeName;
    final ofDivision = divisionId == null
        ? source
        : source.where((m) => matchDivisionId(m) == divisionId).toList();
    final all = ofDivision;
    _finalIds = focusFinal
        ? pickFinalMatches(ofDivision)?.map((m) => m.id).toSet()
        : null;
    final real = all.where((m) => !m.isBye).toList();
    _all = all;
    _rounds = buildResultsRounds(all, (m) => _roundLabel(m, all, l10n));
    _live = splitResultsMatches(all).live;
    _liveRoundLabels = {for (final m in _live) m.id: _roundLabel(m, all, l10n)};
    _counts = {
      for (final f in ResultsBoardFilter.values)
        f: real.where((m) => _passes(f, m, manage: widget.canManage)).length,
    };
    _waiting.clear();
    _haystack.clear();
  }

  VoidCallback? _scoreAction(MatchModel match, String label) =>
      widget.canManage && canEnterScore(match)
      ? () => _openScore(match, label)
      : null;

  Future<void> _openScore(MatchModel match, String label) async {
    final saved = await showResultsScoreDialog(
      context,
      match: match,
      tournamentId: widget.tournamentId,
      label: label,
      liveRoute: NavigationHelper.getLiveMatchRoute(
        widget.tournamentId,
        match.id,
      ),
      isLite: widget.isLite,
    );
    if (saved != true || !mounted) return;
    ref.invalidate(
      managedMatchesWithDivisionProvider((
        tournamentId: widget.tournamentId,
        divisionId: null,
      )),
    );
    ref.invalidate(
      widget.isLite
          ? liteBracketMatchesProvider(widget.tournamentId)
          : matchesProvider(widget.tournamentId),
    );
  }

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
    onScore: _scoreAction(match, _rowLabel(match, index)),
    onSchedule: _scheduleAction(match),
  );

  /// "Tới vòng": open only [roundKey], fold the other rounds, then scroll to it
  /// once the folding has settled (the boxes above it change height).
  void _jumpTo(String roundKey) {
    setState(
      () => _boxChoice = openOnlyRound([
        for (final r in _rounds) r.key,
      ], roundKey),
    );
    _jumpTimer?.cancel();
    _jumpTimer = Timer(_foldSettle, () {
      final target = _roundKeys[roundKey]?.currentContext;
      if (!mounted || target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
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
        (_filter == ResultsBoardFilter.all ||
            _filter == ResultsBoardFilter.live) &&
        live.any(_matchesQuery);
    final visible = _visibleRounds();
    final defaultKey = focusResultsRoundKey([
      for (final (round, _) in visible) round,
    ], _finalIds);
    final searching = _needle.isNotEmpty;
    final boxes = [
      if (showLive)
        _MatchBox(
          key: const ValueKey('results-box-live'),
          boxKey: 'live',
          title: l10n.resultsBoard_filterLive,
          isLive: true,
          open: _boxChoice['live'] ?? true,
          onToggle: () => _toggleBox('live', _boxChoice['live'] ?? true),
          rows: [
            for (final (i, m) in live.where(_matchesQuery).indexed)
              _row(m, i, all, roundLabel: _liveRoundLabels[m.id]),
          ],
        ),
      for (final (round, matches) in visible)
        _roundBox(
          round,
          matches,
          all,
          open: isRoundBoxOpen(
            choice: _boxChoice[round.key],
            isDefault: round.key == defaultKey,
            searching: searching,
          ),
        ),
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

  /// Rounds with at least one match that passes the filter chip and the search.
  List<(ResultsRound, List<MatchModel>)> _visibleRounds() {
    // Live matches have their own box, except under "Chưa xong" where they
    // are unfinished matches like the rest and stay in their round.
    final liveInRound = _filter == ResultsBoardFilter.unfinished;
    return [
      for (final round in _rounds)
        if (round.matches
                .where(
                  (m) =>
                      (liveInRound || !isLiveMatch(m)) &&
                      _passes(_filter, m, manage: widget.canManage) &&
                      _matchesQuery(m),
                )
                .toList()
            case final matches when matches.isNotEmpty)
          (round, matches),
    ];
  }

  Widget _roundBox(
    ResultsRound round,
    List<MatchModel> matches,
    List<MatchModel> all, {
    required bool open,
  }) {
    return _MatchBox(
      key: _roundKeys.putIfAbsent(round.key, GlobalKey.new),
      boxKey: round.key,
      title: round.label,
      branch: round.branch,
      open: open,
      onToggle: () => _toggleBox(round.key, open),
      rows: open
          ? [for (final (i, m) in matches.indexed) _row(m, i, all)]
          : const [],
      matchCount: matches.length,
    );
  }

  void _toggleBox(String key, bool wasOpen) =>
      setState(() => _boxChoice = {..._boxChoice, key: !wasOpen});

  Widget _filterChips(AppLocalizations l10n) {
    final labels = {
      ResultsBoardFilter.all: l10n.filterAll,
      ResultsBoardFilter.live: l10n.resultsBoard_filterLive,
      ResultsBoardFilter.upcoming: l10n.resultsBoard_upcoming,
      ResultsBoardFilter.finished: l10n.resultsBoard_finished,
      if (widget.canManage)
        ResultsBoardFilter.unfinished: l10n.resultsBoard_unfinished,
    };
    int? countOf(ResultsBoardFilter f) =>
        f == ResultsBoardFilter.all ? null : _counts[f];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in labels.entries) ...[
            _FilterChip(
              filterName: entry.key.name,
              label: entry.value,
              count: countOf(entry.key),
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
          itemBuilder: (context) => [
            for (final round in rounds)
              PopupMenuItem(
                value: round.key,
                child: _jumpItem(context, round, l10n),
              ),
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

  /// Menu entry: the branch icon, the round name and how many matches wait.
  Widget _jumpItem(
    BuildContext context,
    ResultsRound round,
    AppLocalizations l10n,
  ) {
    final tone = ResultsBoardPalette.branchTone(context, round.branch);
    final label = round.pending > 0
        ? l10n.resultsBoard_roundOption(round.label, round.pending)
        : round.label;
    return Row(
      children: [
        Icon(tone.icon, size: 16, color: tone.pillText),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
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

/// Mockup `.box`: white, 1px border, 12px radius. The head is one button that
/// folds the box: a branch icon, a pill with the title, a "N trận" chip and a
/// chevron. Its colours follow the bracket [branch] (Web `BOX_TONE`); the red
/// head is for the live box. A folded box builds no rows.
class _MatchBox extends StatelessWidget {
  const _MatchBox({
    super.key,
    required this.boxKey,
    required this.title,
    required this.rows,
    required this.open,
    required this.onToggle,
    this.branch = ResultsBranch.main,
    this.isLive = false,
    this.matchCount,
  });

  final String boxKey;
  final String title;
  final List<Widget> rows;
  final bool open;
  final VoidCallback onToggle;
  final ResultsBranch branch;
  final bool isLive;

  /// Matches in the box when [rows] is empty because the box is folded.
  final int? matchCount;

  static const _fold = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final palette = ResultsBoardPalette.of(context);
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
          _head(context, palette),
          AnimatedSize(
            duration: _fold,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const ResultsColumnHeader(),
                      for (final row in rows) ...[
                        Divider(height: 1, color: palette.rowLine),
                        row,
                      ],
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _head(BuildContext context, ResultsBoardPalette palette) {
    final l10n = AppLocalizations.of(context)!;
    final tone = ResultsBoardPalette.branchTone(context, branch);
    final pillColor = isLive ? palette.pillLiveText : tone.pillText;
    return Material(
      key: ValueKey('results-box-head-$boxKey'),
      color: isLive ? palette.headLiveBg : tone.head,
      child: Semantics(
        expanded: open,
        child: InkWell(
          key: ValueKey('results-box-toggle-$boxKey'),
          onTap: onToggle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  if (isLive)
                    Icon(Icons.circle, size: 9, color: ResultsBoardPalette.live)
                  else
                    Icon(tone.icon, size: 17, color: pillColor),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Row(
                      children: [
                        _HeadChip(
                          label: title,
                          background: isLive ? palette.pillLiveBg : tone.pill,
                          border: isLive ? palette.pillLiveLine : tone.pillLine,
                          color: pillColor,
                          fontSize: 11.5,
                          weight: FontWeight.w800,
                        ),
                        const SizedBox(width: 8),
                        _HeadChip(
                          label: l10n.resultsBoard_matchCount(
                            matchCount ?? rows.length,
                          ),
                          background: palette.countBg,
                          border: palette.chipLine,
                          color: palette.chipText,
                          fontSize: 11,
                          weight: FontWeight.w400,
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0 : -0.25,
                    duration: _fold,
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 22,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
