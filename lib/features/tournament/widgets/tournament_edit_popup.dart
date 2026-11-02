import 'package:app_quanly_giaidau/core/dialogs/popup_dialog.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_section_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Fraction of the screen height taken by popups that hold a list or an
/// upload area (venues, entry fee, logo and banner).
const _tallPopupHeightFactor = 0.7;

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
  final tall = _isTall(focus);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    sheetAnimationStyle: popupSheetAnimation,
    builder: (sheetContext) {
      final content = TournamentManagementSectionScreen(
        tournament: tournament,
        section: _sectionOf(focus),
        focus: focus,
        popup: true,
        opsWorkspaceRoute: opsWorkspaceRoute,
        actionRouteBase: actionRouteBase,
      );
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                _titleOf(l10n, focus),
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (tall)
              SizedBox(
                height:
                    MediaQuery.sizeOf(sheetContext).height *
                    _tallPopupHeightFactor,
                child: content,
              )
            else
              Flexible(child: content),
          ],
        ),
      );
    },
  );
}

bool _isTall(TournamentManagementFocus focus) => switch (focus) {
  TournamentManagementFocus.venue ||
  TournamentManagementFocus.fee ||
  TournamentManagementFocus.contact ||
  TournamentManagementFocus.branding => true,
  _ => false,
};

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
      TournamentManagementFocus.tournamentOpening =>
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
    };
