/// One stage of a division bracket, reduced to what the stage-operation
/// actions need (counts come from `GET /tournaments/:id/bracket`).
class StageOpsStage {
  const StageOpsStage({
    required this.id,
    required this.name,
    required this.type,
    required this.order,
    this.playoffTiebreak = false,
    this.totalMatches = 0,
    this.openMatches = 0,
    this.openGroupMatches = 0,
    this.hasStartedMatch = false,
  });

  final String id;
  final String name;

  /// Upper-cased Backend stage type (ROUND_ROBIN, SINGLE_ELIMINATION, ...).
  final String type;
  final int order;

  /// `roundConfig.tiebreakerMode == 'playoff'`: ties are settled by a playoff.
  final bool playoffTiebreak;

  /// Every non-deleted match of the stage, byes included.
  final int totalMatches;

  /// Matches that are neither COMPLETED nor CANCELLED: what finalizing cancels.
  final int openMatches;

  /// Open real matches that block advancing standings (byes and PLAYOFF
  /// branch matches excluded, as the Backend does).
  final int openGroupMatches;

  /// A real (non-bye) match was started or finished: the bracket can no
  /// longer be cancelled.
  final bool hasStartedMatch;

  bool get isRoundRobin => type == 'ROUND_ROBIN';

  factory StageOpsStage.fromJson(Map<String, dynamic> json) {
    var total = 0;
    var open = 0;
    var openGroup = 0;
    var started = false;
    final groups = json['groups'];
    for (final group in groups is List ? groups : const []) {
      final matches = group is Map ? group['matches'] : null;
      for (final match in matches is List ? matches : const []) {
        if (match is! Map) continue;
        total++;
        final status = (match['status'] ?? '').toString().toUpperCase();
        final isBye = match['isBye'] == true;
        final isOpen = status != 'COMPLETED' && status != 'CANCELLED';
        if (isOpen) open++;
        if (isBye) continue;
        final isPlayoff =
            (match['bracketBranch'] ?? '').toString().toUpperCase() ==
            'PLAYOFF';
        if (isOpen && !isPlayoff) openGroup++;
        if (status == 'ONGOING' ||
            status == 'COMPLETED' ||
            match['startedAt'] != null ||
            match['completedAt'] != null) {
          started = true;
        }
      }
    }
    final config = json['roundConfig'];
    return StageOpsStage(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString().toUpperCase(),
      order: (json['order'] as num?)?.toInt() ?? 0,
      playoffTiebreak: config is Map && config['tiebreakerMode'] == 'playoff',
      totalMatches: total,
      openMatches: open,
      openGroupMatches: openGroup,
      hasStartedMatch: started,
    );
  }
}

/// Result of `POST /tournaments/:id/advance-standings`.
class StageOpsAdvanceResult {
  const StageOpsAdvanceResult({this.stageCount = 0, this.totalMatches = 0});

  final int stageCount;
  final int totalMatches;
}

/// Result of `DELETE /tournaments/:id/bracket/divisions/:divisionId`.
class StageOpsCancelResult {
  const StageOpsCancelResult({
    this.cancelledStages = 0,
    this.cancelledMatches = 0,
  });

  final int cancelledStages;
  final int cancelledMatches;
}

/// Organizer operations on the stages of a division bracket. Kept apart from
/// the tournament repositories so adding a route never touches their fakes.
abstract class IStageOperationsRepository {
  Future<List<StageOpsStage>> getStages(
    String tournamentId, {
    required String divisionId,
  });

  /// `POST /tournaments/:id/stages/:stageId/finalize`: cancels every
  /// not-yet-completed match of the stage.
  Future<void> finalizeStage(String tournamentId, String stageId);

  /// `POST /tournaments/:id/advance-standings`.
  Future<StageOpsAdvanceResult> advanceStandings(
    String tournamentId, {
    required String divisionId,
    required String stageId,
  });

  /// `POST /tournaments/:id/playoff`.
  Future<void> createPlayoffMatch(
    String tournamentId, {
    required String stageId,
    required String participant1Id,
    required String participant2Id,
  });

  /// `DELETE /tournaments/:id/bracket/divisions/:divisionId`.
  Future<StageOpsCancelResult> cancelDivisionBracket(
    String tournamentId,
    String divisionId,
  );
}
