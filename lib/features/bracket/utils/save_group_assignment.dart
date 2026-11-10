import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_stage_utils.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/group_stage_config.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Outcome of [saveGroupAssignment] once the config PATCH succeeded.
class SaveGroupAssignmentResult {
  /// True when the bracket was regenerated after the config update.
  final bool regenerated;

  /// Set when regeneration was attempted but failed (the config is saved).
  final Object? regenerationError;

  const SaveGroupAssignmentResult({
    required this.regenerated,
    this.regenerationError,
  });
}

/// True when a match already has a start time, a score or a result.
bool groupMatchHasStartedOrResult(MatchModel match) =>
    match.startedAt != null ||
    match.isLive ||
    match.isCompleted ||
    match.score1 != 0 ||
    match.score2 != 0 ||
    match.winnerId.isNotEmpty ||
    match.sets.any((set) => set.score1 != 0 || set.score2 != 0) ||
    (match.scoreDetails?.isNotEmpty ?? false);

/// Saves [config] to the division, then regenerates the group bracket when no
/// group match has started. A failing PATCH is rethrown (nothing changed); a
/// failing regeneration is reported in the result (the config stays saved).
Future<SaveGroupAssignmentResult> saveGroupAssignment(
  WidgetRef ref, {
  required String tournamentId,
  required String divisionId,
  required TournamentDivision division,
  required GroupStageConfig config,
  required List<MatchModel> matches,
}) async {
  await ref
      .read(tournamentManagementRepositoryProvider)
      .updateDivisionConfig(
        tournamentId,
        divisionId,
        buildDivisionConfigPatchPayload(
          currentRoundConfig: division.roundConfig,
          config: config,
        ),
      );

  void invalidateMatches() {
    ref.invalidate(
      bracketMatchesWithDivisionProvider((
        tournamentId: tournamentId,
        divisionId: divisionId,
      )),
    );
    ref.invalidate(bracketMatchesProvider(tournamentId));
    ref.invalidate(matchesProvider(tournamentId));
  }

  ref.invalidate(tournamentProvider(tournamentId));
  invalidateMatches();

  final groupMatches = matches.where(isGroupStageMatch);
  if (groupMatches.isEmpty || groupMatches.any(groupMatchHasStartedOrResult)) {
    return const SaveGroupAssignmentResult(regenerated: false);
  }
  try {
    await ref
        .read(tournamentRepositoryProvider)
        .generateBracket(
          tournamentId,
          divisionId: divisionId,
          seedingType: 'RANDOM',
          allowReset: true,
        );
    return const SaveGroupAssignmentResult(regenerated: true);
  } catch (error) {
    return SaveGroupAssignmentResult(
      regenerated: false,
      regenerationError: error,
    );
  } finally {
    invalidateMatches();
  }
}
