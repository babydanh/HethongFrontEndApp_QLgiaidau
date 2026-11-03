import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/played_at.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_board_palette.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_row.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _defaultSets = 3;
const _maxSets = 7;
const _inputWidth = 48.0;

/// Score popup of the results board: both sides, time and court, one pair of
/// inputs per set. Resolves to true once the score was saved.
Future<bool?> showResultsScoreDialog(
  BuildContext context, {
  required MatchModel match,
  required String tournamentId,
  required String label,
  required String liveRoute,
  bool isLite = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ResultsScoreSheet(
      match: match,
      tournamentId: tournamentId,
      label: label,
      liveRoute: liveRoute,
      isLite: isLite,
    ),
  );
}

class _ResultsScoreSheet extends ConsumerStatefulWidget {
  const _ResultsScoreSheet({
    required this.match,
    required this.tournamentId,
    required this.label,
    required this.liveRoute,
    required this.isLite,
  });

  final MatchModel match;
  final String tournamentId;
  final String label;
  final String liveRoute;
  final bool isLite;

  @override
  ConsumerState<_ResultsScoreSheet> createState() => _ResultsScoreSheetState();
}

class _ResultsScoreSheetState extends ConsumerState<_ResultsScoreSheet> {
  final List<TextEditingController> _side1 = [];
  final List<TextEditingController> _side2 = [];
  late final TextEditingController _played;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _played = TextEditingController(
      text: formatPlayedAt(
        seedPlayedAt(
          playedDate: widget.match.playedDate,
          playedTime: widget.match.playedTime,
          today: DateTime.now(),
        ),
      ),
    );
    final history = widget.match.scoreHistory;
    final count = history.length > _defaultSets ? history.length : _defaultSets;
    for (var i = 0; i < count; i++) {
      final set = i < history.length ? history[i] : null;
      _side1.add(
        TextEditingController(text: set == null ? '' : '${set.score1}'),
      );
      _side2.add(
        TextEditingController(text: set == null ? '' : '${set.score2}'),
      );
    }
  }

  @override
  void dispose() {
    for (final c in [..._side1, ..._side2, _played]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Typed date and time; null when the field is empty or unreadable.
  PlayedAt? get _playedAt => parsePlayedAt(_played.text);

  bool get _playedInvalid =>
      _played.text.trim().isNotEmpty && _playedAt == null;

  /// Calendar button: pick a date, then a time (cancelling the time keeps the
  /// previous one).
  Future<void> _pickPlayedAt() async {
    final current =
        _playedAt ??
        seedPlayedAt(playedDate: null, playedTime: null, today: DateTime.now());
    final day = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(current.date) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (day == null || !mounted) return;
    final parts = current.time?.split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: parts == null
          ? TimeOfDay.now()
          : TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (!mounted) return;
    String two(int v) => v.toString().padLeft(2, '0');
    setState(() {
      _error = null;
      _played.text = formatPlayedAt((
        date: '${day.year}-${two(day.month)}-${two(day.day)}',
        time: time == null
            ? current.time
            : '${two(time.hour)}:${two(time.minute)}',
      ));
    });
  }

  /// Sets with a score on both sides; empty or half-filled sets are ignored.
  List<SetScoreData> _sets() {
    final sets = <SetScoreData>[];
    for (var i = 0; i < _side1.length; i++) {
      final a = int.tryParse(_side1[i].text);
      final b = int.tryParse(_side2[i].text);
      if (a != null && b != null) {
        sets.add(SetScoreData(score1: a, score2: b, isFinished: true));
      }
    }
    return sets;
  }

  void _addSet() {
    if (_side1.length >= _maxSets) return;
    setState(() {
      _side1.add(TextEditingController());
      _side2.add(TextEditingController());
    });
  }

  Future<void> _save() async {
    final sets = _sets();
    final (wonA, wonB) = computeMatchSetsWon(sets);
    if (_saving || sets.isEmpty || wonA == wonB || _playedInvalid) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final match = widget.match;
    try {
      await ref
          .read(matchRepositoryProvider)
          .updateScoreDetails(
            widget.tournamentId,
            match.id,
            p1SetsWon: wonA,
            p2SetsWon: wonB,
            scoreDetails: sets,
            winnerId: wonA > wonB ? match.team1Id : match.team2Id,
            expectedRevision: match.revision,
            useLiteParticipantAccess: widget.isLite,
            playedAt: _playedAt,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final text = error.toString().replaceFirst('Exception: ', '').trim();
      setState(() {
        _saving = false;
        _error = text.isEmpty
            ? AppLocalizations.of(context)!.resultsScore_error
            : text;
      });
    }
  }

  void _openLive() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop(false);
    router.push(widget.liveRoute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final (wonA, wonB) = computeMatchSetsWon(_sets());
    final hasSets = _sets().isNotEmpty;
    final tied = hasSets && wonA == wonB;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        key: const ValueKey('results-score-sheet'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.resultsScore_title(widget.label),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            _meta(l10n, colors),
            const SizedBox(height: 12),
            _playedAtField(l10n),
            if (_playedInvalid)
              _message(
                l10n.resultsScore_playedAtInvalid,
                'results-score-played-error',
              ),
            const SizedBox(height: 12),
            _setHeader(l10n, colors),
            _sideRow(1),
            const Divider(height: 14),
            _sideRow(2),
            _addSetButton(l10n),
            if (tied) _message(l10n.resultsScore_tied, 'results-score-tied'),
            if (_error != null) _message(_error!, 'results-score-error'),
            const SizedBox(height: 8),
            _buttons(
              l10n,
              canSave: hasSets && !tied && !_saving && !_playedInvalid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(AppLocalizations l10n, AppColorsExtension colors) {
    final match = widget.match;
    final referee = match.refereeName?.trim() ?? '';
    final items = [
      resultsMatchClock(match),
      resultsMatchCourt(match),
      if (referee.isNotEmpty) l10n.resultsBoard_referee(referee),
    ].where((text) => text.isNotEmpty);
    return Wrap(
      spacing: 12,
      children: [
        for (final text in items)
          Text(
            text,
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
      ],
    );
  }

  Widget _playedAtField(AppLocalizations l10n) {
    return TextField(
      key: const ValueKey('results-score-played-at'),
      controller: _played,
      enabled: !_saving,
      keyboardType: TextInputType.datetime,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9/: ]')),
        LengthLimitingTextInputFormatter(16),
      ],
      onChanged: (_) => setState(() => _error = null),
      decoration: InputDecoration(
        isDense: true,
        labelText: l10n.resultsScore_playedAt,
        hintText: l10n.resultsScore_playedAtHint,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          key: const ValueKey('results-score-played-pick'),
          tooltip: l10n.resultsScore_playedAtPick,
          icon: const Icon(Icons.calendar_month_rounded),
          onPressed: _saving ? null : _pickPlayedAt,
        ),
      ),
    );
  }

  Widget _setHeader(AppLocalizations l10n, AppColorsExtension colors) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: colors.textSecondary,
    );
    return Row(
      children: [
        const Spacer(),
        for (var i = 0; i < _side1.length; i++)
          SizedBox(
            width: _inputWidth + 6,
            child: Text(
              l10n.resultsScore_set(i + 1),
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
      ],
    );
  }

  Widget _sideRow(int side) {
    final match = widget.match;
    final controllers = side == 1 ? _side1 : _side2;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ParticipantSideLines(
              teamName: matchSideTeamName(match, side),
              players: matchSidePlayers(match, side),
              logoUrl: side == 1 ? match.team1LogoUrl : match.team2LogoUrl,
              teamOnly: isFootballMatch(match),
            ),
          ),
        ),
        for (var i = 0; i < controllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: SizedBox(
              width: _inputWidth,
              height: 44,
              child: TextField(
                key: ValueKey('results-score-input-$side-$i'),
                controller: controllers[i],
                enabled: !_saving,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                onChanged: (_) => setState(() => _error = null),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _addSetButton(AppLocalizations l10n) {
    if (_side1.length >= _maxSets) return const SizedBox.shrink();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        key: const ValueKey('results-score-add-set'),
        onPressed: _saving ? null : _addSet,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(l10n.resultsScore_addSet),
      ),
    );
  }

  Widget _message(String text, String key) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      key: ValueKey(key),
      style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
    ),
  );

  Widget _buttons(AppLocalizations l10n, {required bool canSave}) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const ValueKey('results-score-live'),
            onPressed: _saving ? null : _openLive,
            child: Text(l10n.resultsScore_openLive),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            key: const ValueKey('results-score-save'),
            style: FilledButton.styleFrom(
              backgroundColor: ResultsBoardPalette.chipOn,
            ),
            onPressed: canSave ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.resultsScore_save),
          ),
        ),
      ],
    );
  }
}
