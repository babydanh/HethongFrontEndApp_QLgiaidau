import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/leaderboard_view.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';

class ResultsTab extends ConsumerWidget {
  final String tournamentId;
  final String? selectedDivisionId;
  final String? selectedDivision;

  const ResultsTab({
    super.key,
    required this.tournamentId,
    this.selectedDivisionId,
    this.selectedDivision,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(standingsWithDivisionProvider((
      tournamentId: tournamentId,
      divisionId: selectedDivisionId,
    )));

    return standingsAsync.when(
      data: (standings) => LeaderboardView(
        standings: standings,
        selectedDivision: selectedDivision ?? '',
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (e, _) => Center(
        child: Text(
          'Không thể tải bảng xếp hạng: $e',
          style: TextStyle(color: context.colors.textSecondary),
        ),
      ),
    );
  }
}
