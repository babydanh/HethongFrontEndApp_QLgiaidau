import 'package:app_quanly_giaidau/core/services/socket_room_ref_counter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SocketRoomRefCounter', () {
    test('người giữ đầu tiên báo cần join, người giữ sau thì không', () {
      final rooms = SocketRoomRefCounter();

      expect(rooms.retain('tour-1'), isTrue);
      expect(rooms.retain('tour-1'), isFalse);
    });

    test('rời khi còn người giữ khác thì không báo leave và giữ phòng', () {
      final rooms = SocketRoomRefCounter()
        ..retain('tour-1')
        ..retain('tour-1');

      expect(rooms.release('tour-1'), isFalse);
      expect(rooms.ids.toList(), ['tour-1']);
    });

    test('người giữ cuối cùng rời thì báo leave và phòng biến mất', () {
      final rooms = SocketRoomRefCounter()
        ..retain('tour-1')
        ..retain('tour-1');
      rooms.release('tour-1');

      expect(rooms.release('tour-1'), isTrue);
      expect(rooms.isEmpty, isTrue);
    });

    test('rời một phòng chưa được giữ không báo leave và không lỗi', () {
      final rooms = SocketRoomRefCounter();

      expect(rooms.release('chua-giu'), isFalse);
      expect(rooms.isEmpty, isTrue);
    });

    test('giữ lại sau khi đã rời hết thì báo join lại', () {
      final rooms = SocketRoomRefCounter()..retain('match-1');
      rooms.release('match-1');

      expect(rooms.retain('match-1'), isTrue);
    });

    test('hai phòng độc lập, rời phòng này không ảnh hưởng phòng kia', () {
      final rooms = SocketRoomRefCounter()
        ..retain('a')
        ..retain('b');

      expect(rooms.release('a'), isTrue);
      expect(rooms.ids.toList(), ['b']);
    });

    test('clear xoá toàn bộ người giữ', () {
      final rooms = SocketRoomRefCounter()
        ..retain('a')
        ..retain('b');

      rooms.clear();

      expect(rooms.isEmpty, isTrue);
      expect(rooms.retain('a'), isTrue);
    });
  });
}
