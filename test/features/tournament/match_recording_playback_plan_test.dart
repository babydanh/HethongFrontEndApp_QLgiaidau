import 'package:app_quanly_giaidau/features/tournament/utils/match_recording_playback_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bắt đầu từ đoạn đầu khi chưa phát đoạn nào', () {
    final plan = MatchRecordingPlaybackPlan(segmentCount: 3);

    expect(plan.nextAfter(-1), 0);
  });

  test('chuyển sang đoạn kế tiếp theo thứ tự, hết đoạn thì null', () {
    final plan = MatchRecordingPlaybackPlan(segmentCount: 3);

    expect(plan.nextAfter(0), 1);
    expect(plan.nextAfter(1), 2);
    expect(plan.nextAfter(2), isNull);
  });

  test('bỏ qua đoạn đã đánh dấu lỗi', () {
    final plan = MatchRecordingPlaybackPlan(segmentCount: 3)..markFailed(1);

    expect(plan.isFailed(1), isTrue);
    expect(plan.nextAfter(0), 2);
    expect(plan.allFailed, isFalse);
  });

  test('allFailed khi mọi đoạn đều lỗi', () {
    final plan = MatchRecordingPlaybackPlan(segmentCount: 2)
      ..markFailed(0)
      ..markFailed(1);

    expect(plan.allFailed, isTrue);
    expect(plan.nextAfter(-1), isNull);
  });

  test('danh sách rỗng: không có đoạn nào và không tính là allFailed', () {
    final plan = MatchRecordingPlaybackPlan(segmentCount: 0);

    expect(plan.nextAfter(-1), isNull);
    expect(plan.allFailed, isFalse);
  });

  test('chỉ số đánh dấu lỗi ngoài khoảng bị từ chối', () {
    final plan = MatchRecordingPlaybackPlan(segmentCount: 2);

    expect(() => plan.markFailed(2), throwsA(isA<RangeError>()));
    expect(() => plan.markFailed(-1), throwsA(isA<RangeError>()));
  });
}
