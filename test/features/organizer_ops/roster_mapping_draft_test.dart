import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_layout.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_mapping_draft.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_pairing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixture_workbook.dart';
import 'roster_mapping_fixture.dart';

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

  group('RosterMappingDraft', () {
    bool doubles(String? _) => true;

    Future<RosterMappingDraft> sampleDraft() async {
      final sheets = await sampleUserLayoutGrid();
      return RosterMappingDraft.fromReading(
        readSheetByRules(sheets.single)!,
        isDoublesFor: doubles,
      );
    }

    String allNotes(RosterMappingDraft draft) => assembleRosterRows(
      draft.reading,
      doubles,
    ).map((row) => row.notes ?? '').join('|');

    test(
      'TC-ROSTERMAP-05 liệt kê cột của file mẫu với loại, slot và ô mẫu',
      () async {
        final draft = await sampleDraft();
        final columns = draft.columns;

        expect(columns, hasLength(9));
        expect(columns[0].kind, RosterColumnKind.serial);
        expect(columns[7].kind, RosterColumnKind.sensitive);
        expect(columns[2].slot, isNull);
        expect(columns[2].kind, RosterColumnKind.normal);
        expect(columns[1].slot, RosterSlot.player1Name);
        expect(columns[1].header, 'Họ và tên VĐV');
        expect(columns[1].sample, fakeName(0));
      },
    );

    test(
      'TC-ROSTERMAP-06 chuyển slot sang cột khác thì cột cũ vào ghi chú',
      () async {
        final draft = (await sampleDraft()).assign(5, RosterSlot.player1Phone);

        expect(draft.columns[5].slot, RosterSlot.player1Phone);
        expect(draft.columns[4].slot, isNull);
        expect(allNotes(draft), contains('Số điện thoại: ${fakePhone(0)}'));
      },
    );

    test('TC-ROSTERMAP-07 gán null gỡ slot khỏi cột', () async {
      final draft = (await sampleDraft()).assign(4, null);

      expect(draft.columns[4].slot, isNull);
      expect(draft.reading.mapping.indexOf(RosterSlot.player1Phone), isNull);
    });

    test('TC-ROSTERMAP-08 cột khóa không đổi khi gán slot', () async {
      final before = await sampleDraft();
      final after = before
          .assign(0, RosterSlot.player1Name)
          .assign(7, RosterSlot.player1Email);

      expect(after.reading.mapping.columns, before.reading.mapping.columns);
    });

    test(
      'TC-ROSTERMAP-09 gán VĐV 2 khi đánh đơn chuyển sang hai cột',
      () async {
        final draft = await sampleDraft();
        expect(draft.effectiveLayout, RosterPairLayout.single);

        final assigned = draft.assign(2, RosterSlot.player2Name);

        expect(assigned.effectiveLayout, RosterPairLayout.columns);
        expect(assigned.reading.layoutChosen, isTrue);
      },
    );

    test(
      'TC-ROSTERMAP-10 đổi hàng tiêu đề dò lại cột và cảnh báo banner gộp',
      () async {
        final sheets = await sampleUserLayoutGrid();
        final reading = readSheetByRules(sheets.single)!;
        final banner = RosterMappingDraft.fromReading(
          reading.copyWith(
            headerRowIndex: 0,
            firstDataRowIndex: 1,
            mapping: detectRosterColumnMapping(reading.grid.rows[0]),
          ),
          isDoublesFor: doubles,
        );
        expect(banner.headerMayBeShifted, isTrue);

        final fixed = banner.withHeaderRow(1);

        expect(fixed.headerMayBeShifted, isFalse);
        expect(fixed.reading.firstDataRowIndex, 2);
        expect(fixed.reading.mapping.indexOf(RosterSlot.player1Name), 1);
      },
    );

    test('TC-ROSTERMAP-11 hàng tiêu đề ngoài khoảng được kẹp lại', () async {
      final draft = await sampleDraft();
      final rows = draft.reading.grid.rows.length;

      expect(draft.withHeaderRow(-5).reading.headerRowIndex, 0);
      expect(draft.withHeaderRow(999).reading.headerRowIndex, rows - 2);
    });

    test('TC-ROSTERMAP-12 nhận diện và số dòng theo cách ghép', () async {
      final sheets = await workbookFrom([
        ['STT', 'Họ và tên'],
        [1, fakeName(0)],
        [2, fakeName(1)],
        [3, fakeName(2)],
        [4, fakeName(3)],
      ]);
      final draft = RosterMappingDraft.fromReading(
        readSheetByRules(sheets.single)!,
        isDoublesFor: doubles,
      );
      expect(draft.hasIdentity, isTrue);
      expect(draft.rowCount, 4);
      expect(draft.withLayout(RosterPairLayout.consecutiveRows).rowCount, 2);

      final none = draft.assign(1, null);
      expect(none.hasIdentity, isFalse);
      expect(none.assign(1, RosterSlot.teamName).hasIdentity, isTrue);
    });

    test('TC-ROSTERMAP-13 ngày sinh không bao giờ vào ghi chú', () async {
      var draft = await sampleDraft();
      for (var column = 0; column < 9; column++) {
        draft = draft.assign(column, null);
      }
      draft = draft.assign(7, RosterSlot.notes).assign(2, RosterSlot.notes);

      expect(allNotes(draft), isNot(contains('01/01/1990')));
    });

    test('TC-ROSTERMAP-14 sheet bị bỏ qua chọn dòng đầu có từ hai ô', () async {
      final sheets = await workbookFrom([
        ['Banner'],
        [],
        ['A', 'B'],
        ['x', 'y'],
      ]);
      final draft = RosterMappingDraft.forSkippedSheet(
        sheets.single,
        isDoublesFor: doubles,
      );
      expect(draft.wasSkipped, isTrue);
      expect(draft.reading.headerRowIndex, 2);
      expect(draft.columns.map((c) => c.header), ['A', 'B']);

      final tiny = await workbookFrom([
        ['Banner'],
      ]);
      expect(
        RosterMappingDraft.forSkippedSheet(
          tiny.single,
          isDoublesFor: doubles,
        ).columns,
        isEmpty,
      );
    });

    test('TC-ROSTERMAP-15 Địa chỉ email đã ghép Email không bị khóa', () async {
      final sheets = await workbookFrom([
        ['Họ và tên', 'Địa chỉ email', 'Địa chỉ'],
        [fakeName(0), 'a@example.com', 'Số 1'],
      ]);
      final draft = RosterMappingDraft.fromReading(
        readSheetByRules(sheets.single)!,
        isDoublesFor: doubles,
      );

      expect(draft.columns[1].slot, RosterSlot.player1Email);
      expect(draft.columns[1].kind, RosterColumnKind.normal);
      expect(draft.columns[2].kind, RosterColumnKind.sensitive);
    });

    test('TC-ROSTERMAP-16 hai VĐV một ô tách theo ký tự đã chọn', () async {
      final sheets = await workbookFrom([
        ['STT', 'Họ và tên'],
        [1, '${fakeName(0)} & ${fakeName(1)}'],
      ]);
      final draft = RosterMappingDraft.fromReading(
        readSheetByRules(sheets.single)!,
        isDoublesFor: doubles,
      ).withLayout(RosterPairLayout.sameCell, separator: ' & ');

      final row = assembleRosterRows(draft.reading, doubles).single;
      expect(row.player1Name, fakeName(0));
      expect(row.player2Name, fakeName(1));
    });
  });
}
