import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
import 'package:flutter_test/flutter_test.dart';

CourtDragSource _player(int team, int index) =>
    CourtDragSource(kind: CourtDragKind.player, team: team, playerIndex: index);

CourtDragSource _ball(int team, int index) =>
    CourtDragSource(kind: CourtDragKind.ball, team: team, playerIndex: index);

void main() {
  group('player drag', () {
    test('onto a teammate swaps places of that team', () {
      final action = resolveCourtDrop(
        _player(1, 0),
        const CourtDropTarget.player(team: 1, playerIndex: 1),
        1,
      );
      expect(action, isA<SwapPlaces>());
      expect((action! as SwapPlaces).team, 1);
    });

    test('onto the free area of the same half swaps places', () {
      final action = resolveCourtDrop(
        _player(2, 1),
        const CourtDropTarget.half(team: 2),
        1,
      );
      expect(action, isA<SwapPlaces>());
      expect((action! as SwapPlaces).team, 2);
    });

    test('onto an opponent switches ends', () {
      final action = resolveCourtDrop(
        _player(1, 0),
        const CourtDropTarget.player(team: 2, playerIndex: 1),
        1,
      );
      expect(action, isA<SwitchEnds>());
    });

    test('onto the opponent half switches ends', () {
      final action = resolveCourtDrop(
        _player(1, 1),
        const CourtDropTarget.half(team: 2),
        null,
      );
      expect(action, isA<SwitchEnds>());
    });

    test('onto itself does nothing', () {
      final action = resolveCourtDrop(
        _player(1, 0),
        const CourtDropTarget.player(team: 1, playerIndex: 0),
        1,
      );
      expect(action, isNull);
    });
  });

  group('ball drag', () {
    test('onto the serving teammate sets the server without side-out', () {
      final action = resolveCourtDrop(
        _ball(1, 0),
        const CourtDropTarget.player(team: 1, playerIndex: 1),
        1,
      );
      final set = action! as SetServer;
      expect(set.team, 1);
      expect(set.playerIndex, 1);
      expect(set.changesServingTeam, isFalse);
    });

    test('onto an opponent sets the server and changes the serving team', () {
      final action = resolveCourtDrop(
        _ball(1, 0),
        const CourtDropTarget.player(team: 2, playerIndex: 0),
        1,
      );
      final set = action! as SetServer;
      expect(set.team, 2);
      expect(set.playerIndex, 0);
      expect(set.changesServingTeam, isTrue);
    });

    test('onto the player holding it does nothing', () {
      final action = resolveCourtDrop(
        _ball(2, 1),
        const CourtDropTarget.player(team: 2, playerIndex: 1),
        2,
      );
      expect(action, isNull);
    });

    test('onto a half does nothing', () {
      expect(
        resolveCourtDrop(_ball(1, 0), const CourtDropTarget.half(team: 1), 1),
        isNull,
      );
      expect(
        resolveCourtDrop(_ball(1, 0), const CourtDropTarget.half(team: 2), 1),
        isNull,
      );
    });

    test('does nothing while no team is serving', () {
      final action = resolveCourtDrop(
        _ball(1, 0),
        const CourtDropTarget.player(team: 1, playerIndex: 1),
        null,
      );
      expect(action, isNull);
    });
  });
}
