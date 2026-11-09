import 'package:flutter/material.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_venues_section.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Full-screen host of the venue and court editor, opened from the schedule
/// tab so a manager can create courts without leaving the tournament page.
class ScheduleCourtManagementScreen extends StatelessWidget {
  const ScheduleCourtManagementScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        title: Text(
          l10n.tournamentManagementVenues,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: TournamentManagementVenuesSection(tournamentId: tournamentId),
      ),
    );
  }
}
