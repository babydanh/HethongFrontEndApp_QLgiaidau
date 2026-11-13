import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
import 'package:app_quanly_giaidau/features/match/utils/racket_court_drag.dart';
import 'package:flutter_test/flutter_test.dart';

CourtDragSource _player(int team, int index) => CourtDragSource(
  kind: CourtDragKind.player,
  team: team,
  playerIndex: index,
);

CourtDragSource _ball(int team, int index) =>
    CourtDragSource(kind: CourtDragKind.ball, team: team, playerIndex: index);

CourtDropAction? _drop(
  CourtDragSource source,
  CourtDropTarget target, {
  int? serving = 1,
  bool doubles = true,
  bool tennis = false,
  bool finished = false,
}) => racketResolveDrop(
  source: source,
  target: target,
  servingTeam: serving,
  isDoubles: doubles,
  isTennis: tennis,
  finished: finished,
);

void main() {
  group('TC-RACKET-D-01 badminton doubles', () {
    test('a player on the teammate swaps the two cells', () {
      final a = _drop(
        _player(1, 0),
        const CourtDropTarget.player(team: 1, playerIndex: 1),
      );
      expect(a, isA<SwapPlaces>());
      expect((a as SwapPlaces).team, 1);
    });
    test('a player on the free area of the own half swaps too', () {
      expect(
        _drop(_player(1, 0), const CourtDropTarget.half(team: 1)),
        isA<SwapPlaces>(),
      );
    });
    test('a player on itself does nothing', () {
      expect(
        _drop(
          _player(1, 0),
          const CourtDropTarget.player(team: 1, playerIndex: 0),
        ),
        isNull,
      );
    });
  });

  group('TC-RACKET-D-02 switch ends', () {
    test('a player on the other half switches ends', () {
      expect(
        _drop(_player(1, 0), const CourtDropTarget.half(team: 2)),
        isA<SwitchEnds>(),
      );
    });
    test('also in singles', () {
      expect(
        _drop(
          _player(1, 0),
          const CourtDropTarget.player(team: 2, playerIndex: 0),
          doubles: false,
        ),
        isA<SwitchEnds>(),
      );
    });
  });

  group('TC-RACKET-D-03 singles', () {
    test('no swap inside the own half', () {
      expect(
        _drop(
          _player(1, 0),
          const CourtDropTarget.half(team: 1),
          doubles: false,
        ),
        isNull,
      );
    });
  });

  group('TC-RACKET-D-04 tennis doubles', () {
    test('the serving pair cannot be swapped', () {
      expect(
        _drop(
          _player(1, 0),
          const CourtDropTarget.player(team: 1, playerIndex: 1),
          tennis: true,
        ),
        isNull,
      );
    });
    test('the receiving pair can', () {
      expect(
        _drop(
          _player(2, 0),
          const CourtDropTarget.player(team: 2, playerIndex: 1),
          tennis: true,
        ),
        isA<SwapPlaces>(),
      );
    });
  });

  group('TC-RACKET-D-05 ball', () {
    test('on a teammate: the teammate serves', () {
      final a = _drop(
        _ball(1, 0),
        const CourtDropTarget.player(team: 1, playerIndex: 1),
      );
      expect(a, isA<SetServer>());
      expect((a as SetServer).changesServingTeam, isFalse);
    });
    test('on an opponent: the serve changes team', () {
      final a = _drop(
        _ball(1, 0),
        const CourtDropTarget.player(team: 2, playerIndex: 1),
      );
      expect((a as SetServer).changesServingTeam, isTrue);
      expect(a.team, 2);
      expect(a.playerIndex, 1);
    });
    test('on its own cell or on a free area does nothing', () {
      expect(
        _drop(
          _ball(1, 0),
          const CourtDropTarget.player(team: 1, playerIndex: 0),
        ),
        isNull,
      );
      expect(_drop(_ball(1, 0), const CourtDropTarget.half(team: 2)), isNull);
    });
    test('no serving team: no ball drop', () {
      expect(
        _drop(
          _ball(1, 0),
          const CourtDropTarget.player(team: 2, playerIndex: 0),
          serving: null,
        ),
        isNull,
      );
    });
  });

  group('TC-RACKET-D-06 finished match', () {
    test('nothing is accepted', () {
      expect(
        _drop(
          _player(1, 0),
          const CourtDropTarget.half(team: 2),
          finished: true,
        ),
        isNull,
      );
      expect(
        _drop(
          _ball(1, 0),
          const CourtDropTarget.player(team: 2, playerIndex: 0),
          finished: true,
        ),
        isNull,
      );
    });
  });
}
