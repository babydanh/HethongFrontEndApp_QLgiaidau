import 'package:flutter_test/flutter_test.dart';

import 'package:app_quanly_giaidau/features/tournament/widgets/court_schedule_board.dart';

void main() {
  test('schedule date keys are local calendar dates', () {
    expect(scheduleDateKey(DateTime(2026, 9, 20, 23, 59)), '2026-09-20');
    expect(scheduleDateKey(DateTime(2026, 1, 3)), '2026-01-03');
  });

  test('schedule time labels use the web 24-hour format', () {
    expect(scheduleTimeLabel(8 * 60), '08:00');
    expect(scheduleTimeLabel(17 * 60 + 5), '17:05');
  });
}
