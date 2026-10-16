import 'dart:typed_data';

import 'package:excel/excel.dart';

/// Một sheet đã đọc thành lưới chữ. `rows[0]` là dòng 1 của sheet, cột A là chỉ số 0.
/// Ô trống hoặc null thành chuỗi rỗng, giá trị đã được trim.
class RosterGridSheet {
  const RosterGridSheet({required this.name, required this.rows});

  final String name;
  final List<List<String>> rows;
}

/// Giới hạn giống `readSheet` của web (MAX_ROWS, MAX_COLUMNS).
const int _maxGridRows = 5200;
const int _maxGridColumns = 60;

/// Đọc mọi sheet của một workbook xlsx. Sheet rỗng vẫn được trả về với `rows` rỗng.
Future<List<RosterGridSheet>> readRosterWorkbook(Uint8List bytes) async {
  final excel = Excel.decodeBytes(bytes);
  return [
    for (final entry in excel.tables.entries)
      _readSheet(entry.key, entry.value),
  ];
}

RosterGridSheet _readSheet(String name, Sheet sheet) {
  final grid = sheet.rows;
  final rowCount = sheet.maxRows < _maxGridRows ? sheet.maxRows : _maxGridRows;
  final rows = <List<String>>[];
  for (var r = 0; r < rowCount; r++) {
    if (r >= grid.length) {
      rows.add(const <String>[]);
      continue;
    }
    final cells = grid[r];
    final width = cells.length < _maxGridColumns
        ? cells.length
        : _maxGridColumns;
    rows.add([
      for (var c = 0; c < width; c++)
        (cells[c]?.value?.toString() ?? '').trim(),
    ]);
  }
  return RosterGridSheet(name: name, rows: rows);
}
