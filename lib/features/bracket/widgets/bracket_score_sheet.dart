import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/utils/match_code.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_score_dialog.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';

/// Opens the same "Nhập điểm" sheet as the Results tab for a bracket match
/// (date, sets, "Vào trang Live", "Lưu"), then reloads the match lists once a
/// score was saved.
Future<void> showBracketScoreSheet(
  BuildContext context, {
  required MatchModel match,
  required String tournamentId,
}) async {
  // Taken before the await: the card may be gone when the sheet closes.
  final container = ProviderScope.containerOf(context, listen: false);
  final code = matchCodeOrNull(match);
  final saved = await showResultsScoreDialog(
    context,
    match: match,
    tournamentId: tournamentId,
    label: code == null ? '#${match.matchNumber}' : '#$code',
    liveRoute: NavigationHelper.getLiveMatchRoute(tournamentId, match.id),
    isLite:
        container.read(tournamentProvider(tournamentId)).value?.isLite == true,
  );
  if (saved != true) return;
  container
    ..invalidate(bracketMatchesProvider(tournamentId))
    ..invalidate(bracketMatchesWithDivisionProvider)
    ..invalidate(matchesProvider(tournamentId))
    ..invalidate(managedMatchesWithDivisionProvider)
    ..invalidate(liteBracketMatchesProvider(tournamentId));
}
