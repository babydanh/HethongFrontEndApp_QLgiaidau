import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/roster_excel_reader.dart';

import 'roster_fixture_workbook.dart';

/// Tiêu đề 9 cột của "file mẫu người dùng": dòng 1 là banner gộp ngang, dòng 2 là tiêu đề cột.
const List<String> sampleUserLayoutHeaders = [
  'STT',
  'Họ và tên VĐV',
  'Đơn vị công tác',
  'Chức vụ',
  'Số điện thoại',
  'Size áo',
  'Trình điểm gần nhất',
  'Ngày sinh',
  'Xác nhận',
];

/// Ba cặp, mỗi cặp hai dòng liền nhau gộp STT và xác nhận. Tên, SĐT và ngày sinh đều bịa.
Future<List<RosterGridSheet>> sampleUserLayoutGrid() {
  final sample = _sampleUserLayout();
  return workbookFrom(sample.rows, merges: sample.merges);
}

/// Cùng nội dung với [sampleUserLayoutGrid], dạng bytes xlsx cho file picker giả của test màn nhập.
Uint8List sampleUserLayoutBytes() {
  final sample = _sampleUserLayout();
  return workbookBytes(sample.rows, merges: sample.merges);
}

({List<List<FixtureCell>> rows, List<String> merges}) _sampleUserLayout() {
  final rows = <List<FixtureCell>>[
    ['DANH SÁCH VĐV GIẢI MẪU'],
    sampleUserLayoutHeaders,
  ];
  final merges = <String>['A1:I1'];
  for (var pair = 0; pair < 3; pair++) {
    final sheetRow = 3 + pair * 2;
    for (var side = 0; side < 2; side++) {
      final person = pair * 2 + side;
      rows.add([
        side == 0 ? pair + 1 : null,
        fakeName(person),
        'Công ty X',
        'Nhân viên',
        fakePhone(person),
        'M',
        '620',
        '01/01/1990',
        side == 0 ? 'Có' : null,
      ]);
    }
    merges
      ..add('A$sheetRow:A${sheetRow + 1}')
      ..add('I$sheetRow:I${sheetRow + 1}');
  }
  return (rows: rows, merges: merges);
}
