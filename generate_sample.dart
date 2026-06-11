import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  var excel = Excel.createExcel();
  Sheet sheetObject = excel['Sheet1'];

  // Dòng 1: Tiêu đề (Sẽ bị app bỏ qua vì ô A1 chứa chữ "Tên")
  sheetObject.appendRow([
    TextCellValue('Tên Đội'), 
    TextCellValue('VĐV 1'), 
    TextCellValue('VĐV 2'),
    TextCellValue('Ghi chú')
  ]);

  // Dòng 2: Đội có 2 thành viên
  sheetObject.appendRow([
    TextCellValue('CLB Sức Trẻ'), 
    TextCellValue('Nguyễn Văn A'), 
    TextCellValue('Trần Thị B'), 
    TextCellValue('Đã nộp lệ phí')
  ]);

  // Dòng 3: Đội có 2 thành viên
  sheetObject.appendRow([
    TextCellValue('Đội Lốc Xoáy'), 
    TextCellValue('Lê Văn C'), 
    TextCellValue('Phạm Văn D'), 
    TextCellValue('')
  ]);

  // Dòng 4: Đội chỉ có 1 thành viên (đánh đơn)
  sheetObject.appendRow([
    TextCellValue('Tuyển Quận 1'), 
    TextCellValue('Hoàng Hữu E'), 
    TextCellValue(''), 
    TextCellValue('')
  ]);

  // Dòng 5: Đội khác
  sheetObject.appendRow([
    TextCellValue('Hội Yêu Cầu Lông'), 
    TextCellValue('Trịnh Văn F'), 
    TextCellValue('Lý Tiểu G'), 
    TextCellValue('')
  ]);

  var fileBytes = excel.save();
  if (fileBytes != null) {
    File('DanhSachDoiMau.xlsx')
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);
    print('Da tao thanh cong DanhSachDoiMau.xlsx');
  }
}
