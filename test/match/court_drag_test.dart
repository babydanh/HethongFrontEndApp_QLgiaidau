import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
import 'package:flutter_test/flutter_test.dart';

CourtDragSource _player(int team, int index) =>
    CourtDragSource(team: team, playerIndex: index);

void main() {
  group('player drag', () {
    test('onto a teammate swaps places of that team', () {
      final action = resolveCourtDrop(
        _player(1, 0),
        const CourtDropTarget.player(team: 1, playerIndex: 1),
      );
      expect(action, isA<SwapPlaces>());
      expect((action! as SwapPlaces).team, 1);
    });

    test('onto the free area of the same half swaps places', () {
      final action = resolveCourtDrop(
        _player(2, 1),
        const CourtDropTarget.half(team: 2),
      );
      expect(action, isA<SwapPlaces>());
      expect((action! as SwapPlaces).team, 2);
    });

    test('onto an opponent switches ends', () {
      final action = resolveCourtDrop(
        _player(1, 0),
        const CourtDropTarget.player(team: 2, playerIndex: 1),
      );
      expect(action, isA<SwitchEnds>());
    });

    test('onto the opponent half switches ends', () {
      final action = resolveCourtDrop(
        _player(1, 1),
        const CourtDropTarget.half(team: 2),
      );
      expect(action, isA<SwitchEnds>());
    });

    test('onto itself does nothing', () {
      final action = resolveCourtDrop(
        _player(1, 0),
        const CourtDropTarget.player(team: 1, playerIndex: 0),
      );
      expect(action, isNull);
    });
  });
}
