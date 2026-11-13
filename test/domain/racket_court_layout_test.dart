import 'package:app_quanly_giaidau/domain/services/racket_court_layout.dart';
import 'package:flutter_test/flutter_test.dart';

// Cases mirror the Lavish mock `app-bam-diem-san-thao-tac.html`.
RacketCourtCell _cell(
  List<RacketCourtCell> cells,
  int team, {
  required bool right,
}) => cells.singleWhere((c) => c.team == team && c.rightCourt == right);

void main() {
  group('TC-RACKET-L-01 doubles, team 2 serves from the right', () {
    final cells = racketCourtCells(
      serverTeam: 2,
      serverRight: true,
      serverPlayerIndex: 0,
      doubles: true,
    );

    test('always four cells: team 1 right/left, team 2 right/left', () {
      expect(cells.length, 4);
      expect(cells.map((c) => (c.team, c.rightCourt)).toList(), [
        (1, true),
        (1, false),
        (2, true),
        (2, false),
      ]);
    });
    test('server on the right cell of team 2, receiver on the right of team 1', () {
      expect(_cell(cells, 2, right: true).role, CourtCellRole.server);
      expect(_cell(cells, 2, right: true).playerIndex, 0);
      expect(_cell(cells, 1, right: true).role, CourtCellRole.receiver);
      expect(_cell(cells, 2, right: false).role, CourtCellRole.none);
      expect(_cell(cells, 1, right: false).role, CourtCellRole.none);
    });
  });

  group('TC-RACKET-L-02 singles, odd score: left court', () {
    final cells = racketCourtCells(
      serverTeam: 1,
      serverRight: false,
      serverPlayerIndex: 0,
      doubles: false,
    );
    test('server and receiver on the left, the other cells are empty', () {
      expect(_cell(cells, 1, right: false).role, CourtCellRole.server);
      expect(_cell(cells, 2, right: false).role, CourtCellRole.receiver);
      expect(_cell(cells, 1, right: false).playerIndex, 0);
      expect(_cell(cells, 2, right: false).playerIndex, 0);
      expect(_cell(cells, 1, right: true).playerIndex, isNull);
      expect(_cell(cells, 2, right: true).playerIndex, isNull);
    });
  });

  group('TC-RACKET-L-03 doubles, second player serves from the left', () {
    final cells = racketCourtCells(
      serverTeam: 1,
      serverRight: false,
      serverPlayerIndex: 1,
      doubles: true,
    );
    test('the partner stands on the right', () {
      expect(_cell(cells, 1, right: false).playerIndex, 1);
      expect(_cell(cells, 1, right: true).playerIndex, 0);
      expect(_cell(cells, 1, right: false).role, CourtCellRole.server);
    });
  });

  group('TC-RACKET-L-04 receiving pair uses its own right player', () {
    test('team 2 right player 1 receives from the right', () {
      final cells = racketCourtCells(
        serverTeam: 1,
        serverRight: true,
        serverPlayerIndex: 0,
        doubles: true,
        team2RightPlayer: 1,
      );
      final r = _cell(cells, 2, right: true);
      expect(r.role, CourtCellRole.receiver);
      expect(r.playerIndex, 1);
      expect(_cell(cells, 2, right: false).playerIndex, 0);
    });
  });

  group('TC-RACKET-L-05 doubles with an unknown server player', () {
    final cells = racketCourtCells(
      serverTeam: 2,
      serverRight: true,
      serverPlayerIndex: null,
      doubles: true,
    );
    test('shows the pairs without a GIAO or NHẬN role', () {
      expect(cells.every((c) => c.role == CourtCellRole.none), isTrue);
      expect(_cell(cells, 1, right: true).playerIndex, 0);
      expect(_cell(cells, 1, right: false).playerIndex, 1);
    });
  });

  group('TC-RACKET-L-06 no serving team', () {
    test('doubles: no roles', () {
      final cells = racketCourtCells(
        serverTeam: null,
        serverRight: true,
        serverPlayerIndex: null,
        doubles: true,
      );
      expect(cells.every((c) => c.role == CourtCellRole.none), isTrue);
    });
    test('singles: each player stands on the right, no roles', () {
      final cells = racketCourtCells(
        serverTeam: null,
        serverRight: true,
        serverPlayerIndex: null,
        doubles: false,
      );
      expect(cells.every((c) => c.role == CourtCellRole.none), isTrue);
      expect(_cell(cells, 1, right: true).playerIndex, 0);
      expect(_cell(cells, 1, right: false).playerIndex, isNull);
    });
  });
}
