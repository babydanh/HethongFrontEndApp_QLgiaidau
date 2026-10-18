/// Thứ tự phát nối tiếp các đoạn bản ghi và các đoạn đã lỗi.
///
/// Thuần Dart (không import Flutter hay video_player) để test được. Widget mở
/// video và báo đoạn lỗi bằng [markFailed]; lớp này chỉ quyết định đoạn nào được
/// phát tiếp theo.
class MatchRecordingPlaybackPlan {
  MatchRecordingPlaybackPlan({required this.segmentCount})
    : assert(segmentCount >= 0);

  final int segmentCount;
  final Set<int> _failed = <int>{};

  bool isFailed(int index) => _failed.contains(index);

  void markFailed(int index) {
    if (index < 0 || index >= segmentCount) {
      throw RangeError.range(index, 0, segmentCount - 1, 'index');
    }
    _failed.add(index);
  }

  /// Đoạn chưa lỗi đầu tiên sau [index], bỏ qua các đoạn đã lỗi. Truyền -1 để
  /// lấy đoạn đầu tiên. Trả null khi không còn đoạn nào để phát.
  int? nextAfter(int index) {
    for (var i = index < 0 ? 0 : index + 1; i < segmentCount; i++) {
      if (!_failed.contains(i)) return i;
    }
    return null;
  }

  /// Mọi đoạn đều lỗi (và có ít nhất một đoạn): trình phát báo không phát được.
  bool get allFailed => segmentCount > 0 && _failed.length == segmentCount;
}
