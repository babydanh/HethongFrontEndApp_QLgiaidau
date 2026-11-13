import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/roster_excel_reader.dart';
import 'package:excel/excel.dart';

/// Tên và SĐT bịa, cùng bố cục với corpus Web `consecutive-merged-stt-section-singles`.
const List<String> _givenNames = [
  'An',
  'Bình',
  'Cường',
  'Dũng',
  'Giang',
  'Hà',
  'Khoa',
  'Lâm',
  'Minh',
  'Nam',
  'Phúc',
  'Quân',
  'Sơn',
  'Tài',
  'Út',
  'Việt',
  'Xuân',
  'Yến',
  'Bảo',
  'Đạt',
  'Hiếu',
  'Kiên',
  'Long',
  'Nhân',
  'Phong',
  'Thịnh',
  'Trung',
  'Vinh',
  'Huy',
];

String fakeName(int index) => 'Mẫu Văn ${_givenNames[index]}';

String fakePhone(int index) =>
    '09000000${(index + 10).toString().padLeft(2, '0')}';

const String scoreHeader =
    'Trình điểm giải đấu gần nhất (tham khảo theo diễn đàn/giải đấu)';

/// Một ô: chuỗi hoặc số nguyên. Chuỗi rỗng và null bỏ qua (không tạo ô).
typedef FixtureCell = Object?;

/// Dựng workbook một sheet từ các dòng và vùng gộp (địa chỉ A1), rồi đọc lại qua đúng đường đọc file.
Future<List<RosterGridSheet>> workbookFrom(
  List<List<FixtureCell>> rows, {
  List<String> merges = const [],
  String sheetName = 'Đôi Nam',
}) => readRosterWorkbook(
  workbookBytes(rows, merges: merges, sheetName: sheetName),
);

/// Bytes của workbook một sheet; dùng cho file picker giả của test màn nhập.
Uint8List workbookBytes(
  List<List<FixtureCell>> rows, {
  List<String> merges = const [],
  String sheetName = 'Đôi Nam',
}) {
  final excel = Excel.createExcel();
  final defaultName = excel.getDefaultSheet()!;
  excel.rename(defaultName, sheetName);
  final sheet = excel[sheetName];
  for (var r = 0; r < rows.length; r++) {
    for (var c = 0; c < rows[r].length; c++) {
      final value = rows[r][c];
      if (value == null || value == '') continue;
      final cell = value is int
          ? IntCellValue(value)
          : TextCellValue(value.toString());
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
        cell,
      );
    }
  }
  for (final merge in merges) {
    final parts = merge.split(':');
    sheet.merge(
      CellIndex.indexByString(parts[0]),
      CellIndex.indexByString(parts[1]),
    );
  }
  return Uint8List.fromList(excel.encode()!);
}

/// File mẫu: 76 dòng x 9 cột, 11 cặp hai dòng (STT và ô xác nhận gộp), tiêu đề phần gộp, 7 VĐV lẻ
/// đánh số lại từ 1, rồi 44 dòng chỉ có STT. Cột `Xác nhận BTC` để trống.
({List<List<FixtureCell>> rows, List<String> merges}) sampleRows() {
  const header = <String>[
    'STT',
    'Họ và tên VĐV',
    'Đơn đang công tác',
    'Chức Vụ',
    'Số điện thoại liên hệ',
    'Size Áo',
    scoreHeader,
    'VDV đăng ký đứng chung',
    'Xác nhận BTC',
  ];
  const scores = [
    '620',
    '605',
    '620 Robinson , 625-630 CCTV',
    '600 - CCTV Tân Phú',
    '600 4P, 600 BTN, tầm 605 CCTV',
    '610',
  ];
  const pairHints = [
    ['Bình tsc', 'An béo'],
    ['2 người', ''],
    ['Chưa có', 'Chưa'],
    ['', ''],
    ['Chưa', ''],
    ['Dũng cơ', ''],
    ['', ''],
    ['', 'Nam xe ôm'],
    ['', ''],
    ['', ''],
    ['', ''],
  ];
  const singleHints = [
    'Chưa có',
    'Chưa',
    '',
    'Bình tsc',
    'Chưa có',
    '',
    'Chưa',
  ];
  const sizes = ['M', 'L', 'XL'];
  final rows = <List<FixtureCell>>[
    ['DANH SÁCH CẶP ĐẤU DRAGONS LẦN IV - TRANH CUP VCOM - 2026'],
    header,
  ];
  final merges = <String>['A1:I1'];
  for (var pair = 0; pair < 11; pair++) {
    final sheetRow = 3 + pair * 2;
    for (var side = 0; side < 2; side++) {
      final person = pair * 2 + side;
      rows.add([
        side == 0 ? pair + 1 : null,
        fakeName(person),
        'Phòng ${String.fromCharCode(65 + pair % 5)}',
        side == 0 ? 'Nhân viên' : 'Trưởng nhóm',
        fakePhone(person),
        sizes[person % 3],
        scores[person % scores.length],
        pairHints[pair][side],
        null,
      ]);
    }
    merges
      ..add('A$sheetRow:A${sheetRow + 1}')
      ..add('I$sheetRow:I${sheetRow + 1}');
  }
  rows.add(['DANH SÁCH VDV CHƯA CÓ CẶP']);
  merges.add('A25:I25');
  for (var single = 0; single < 7; single++) {
    final person = 22 + single;
    rows.add([
      single + 1,
      fakeName(person),
      'Phòng ${String.fromCharCode(70 + single)}',
      'Nhân viên',
      fakePhone(person),
      'L',
      scores[person % scores.length],
      singleHints[single],
      null,
    ]);
  }
  for (var blank = 8; blank <= 51; blank++) {
    rows.add([blank]);
  }
  return (rows: rows, merges: merges);
}

Future<List<RosterGridSheet>> sampleWorkbook() {
  final sample = sampleRows();
  return workbookFrom(sample.rows, merges: sample.merges);
}

Uint8List sampleWorkbookBytes() {
  final sample = sampleRows();
  return workbookBytes(sample.rows, merges: sample.merges);
}
