import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/swiss_pairing_draft.dart';
import 'package:flutter_test/flutter_test.dart';

SwissPreview _preview() => SwissPreview(
  roundNumber: 2,
  totalRounds: 5,
  pairs: const [
    SwissPreviewPair(board: 1, participant1Id: 'a', participant2Id: 'b'),
    SwissPreviewPair(board: 2, participant1Id: 'c', participant2Id: 'd'),
  ],
  byeParticipantId: 'e',
  sitOutParticipantIds: const ['f'],
  participants: const [
    SwissPreviewParticipant(id: 'a', teamName: 'A', totalPoints: 3, buchholz: 5, hadBye: false),
    SwissPreviewParticipant(id: 'b', teamName: 'B', totalPoints: 3, buchholz: 4, hadBye: false),
    SwissPreviewParticipant(id: 'c', teamName: 'C', totalPoints: 2, buchholz: 3, hadBye: false),
    SwissPreviewParticipant(id: 'd', teamName: 'D', totalPoints: 2, buchholz: 2, hadBye: false),
    SwissPreviewParticipant(id: 'e', teamName: 'E', totalPoints: 1, buchholz: 1, hadBye: false),
    SwissPreviewParticipant(id: 'f', teamName: 'F', totalPoints: 0, buchholz: 0, hadBye: false),
    SwissPreviewParticipant(id: 'g', teamName: 'G', totalPoints: 0, buchholz: 0, hadBye: false),
  ],
  warnings: const [],
);

void main() {
  group('TC-FEAT-SWISS-DRAFT-01: khởi tạo và đổi chỗ', () {
    test('đưa người chưa được phân vào pool theo thứ tự preview', () {
      final draft = draftFromPreview(_preview());

      expect(draft.pairs, [(p1: 'a', p2: 'b'), (p1: 'c', p2: 'd')]);
      expect(draft.byeId, 'e');
      expect(draft.sitOutIds, ['f']);
      expect(draft.poolIds, ['g']);
    });

    test('đổi chỗ hai người trong các cặp và không sửa bản nháp cũ', () {
      final initial = draftFromPreview(_preview());
      final moved = moveParticipant(initial, 'a', const SwissPairSlot(1, 1));

      expect(moved.pairs, [(p1: 'c', p2: 'b'), (p1: 'a', p2: 'd')]);
      expect(initial.pairs.first.p1, 'a');
      expect(moved.poolIds, ['g']);
    });

    test('chuyển từ cặp sang pool để trống đúng ô', () {
      final initial = draftFromPreview(_preview());
      final moved = moveParticipant(initial, 'a', const SwissPoolSlot());

      expect(moved.pairs.first.p1, isNull);
      expect(moved.poolIds, ['g', 'a']);
      expect(isDraftComplete(moved), isFalse);
    });

    test('chuyển vào nghỉ và đổi BYE đang có', () {
      final initial = draftFromPreview(_preview());
      final sitOut = moveParticipant(initial, 'a', const SwissSitOutSlot());
      final bye = moveParticipant(initial, 'a', const SwissByeSlot());

      expect(sitOut.pairs.first.p1, isNull);
      expect(sitOut.sitOutIds, ['f', 'a']);
      expect(bye.byeId, 'a');
      expect(bye.pairs.first.p1, 'e');
    });

    test('không đổi khi thả vào đúng ô hoặc người không có trong nháp', () {
      final initial = draftFromPreview(_preview());

      expect(
        moveParticipant(initial, 'a', const SwissPairSlot(0, 1)),
        same(initial),
      );
      expect(moveParticipant(initial, 'missing', const SwissPoolSlot()), same(initial));
    });
  });

  group('TC-FEAT-SWISS-DRAFT-02: hợp lệ và yêu cầu', () {
    test('bỏ qua cặp rỗng hoàn toàn nhưng không nhận cặp thiếu một phía', () {
      final complete = SwissDraft(
        pairs: const [(p1: 'a', p2: 'b'), (p1: null, p2: null)],
        byeId: null,
        sitOutIds: const [],
        poolIds: const [],
      );
      final incomplete = SwissDraft(
        pairs: const [(p1: 'a', p2: null)],
        byeId: null,
        sitOutIds: const [],
        poolIds: const [],
      );

      expect(isDraftComplete(complete), isTrue);
      expect(isDraftComplete(incomplete), isFalse);
      expect(
        draftToRequest(complete, divisionId: 'division-1').pairs,
        [(participant1Id: 'a', participant2Id: 'b')],
      );
    });

    test('lịch sử hoàn tác và đặt lại giữ đúng trạng thái hiện tại', () {
      final first = draftFromPreview(_preview());
      final second = moveParticipant(first, 'a', const SwissPoolSlot());
      final history = SwissDraftHistory(first);

      expect(history.canUndo, isFalse);
      history.push(second);
      expect(history.current, same(second));
      expect(history.canUndo, isTrue);
      expect(history.undo(), same(first));
      expect(history.canUndo, isFalse);
      history.push(second);
      history.reset(first);
      expect(history.current, same(first));
      expect(history.canUndo, isFalse);
    });
  });
}
