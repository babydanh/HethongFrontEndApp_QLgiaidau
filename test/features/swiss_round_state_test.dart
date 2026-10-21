import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/swiss_round_state.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match({
  required String id,
  required int round,
  String status = 'SCHEDULED',
  bool isBye = false,
}) => MatchModel(
  id: id,
  round: round,
  matchNumber: round,
  status: status,
  isBye: isBye,
  bracketPosition: BracketPosition(round: round, position: 0),
  updatedAt: DateTime.utc(2026, 10, 21),
);

void main() {
  group('TC-FEAT-SWISS-ROUND-01: trạng thái vòng', () {
    test('không có trận thì chưa có vòng và không thể thao tác', () {
      final state = swissRoundState(const [], 5);

      expect(state.currentRound, 0);
      expect(state.roundComplete, isFalse);
      expect(state.canGenerateNext, isFalse);
      expect(state.nextRound, isNull);
      expect(state.canUndo, isFalse);
    });

    test('chỉ xét trận không-BYE của vòng hiện tại để xác định đã xong', () {
      final state = swissRoundState([
        _match(id: 'old', round: 1, status: 'SCHEDULED'),
        _match(id: 'current', round: 2, status: 'COMPLETED'),
        _match(id: 'bye', round: 2, isBye: true),
      ], 5);

      expect(state.currentRound, 2);
      expect(state.roundComplete, isTrue);
      expect(state.canGenerateNext, isTrue);
      expect(state.nextRound, 3);
      expect(state.canUndo, isFalse);
    });

    test('vòng có trận chưa xong không sinh vòng kế và không hoàn tác', () {
      final state = swissRoundState([
        _match(id: 'done', round: 3, status: 'COMPLETED'),
        _match(id: 'live', round: 3, status: 'IN_PROGRESS'),
      ], 5);

      expect(state.roundComplete, isFalse);
      expect(state.canGenerateNext, isFalse);
      expect(state.nextRound, isNull);
      expect(state.canUndo, isFalse);
    });

    test('chỉ hoàn tác vòng mới nhất khi mọi trận thường còn SCHEDULED', () {
      final state = swissRoundState([
        _match(id: 'old', round: 1, status: 'COMPLETED'),
        _match(id: 'current', round: 4, status: 'SCHEDULED'),
        _match(id: 'bye', round: 4, isBye: true, status: 'COMPLETED'),
      ], 4);

      expect(state.roundComplete, isFalse);
      expect(state.canGenerateNext, isFalse);
      expect(state.canUndo, isTrue);
    });

    test('không sinh quá tổng số vòng và không hoàn tác vòng một', () {
      final last = swissRoundState([
        _match(id: 'last', round: 3, status: 'COMPLETED'),
      ], 3);
      final first = swissRoundState([
        _match(id: 'first', round: 1, status: 'SCHEDULED'),
      ], 5);

      expect(last.canGenerateNext, isFalse);
      expect(last.nextRound, isNull);
      expect(first.canUndo, isFalse);
    });
  });
}
