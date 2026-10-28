import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Index (0..4) of the lifecycle step reached by a normalized tournament
/// status: draft, publish, registration open, playing, finished. Null for a
/// cancelled tournament (no step applies).
int? lifecycleStepIndex(String status) => switch (status) {
  AppConstants.statusDraft => 0,
  AppConstants.statusRegistration ||
  AppConstants.statusRegistrationClosed ||
  AppConstants.statusDrawing => 2,
  AppConstants.statusInProgress => 3,
  AppConstants.statusCompleted => 4,
  AppConstants.statusCancelled => null,
  // upcoming, pending approval and any other published-but-not-open state.
  _ => 1,
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

/// Five-step pill bar (design `.stp`): done steps green, the current one in
/// the accent colour (`lifecycle-step-current`), the rest grey.
class LifecycleStepBar extends StatelessWidget {
  const LifecycleStepBar({super.key, required this.status});

  /// Normalized tournament status.
  final String status;

  @override
  Widget build(BuildContext context) {
    final current = lifecycleStepIndex(status);
    if (current == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.lifecycleStepDraft,
      l10n.lifecycleStepPublish,
      l10n.lifecycleStepOpen,
      l10n.lifecycleStepRunning,
      l10n.lifecycleStepDone,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _Step(
                label: labels[i],
                done: i < current,
                current: i == current,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One equal-width pill; the label scales down so five fit a 320dp screen.
class _Step extends StatelessWidget {
  const _Step({required this.label, required this.done, required this.current});

  final String label;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final colors = LavishColors.of(context);
    final tone = done ? LavishTone.ok : LavishTone.neutral;
    return Container(
      key: current ? const ValueKey('lifecycle-step-current') : null,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
      decoration: BoxDecoration(
        color: current ? LavishColors.accent : colors.soft(tone),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: current
                ? Colors.white
                : done
                ? colors.pillText(LavishTone.ok)
                : colors.faint,
          ),
        ),
      ),
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
  final confirmed = await showDialog<bool>(
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
