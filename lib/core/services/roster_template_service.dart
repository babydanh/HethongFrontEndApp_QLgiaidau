import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Nội dung file mẫu danh sách VĐV, lấy đúng từ `ROSTER_TEMPLATE_COPY` và `EXPORT_COPY` của web.
class _TemplateCopy {
  const _TemplateCopy({
    required this.fileName,
    required this.sheetName,
    required this.headers,
    required this.rows,
  });

  final String fileName;
  final String sheetName;
  final List<String> headers;

  /// Ô số là `int`, ô chữ là `String`.
  final List<List<Object>> rows;
}

const _templateEn = _TemplateCopy(
  fileName: 'Registration_List_Template.xlsx',
  sheetName: 'Registration template',
  headers: [
    'No.',
    'Player 1 name',
    'Player 1 email (optional)',
    'Player 1 phone',
    'Player 2 name',
    'Player 2 email (optional)',
    'Player 2 phone',
    'Team name (Optional)',
    'Registration format',
    'ELO points (if available)',
    'Entry fee paid',
    'Notes',
  ],
  rows: [
    [
      1,
      'Alex Brown',
      'alex.brown@example.com',
      '0901234567',
      'Jamie Lee',
      'jamie.lee@example.com',
      '0907654321',
      'Saigon Pickleball Club',
      'Men doubles 6.5',
      1250,
      'Yes',
      'Deposit transferred',
    ],
    [
      2,
      'Taylor Smith',
      'taylor.smith@example.com',
      '0912345678',
      'Morgan Davis',
      'morgan.davis@example.com',
      '0918765432',
      'Hanoi Pickleball Team',
      'Mixed doubles',
      1100,
      'No',
      '',
    ],
    [
      3,
      'Jordan Wilson',
      'jordan.wilson@example.com',
      '0933445566',
      '',
      '',
      '',
      '',
      'Men singles',
      1300,
      'Yes',
      '',
    ],
  ],
);

const _templateVi = _TemplateCopy(
  fileName: 'Mau_Danh_Sach_VDV_Dang_Ky.xlsx',
  sheetName: 'Mau_Dang_Ky',
  headers: [
    'STT',
    'Họ và tên VĐV 1',
    'Email VĐV 1 (không bắt buộc)',
    'Số điện thoại 1',
    'Họ và tên VĐV 2',
    'Email VĐV 2 (không bắt buộc)',
    'Số điện thoại 2',
    'Tên Đội (Tùy chọn)',
    'Nội dung đăng ký',
    'Điểm ELO (nếu có)',
    'Đã đóng lệ phí',
    'Ghi chú',
  ],
  rows: [
    [
      1,
      'Nguyễn Văn A',
      'nguyenvana@example.com',
      '0901234567',
      'Trần Văn B',
      'tranvanb@example.com',
      '0907654321',
      'CLB Pickleball Saigon',
      'Đôi Nam 6.5',
      1250,
      'Có',
      'Đã chuyển khoản cọc',
    ],
    [
      2,
      'Lê Thị C',
      'lethic@example.com',
      '0912345678',
      'Phạm Hoàng D',
      'phamhoangd@example.com',
      '0918765432',
      'Hà Nội Pickleball Team',
      'Đôi Nam Nữ',
      1100,
      'Không',
      '',
    ],
    [
      3,
      'Đỗ Hữu E',
      'dohuu@example.com',
      '0933445566',
      '',
      '',
      '',
      '',
      'Đơn Nam',
      1300,
      'Có',
      '',
    ],
  ],
);

const _xlsxMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Tạo file xlsx mẫu danh sách VĐV rồi mở bảng chia sẻ. [locale] là `'en'`, còn lại dùng tiếng Việt.
Future<void> shareRosterTemplate({required String locale}) async {
  final copy = locale == 'en' ? _templateEn : _templateVi;

  final excel = Excel.createExcel();
  final sheet = excel[copy.sheetName];
  excel.setDefaultSheet(copy.sheetName);
  if (excel.tables.containsKey('Sheet1')) {
    excel.delete('Sheet1');
  }

  sheet.appendRow([for (final header in copy.headers) TextCellValue(header)]);
  for (final row in copy.rows) {
    sheet.appendRow([
      for (final value in row)
        value is int ? IntCellValue(value) : TextCellValue(value as String),
    ]);
  }

  final bytes = excel.save();
  if (bytes == null) return;
  final fileBytes = Uint8List.fromList(bytes);

  if (kIsWeb) {
    // ignore: deprecated_member_use
    await Share.shareXFiles([
      XFile.fromData(
        fileBytes,
        name: copy.fileName,
        mimeType: _xlsxMimeType,
      ),
    ]);
    return;
  }

  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/${copy.fileName}');
  await file.writeAsBytes(fileBytes);
  if (Platform.isAndroid || Platform.isIOS) {
    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)]);
  }
}
