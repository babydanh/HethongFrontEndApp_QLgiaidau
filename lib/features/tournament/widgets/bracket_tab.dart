import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';

class BracketTab extends StatelessWidget {
  final String tournamentId;
  final String? selectedDivisionId;
  final ScrollController? scrollController;

  const BracketTab({
    super.key,
    required this.tournamentId,
    this.selectedDivisionId,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return BracketViewScreen(
      tournamentId: tournamentId,
      divisionId: selectedDivisionId,
      isEmbedded: true,
      scrollController: scrollController,
    );
  }
}
