import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/swiss_round_state.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match({
  required String id,
  required int round,
  String status = 'scheduled',
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
        _match(id: 'old', round: 1, status: 'scheduled'),
        _match(id: 'current', round: 2, status: 'completed'),
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
        _match(id: 'done', round: 3, status: 'completed'),
        _match(id: 'live', round: 3, status: 'in_progress'),
      ], 5);

      expect(state.roundComplete, isFalse);
      expect(state.canGenerateNext, isFalse);
      expect(state.nextRound, isNull);
      expect(state.canUndo, isFalse);
    });

    test('chỉ hoàn tác vòng mới nhất khi mọi trận thường còn SCHEDULED', () {
      final state = swissRoundState([
        _match(id: 'old', round: 1, status: 'completed'),
        _match(id: 'current', round: 4, status: 'scheduled'),
        _match(id: 'bye', round: 4, isBye: true, status: 'completed'),
      ], 4);

      expect(state.roundComplete, isFalse);
      expect(state.canGenerateNext, isFalse);
      expect(state.canUndo, isTrue);
    });

    test('không sinh quá tổng số vòng và không hoàn tác vòng một', () {
      final last = swissRoundState([
        _match(id: 'last', round: 3, status: 'completed'),
      ], 3);
      final first = swissRoundState([
        _match(id: 'first', round: 1, status: 'scheduled'),
      ], 5);

      expect(last.canGenerateNext, isFalse);
      expect(last.nextRound, isNull);
      expect(first.canUndo, isFalse);
    });
  });

  group('status đến từ JSON thật (MatchModel.fromJson hạ chữ thường)', () {
    MatchModel fromJson(String id, int round, String status, {bool? isBye}) =>
        MatchModel.fromJson({
          'id': id,
          'round': round,
          'status': status,
          if (isBye != null) 'isBye': isBye,
        }, id);

    test('vòng COMPLETED từ JSON thì được sinh vòng kế', () {
      final state = swissRoundState([
        fromJson('a', 2, 'COMPLETED'),
        fromJson('b', 2, 'COMPLETED'),
        fromJson('bye', 2, 'COMPLETED', isBye: true),
      ], 5);

      expect(state.roundComplete, isTrue);
      expect(state.canGenerateNext, isTrue);
      expect(state.nextRound, 3);
    });

    test('vòng SCHEDULED từ JSON thì hoàn tác được', () {
      final state = swissRoundState([
        fromJson('old', 1, 'COMPLETED'),
        fromJson('a', 2, 'SCHEDULED'),
        fromJson('b', 2, 'SCHEDULED'),
      ], 5);

      expect(state.canUndo, isTrue);
      expect(state.canGenerateNext, isFalse);
    });
  });

  group('swissRoundFilterReset', () {
    test('giữ nguyên khi vòng đang lọc còn và vòng hiện tại không đổi', () {
      expect(
        swissRoundFilterReset(
          selected: 1,
          currentRound: 2,
          rounds: {1, 2},
          keyChanged: false,
        ),
        isNull,
      );
      // "Tất cả các vòng" (0) là lựa chọn của người dùng, không bị đè.
      expect(
        swissRoundFilterReset(
          selected: 0,
          currentRound: 2,
          rounds: {1, 2},
          keyChanged: false,
        ),
        isNull,
      );
    });

    test('theo vòng mới khi vòng hiện tại hoặc nội dung đổi', () {
      expect(
        swissRoundFilterReset(
          selected: 1,
          currentRound: 2,
          rounds: {1, 2},
          keyChanged: true,
        ),
        2,
      );
    });

    test('vòng đang lọc đã bị hoàn tác thì về vòng hiện tại', () {
      expect(
        swissRoundFilterReset(
          selected: 3,
          currentRound: 2,
          rounds: {1, 2},
          keyChanged: false,
        ),
        2,
      );
    });
  });
}
