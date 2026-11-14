import 'dart:typed_data';

import 'package:excel/excel.dart';

import 'roster_fixture_workbook.dart';

/// Một file Excel giả (tên, email, SĐT bịa) cùng kết quả mong đợi sau khi đọc.
class RosterCorpusCase {
  const RosterCorpusCase({
    required this.id,
    required this.title,
    required this.sheets,
    this.doubles = false,
    this.expectedRows,
    this.expectedPairs,
    this.expectedErrors = const {},
    this.expectNoReading = false,
  });

  /// Mã ca, dùng trong tên test và tên file khi dùng cho E2E.
  final String id;
  final String title;
  final List<RosterCorpusSheet> sheets;

  /// Nội dung đôi: luật ghép cặp được bật.
  final bool doubles;

  /// Số dòng sau khi đọc (VĐV lẻ hoặc cặp); null nghĩa là không kiểm.
  final int? expectedRows;

  /// Số dòng có VĐV 2; null nghĩa là không kiểm.
  final int? expectedPairs;

  /// Số dòng mang từng mã lỗi cục bộ; mã không liệt kê thì không kiểm.
  final Map<String, int> expectedErrors;

  /// Không sheet nào có tiêu đề đọc được, màn nhập phải báo bỏ qua.
  final bool expectNoReading;

  Uint8List get bytes => rosterCorpusBytes(sheets);
}

class RosterCorpusSheet {
  const RosterCorpusSheet(this.name, this.rows, {this.merges = const []});

  final String name;
  final List<List<FixtureCell>> rows;
  final List<String> merges;
}

/// Bytes của workbook nhiều sheet, đúng đường encode của gói `excel`.
Uint8List rosterCorpusBytes(List<RosterCorpusSheet> sheets) {
  final excel = Excel.createExcel();
  final defaultName = excel.getDefaultSheet()!;
  for (var i = 0; i < sheets.length; i++) {
    final spec = sheets[i];
    if (i == 0) {
      excel.rename(defaultName, spec.name);
    }
    final sheet = excel[spec.name];
    for (var r = 0; r < spec.rows.length; r++) {
      for (var c = 0; c < spec.rows[r].length; c++) {
        final value = spec.rows[r][c];
        if (value == null || value == '') continue;
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
          value is int ? IntCellValue(value) : TextCellValue(value.toString()),
        );
      }
    }
    for (final merge in spec.merges) {
      final parts = merge.split(':');
      sheet.merge(
        CellIndex.indexByString(parts[0]),
        CellIndex.indexByString(parts[1]),
      );
    }
  }
  return Uint8List.fromList(excel.encode()!);
}

String corpusName(int i) => 'Mẫu Văn N${i.toString().padLeft(3, '0')}';
String corpusEmail(int i) => 'corpus.vdv$i@example.com';
String corpusPhone(int i) => '0900${(100000 + i).toString()}';

List<List<FixtureCell>> _singles(
  int count, {
  List<String> headers = const [
    'STT',
    'Họ và tên',
    'Email',
    'Số điện thoại',
    'Đã đóng phí',
  ],
  int from = 1,
}) => [
  headers,
  for (var i = from; i < from + count; i++)
    [i, corpusName(i), corpusEmail(i), corpusPhone(i), i.isEven ? 'x' : ''],
];

/// Bộ file giả phủ các cách người tổ chức hay làm Excel: đơn, đôi hai cột, đôi hai dòng, tiêu đề lệch
/// dòng, ô gộp, nhiều sheet, cột nhạy cảm, email hỏng, file rỗng và các mốc 500/501 dòng.
List<RosterCorpusCase> rosterCorpus() => [
  RosterCorpusCase(
    id: 'single-basic',
    title: 'Đơn: STT, tên, email, SĐT, phí',
    sheets: [RosterCorpusSheet('Đơn Nam', _singles(5))],
    expectedRows: 5,
    expectedPairs: 0,
    expectedErrors: const {'MISSING_EMAIL': 0, 'INVALID_EMAIL': 0},
  ),
  RosterCorpusCase(
    id: 'single-header-aliases',
    title: 'Đơn: tiêu đề kiểu khác (Tên VĐV, Email, SĐT, Ghi chú)',
    sheets: [
      RosterCorpusSheet(
        'Đơn Nữ',
        _singles(
          4,
          headers: const ['TT', 'Tên VĐV', 'Email', 'SĐT', 'Ghi chú'],
        ),
      ),
    ],
    expectedRows: 4,
    expectedPairs: 0,
    expectedErrors: const {'MISSING_EMAIL': 0},
  ),
  // Bảng tên cột của app giống Web: `Mail` trơ trọi không được nhận ra là email. Ca này ghi lại hành vi
  // đó; người dùng sửa bằng popup Ghép cột (E2E chọn cột tay).
  RosterCorpusCase(
    id: 'single-header-mail-only',
    title: 'Đơn: cột email tên "Mail" (luật không tự nhận, cần Ghép cột)',
    sheets: [
      RosterCorpusSheet(
        'Đơn Nữ',
        _singles(4, headers: const ['TT', 'Tên VĐV', 'Mail', 'SĐT', 'Ghi chú']),
      ),
    ],
    expectedRows: 4,
    expectedPairs: 0,
    expectedErrors: const {'MISSING_EMAIL': 4},
  ),
  RosterCorpusCase(
    id: 'single-no-email',
    title: 'Đơn: file không có cột email',
    sheets: [
      RosterCorpusSheet('Đơn', [
        ['STT', 'Họ và tên', 'Số điện thoại'],
        for (var i = 1; i <= 3; i++) [i, corpusName(i), corpusPhone(i)],
      ]),
    ],
    expectedRows: 3,
    expectedErrors: const {'MISSING_EMAIL': 3},
  ),
  RosterCorpusCase(
    id: 'single-invalid-email',
    title: 'Đơn: email thiếu @, trống và hợp lệ lẫn lộn',
    sheets: [
      RosterCorpusSheet('Đơn', [
        ['STT', 'Họ và tên', 'Email'],
        [1, corpusName(1), 'khong-co-a-cong.com'],
        [2, corpusName(2), ''],
        [3, corpusName(3), corpusEmail(3)],
        [4, corpusName(4), 'co khoang@trang.com'],
      ]),
    ],
    expectedRows: 4,
    expectedErrors: const {'INVALID_EMAIL': 2, 'MISSING_EMAIL': 1},
  ),
  RosterCorpusCase(
    id: 'single-banner-header-row3',
    title: 'Đơn: banner gộp ngang, tiêu đề ở dòng 3',
    sheets: [
      RosterCorpusSheet(
        'Đơn',
        [
          ['DANH SÁCH THI ĐẤU'],
          [],
          ..._singles(4),
        ],
        merges: const ['A1:E1'],
      ),
    ],
    expectedRows: 4,
    expectedErrors: const {'MISSING_EMAIL': 0},
  ),
  RosterCorpusCase(
    id: 'single-blank-lines',
    title: 'Đơn: dòng trống xen kẽ và cuối file',
    sheets: [
      RosterCorpusSheet('Đơn', [
        ['STT', 'Họ và tên', 'Email'],
        [1, corpusName(1), corpusEmail(1)],
        [],
        [2, corpusName(2), corpusEmail(2)],
        [null, null, null],
        [3, corpusName(3), corpusEmail(3)],
        [],
        [],
      ]),
    ],
    expectedRows: 3,
    expectedErrors: const {'MISSING_EMAIL': 0},
  ),
  RosterCorpusCase(
    id: 'single-sensitive-columns',
    title: 'Đơn: có CCCD, ngày sinh, địa chỉ (không được giữ)',
    sheets: [
      RosterCorpusSheet('Đơn', [
        ['STT', 'Họ và tên', 'Email', 'CCCD', 'Ngày sinh', 'Địa chỉ'],
        [1, corpusName(1), corpusEmail(1), '079000000001', '01/01/1990', 'Q1'],
        [2, corpusName(2), corpusEmail(2), '079000000002', '02/02/1991', 'Q2'],
      ]),
    ],
    expectedRows: 2,
    expectedErrors: const {'MISSING_EMAIL': 0},
  ),
  RosterCorpusCase(
    id: 'doubles-two-columns',
    title: 'Đôi: hai cột VĐV 1 và VĐV 2 cùng một dòng',
    doubles: true,
    sheets: [
      RosterCorpusSheet('Đôi Nam', [
        ['STT', 'VĐV 1', 'Email VĐV 1', 'VĐV 2', 'Email VĐV 2'],
        for (var i = 1; i <= 3; i++)
          [
            i,
            corpusName(i * 2),
            corpusEmail(i * 2),
            corpusName(i * 2 + 1),
            corpusEmail(i * 2 + 1),
          ],
      ]),
    ],
    expectedRows: 3,
    expectedPairs: 3,
    expectedErrors: const {'MISSING_EMAIL': 0},
  ),
  RosterCorpusCase(
    id: 'doubles-two-rows-merged-stt',
    title: 'Đôi: mỗi cặp hai dòng, STT gộp dọc',
    doubles: true,
    sheets: [
      RosterCorpusSheet(
        'Đôi Nam Nữ',
        [
          ['STT', 'Họ và tên', 'Email', 'Xác nhận'],
          for (var p = 0; p < 4; p++) ...[
            [p + 1, corpusName(p * 2), corpusEmail(p * 2), p.isEven ? 'x' : ''],
            [null, corpusName(p * 2 + 1), corpusEmail(p * 2 + 1), null],
          ],
        ],
        merges: const ['A2:A3', 'A4:A5', 'A6:A7', 'A8:A9', 'D2:D3', 'D4:D5'],
      ),
    ],
    expectedRows: 4,
    expectedPairs: 4,
    expectedErrors: const {'MISSING_EMAIL': 0},
  ),
  RosterCorpusCase(
    id: 'doubles-partner-hint',
    title: 'Đôi: cột gợi ý đồng đội chỉ là manh mối, không thành VĐV 2',
    doubles: true,
    sheets: [
      RosterCorpusSheet('Đôi', [
        ['STT', 'Họ và tên', 'Email', 'VĐV đăng ký đứng chung'],
        [1, corpusName(1), corpusEmail(1), 'Anh Bình'],
        [2, corpusName(2), corpusEmail(2), 'Chưa có'],
        [3, corpusName(3), corpusEmail(3), ''],
      ]),
    ],
    expectedRows: 3,
    expectedPairs: 0,
  ),
  RosterCorpusCase(
    id: 'multi-sheet',
    title: 'Hai sheet: Đơn Nam và Đơn Nữ',
    sheets: [
      RosterCorpusSheet('Đơn Nam', _singles(3)),
      RosterCorpusSheet('Đơn Nữ', _singles(2, from: 10)),
    ],
    expectedRows: 5,
    expectedPairs: 0,
  ),
  RosterCorpusCase(
    id: 'multi-sheet-one-junk',
    title: 'Hai sheet: một sheet dữ liệu, một sheet chỉ có ghi chú',
    sheets: [
      RosterCorpusSheet('Đơn Nam', _singles(3)),
      RosterCorpusSheet('Hướng dẫn', [
        ['Điền thông tin đúng mẫu'],
        ['Liên hệ BTC khi cần'],
      ]),
    ],
    expectedRows: 3,
  ),
  RosterCorpusCase(
    id: 'empty-sheet',
    title: 'Sheet rỗng hoàn toàn',
    sheets: const [RosterCorpusSheet('Trống', [])],
    expectNoReading: true,
  ),
  RosterCorpusCase(
    id: 'no-header',
    title: 'Chỉ có số, không có dòng tiêu đề',
    sheets: const [
      RosterCorpusSheet('Số', [
        [1, 2, 3],
        [4, 5, 6],
      ]),
    ],
    expectNoReading: true,
  ),
  RosterCorpusCase(
    id: 'unicode-spacing',
    title: 'Tên có khoảng trắng thừa và dấu tiếng Việt',
    sheets: [
      RosterCorpusSheet('Đơn', [
        ['STT', 'Họ và tên', 'Email'],
        [1, '  Nguyễn  Thị  Ánh Tuyết  ', ' Corpus.UPPER@Example.COM '],
        [2, 'Đặng Quốc Việt', corpusEmail(2)],
      ]),
    ],
    expectedRows: 2,
    expectedErrors: const {'MISSING_EMAIL': 0, 'INVALID_EMAIL': 0},
  ),
  RosterCorpusCase(
    id: 'limit-500',
    title: 'Đúng 500 dòng (mức tối đa một lượt nhập)',
    sheets: [RosterCorpusSheet('Đơn', _singles(500))],
    expectedRows: 500,
  ),
  RosterCorpusCase(
    id: 'limit-501',
    title: 'Quá mức: 501 dòng',
    sheets: [RosterCorpusSheet('Đơn', _singles(501))],
    expectedRows: 501,
  ),
];
