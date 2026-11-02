import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Same two team colors as the score panels.
const _team1Color = Color(0xFF2979FF);
const _team2Color = Color(0xFFEA580C);

/// Reason for an exception result. Every keystroke goes to the score panel so
/// the dialog buttons and the saved result see the same text.
class _OverrideReasonField extends ConsumerStatefulWidget {
  const _OverrideReasonField({required this.params});

  final MatchControlParams params;

  @override
  ConsumerState<_OverrideReasonField> createState() =>
      _OverrideReasonFieldState();
}

class _OverrideReasonFieldState extends ConsumerState<_OverrideReasonField> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(scorePanelNotifierProvider(widget.params)).overrideReason,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: _controller,
      autofocus: true,
      onChanged: (value) => ref
          .read(scorePanelNotifierProvider(widget.params).notifier)
          .setOverride(true, value),
      decoration: InputDecoration(
        hintText: l10n.officialScore_overrideReasonHint,
        isDense: true,
      ),
    );
  }
}

/// True when an exception result is on but its reason is still empty.
bool _reasonMissing(ScorePanelState state) =>
    !state.isOpenScoring &&
    state.overrideEnabled &&
    state.overrideReason.trim().isEmpty;

bool _needsReason(ScorePanelState state) =>
    !state.isOpenScoring && state.overrideEnabled;

/// Confirms finishing the current set. Pops `true` on confirm.
class FinishSetDialog extends ConsumerWidget {
  const FinishSetDialog({
    super.key,
    required this.params,
    required this.message,
  });

  final MatchControlParams params;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(scorePanelNotifierProvider(params));
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.matchFinishSet),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message),
          if (_needsReason(state)) ...[
            const SizedBox(height: 12),
            _OverrideReasonField(params: params),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.matchCancel),
        ),
        FilledButton(
          onPressed: _reasonMissing(state)
              ? null
              : () => Navigator.pop(context, true),
          child: Text(l10n.matchConfirm),
        ),
      ],
    );
  }
}

/// Picks the winning team. Pops the team (1 or 2) the referee taps. A team
/// that cannot win yet is locked, with a line saying why.
class PickWinnerDialog extends ConsumerWidget {
  const PickWinnerDialog({super.key, required this.params});

  final MatchControlParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(scorePanelNotifierProvider(params));
    final notifier = ref.read(scorePanelNotifierProvider(params).notifier);
    final match = ref.watch(singleMatchProvider(params)).value;
    final missingReason = _reasonMissing(state);
    final canWin = {1: notifier.canCompleteAs(1), 2: notifier.canCompleteAs(2)};
    final nobodyCanWin = !canWin[1]! && !canWin[2]!;

    Widget teamButton(int team, Color color) {
      final label = match == null ? '$team' : matchSideLabel(match, team);
      return FilledButton(
        onPressed: canWin[team]! && !missingReason
            ? () => Navigator.pop(context, team)
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size.fromHeight(52),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
    }

    return AlertDialog(
      scrollable: true,
      title: Text(l10n.pickleballCourtPickWinner),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (_needsReason(state)) _OverrideReasonField(params: params),
          teamButton(1, _team1Color),
          teamButton(2, _team2Color),
          if (nobodyCanWin)
            Text(
              l10n.scorePanel_matchNotReady,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.matchCancel),
        ),
      ],
    );
  }
}

/// Asks for the reason right when the exception switch is turned on, so the
/// referee is never left with a switch on and nowhere to type. Pops `true` on
/// confirm; the caller switches override back off otherwise.
class OverrideReasonDialog extends ConsumerWidget {
  const OverrideReasonDialog({super.key, required this.params});

  final MatchControlParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(scorePanelNotifierProvider(params));
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.matchOverrideLabel),
      content: _OverrideReasonField(params: params),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.matchCancel),
        ),
        FilledButton(
          onPressed: state.overrideReason.trim().isEmpty
              ? null
              : () => Navigator.pop(context, true),
          child: Text(l10n.matchConfirm),
        ),
      ],
    );
  }
}
