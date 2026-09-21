import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_diagram_screen.dart';

class BracketTab extends StatelessWidget {
  final String tournamentId;
  final String? selectedDivisionId;
  final String? bracketType;
  final int configuredLegs;

  const BracketTab({
    super.key,
    required this.tournamentId,
    this.selectedDivisionId,
    this.bracketType,
    this.configuredLegs = 1,
  });

  @override
  Widget build(BuildContext context) {
    return BracketDiagramScreen(
      tournamentId: tournamentId,
      divisionId: selectedDivisionId,
      bracketType: bracketType ?? 'single_elimination',
      configuredLegs: configuredLegs,
      isEmbedded: true,
    );
  }
}
