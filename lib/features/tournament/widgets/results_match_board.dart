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

  /// Design 6: "CHỜ NHẬP ĐIỂM" (real matches that take a score now), then
  /// "ĐÃ XONG", then "SẮP TỚI" (still waiting for opponents).
  List<Widget> _panels(
    BuildContext context,
    AppLocalizations l10n,
    ResultsRound round,
  ) {
    final split = splitResultsMatches(round.matches);
    final byTime = splitUpcomingByTime(split.upcoming);
    final ordered = [...byTime.timed, ...byTime.untimed];
    final pending = ordered.where(canEnterScore).toList();
    final waiting = ordered.where((m) => !canEnterScore(m)).toList();
    return [
      if (pending.isNotEmpty)
        _Panel(
          title: l10n.resultsBoard_pendingScore,
          count: pending.length,
          children: [for (final m in pending) _row(m)],
        ),
      if (split.finished.isNotEmpty)
        _Panel(
          title: l10n.resultsBoard_finished,
          count: split.finished.length,
          children: [for (final m in split.finished) _row(m)],
        ),
      if (waiting.isNotEmpty)
        _Panel(
          title: l10n.resultsBoard_upcoming,
          count: waiting.length,
          children: [for (final m in waiting) _row(m)],
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

  String _title(AppLocalizations l10n) {
    if (!match.hasTeams) return l10n.resultsBoard_waitingTeams;
    String side(int n) => participantLabel(
      teamName: matchSideTeamName(match, n),
      players: matchSidePlayers(match, n),
      teamOnly: isFootballMatch(match),
      abbreviated: true,
    );
    return '${side(1)} vs ${side(2)}';
  }

  /// "Sân 1 · 07:00", or "Chưa xếp lịch"; finished rows lead with the score.
  String _subtitle(AppLocalizations l10n, bool closed) {
    final time = match.completedAt ?? match.scheduledTime;
    final court = TournamentLocationFormatter.matchShortCourt(
      match.court.isNotEmpty ? match.court : match.courtName,
    );
    final when = [
      if (court.isNotEmpty) court,
      if (time != null) DateFormat('HH:mm').format(time.toLocal()),
    ].join(' · ');
    final place = when.isEmpty ? l10n.resultsBoard_unscheduled : when;
    if (!closed || !match.hasTeams) return place;
    final sets = match.scoreHistory.isNotEmpty
        ? match.scoreHistory
        : [SetScore(score1: match.score1, score2: match.score2)];
    final score = sets.map((s) => '${s.score1}–${s.score2}').join(', ');
    return '$score · $place';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final closed = !canEnterScore(match);
    return LavishRow(
      title: _title(l10n),
      subtitle: _subtitle(l10n, closed),
      onTap: onTap,
      trailing: [
        // Design 6: pencil (score entry) and clock (schedule) boxes; closed
        // rows carry the green "Xong" pill instead.
        if (closed && match.hasTeams)
          LavishPill(l10n.resultsBoard_doneBadge, tone: LavishTone.ok),
        if (onTap != null && !closed)
          LavishIconBox(
            key: ValueKey('results-score-${match.id}'),
            size: 36,
            tooltip: l10n.resultsBoard_enterScore,
            onTap: onTap,
            child: const Icon(Icons.edit_outlined),
          ),
        if (onSchedule != null)
          LavishIconBox(
            key: ValueKey('results-schedule-${match.id}'),
            size: 36,
            tone: LavishTone.warn,
            tooltip: l10n.matchSchedule_title,
            onTap: onSchedule,
            child: const Icon(Icons.event_outlined),
          ),
      ],
    );
  }
}
