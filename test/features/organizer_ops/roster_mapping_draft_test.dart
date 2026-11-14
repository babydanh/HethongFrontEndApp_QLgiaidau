import 'package:app_quanly_giaidau/core/services/roster_excel_reader.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_layout.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_mapping_draft.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_pairing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixture_workbook.dart';
import 'roster_mapping_fixture.dart';

Future<RosterReading> _twoColumnReading() async {
  final grid = await workbookFrom([
    ['STT', 'Họ và tên VĐV 1', 'Họ và tên VĐV 2'],
    [1, fakeName(0), fakeName(1)],
    [2, fakeName(2), fakeName(3)],
  ]);
  return readSheetByRules(grid.single)!;
}

bool _allDoubles(String? _) => true;
bool _noDoubles(String? _) => false;

Future<RosterMappingDraft> _sampleDraft({
  bool Function(String?) doubles = _allDoubles,
}) async {
  final grid = await sampleUserLayoutGrid();
  return RosterMappingDraft.fromReading(
    readSheetByRules(grid.single)!,
    isDoublesFor: doubles,
  );
}

List<RosterParsedRow> _rowsOf(RosterMappingDraft draft) =>
    assembleRosterRows(draft.reading, _allDoubles);

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

  group('RosterMappingDraft', () {
    test('TC-ROSTERMAP-05 liệt kê cột của file mẫu với loại, ô ghép và giá trị mẫu', () async {
      final draft = await _sampleDraft();

      final columns = draft.columns;

      expect(columns, hasLength(9));
      expect(columns[0].header, 'STT');
      expect(columns[0].kind, RosterColumnKind.serial);
      expect(columns[0].sample, '1');
      expect(columns[1].slot, RosterSlot.player1Name);
      expect(columns[1].sample, fakeName(0));
      expect(columns[2].header, 'Đơn vị công tác');
      expect(columns[2].slot, isNull);
      expect(columns[2].kind, RosterColumnKind.normal);
      expect(columns[7].header, 'Ngày sinh');
      expect(columns[7].kind, RosterColumnKind.sensitive);
    });

    test('TC-ROSTERMAP-06 gán slot sang cột khác đưa cột cũ về ghi chú', () async {
      final draft = await _sampleDraft();

      final moved = draft.assign(2, RosterSlot.player1Name);

      expect(moved.columns[2].slot, RosterSlot.player1Name);
      expect(moved.columns[1].slot, isNull);
      final rows = _rowsOf(moved);
      expect(rows.first.player1Name, 'Công ty X');
      expect(
        rows.any((r) => (r.notes ?? '').contains('Họ và tên VĐV: ${fakeName(0)}')),
        isTrue,
      );
    });

    test('TC-ROSTERMAP-07 gán null gỡ cột khỏi slot', () async {
      final draft = await _sampleDraft();
      expect(draft.columns[4].slot, RosterSlot.player1Phone);

      final cleared = draft.assign(4, null);

      expect(cleared.columns[4].slot, isNull);
      expect(cleared.reading.mapping.indexOf(RosterSlot.player1Phone), isNull);
    });

    test('TC-ROSTERMAP-08 gán vào cột khóa không đổi gì', () async {
      final draft = await _sampleDraft();

      expect(draft.assign(0, RosterSlot.player1Name), same(draft));
      expect(draft.assign(7, RosterSlot.player1Email), same(draft));
    });

    test('TC-ROSTERMAP-09 gán tên VĐV 2 khi đang đánh đơn thì chọn cách ghép hai cột', () async {
      final draft = await _sampleDraft(doubles: _noDoubles);
      expect(draft.effectiveLayout, RosterPairLayout.single);

      final next = draft.assign(2, RosterSlot.player2Name);

      expect(next.reading.layout, RosterPairLayout.columns);
      expect(next.reading.layoutChosen, isTrue);
    });

    test('TC-ROSTERMAP-10 đổi hàng tiêu đề dò lại cột và cảnh báo tiêu đề gộp ngang', () async {
      final grid = await sampleUserLayoutGrid();
      final detected = readSheetByRules(grid.single)!;
      final onBanner = RosterMappingDraft.fromReading(
        detected.copyWith(headerRowIndex: 0, firstDataRowIndex: 1),
        isDoublesFor: _allDoubles,
      );
      expect(onBanner.headerMayBeShifted, isTrue);

      final fixed = onBanner.withHeaderRow(1);

      expect(fixed.reading.headerRowIndex, 1);
      expect(fixed.reading.firstDataRowIndex, 2);
      expect(fixed.reading.mapping.indexOf(RosterSlot.player1Name), 1);
      expect(fixed.headerMayBeShifted, isFalse);
    });

    test('TC-ROSTERMAP-11 hàng tiêu đề được kẹp vào khoảng hợp lệ', () async {
      final draft = await _sampleDraft();
      final lastRow = draft.reading.grid.rows.length - 1;

      expect(draft.withHeaderRow(-5).reading.headerRowIndex, 0);
      expect(draft.withHeaderRow(999).reading.headerRowIndex, lastRow - 1);
    });

    test('TC-ROSTERMAP-12 có nhận diện khi có đội, và ghép 2 dòng làm số dòng giảm một nửa', () async {
      final grid = await workbookFrom([
        ['STT', 'Ghi chú riêng'],
        [1, 'a'],
      ]);
      final bare = RosterMappingDraft.forSkippedSheet(
        grid.single,
        isDoublesFor: _allDoubles,
      );
      expect(bare.hasIdentity, isFalse);
      expect(bare.assign(1, RosterSlot.teamName).hasIdentity, isTrue);

      final singles = await workbookFrom([
        ['STT', 'Họ và tên', 'Số điện thoại'],
        for (var i = 0; i < 4; i++) [i + 1, fakeName(i), fakePhone(i)],
      ]);
      final base = RosterMappingDraft.fromReading(
        readSheetByRules(singles.single)!.copyWith(
          layout: RosterPairLayout.single,
          layoutChosen: true,
        ),
        isDoublesFor: _allDoubles,
      );
      expect(base.rowCount, 4);
      expect(base.withLayout(RosterPairLayout.consecutiveRows).rowCount, 2);
    });

    test('TC-ROSTERMAP-13 cột ngày sinh không bao giờ vào ghi chú', () async {
      var draft = await _sampleDraft();
      for (var column = 0; column < 9; column++) {
        for (final slot in [null, ...RosterSlot.values]) {
          draft = draft.assign(column, slot);
          for (final row in _rowsOf(draft)) {
            expect(row.notes ?? '', isNot(contains('01/01/1990')));
          }
        }
      }
    });

    test('TC-ROSTERMAP-14 sheet bị bỏ qua chọn dòng đầu có từ hai ô làm tiêu đề', () {
      const grid = RosterGridSheet(
        name: 'S',
        rows: [
          ['Banner'],
          ['a', 'b', 'c'],
          ['1', '2', '3'],
        ],
      );
      final draft = RosterMappingDraft.forSkippedSheet(
        grid,
        isDoublesFor: _allDoubles,
      );
      expect(draft.wasSkipped, isTrue);
      expect(draft.reading.headerRowIndex, 1);
      expect(draft.columns, hasLength(3));

      const tiny = RosterGridSheet(
        name: 'T',
        rows: [
          ['chỉ một dòng'],
        ],
      );
      expect(
        RosterMappingDraft.forSkippedSheet(tiny, isDoublesFor: _allDoubles)
            .columns,
        isEmpty,
      );
    });

    test('TC-ROSTERMAP-15 cột Địa chỉ email đã ghép Email thì không bị khóa', () async {
      final grid = await workbookFrom([
        ['STT', 'Họ và tên', 'Địa chỉ email'],
        [1, fakeName(0), 'a@example.com'],
      ]);
      final draft = RosterMappingDraft.fromReading(
        readSheetByRules(grid.single)!,
        isDoublesFor: _allDoubles,
      ).assign(2, RosterSlot.player1Email);

      expect(draft.columns[2].slot, RosterSlot.player1Email);
      expect(draft.columns[2].kind, RosterColumnKind.normal);
    });

    test('TC-ROSTERMAP-16 hai VĐV một ô tách theo ký tự ngăn đã chọn', () async {
      final grid = await workbookFrom([
        ['STT', 'Họ và tên'],
        [1, 'An & Bình'],
        [2, 'Cường & Dũng'],
      ]);
      final draft = RosterMappingDraft.fromReading(
        readSheetByRules(grid.single)!,
        isDoublesFor: _allDoubles,
      ).withLayout(RosterPairLayout.sameCell, separator: ' & ');

      final rows = _rowsOf(draft);

      expect(rows.map((r) => r.player1Name), ['An', 'Cường']);
      expect(rows.map((r) => r.player2Name), ['Bình', 'Dũng']);
    });
  });
}
