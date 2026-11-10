import 'package:app_quanly_giaidau/features/tournament/utils/participant_row_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canKickParticipant (như Web RegistrationTab)', () {
    test('cho phép khi đã duyệt hoặc chờ đồng đội', () {
      expect(canKickParticipant('COMPLETE', 'REGISTRATION_OPEN'), isTrue);
      expect(canKickParticipant('complete', 'ONGOING'), isTrue);
      expect(canKickParticipant('PENDING_PARTNER', 'ONGOING'), isTrue);
    });

    test('không cho khi chờ duyệt, bị từ chối, đã loại', () {
      for (final status in [
        'PENDING',
        'PENDING_APPROVAL',
        'REJECTED',
        'KICKED',
        'WITHDRAWN',
      ]) {
        expect(canKickParticipant(status, 'ONGOING'), isFalse, reason: status);
      }
    });

    test('không cho khi giải đã kết thúc hoặc huỷ', () {
      expect(canKickParticipant('COMPLETE', 'COMPLETED'), isFalse);
      expect(canKickParticipant('COMPLETE', 'cancelled'), isFalse);
    });
  });

  test('lý do mặc định giống Web', () {
    expect(kickDefaultReason, 'Loại khỏi giải theo điều lệ');
  });

  group('shouldOpenStreamKeyAfterCreate (như Web LivestreamTab)', () {
    test('chỉ camera PUSH mới mở QR ngay', () {
      expect(shouldOpenStreamKeyAfterCreate('PUSH'), isTrue);
      expect(shouldOpenStreamKeyAfterCreate('push'), isTrue);
      expect(shouldOpenStreamKeyAfterCreate('PULL'), isFalse);
      expect(shouldOpenStreamKeyAfterCreate(''), isFalse);
    });
  });
}
