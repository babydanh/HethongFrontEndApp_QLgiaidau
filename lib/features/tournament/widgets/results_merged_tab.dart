import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_board.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_tab.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Public "Kết quả" tab of one division, like the Web `ResultsMergedTab`: the
/// podium once the division has official results, then the match board. A
/// finished division lists only its final on the board.
class ResultsMergedTab extends ConsumerWidget {
  const ResultsMergedTab({
    super.key,
    required this.tournamentId,
    required this.isLite,
    required this.canManage,
    this.divisionId,
    this.divisionName,
    this.matchType,
    this.onShare,
    this.inline = false,
  });

  final String tournamentId;
  final bool isLite;

  /// Organisers see match codes and the score / schedule buttons.
  final bool canManage;

  /// Null when the tournament has a single division.
  final String? divisionId;
  final String? divisionName;
  final String? matchType;

  /// Opens the share sheet when the podium is tapped.
  final VoidCallback? onShare;

  /// Placed in a page that already scrolls (an accordion row): lays out as a
  /// plain column instead of its own scrolling list.
  final bool inline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPodium = ref.watch(
      tournamentResultProvider((
        tournamentId: tournamentId,
        divisionId: divisionId,
      )).select((async) {
        final awards = async.value?['awards'];
        return awards is List && awards.isNotEmpty;
      }),
    );

    final children = [
        ResultsTab(
          key: ValueKey('results-podium-$divisionId'),
          tournamentId: tournamentId,
          selectedDivisionId: divisionId,
          selectedDivision: divisionName,
          matchType: matchType,
          onShare: onShare,
          embedded: true,
        ),
        if (hasPodium) const SizedBox(height: 12),
        ResultsMatchBoard(
          key: ValueKey('results-board-$divisionId'),
          tournamentId: tournamentId,
          isLite: isLite,
          canManage: canManage,
          divisionId: divisionId,
          finalOnly: hasPodium,
        ),
    ];
    if (inline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 140),
      children: children,
    );
  }
}
