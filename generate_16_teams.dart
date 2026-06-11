import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  generateSingles();
  generateDoubles();
}

void generateSingles() {
  var excel = Excel.createExcel();
  Sheet sheetObject = excel['Sheet1'];

  sheetObject.appendRow([
    TextCellValue('Tên Đội'), 
    TextCellValue('VĐV 1'), 
    TextCellValue('VĐV 2'),
    TextCellValue('Ghi chú')
  ]);

  for (int i = 1; i <= 16; i++) {
    sheetObject.appendRow([
      TextCellValue('Tay Vợt $i'), 
      TextCellValue('VĐV Đơn $i'), 
      TextCellValue(''), 
      TextCellValue('Hạt giống $i')
    ]);
  }

  var fileBytes = excel.save();
  if (fileBytes != null) {
    File('DanhSach_16_Don.xlsx')
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);
    print('Đã tạo thành công DanhSach_16_Don.xlsx');
  }
}

void generateDoubles() {
  var excel = Excel.createExcel();
  Sheet sheetObject = excel['Sheet1'];

  sheetObject.appendRow([
    TextCellValue('Tên Đội'), 
    TextCellValue('VĐV 1'), 
    TextCellValue('VĐV 2'),
    TextCellValue('Ghi chú')
  ]);

  for (int i = 1; i <= 16; i++) {
    sheetObject.appendRow([
      TextCellValue('Đội Đôi $i'), 
      TextCellValue('VĐV A_$i'), 
      TextCellValue('VĐV B_$i'), 
      TextCellValue('Nhóm $i')
    ]);
  }

  var fileBytes = excel.save();
  if (fileBytes != null) {
    File('DanhSach_16_Doi.xlsx')
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);
    print('Đã tạo thành công DanhSach_16_Doi.xlsx');
  }
}
