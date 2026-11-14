import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_layout.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_pairing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixture_workbook.dart';

Future<RosterReading> _doublesReading() async {
  final sheets = await workbookFrom([
    ['STT', 'Họ và tên VĐV 1', 'Họ và tên VĐV 2'],
    [1, fakeName(0), fakeName(1)],
    [2, fakeName(2), fakeName(3)],
  ]);
  return readSheetByRules(sheets.single)!;
}

void main() {
  group('RosterReading.layoutChosen', () {
    test(
      'TC-ROSTERMAP-04 chưa chọn cách ghép thì luật suy VĐV 2, đã chọn đánh đơn thì không',
      () async {
        final reading = await _doublesReading();

        final inferred = assembleRosterRows(reading, (_) => true);
        final chosenSingle = assembleRosterRows(
          reading.copyWith(layout: RosterPairLayout.single, layoutChosen: true),
          (_) => true,
        );

        expect(inferred.first.player2Name, fakeName(1));
        expect(chosenSingle.first.player2Name, isNull);
        expect(chosenSingle, hasLength(2));
      },
    );
  });
}
