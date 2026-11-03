import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/dialogs/popup_dialog.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Index (0..3) of the progress step reached by a normalized tournament
/// status, as on the Web stepper: registration, schedule, in progress,
/// finished. -1 for a draft (nothing lit yet); null for a cancelled
/// tournament (no bar).
int? lifecycleStepIndex(String status) => switch (status) {
  AppConstants.statusCancelled => null,
  AppConstants.statusDraft => -1,
  AppConstants.statusRegistrationClosed || AppConstants.statusDrawing => 1,
  AppConstants.statusInProgress => 2,
  AppConstants.statusCompleted => 3,
  // upcoming, registration open and any other published-but-not-playing state.
  _ => 0,
};

/// `occupied/max` when every limited division is full (or, for a tournament
/// without divisions, the tournament-level capacity says so); null otherwise.
({int occupied, int max})? lifecycleCapacityFull(Tournament tournament) {
  final divisions = tournament.divisions
      .where((division) => division.status?.toUpperCase() != 'CANCELLED')
      .toList();
  if (divisions.isNotEmpty) {
    var occupied = 0;
    var max = 0;
    for (final division in divisions) {
      final limit = division.maxParticipants;
      if (limit == null || limit <= 0 || division.participantCount < limit) {
        return null;
      }
      occupied += division.participantCount;
      max += limit;
    }
    return (occupied: occupied, max: max);
  }
  final capacity = tournament.capacity;
  final limit = capacity?.maxTeamSlots;
  if (capacity == null || limit == null || capacity.isFull != true) return null;
  return (occupied: capacity.occupiedTeamSlots.round(), max: limit);
}

/// Publish fee configured on the Backend for this kind of tournament (the
/// same three keys the finance section shows). The App never computes it.
/// Failure reads as "no fee" in the UI; the Backend still refuses a publish
/// that owes a fee.
final lifecyclePublishFeeProvider = FutureProvider.autoDispose
    .family<num, ({bool isClub, bool isRanked})>((ref, kind) async {
      final values = await ref
          .read(tournamentManagementRepositoryProvider)
          .getFeesConfig();
      final key = kind.isClub
          ? 'feeClub'
          : kind.isRanked
          ? 'feePublicRanked'
          : 'feePublicUnranked';
      return num.tryParse('${values[key] ?? ''}') ?? 0;
    });

String lifecycleMoney(BuildContext context, num amount) =>
    NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      name: 'VND',
      decimalDigits: 0,
    ).format(amount);

/// Four-step progress bar like the Web stepper: registration, schedule, in
/// progress, finished. Done steps are green with a check, the current one is
/// accent-coloured (`lifecycle-step-current`), the rest grey. A draft shows
/// the bar dimmed with no step lit.
class LifecycleStepBar extends StatelessWidget {
  const LifecycleStepBar({super.key, required this.status, this.onStepTap});

  /// Normalized tournament status.
  final String status;

  /// Tapped step index (0..3, as in [lifecycleStepIndex]); null keeps the bar
  /// read-only.
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    final current = lifecycleStepIndex(status);
    if (current == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      (l10n.lifecycleStepOpen, Icons.groups_outlined),
      (l10n.lifecycleStepSchedule, Icons.account_tree_outlined),
      (l10n.lifecycleStepRunning, Icons.play_arrow_rounded),
      (l10n.lifecycleStepDone, Icons.emoji_events_outlined),
    ];
    return Opacity(
      opacity: current < 0 ? 0.5 : 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: Stack(
          children: [
            // Rail between the first and last circle (1/8 inset each side),
            // filled up to the current step.
            Positioned(
              left: 0,
              right: 0,
              top: _stepDot / 2 - 1,
              child: Row(
                children: [
                  const Spacer(),
                  Expanded(
                    flex: 6,
                    child: _StepRail(
                      progress: (current / (steps.length - 1)).clamp(0.0, 1.0),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < steps.length; i++)
                  Expanded(
                    child: _Step(
                      label: steps[i].$1,
                      icon: steps[i].$2,
                      done: i < current,
                      current: i == current,
                      onTap: onStepTap == null ? null : () => onStepTap!(i),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const double _stepDot = 24;

/// Thin line behind the step circles; the part up to [progress] is accent.
class _StepRail extends StatelessWidget {
  const _StepRail({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: LavishColors.of(context).line),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: const ColoredBox(color: LavishColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// One step: a circle (check when done) with its label underneath.
class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.icon,
    required this.done,
    required this.current,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool done;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = LavishColors.of(context);
    final fill = done
        ? LavishColors.ok
        : current
        ? LavishColors.accent
        : colors.rowLine;
    final content = Column(
      key: current ? const ValueKey('lifecycle-step-current') : null,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _stepDot,
          height: _stepDot,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: colors.surface, width: 2),
            boxShadow: current
                ? [
                    BoxShadow(
                      color: LavishColors.accent.withValues(alpha: 0.25),
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            done ? Icons.check_rounded : icon,
            size: 13,
            color: done || current ? Colors.white : colors.faint,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            height: 1.15,
            fontWeight: current ? FontWeight.w800 : FontWeight.w700,
            color: current
                ? LavishColors.accent
                : done
                ? colors.text
                : colors.faint,
          ),
        ),
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: content,
    );
  }
}

/// "Full N/N teams" notice (design `.li` with a warning box and a reminder
/// pill). Closing registration is the card's one primary button right below;
/// tapping the pill only hides this notice until the widget is rebuilt.
class LifecycleCapacityBanner extends StatefulWidget {
  const LifecycleCapacityBanner({
    super.key,
    required this.occupied,
    required this.max,
  });

  final int occupied;
  final int max;

  @override
  State<LifecycleCapacityBanner> createState() =>
      _LifecycleCapacityBannerState();
}

class _LifecycleCapacityBannerState extends State<LifecycleCapacityBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: LavishRow(
        leading: const LavishIconBox(
          tone: LavishTone.warn,
          child: Text('!', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        title: l10n.lifecycleFullTitle(widget.max, widget.occupied),
        subtitle: l10n.lifecycleFullHint,
        trailing: [
          InkWell(
            key: const ValueKey('lifecycle-full-remind'),
            borderRadius: BorderRadius.circular(999),
            onTap: () => setState(() => _dismissed = true),
            child: LavishPill(l10n.lifecycleRemindLater, tone: LavishTone.warn),
          ),
        ],
      ),
    );
  }
}

/// Confirms deleting a tournament; the delete button stays off until the
/// tournament name is typed back exactly (surrounding spaces ignored).
Future<bool> showDeleteTournamentDialog(
  BuildContext context, {
  required String tournamentName,
}) async {
  final confirmed = await showPopupDialog<bool>(
    context: context,
    builder: (_) => _DeleteTournamentDialog(tournamentName: tournamentName),
  );
  return confirmed == true;
}

class _DeleteTournamentDialog extends StatefulWidget {
  const _DeleteTournamentDialog({required this.tournamentName});

  final String tournamentName;

  @override
  State<_DeleteTournamentDialog> createState() =>
      _DeleteTournamentDialogState();
}

class _DeleteTournamentDialogState extends State<_DeleteTournamentDialog> {
  final TextEditingController _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  bool get _matches => _typed.text.trim() == widget.tournamentName.trim();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.deleteTournamentTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteTournamentContent),
          const SizedBox(height: 8),
          Text(l10n.lifecycleDeleteTypePrompt(widget.tournamentName)),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('delete-tournament-name'),
            controller: _typed,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.lifecycleDeleteNameLabel,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.tournamentManagementCancel),
        ),
        FilledButton(
          key: const ValueKey('delete-tournament-confirm'),
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(backgroundColor: context.colors.error),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}
