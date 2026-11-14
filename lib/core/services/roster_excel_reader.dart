import 'dart:typed_data';

import 'package:excel/excel.dart';

/// Một sheet đã đọc thành lưới chữ. `rows[0]` là dòng 1 của sheet, cột A là chỉ số 0.
/// Ô trống hoặc null thành chuỗi rỗng, giá trị đã được trim.
class RosterGridSheet {
  const RosterGridSheet({
    required this.name,
    required this.rows,
    this.mergedRegions = const [],
    this.horizontalMerges = const [],
  });

  final String name;
  final List<List<String>> rows;

  /// Vùng ô gộp qua hai dòng trở lên ở dạng địa chỉ A1 (`A3:A4`). Giá trị chưa được điền xuống các ô
  /// dưới; gọi `fillRosterMerges` (roster_excel_parser.dart) để điền.
  final List<String> mergedRegions;

  /// Vùng gộp một dòng nhiều cột (`A1:I1`). Chỉ dùng để cảnh báo tiêu đề lệch cột, không phải bằng chứng cặp.
  final List<String> horizontalMerges;
}

/// Vùng ô theo chỉ số 0-based, cột A = 0.
class RosterRange {
  const RosterRange(
    this.startRow,
    this.startColumn,
    this.endRow,
    this.endColumn,
  );

  final int startRow;
  final int startColumn;
  final int endRow;
  final int endColumn;
}

/// Đọc địa chỉ `A3:A4` thành vùng; null khi sai dạng.
RosterRange? parseA1Range(String region) {
  final match = RegExp(
    r'^([A-Z]{1,3})(\d+):([A-Z]{1,3})(\d+)$',
  ).firstMatch(region);
  if (match == null) return null;
  int column(String letters) {
    var value = 0;
    for (final unit in letters.codeUnits) {
      value = value * 26 + (unit - 64);
    }
    return value - 1;
  }

  final startRow = int.parse(match.group(2)!) - 1;
  final endRow = int.parse(match.group(4)!) - 1;
  if (startRow < 0 || endRow < 0) return null;
  return RosterRange(
    startRow,
    column(match.group(1)!),
    endRow,
    column(match.group(3)!),
  );
}

/// Giới hạn giống `readSheet` của web (MAX_ROWS, MAX_COLUMNS).
const int _maxGridRows = 5200;
const int _maxGridColumns = 60;

/// Giới hạn số vùng gộp gửi cho AI, giống web.
const int maxMergedRegions = 200;

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
  // Chỉ vùng gộp qua nhiều dòng: gộp một dòng là tiêu đề, không phải bằng chứng cặp.
  final merged = <String>[];
  final horizontal = <String>[];
  for (final region in sheet.spannedItems) {
    final range = parseA1Range(region);
    if (range == null || range.startRow >= _maxGridRows) continue;
    if (range.endRow > range.startRow) {
      if (merged.length < maxMergedRegions) merged.add(region);
    } else if (range.endColumn > range.startColumn) {
      if (horizontal.length < maxMergedRegions) horizontal.add(region);
    }
  }
  return RosterGridSheet(
    name: name,
    rows: rows,
    mergedRegions: merged,
    horizontalMerges: horizontal,
  );
}
