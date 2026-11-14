import 'package:app_quanly_giaidau/core/services/roster_excel_reader.dart';

import 'roster_fixture_workbook.dart';

/// Tiêu đề 9 cột của "file mẫu người dùng": banner gộp ngang ở dòng 1, tiêu đề cột ở dòng 2.
const List<String> sampleUserHeaders = [
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

/// Số cặp trong fixture; mỗi cặp là hai dòng liền nhau gộp STT và xác nhận.
const int sampleUserPairCount = 4;

/// Dựng lưới: dòng 1 banner `A1:I1`, dòng 2 tiêu đề, rồi các cặp hai dòng (STT và xác nhận gộp dọc).
Future<List<RosterGridSheet>> sampleUserLayoutGrid() {
  final rows = <List<FixtureCell>>[
    ['DANH SÁCH VẬN ĐỘNG VIÊN THAM GIA'],
    sampleUserHeaders,
  ];
  final merges = <String>['A1:I1'];
  for (var pair = 0; pair < sampleUserPairCount; pair++) {
    final top = rows.length + 1;
    for (var member = 0; member < 2; member++) {
      final index = pair * 2 + member;
      rows.add([
        member == 0 ? pair + 1 : null,
        fakeName(index),
        'Công ty X',
        'Nhân viên',
        fakePhone(index),
        'L',
        '3.5',
        '01/01/1990',
        member == 0 ? 'Có' : null,
      ]);
    }
    merges
      ..add('A$top:A${top + 1}')
      ..add('I$top:I${top + 1}');
  }
  return workbookFrom(rows, merges: merges);
}
