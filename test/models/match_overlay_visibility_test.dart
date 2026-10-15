import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('overlay flags default to hidden when the payload omits them', () {
    final match = MatchModel.fromJson({
      'id': 'match-1',
      'round': 1,
      'status': 'LIVE',
    }, 'match-1');

    expect(match.h2hOverlayVisible, isFalse);
    expect(match.bracketOverlayVisible, isFalse);
  });

  test('overlay flags read the server booleans', () {
    final match = MatchModel.fromJson({
      'id': 'match-1',
      'round': 1,
      'status': 'LIVE',
      'h2hOverlayVisible': true,
      'bracketOverlayVisible': false,
    }, 'match-1');

    expect(match.h2hOverlayVisible, isTrue);
    expect(match.bracketOverlayVisible, isFalse);
  });

  test('copyWith changes one overlay flag and keeps the other', () {
    final match = MatchModel.fromJson({
      'id': 'match-1',
      'round': 1,
      'status': 'LIVE',
      'h2hOverlayVisible': true,
    }, 'match-1');

    final updated = match.copyWith(bracketOverlayVisible: true);

    expect(updated.h2hOverlayVisible, isTrue);
    expect(updated.bracketOverlayVisible, isTrue);
  });
}
