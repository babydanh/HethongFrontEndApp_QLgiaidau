import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/leaderboard_view.dart';

class LeaderboardTab extends ConsumerWidget {
  final String tournamentId;
  final String selectedDivision;

  const LeaderboardTab({
    super.key,
    required this.tournamentId,
    required this.selectedDivision,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(standingsProvider(tournamentId));
    final colors = context.colors;

    return standingsAsync.when(
      data: (standings) {
        final filteredStandings = selectedDivision == "Tất cả"
            ? standings
            : standings.where((s) => s.group == selectedDivision).toList();

        return LeaderboardView(
          standings: filteredStandings,
          selectedDivision: selectedDivision,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          "Lỗi khi tải bảng xếp hạng",
          style: TextStyle(color: colors.error),
        ),
      ),
    );
  }
}
