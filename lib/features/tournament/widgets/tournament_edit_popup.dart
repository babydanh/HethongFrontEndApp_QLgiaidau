import 'package:app_quanly_giaidau/core/dialogs/popup_dialog.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_section_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_edit_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Opens the one thing tapped on the overview in its own bottom sheet, so the
/// manager edits it in place instead of landing on a settings page.
Future<void> showTournamentEditPopup(
  BuildContext context, {
  required Tournament tournament,
  required TournamentManagementFocus focus,
  required String opsWorkspaceRoute,
  required String actionRouteBase,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    sheetAnimationStyle: popupSheetAnimation,
    builder: (_) => TournamentEditSheet(
      title: _titleOf(l10n, focus),
      fillHeight: _needsBoundedHeight(focus),
      child: TournamentManagementSectionScreen(
        tournament: tournament,
        section: _sectionOf(focus),
        focus: focus,
        popup: true,
        opsWorkspaceRoute: opsWorkspaceRoute,
        actionRouteBase: actionRouteBase,
      ),
    ),
  );
}

/// Venues and entry fee lay themselves out with `Expanded`.
bool _needsBoundedHeight(TournamentManagementFocus focus) =>
    focus == TournamentManagementFocus.venue ||
    focus == TournamentManagementFocus.fee;

TournamentManagementSection _sectionOf(TournamentManagementFocus focus) =>
    switch (focus) {
      TournamentManagementFocus.name ||
      TournamentManagementFocus.branding ||
      TournamentManagementFocus.contact =>
        TournamentManagementSection.information,
      TournamentManagementFocus.venue => TournamentManagementSection.schedule,
      TournamentManagementFocus.fee => TournamentManagementSection.finance,
      TournamentManagementFocus.registrationOpens ||
      TournamentManagementFocus.registrationDeadline ||
      TournamentManagementFocus.tournamentOpening ||
      TournamentManagementFocus.tournamentClosing =>
        TournamentManagementSection.registration,
    };

String _titleOf(AppLocalizations l10n, TournamentManagementFocus focus) =>
    switch (focus) {
      TournamentManagementFocus.name => l10n.tournamentManagementName,
      TournamentManagementFocus.branding => l10n.tournamentManagementBranding,
      TournamentManagementFocus.contact => l10n.tournamentContactTitle,
      TournamentManagementFocus.venue => l10n.tournamentManagementVenues,
      TournamentManagementFocus.fee => l10n.tournamentManagementEntryFee,
      TournamentManagementFocus.registrationOpens =>
        l10n.tournamentManagementRegistrationStarts,
      TournamentManagementFocus.registrationDeadline =>
        l10n.tournamentManagementRegistrationEnds,
      TournamentManagementFocus.tournamentOpening =>
        l10n.tournamentManagementStartDate,
      TournamentManagementFocus.tournamentClosing =>
        l10n.tournamentManagementEndDate,
    };
