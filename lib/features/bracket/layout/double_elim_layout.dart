import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

class DoubleElimLayout {
  const DoubleElimLayout({
    required this.positions,
    required this.winnerRounds,
    required this.loserRounds,
    required this.winnersTop,
    required this.losersTop,
    required this.winnersHeight,
    required this.losersHeight,
    required this.grandFinalX,
    required this.grandFinalTop,
    required this.width,
    required this.height,
    required this.cardWidth,
    required this.cardHeight,
    required this.columnGap,
  });

  final Map<String, Offset> positions;
  final List<int> winnerRounds;
  final List<int> loserRounds;
  final double winnersTop;
  final double losersTop;
  final double winnersHeight;
  final double losersHeight;
  final double grandFinalX;
  final double grandFinalTop;
  final double width;
  final double height;
  final double cardWidth;
  final double cardHeight;
  final double columnGap;

  double get columnWidth => cardWidth + columnGap;

  double winnerColumnX(int round) => (round - 1) * 2 * columnWidth;

  double loserColumnX(int round) {
    final maxWinnerRound = winnerRounds.isEmpty ? 1 : winnerRounds.last;
    final maxLoserRound = loserRounds.isEmpty ? 1 : loserRounds.last;
    var columnIndex = round - 1;
    if (round == maxLoserRound) {
      columnIndex = (maxWinnerRound - 1) * 2;
    }
    return columnIndex * columnWidth;
  }

  double get winnersBandWidth {
    if (winnerRounds.isEmpty) return 0;
    return winnerColumnX(winnerRounds.last) + cardWidth;
  }

  double get losersBandWidth {
    if (loserRounds.isEmpty) return 0;
    return loserColumnX(loserRounds.last) + cardWidth;
  }
}

class DoubleElimLayoutCalculator {
  const DoubleElimLayoutCalculator({
    this.cardWidth = 240,
    this.cardHeight = 88,
    this.columnGap = 72,
    this.rowGap = 20,
    this.bandGap = 80,
    this.winnersTop = 52,
  });

  final double cardWidth;
  final double cardHeight;
  final double columnGap;
  final double rowGap;
  final double bandGap;
  final double winnersTop;

  double get _columnWidth => cardWidth + columnGap;
  double get _baseSlotHeight => cardHeight + rowGap;

  DoubleElimLayout calculate({
    required Map<int, List<MatchModel>> winners,
    required Map<int, List<MatchModel>> losers,
    required List<MatchModel> finals,
  }) {
    final winnerRounds = winners.keys.toList()..sort();
    final loserRounds = losers.keys.toList()..sort();
    final maxWinnerRound = winnerRounds.isEmpty ? 1 : winnerRounds.last;
    final maxLoserRound = loserRounds.isEmpty ? 1 : loserRounds.last;
    final maxWinnerCount = _maxRoundSize(winners, winnerRounds);
    final maxLoserCount = _maxRoundSize(losers, loserRounds);
    final winnersHeight = maxWinnerCount * _baseSlotHeight;
    final losersTop = winnersTop + winnersHeight + bandGap;
    final losersHeight = maxLoserCount * _baseSlotHeight;
    final positions = <String, Offset>{};

    for (final round in winnerRounds) {
      final roundMatches = winners[round]!;
      final slotHeight = math.pow(2, round - 1) * _baseSlotHeight;
      final roundHeight = roundMatches.length * slotHeight;
      final roundTop = winnersTop + (winnersHeight - roundHeight) / 2;
      final x = (round - 1) * 2 * _columnWidth;

      for (var index = 0; index < roundMatches.length; index++) {
        positions[roundMatches[index].id] = Offset(
          x,
          roundTop + index * slotHeight + slotHeight / 2 - cardHeight / 2,
        );
      }
    }
    _alignTargetsToSources(winners, winnerRounds, positions);

    for (final round in loserRounds) {
      var columnIndex = round - 1;
      if (round == maxLoserRound) {
        columnIndex = (maxWinnerRound - 1) * 2;
      }
      final roundMatches = losers[round]!;
      final roundHeight = roundMatches.length * _baseSlotHeight;
      final roundTop = losersTop + (losersHeight - roundHeight) / 2;

      for (var index = 0; index < roundMatches.length; index++) {
        positions[roundMatches[index].id] = Offset(
          columnIndex * _columnWidth,
          roundTop +
              index * _baseSlotHeight +
              _baseSlotHeight / 2 -
              cardHeight / 2,
        );
      }
    }
    _alignTargetsToSources(losers, loserRounds, positions);

    final columnsCount = math.max(maxWinnerRound * 2 - 1, maxLoserRound);
    final grandFinalX = columnsCount * _columnWidth;
    final winnerFinal = winnerRounds.isEmpty
        ? null
        : winners[maxWinnerRound]?.firstOrNull;
    final loserFinal = loserRounds.isEmpty
        ? null
        : losers[maxLoserRound]?.firstOrNull;
    final winnerCenter = _centerOf(
      winnerFinal == null ? null : positions[winnerFinal.id],
      winnersTop + winnersHeight / 2,
    );
    final loserCenter = _centerOf(
      loserFinal == null ? null : positions[loserFinal.id],
      losersTop + losersHeight / 2,
    );
    final grandFinalTop = (winnerCenter + loserCenter) / 2 - cardHeight / 2;

    for (var index = 0; index < finals.length; index++) {
      positions[finals[index].id] = Offset(
        grandFinalX + index * _columnWidth,
        grandFinalTop,
      );
    }

    final rightEdge =
        grandFinalX + math.max(finals.length, 1) * _columnWidth + 48;
    final bottomEdge = math.max(
      losersTop + losersHeight + 48,
      grandFinalTop + cardHeight + 48,
    );

    return DoubleElimLayout(
      positions: Map.unmodifiable(positions),
      winnerRounds: List.unmodifiable(winnerRounds),
      loserRounds: List.unmodifiable(loserRounds),
      winnersTop: winnersTop,
      losersTop: losersTop,
      winnersHeight: winnersHeight,
      losersHeight: losersHeight,
      grandFinalX: grandFinalX,
      grandFinalTop: grandFinalTop,
      width: rightEdge,
      height: bottomEdge,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      columnGap: columnGap,
    );
  }

  int _maxRoundSize(Map<int, List<MatchModel>> rounds, List<int> sortedRounds) {
    if (sortedRounds.isEmpty) return 1;
    return sortedRounds
        .map((round) => rounds[round]?.length ?? 0)
        .fold(1, math.max);
  }

  void _alignTargetsToSources(
    Map<int, List<MatchModel>> rounds,
    List<int> sortedRounds,
    Map<String, Offset> positions,
  ) {
    final allMatches = sortedRounds.expand((round) => rounds[round]!).toList();
    for (final round in sortedRounds.skip(1)) {
      for (final target in rounds[round]!) {
        final sourcePositions = allMatches
            .where((source) => source.nextMatchId == target.id)
            .map((source) => positions[source.id])
            .whereType<Offset>()
            .toList();
        if (sourcePositions.isEmpty) continue;

        final targetPosition = positions[target.id]!;
        final averageCenter =
            sourcePositions
                .map((position) => position.dy + cardHeight / 2)
                .reduce((sum, value) => sum + value) /
            sourcePositions.length;
        positions[target.id] = Offset(
          targetPosition.dx,
          averageCenter - cardHeight / 2,
        );
      }
    }
  }

  double _centerOf(Offset? position, double fallback) {
    return position == null ? fallback : position.dy + cardHeight / 2;
  }
}
