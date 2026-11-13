import 'package:app_quanly_giaidau/core/services/roster_excel_reader.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_layout.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_pairing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixture_workbook.dart';

/// Đường đọc đầy đủ như màn nhập: luật đọc từng sheet, rồi ghép cho nội dung đôi hoặc đơn.
List<RosterParsedRow> readRows(
  List<RosterGridSheet> grid, {
  bool doubles = true,
}) => [
  for (final sheet in grid)
    if (readSheetByRules(sheet) case final reading?)
      ...assembleRosterRows(reading, (_) => doubles),
];

List<List<FixtureCell>> _table(List<List<FixtureCell>> body) => [
  ['STT', 'Họ và tên VĐV', 'Số điện thoại liên hệ'],
  ...body,
];

void main() {
  group('TC-APP-ROSTER-PAIR-STT: STT gộp hoặc trùng ghép hai dòng liền nhau', () {
    test(
      'TC-APP-ROSTER-PAIR-STT-01 file mẫu cho 11 cặp và 7 VĐV lẻ, 0 người đã thanh toán',
      () async {
        final rows = readRows(await sampleWorkbook());

        expect(rows, hasLength(18));
        final pairs = rows.where((row) => row.player2Name != null).toList();
        final singles = rows.where((row) => row.player2Name == null).toList();
        expect(pairs, hasLength(11));
        expect(singles, hasLength(7));
        expect(rows.where((row) => row.isPaid), isEmpty);
        // Cặp 1: hai dòng 3 và 4, SĐT của từng người vào đúng cột.
        expect(pairs.first.player1Name, fakeName(0));
        expect(pairs.first.player2Name, fakeName(1));
        expect(pairs.first.player1Phone, fakePhone(0));
        expect(pairs.first.player2Phone, fakePhone(1));
        expect(pairs.first.sourceRowIndex, 3);
        // VĐV lẻ bắt đầu ở dòng 26, không dòng nào là tiêu đề hay dòng chỉ có STT.
        expect(singles.map((row) => row.sourceRowIndex), [
          26,
          27,
          28,
          29,
          30,
          31,
          32,
        ]);
        expect(singles.every((row) => row.singles), isTrue);
      },
    );

    test(
      'TC-APP-ROSTER-PAIR-STT-02 STT chỉ ghi ở dòng trên vẫn ghép thành cặp',
      () async {
        final grid = await workbookFrom(
          _table([
            [1, fakeName(0), fakePhone(0)],
            [null, fakeName(1), fakePhone(1)],
            [2, fakeName(2), fakePhone(2)],
            [null, fakeName(3), fakePhone(3)],
            [3, fakeName(4), fakePhone(4)],
            [null, fakeName(5), fakePhone(5)],
            [4, fakeName(6), fakePhone(6)],
          ]),
        );

        final rows = readRows(grid);

        expect(rows.where((r) => r.player2Name != null), hasLength(3));
        expect(rows.last.player1Name, fakeName(6));
        expect(rows.last.player2Name, isNull);
      },
    );

    test(
      'TC-APP-ROSTER-PAIR-STT-03 STT ghi ở cả hai dòng ghép thành cặp',
      () async {
        final grid = await workbookFrom(
          _table([
            [1, fakeName(0), ''],
            [1, fakeName(1), ''],
            [2, fakeName(2), ''],
            [2, fakeName(3), ''],
          ]),
        );

        final rows = readRows(grid);

        expect(rows.map((r) => [r.player1Name, r.player2Name]), [
          [fakeName(0), fakeName(1)],
          [fakeName(2), fakeName(3)],
        ]);
      },
    );

    test(
      'TC-APP-ROSTER-PAIR-STT-04 danh sách đánh số 1..n và STT trùng quá ít không ghép',
      () async {
        final numbered = readRows(
          await workbookFrom(
            _table([
              [1, fakeName(0), ''],
              [2, fakeName(1), ''],
              [3, fakeName(2), ''],
              [4, fakeName(3), ''],
            ]),
          ),
        );
        expect(numbered, hasLength(4));
        expect(numbered.every((r) => r.player2Name == null), isTrue);

        // Một cặp trùng trong năm dòng: 40% < 80%, nên không ghép.
        final sparse = readRows(
          await workbookFrom(
            _table([
              [1, fakeName(0), ''],
              [1, fakeName(1), ''],
              [2, fakeName(2), ''],
              [3, fakeName(3), ''],
              [4, fakeName(4), ''],
            ]),
          ),
        );
        expect(sparse, hasLength(5));
        expect(sparse.every((r) => r.player2Name == null), isTrue);
      },
    );

    test(
      'TC-APP-ROSTER-PAIR-STT-05 ô STT gộp được đọc từ file và điền xuống dòng dưới, tiêu đề gộp thì không',
      () async {
        final grid = await workbookFrom(
          [
            ['DANH SÁCH'],
            ['STT', 'Họ và tên VĐV', 'Số điện thoại liên hệ'],
            [1, fakeName(0), ''],
            [null, fakeName(1), ''],
          ],
          merges: ['A1:C1', 'A3:A4'],
        );

        expect(grid.single.mergedRegions, ['A3:A4']);
        final filled = fillRosterMerges(grid.single);
        expect(filled.rows[3][0], '1');
        expect(filled.rows[0].where((c) => c.isNotEmpty), ['DANH SÁCH']);
      },
    );

    test(
      'TC-APP-ROSTER-PAIR-STT-06 dòng chỉ có STT không thành VĐV và không làm hỏng các cặp quanh nó',
      () async {
        final rows = readRows(
          await workbookFrom(
            _table([
              [1, fakeName(0), ''],
              [null, fakeName(1), ''],
              [2, null, null],
              [3, null, null],
            ]),
          ),
        );

        expect(rows.map((r) => [r.player1Name, r.player2Name]), [
          [fakeName(0), fakeName(1)],
        ]);
      },
    );

    test(
      'TC-APP-ROSTER-PAIR-STT-07 mã cặp có cột riêng: ô mã trống kế thừa mã dòng trên (ô gộp)',
      () async {
        final grid = await workbookFrom([
          ['Mã cặp', 'Họ và tên VĐV'],
          [1, fakeName(0)],
          [null, fakeName(1)],
          ['Cặp 2', fakeName(2)],
          [null, fakeName(3)],
          [3, fakeName(4)],
        ]);

        final rows = readRows(grid);

        expect(rows.map((r) => [r.player1Name, r.player2Name]), [
          [fakeName(0), fakeName(1)],
          [fakeName(2), fakeName(3)],
          [fakeName(4), null],
        ]);
        expect(rows.last.pairCodeSize, 1);
      },
    );
  });

  group('TC-APP-ROSTER-SECTION-SINGLES: phần VĐV lẻ chờ ghép', () {
    test(
      'TC-APP-ROSTER-SECTION-SINGLES-01 STT đánh lại từ 1 sau tiêu đề phần không ghép với cặp phía trên',
      () async {
        final rows = readRows(
          await workbookFrom(
            _table([
              [1, fakeName(0), ''],
              [null, fakeName(1), ''],
              [2, fakeName(2), ''],
              [null, fakeName(3), ''],
              ['DANH SÁCH VĐV CHƯA CÓ CẶP', null, null],
              [1, fakeName(4), ''],
              [2, fakeName(5), ''],
              [3, fakeName(6), ''],
            ]),
          ),
        );

        expect(rows.map((r) => [r.player1Name, r.player2Name, r.singles]), [
          [fakeName(0), fakeName(1), false],
          [fakeName(2), fakeName(3), false],
          [fakeName(4), null, true],
          [fakeName(5), null, true],
          [fakeName(6), null, true],
        ]);
      },
    );

    test(
      'TC-APP-ROSTER-SECTION-SINGLES-02 các cụm tiêu đề phần được nhận, tên người thì không',
      () {
        for (final title in [
          'DANH SÁCH VĐV CHƯA CÓ CẶP',
          'Chưa có cặp',
          'VĐV chờ ghép',
          'Danh sách đánh lẻ',
          'Danh sách VĐV tự do',
          'chưa ghép cặp',
        ]) {
          expect(isSinglesSectionRow([title, '', '']), isTrue, reason: title);
        }
        expect(isSinglesSectionRow(['Tự Do Nguyễn', '', '']), isFalse);
        expect(isSinglesSectionRow(['1', fakeName(0), '0900000001']), isFalse);
        expect(isSinglesSectionRow(['Chưa có cặp', 'x', '']), isFalse);
      },
    );

    test(
      'TC-APP-ROSTER-SECTION-SINGLES-03 dòng AI chỉ ra (singlesFromRow) đánh dấu VĐV lẻ từ dòng đó',
      () async {
        final grid = await workbookFrom(
          _table([
            [1, fakeName(0), ''],
            [null, fakeName(1), ''],
            [3, fakeName(2), ''],
            [3, fakeName(3), ''],
          ]),
        );
        final sheet = grid.single;

        final rows = parseRosterSheet(
          sheet,
          headerRowIndex: 0,
          mapping: detectRosterColumnMapping(sheet.rows[0]),
          singlesFromRow: 4,
        );

        expect(rows.map((r) => r.singles), [false, false, true, true]);
      },
    );
  });

  group('TC-APP-ROSTER-PAID-DEFAULT: thanh toán theo file, không có thì chưa', () {
    test(
      'TC-APP-ROSTER-PAID-DEFAULT-01 giá trị đã trả nhận không phân biệt hoa thường và dấu',
      () {
        for (final value in [
          'x',
          'X',
          '✓',
          '✔',
          'v',
          'ok',
          'OK',
          'có',
          'Có',
          'đã',
          'đã đóng',
          'Đã ck',
          'đã chuyển khoản',
          'Đã thanh toán',
          'paid',
          'yes',
          '1',
          'true',
          '500000',
          '500.000đ',
          '300k',
        ]) {
          expect(parseRosterPaid(value), isTrue, reason: value);
        }
      },
    );

    test(
      'TC-APP-ROSTER-PAID-DEFAULT-02 chưa, không, no, 0, trống và chữ lạ là chưa trả',
      () {
        for (final value in [
          'chưa',
          'Chưa',
          'không',
          'no',
          '0',
          '',
          '  ',
          'đang chờ',
          'false',
        ]) {
          expect(parseRosterPaid(value), isFalse, reason: value);
        }
      },
    );

    test(
      'TC-APP-ROSTER-PAID-DEFAULT-03 cột Xác nhận BTC đọc theo từng dòng, thiếu cột thì chưa ai trả',
      () async {
        final withColumn = readRows(
          await workbookFrom([
            ['Họ và tên VĐV', 'Xác nhận BTC'],
            [fakeName(0), 'x'],
            [fakeName(1), 'đã ck'],
            [fakeName(2), ''],
            [fakeName(3), 'Chưa'],
            [fakeName(4), '500.000'],
            [fakeName(5), 'đang chờ'],
          ]),
          doubles: false,
        );
        expect(withColumn.map((r) => r.isPaid), [
          true,
          true,
          false,
          false,
          true,
          false,
        ]);

        final withoutColumn = readRows(
          await workbookFrom([
            ['Họ và tên VĐV', 'Ghi chú'],
            [fakeName(0), 'ghi chú'],
          ]),
          doubles: false,
        );
        expect(withoutColumn.single.isPaid, isFalse);
      },
    );

    test(
      'TC-APP-ROSTER-PAID-DEFAULT-04 ô thanh toán gộp theo cặp áp cho cả hai VĐV',
      () async {
        final grid = await workbookFrom(
          [
            ['STT', 'Họ và tên VĐV', 'Xác nhận BTC'],
            [1, fakeName(0), 'x'],
            [null, fakeName(1), null],
            [2, fakeName(2), null],
            [null, fakeName(3), null],
            [3, fakeName(4), 'đã ck'],
            [null, fakeName(5), null],
          ],
          merges: ['A2:A3', 'C2:C3', 'A4:A5', 'C4:C5', 'A6:A7', 'C6:C7'],
        );

        final rows = readRows(grid);

        expect(rows.map((r) => r.isPaid), [true, false, true]);
        expect(rows.map((r) => r.player2Name != null), [true, true, true]);
      },
    );

    test(
      'TC-APP-ROSTER-PAID-DEFAULT-05 alias cột thanh toán, SĐT liên hệ và trình điểm',
      () {
        for (final header in [
          'Xác nhận BTC',
          'Xác nhận',
          'BTC xác nhận',
          'Đóng phí',
          'Đã đóng',
          'Chuyển khoản',
          'CK',
          'Thanh toán',
          'Lệ phí',
          'Phí',
          'Paid',
          'Payment',
        ]) {
          final mapping = detectRosterColumnMapping(['Họ và tên VĐV', header]);
          expect(mapping.indexOf(RosterSlot.isPaid), 1, reason: header);
        }
        expect(
          detectRosterColumnMapping([
            'Họ và tên VĐV',
            'Chưa đóng lệ phí',
          ]).indexOf(RosterSlot.isPaid),
          isNull,
        );
        final mapping = detectRosterColumnMapping([
          'STT',
          'Họ và tên VĐV',
          'Số điện thoại liên hệ',
          scoreHeader,
        ]);
        expect(mapping.indexOf(RosterSlot.player1Phone), 2);
        expect(mapping.indexOf(RosterSlot.elo), 3);
        for (final header in [
          'Trình điểm',
          'Trình độ',
          'Điểm trình',
          'Trình',
        ]) {
          expect(
            detectRosterColumnMapping([
              'Họ tên',
              header,
            ]).indexOf(RosterSlot.elo),
            1,
            reason: header,
          );
        }
        expect(
          detectRosterColumnMapping([
            'Họ tên',
            'Chương trình',
          ]).indexOf(RosterSlot.elo),
          isNull,
        );
      },
    );

    test(
      'TC-APP-ROSTER-PAID-DEFAULT-06 điểm lấy số đầu tiên: 100-999 là ELO, 2-8 là DUPR, chữ khác để ghi chú',
      () {
        expect(parseRosterScore('620')?.value, 620);
        expect(parseRosterScore('620 Robinson , 625-630 CCTV')?.value, 620);
        expect(parseRosterScore('tầm 605 CCTV')?.value, 605);
        expect(parseRosterScore('600 - CCTV Tân Phú')?.source, 'ELO');
        expect(parseRosterScore('3,25 DUPR')?.value, 3.25);
        expect(parseRosterScore('3.5')?.source, 'DUPR');
        expect(parseRosterScore('1.250')?.value, 1250);
        for (final text in ['', 'chưa rõ', '1', '9.5', '5000']) {
          expect(parseRosterScore(text), isNull, reason: text);
        }
      },
    );

    test(
      'TC-APP-ROSTER-PAID-DEFAULT-07 điểm không đọc được hoặc có thêm chữ vẫn nằm trong ghi chú',
      () async {
        final rows = readRows(
          await workbookFrom([
            ['Họ và tên VĐV', 'Trình độ'],
            [fakeName(0), '620 Robinson'],
            [fakeName(1), 'chưa rõ'],
            [fakeName(2), '605'],
          ]),
          doubles: false,
        );

        expect(rows[0].elo, 620);
        expect(rows[0].notes, 'Trình độ: 620 Robinson');
        expect(rows[1].elo, isNull);
        expect(rows[1].notes, 'Trình độ: chưa rõ');
        expect(rows[2].elo, 605);
        expect(rows[2].notes, isNull);
      },
    );
  });

  group('TC-APP-ROSTER-PARTNER-HINT: cột đồng đội chỉ là gợi ý', () {
    const hint = 'VDV đăng ký đứng chung';
    List<List<FixtureCell>> table(List<List<FixtureCell>> body) => [
      ['STT', 'Họ và tên VĐV', hint],
      ...body,
    ];

    test(
      'TC-APP-ROSTER-PARTNER-HINT-01 cột gợi ý không phải VĐV 2 và không thành ghi chú',
      () async {
        final grid = await workbookFrom(
          table([
            [1, fakeName(0), 'Bình tsc'],
            [2, fakeName(1), 'An béo'],
          ]),
        );
        final reading = readSheetByRules(grid.single)!;

        expect(reading.mapping.indexOf(RosterSlot.player2Name), isNull);
        expect(findPartnerHintColumn(reading.headers, reading.mapping), 2);
        final rows = readRows(grid, doubles: false);
        expect(
          rows.every((r) => !(r.notes ?? '').contains('đứng chung')),
          isTrue,
        );
      },
    );

    test(
      'TC-APP-ROSTER-PARTNER-HINT-02 dòng chưa có tín hiệu STT ghép khi gợi ý khớp tên mờ',
      () async {
        final rows = readRows(
          await workbookFrom(
            table([
              [null, fakeName(0), 'Bình tsc'],
              [null, fakeName(1), ''],
              [null, fakeName(2), ''],
              [null, fakeName(3), ''],
            ]),
          ),
        );

        expect(rows.map((r) => [r.player1Name, r.player2Name]), [
          [fakeName(0), fakeName(1)],
          [fakeName(2), null],
          [fakeName(3), null],
        ]);
      },
    );

    test(
      'TC-APP-ROSTER-PARTNER-HINT-03 gợi ý không đè cặp theo STT và không tạo VĐV từ biệt danh',
      () async {
        final rows = readRows(
          await workbookFrom(
            table([
              [1, fakeName(0), 'Dũng cơ'],
              [null, fakeName(1), ''],
              [2, fakeName(2), ''],
              [null, fakeName(3), ''],
            ]),
          ),
        );

        expect(rows.map((r) => [r.player1Name, r.player2Name]), [
          [fakeName(0), fakeName(1)],
          [fakeName(2), fakeName(3)],
        ]);
      },
    );

    test(
      'TC-APP-ROSTER-PARTNER-HINT-04 chưa, chưa có, 2 người và trống là không có gợi ý',
      () async {
        final rows = readRows(
          await workbookFrom(
            table([
              [null, fakeName(0), 'Chưa'],
              [null, fakeName(1), 'Chưa có'],
              [null, fakeName(2), '2 người'],
              [null, fakeName(3), ''],
            ]),
          ),
        );

        expect(rows, hasLength(4));
        expect(rows.every((r) => r.player2Name == null), isTrue);
      },
    );

    test(
      'TC-APP-ROSTER-PARTNER-HINT-05 gợi ý nêu hai dòng thì bỏ, dòng phần lẻ không ghép theo gợi ý',
      () async {
        final ambiguous = readRows(
          await workbookFrom(
            table([
              [null, fakeName(0), 'Minh'],
              [null, fakeName(8), ''],
              [null, 'Lê Văn Minh', ''],
            ]),
          ),
        );
        expect(ambiguous.every((r) => r.player2Name == null), isTrue);

        final section = readRows(
          await workbookFrom(
            table([
              [1, fakeName(0), ''],
              [null, fakeName(1), ''],
              ['DANH SÁCH VĐV CHƯA CÓ CẶP', null, null],
              [1, fakeName(4), 'Hà'],
              [2, fakeName(5), 'Giang'],
            ]),
          ),
        );
        expect(section.map((r) => [r.player1Name, r.player2Name]), [
          [fakeName(0), fakeName(1)],
          [fakeName(4), null],
          [fakeName(5), null],
        ]);
      },
    );

    test(
      'TC-APP-ROSTER-PARTNER-HINT-06 cột Partner toàn tên đầy đủ vẫn là VĐV 2, toàn biệt danh thì thành gợi ý',
      () {
        const headers = ['Họ và tên VĐV', 'Partner'];
        final full = confirmRosterColumns(
          [
            [fakeName(0), 'Lê Thị Hoa'],
            [fakeName(2), 'Phạm Văn Long'],
          ],
          headers,
          detectRosterColumnMapping(headers),
        );
        expect(full.indexOf(RosterSlot.player2Name), 1);

        final nick = confirmRosterColumns(
          [
            [fakeName(0), 'Cường tsc'],
            [fakeName(2), 'An béo'],
          ],
          headers,
          detectRosterColumnMapping(headers),
        );
        expect(nick.indexOf(RosterSlot.player2Name), isNull);
        expect(findPartnerHintColumn(headers, nick), 1);
      },
    );
  });
}
