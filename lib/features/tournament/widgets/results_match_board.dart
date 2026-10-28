import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_schedule_dialog.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_score_entry_chooser.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/results_rounds.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/schedule_actions.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/live_match_summary_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Match board of the "Kết quả" tab: a live block on top, a round selector and
/// the "Đã xong" / "Sắp tới" groups of the selected round. Organisers can open
/// score entry from a pending row; everyone else only reads.
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
  String? _roundKey;

  List<MatchModel> _divisionMatches() {
    final async = ref.watch(
      widget.isLite
          ? liteBracketMatchesProvider(widget.tournamentId)
          : matchesProvider(widget.tournamentId),
    );
    // `value` keeps the last data when a refresh fails.
    final all = async.value ?? const <MatchModel>[];
    final id = widget.divisionId;
    return id == null
        ? all
        : all.where((m) => matchDivisionId(m) == id).toList();
  }

  void _openScore(MatchModel match) => MatchScoreEntryChooser.show(
    context,
    match: match,
    tournamentId: widget.tournamentId,
  );

  VoidCallback? _scoreAction(MatchModel match) =>
      widget.canManage && canEnterScore(match) ? () => _openScore(match) : null;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final all = _divisionMatches();
    String labelOf(MatchModel m) =>
        MatchRoundLabel.formatRound(match: m, allMatches: all, l10n: l10n);

    final rounds = buildResultsRounds(all, labelOf);
    final live = splitResultsMatches(all).live;
    if (rounds.isEmpty && live.isEmpty) return _empty(context, l10n);

    final selectedKey = rounds.any((r) => r.key == _roundKey)
        ? _roundKey
        : defaultResultsRoundKey(rounds);
    final selected = rounds.where((r) => r.key == selectedKey).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (live.isNotEmpty) _liveBlock(context, l10n, live),
        if (selected != null) ...[
          _roundSelector(context, l10n, rounds, selected.key),
          const SizedBox(height: 10),
          ..._panels(context, l10n, selected),
        ],
      ],
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          l10n.resultsBoard_empty,
          style: TextStyle(color: context.colors.textMuted, fontSize: 13),
        ),
      ),
    );
  }

  Widget _liveBlock(
    BuildContext context,
    AppLocalizations l10n,
    List<MatchModel> live,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(title: l10n.liveMatchesLabel, count: live.length),
          for (final match in live)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LiveMatchSummaryCard(
                match: match,
                roundLabel: MatchRoundLabel.formatRound(
                  match: match,
                  short: true,
                  l10n: l10n,
                ),
                onTap: () => context.push(
                  NavigationHelper.getLiveMatchRoute(
                    widget.tournamentId,
                    match.id,
                  ),
                ),
                onScore: _scoreAction(match),
              ),
            ),
        ],
      ),
    );
  }

  Widget _roundSelector(
    BuildContext context,
    AppLocalizations l10n,
    List<ResultsRound> rounds,
    String selectedKey,
  ) {
    // Design 6: one chip per round ("Vòng 1", "Tứ kết"...), the open one filled.
    return SingleChildScrollView(
      key: const ValueKey('results-round-select'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final round in rounds) ...[
            LavishChipButton(
              key: ValueKey('results-round-${round.key}'),
              label: round.pending > 0
                  ? l10n.resultsBoard_roundOption(round.label, round.pending)
                  : round.label,
              selected: round.key == selectedKey,
              onPressed: () => setState(() => _roundKey = round.key),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  List<Widget> _panels(
    BuildContext context,
    AppLocalizations l10n,
    ResultsRound round,
  ) {
    final split = splitResultsMatches(round.matches);
    final byTime = splitUpcomingByTime(split.upcoming);
    return [
      _Panel(
        title: l10n.resultsBoard_finished,
        count: split.finished.length,
        children: [for (final m in split.finished) _row(m)],
      ),
      const SizedBox(height: 12),
      _Panel(
        title: l10n.resultsBoard_upcoming,
        count: split.upcoming.length,
        children: [
          for (final m in byTime.timed) _row(m),
          if (byTime.untimed.isNotEmpty)
            _GroupHeader(
              text: l10n.resultsBoard_untimed(
                round.label,
                byTime.untimed.length,
              ),
            ),
          for (final m in byTime.untimed) _row(m),
        ],
      ),
    ];
  }

  Widget _row(MatchModel match) => _MatchRow(
    key: ValueKey('results-row-${match.id}'),
    match: match,
    onTap: _scoreAction(match),
    onSchedule: _scheduleAction(match),
  );
}

/// `.hd` group title with the count ("ĐÃ XONG · 3"); the board already sits in
/// the tab's 12dp gutter, so this header only adds a 2dp inset.
class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
    child: Text(
      '$title · $count'.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.66,
        color: LavishColors.of(context).muted,
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.count,
    required this.children,
  });

  final String title;
  final int count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [_PanelTitle(title: title, count: count), ...children],
  );
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = LavishColors.of(context);
    return Container(
      color: colors.rowLine,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: colors.muted,
        ),
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({
    super.key,
    required this.match,
    required this.onTap,
    this.onSchedule,
  });

  final MatchModel match;

  /// Null hides the schedule button (viewers, live or closed matches).
  final VoidCallback? onSchedule;

  /// Null for rows nobody can score (viewers, closed or incomplete matches).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final closed = !canEnterScore(match);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: LavishColors.of(context).rowLine),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: 44, child: _time(colors)),
            Expanded(
              child: match.hasTeams
                  ? _sides(context)
                  : Text(
                      l10n.resultsBoard_waitingTeams,
                      style: TextStyle(color: colors.textMuted, fontSize: 13),
                    ),
            ),
            if (closed && match.hasTeams) _scores(colors),
            // Design 6: pencil (score entry) and clock (schedule) boxes.
            if (onTap != null && !closed) ...[
              const SizedBox(width: 8),
              LavishIconBox(
                key: ValueKey('results-score-${match.id}'),
                size: 36,
                tooltip: l10n.resultsBoard_enterScore,
                onTap: onTap,
                child: const Icon(Icons.edit_outlined),
              ),
            ],
            if (onSchedule != null) ...[
              const SizedBox(width: 8),
              LavishIconBox(
                key: ValueKey('results-schedule-${match.id}'),
                size: 36,
                tone: LavishTone.warn,
                tooltip: l10n.matchSchedule_title,
                onTap: onSchedule,
                child: const Icon(Icons.event_outlined),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _time(AppColorsExtension colors) {
    final time = match.completedAt ?? match.scheduledTime;
    final court = TournamentLocationFormatter.matchShortCourt(
      match.court.isNotEmpty ? match.court : match.courtName,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time == null ? '—' : DateFormat('HH:mm').format(time.toLocal()),
          style: TextStyle(fontSize: 13, color: colors.textMuted),
        ),
        if (court.isNotEmpty)
          Text(
            court,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: colors.textMuted),
          ),
      ],
    );
  }

  Widget _sides(BuildContext context) {
    final colors = context.colors;
    Widget side(int n, bool winner) => ParticipantLabel(
      teamName: matchSideTeamName(match, n),
      players: matchSidePlayers(match, n),
      teamOnly: isFootballMatch(match),
      compact: true,
      style: TextStyle(
        fontSize: 13,
        fontWeight: winner ? FontWeight.w800 : FontWeight.w500,
        color: colors.textPrimary,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        side(1, match.winnerId.isNotEmpty && match.winnerId == match.team1Id),
        const SizedBox(height: 4),
        side(2, match.winnerId.isNotEmpty && match.winnerId == match.team2Id),
      ],
    );
  }

  Widget _scores(AppColorsExtension colors) {
    final sets = match.scoreHistory.isNotEmpty
        ? match.scoreHistory
        : [SetScore(score1: match.score1, score2: match.score2)];
    Widget line(int Function(SetScore) pick, bool winner) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final set in sets)
          SizedBox(
            width: 22,
            child: Text(
              '${pick(set)}',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: winner ? FontWeight.w800 : FontWeight.w500,
                color: winner ? colors.textPrimary : colors.textMuted,
              ),
            ),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        line((s) => s.score1, match.winnerId == match.team1Id),
        const SizedBox(height: 4),
        line((s) => s.score2, match.winnerId == match.team2Id),
      ],
    );
  }
}
