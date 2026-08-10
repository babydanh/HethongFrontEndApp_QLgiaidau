import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';

class BracketTab extends StatelessWidget {
  final String tournamentId;
  final String? selectedDivisionId;
  final String? bracketType;
  final int configuredLegs;
  final ScrollController? scrollController;

  const BracketTab({
    super.key,
    required this.tournamentId,
    this.selectedDivisionId,
    this.bracketType,
    this.configuredLegs = 1,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return BracketViewScreen(
      tournamentId: tournamentId,
      divisionId: selectedDivisionId,
      bracketType: bracketType,
      configuredLegs: configuredLegs,
      isEmbedded: true,
      scrollController: scrollController,
    );
  }
}
