import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
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

/// Five-step bar: steps up to the current one are filled, the current one is
/// marked with `lifecycle-step-current`.
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: _Step(
              label: labels[i],
              hasLeftLine: i > 0,
              hasRightLine: i < labels.length - 1,
              leftReached: i <= current,
              rightReached: i + 1 <= current,
              reached: i <= current,
              current: i == current,
            ),
          ),
      ],
    );
  }
}

/// One equal-width step: circle with half connectors on both sides, label
/// below (ellipsized so five steps always fit a narrow screen).
class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.hasLeftLine,
    required this.hasRightLine,
    required this.leftReached,
    required this.rightReached,
    required this.reached,
    required this.current,
  });

  final String label;
  final bool hasLeftLine;
  final bool hasRightLine;
  final bool leftReached;
  final bool rightReached;
  final bool reached;
  final bool current;

  Widget _line(BuildContext context, bool show, bool filled) => Expanded(
    child: show
        ? Divider(
            height: 2,
            thickness: 2,
            color: filled ? AppTheme.primary : context.colors.border,
          )
        : const SizedBox.shrink(),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      key: current ? const ValueKey('lifecycle-step-current') : null,
      children: [
        Row(
          children: [
            _line(context, hasLeftLine, leftReached),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reached ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color: reached ? AppTheme.primary : colors.border,
                  width: 2,
                ),
              ),
              child: reached && !current
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            _line(context, hasRightLine, rightReached),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: current ? FontWeight.w700 : FontWeight.w500,
            color: current ? colors.textPrimary : colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// "Full N/N teams" notice with a close-registration action; "remind later"
/// only hides it until this widget is rebuilt from scratch.
class LifecycleCapacityBanner extends StatefulWidget {
  const LifecycleCapacityBanner({
    super.key,
    required this.occupied,
    required this.max,
    required this.onClose,
    required this.closeLabel,
  });

  final int occupied;
  final int max;
  final VoidCallback onClose;
  final String closeLabel;

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
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.lifecycleFullTitle(widget.max, widget.occupied),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.lifecycleFullHint,
            style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                key: const ValueKey('lifecycle-full-close'),
                onPressed: widget.onClose,
                child: Text(widget.closeLabel),
              ),
              TextButton(
                key: const ValueKey('lifecycle-full-remind'),
                onPressed: () => setState(() => _dismissed = true),
                child: Text(l10n.lifecycleRemindLater),
              ),
            ],
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
