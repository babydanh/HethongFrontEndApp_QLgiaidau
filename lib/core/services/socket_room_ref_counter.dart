/// Đếm số nơi đang giữ một phòng socket (trận, giải, phiên CLB, cộng đồng).
///
/// Một phòng chỉ rời khi người giữ cuối cùng rời. Nếu không đếm, một màn hình
/// đóng sẽ rời phòng mà màn hình khác vẫn đang xem, và socket còn lại rỗng phòng.
class SocketRoomRefCounter {
  final _holders = <String, int>{};

  /// Các phòng đang có ít nhất một người giữ.
  Iterable<String> get ids => _holders.keys;

  bool get isEmpty => _holders.isEmpty;

  /// Thêm một người giữ [id]. Trả về true khi đây là người giữ đầu tiên,
  /// tức là cần emit join.
  bool retain(String id) {
    final count = _holders[id] ?? 0;
    _holders[id] = count + 1;
    return count == 0;
  }

  /// Bỏ một người giữ [id]. Trả về true khi người giữ cuối cùng vừa rời,
  /// tức là cần emit leave. Rời một phòng chưa được giữ thì không làm gì.
  bool release(String id) {
    final count = _holders[id];
    if (count == null) return false;
    if (count > 1) {
      _holders[id] = count - 1;
      return false;
    }
    _holders.remove(id);
    return true;
  }

  void clear() => _holders.clear();
}
