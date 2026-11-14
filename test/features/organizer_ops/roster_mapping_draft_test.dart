import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_layout.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_pairing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixture_workbook.dart';

Future<RosterReading> _twoColumnReading() async {
  final grid = await workbookFrom([
    ['STT', 'Họ và tên VĐV 1', 'Họ và tên VĐV 2'],
    [1, fakeName(0), fakeName(1)],
    [2, fakeName(2), fakeName(3)],
  ]);
  return readSheetByRules(grid.single)!;
}

void main() {
  group('RosterReading.layoutChosen', () {
    test(
      'TC-ROSTERMAP-04 chưa chọn thì luật suy ra VĐV 2, đã chọn đánh đơn thì không có VĐV 2',
      () async {
        final reading = await _twoColumnReading();
        expect(reading.layoutChosen, isFalse);

        final inferred = assembleRosterRows(reading, (_) => true);
        expect(inferred.map((r) => r.player2Name), [
          fakeName(1),
          fakeName(3),
        ]);

        final chosen = reading.copyWith(
          layout: RosterPairLayout.single,
          layoutChosen: true,
        );
        final rows = assembleRosterRows(chosen, (_) => true);
        expect(rows, hasLength(2));
        expect(rows.every((r) => r.player2Name == null), isTrue);
      },
    );

    test('copyWith giữ nguyên các field không nêu tên', () async {
      final reading = await _twoColumnReading();

      final copy = reading.copyWith(separator: ' & ');

      expect(copy.separator, ' & ');
      expect(copy.grid, same(reading.grid));
      expect(copy.mapping, same(reading.mapping));
      expect(copy.headerRowIndex, reading.headerRowIndex);
      expect(copy.layoutChosen, reading.layoutChosen);
    });
  });
}
