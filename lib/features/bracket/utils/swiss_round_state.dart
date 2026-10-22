import 'package:app_quanly_giaidau/domain/entities/match.dart';

class SwissRoundState {
  const SwissRoundState({
    required this.currentRound,
    required this.roundComplete,
    required this.canGenerateNext,
    required this.nextRound,
    required this.canUndo,
  });

  final int currentRound;
  final bool roundComplete;
  final bool canGenerateNext;
  final int? nextRound;
  final bool canUndo;
}

SwissRoundState swissRoundState(List<MatchModel> matches, int totalRounds) {
  var currentRound = 0;
  for (final match in matches) {
    if (match.round > currentRound) currentRound = match.round;
  }
  if (currentRound == 0) {
    return const SwissRoundState(
      currentRound: 0,
      roundComplete: false,
      canGenerateNext: false,
      nextRound: null,
      canUndo: false,
    );
  }

  var roundComplete = true;
  var allScheduled = true;
  for (final match in matches) {
    if (match.round != currentRound || match.isBye) continue;
    // MatchModel.status is lower-case from the API; compare normalized.
    if (match.normalizedStatus != 'COMPLETED') roundComplete = false;
    if (match.normalizedStatus != 'SCHEDULED') allScheduled = false;
  }
  final canGenerateNext = currentRound < totalRounds && roundComplete;
  final canUndo = currentRound >= 2 && allScheduled;

  return SwissRoundState(
    currentRound: currentRound,
    roundComplete: roundComplete,
    canGenerateNext: canGenerateNext,
    nextRound: canGenerateNext ? currentRound + 1 : null,
    canUndo: canUndo,
  );
}
