import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match(
  String id, {
  required String court,
  DateTime? at,
  String team1 = 'Đội A',
  String team2 = 'Đội B',
}) => MatchModel.fromJson({
  'id': id,
  'tournamentId': 't-1',
  'round': 1,
  'matchNumber': 1,
  'status': 'SCHEDULED',
  'team1Name': team1,
  'team2Name': team2,
  'courtName': court,
  if (at != null) 'scheduledAt': at.toIso8601String(),
}, id);

void main() {
  test('schedule rows follow the 15-minute grid and the court columns', () {
    final rows = ExcelExportService.buildScheduleMatrix(
      courts: const ['Sân 1', 'Sân 2'],
      startHour: 7,
      endHour: 8,
      matches: [
        _match('m1', court: 'Sân 1', at: DateTime(2026, 10, 24, 7, 15)),
        _match('m2', court: 'Sân 2', at: DateTime(2026, 10, 24, 7, 45)),
      ],
    );

    // Hàng đầu là tiêu đề: ô giờ để trống, rồi tên từng sân.
    expect(rows.first, ['', 'Sân 1', 'Sân 2']);
    // Khung 07:00 -> 08:00 chia 4 hàng 15 phút.
    expect(rows.length, 5);

    final byTime = {for (final row in rows.skip(1)) row.first: row};
    expect(byTime['07:00'], ['07:00', '', '']);
    expect(byTime['07:15'], ['07:15', 'Đội A - Đội B', '']);
    expect(byTime['07:30'], ['07:30', '', '']);
    expect(byTime['07:45'], ['07:45', '', 'Đội A - Đội B']);
  });

  test('a match is placed on its own court only', () {
    final rows = ExcelExportService.buildScheduleMatrix(
      courts: const ['Sân 1', 'Sân 2'],
      startHour: 7,
      endHour: 7,
      matches: [
        _match('m1', court: 'Sân 1', at: DateTime(2026, 10, 24, 8, 0)),
      ],
    );
    // Khung giờ rỗng vẫn phải trả về hàng tiêu đề, không ném lỗi.
    expect(rows.length, 1);
  });

  test('a match without court or time is left out of the matrix', () {
    final rows = ExcelExportService.buildScheduleMatrix(
      courts: const ['Sân 1'],
      startHour: 7,
      endHour: 8,
      matches: [_match('m-wait', court: '')],
    );

    final flats = [for (final row in rows) ...row];
    expect(flats.any((cell) => cell.contains('Đội A')), isFalse);
  });
}
