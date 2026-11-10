import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/services/tournament_manage_access.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/schedule_settings_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/schedule_court_management_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';

/// The tournament when the current user may manage its schedule (organizer or
/// co-organizer of a non-lite tournament), else null. Lite tournaments have no
/// venues, so they never get the court actions.
final scheduleManagerTournamentProvider = Provider.autoDispose
    .family<Tournament?, String>((ref, tournamentId) {
      final tournament = ref.watch(tournamentProvider(tournamentId)).value;
      if (tournament == null || tournament.isLite) return null;
      final workspace = ref.watch(myTournamentWorkspaceProvider).value;
      final canManage = canManageTournament(
        tournamentId: tournamentId,
        userId: ref.watch(userProfileProvider).value?.id,
        creatorId: tournament.creatorId,
        managedTournamentIds: {
          ...?workspace?.organizedTournaments.map((t) => t.id),
          ...?workspace?.coOrganizerTournaments.map((t) => t.id),
        },
      );
      return canManage ? tournament : null;
    });

/// Manager-only entry points of the schedule tab, mirroring the Web
/// organizer page: create/manage courts, court hours, and the scheduling
/// workspace. Renders nothing for everyone else.
///
/// With [createCourtCta] it renders a single labelled "Create court" button
/// for the empty state instead of the icon row.
class ScheduleManagerBar extends ConsumerStatefulWidget {
  const ScheduleManagerBar({
    super.key,
    required this.tournamentId,
    this.createCourtCta = false,
  });

  final String tournamentId;
  final bool createCourtCta;

  @override
  ConsumerState<ScheduleManagerBar> createState() => _ScheduleManagerBarState();
}

class _ScheduleManagerBarState extends ConsumerState<ScheduleManagerBar> {
  // Blocks a second tap while a sheet/screen is still open or being awaited.
  bool _busy = false;

  Future<void> _guarded(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Reload everything the schedule tab reads, so a new court or new hours
  /// show up as soon as the manager comes back.
  ///
  /// Waits one frame first: the page underneath only resumes its provider
  /// subscriptions while the pop is being built, and invalidating inside that
  /// build trips Riverpod's "markNeedsBuild during build" assertion.
  Future<void> _refresh() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final id = widget.tournamentId;
    ref.invalidate(tournamentProvider(id));
    ref.invalidate(tournamentIntroWithInviteProvider);
    ref.invalidate(tournamentIntroProvider);
    ref.invalidate(publicVenueCourtNamesProvider);
    ref.invalidate(matchesProvider(id));
  }

  Future<void> _openCourts() => _guarded(() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            ScheduleCourtManagementScreen(tournamentId: widget.tournamentId),
      ),
    );
    await _refresh();
  });

  Future<void> _openHours(Tournament tournament) => _guarded(() async {
    final saved = await ScheduleSettingsSheet.show(
      context,
      tournament: tournament,
    );
    if (saved != true || !mounted) return;
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.scheduleSettingsSaved),
        ),
      );
  });

  Future<void> _openArrange() => _guarded(() async {
    await context.push<void>(
      '/organizer/tournaments/${widget.tournamentId}/ops',
    );
    await _refresh();
  });

  @override
  Widget build(BuildContext context) {
    final tournament = ref.watch(
      scheduleManagerTournamentProvider(widget.tournamentId),
    );
    if (tournament == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    if (widget.createCourtCta) return _cta(l10n);
    final colors = context.colors;
    Widget action(Key key, IconData icon, String tooltip, VoidCallback onTap) =>
        IconButton(
          key: key,
          tooltip: tooltip,
          visualDensity: VisualDensity.compact,
          onPressed: _busy ? null : onTap,
          icon: Icon(icon, size: 20, color: colors.textSecondary),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        action(
          const ValueKey('schedMgmt-courts'),
          Icons.add_location_alt_outlined,
          l10n.schedMgmt_courtsTooltip,
          _openCourts,
        ),
        action(
          const ValueKey('schedMgmt-hours'),
          Icons.schedule_rounded,
          l10n.schedMgmt_hoursTooltip,
          () => _openHours(tournament),
        ),
        action(
          const ValueKey('schedMgmt-arrange'),
          Icons.edit_calendar_outlined,
          l10n.schedMgmt_arrangeTooltip,
          _openArrange,
        ),
      ],
    );
  }

  Widget _cta(AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.schedMgmt_emptyHint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: context.colors.textMuted),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const ValueKey('schedMgmt-empty-create'),
          onPressed: _busy ? null : _openCourts,
          icon: const Icon(Icons.add_location_alt_outlined, size: 18),
          label: Text(l10n.schedMgmt_createCourtCta),
        ),
      ],
    ),
  );
}
