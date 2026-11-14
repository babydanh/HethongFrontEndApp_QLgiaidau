// Đọc bố cục file Excel danh sách VĐV: bằng luật, bằng AI, và guard quyết định có cần hỏi AI. Thuần Dart.
//
// Port của web `rosterLayout.ts` (`applyRosterLayout`, `resolvePairLayout`), `rosterGuards.ts`
// (`rulesLayoutIsConfident`, `findUncapturedEmails`) và phần dựng dòng của `RosterImportModal.tsx`.

import 'package:app_quanly_giaidau/core/services/roster_excel_reader.dart';
import 'package:app_quanly_giaidau/domain/entities/roster_layout.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_pairing.dart';

/// Một sheet hoặc một khối AI đã đọc thành dòng, kèm cách ghép cặp và vùng của nó trên lưới.
class RosterReading {
  const RosterReading({
    required this.grid,
    required this.headerRowIndex,
    required this.firstDataRowIndex,
    required this.lastRowIndex,
    required this.mapping,
    required this.fromAi,
    this.layout = RosterPairLayout.single,
    this.separator = '',
    this.divisionLabel = '',
    this.singlesFromRow = 0,
    this.titleLabels = const {},
    this.layoutChosen = false,
  });

  final RosterGridSheet grid;

  /// 0-based; -1 khi khối không có dòng header.
  final int headerRowIndex;
  final int firstDataRowIndex;
  final int lastRowIndex;
  final RosterColumnMapping mapping;
  final bool fromAi;

  /// Cách ghép AI chọn (`single` nghĩa là để luật quyết định theo nội dung đích).
  final RosterPairLayout layout;
  final String separator;
  final String divisionLabel;
  final int singlesFromRow;
  final Set<String> titleLabels;

  /// Người dùng đã chọn cách ghép trong popup: `single` khi đó nghĩa là đánh đơn thật, không để luật suy.
  final bool layoutChosen;

  RosterReading copyWith({
    int? headerRowIndex,
    int? firstDataRowIndex,
    int? lastRowIndex,
    RosterColumnMapping? mapping,
    RosterPairLayout? layout,
    String? separator,
    bool? layoutChosen,
    bool? fromAi,
  }) => RosterReading(
    grid: grid,
    headerRowIndex: headerRowIndex ?? this.headerRowIndex,
    firstDataRowIndex: firstDataRowIndex ?? this.firstDataRowIndex,
    lastRowIndex: lastRowIndex ?? this.lastRowIndex,
    mapping: mapping ?? this.mapping,
    fromAi: fromAi ?? this.fromAi,
    layout: layout ?? this.layout,
    separator: separator ?? this.separator,
    divisionLabel: divisionLabel,
    singlesFromRow: singlesFromRow,
    titleLabels: titleLabels,
    layoutChosen: layoutChosen ?? this.layoutChosen,
  );

  String get sheetName => grid.name;

  List<String> get headers =>
      headerRowIndex >= 0 ? grid.rows[headerRowIndex] : const <String>[];

  /// Các dòng dữ liệu của khối (không có header).
  List<List<String>> get dataRows => [
    for (
      var r = firstDataRowIndex;
      r <= lastRowIndex && r < grid.rows.length;
      r++
    )
      grid.rows[r],
  ];

  List<RosterParsedRow> parse(RosterColumnMapping columnMapping) =>
      parseRosterSheet(
        grid,
        headerRowIndex: headerRowIndex,
        mapping: columnMapping,
        firstDataRowIndex: firstDataRowIndex,
        lastRowIndex: lastRowIndex,
        singlesFromRow: singlesFromRow,
        defaultDivisionLabel: divisionLabel,
        titleLabels: titleLabels,
      );
}

/// Đọc một sheet bằng luật: dòng header trong 10 dòng đầu, rồi ánh xạ cột. Null khi không có dòng header.
RosterReading? readSheetByRules(RosterGridSheet raw) {
  final grid = fillRosterMerges(raw);
  final headerRow = detectRosterHeaderRow(grid);
  if (headerRow == null) return null;
  final headers = grid.rows[headerRow];
  final dataRows = grid.rows.sublist(headerRow + 1);
  final mapping = confirmRosterColumns(
    dataRows,
    headers,
    detectRosterColumnMapping(headers),
  );
  return RosterReading(
    grid: grid,
    headerRowIndex: headerRow,
    firstDataRowIndex: headerRow + 1,
    lastRowIndex: grid.rows.length - 1,
    mapping: mapping,
    fromAi: false,
  );
}

/// Dòng cuối cùng được ghép: áp cách ghép và gộp theo mã cho nội dung đôi. [isDoublesFor] nhận tên nội
/// dung của dòng (null là nội dung đang mở) và trả `true` khi nội dung đó là đôi.
List<RosterParsedRow> assembleRosterRows(
  RosterReading reading,
  bool Function(String? divisionName) isDoublesFor,
) {
  var mapping = reading.mapping;
  var rows = reading.parse(mapping);
  if (rows.isEmpty) return rows;
  final anyDoubles = rows.any((row) => isDoublesFor(row.divisionName));

  // Cách ghép AI đã chọn thì giữ; `single` để luật quyết định (hai cột, hai tên một ô, hoặc không ghép).
  var layout = reading.layout;
  if (layout == RosterPairLayout.single && !reading.layoutChosen) {
    final resolved = resolvePairLayout(
      reading.dataRows,
      mapping,
      doubles: anyDoubles,
    );
    layout = resolved.layout;
    if (resolved.mapping.columns.toString() != mapping.columns.toString()) {
      mapping = resolved.mapping;
      rows = reading.parse(mapping);
    }
  }
  // Mã cặp của file quyết định cặp, nên ghép theo vị trí nhường chỗ cho mã.
  final hasCodes = rows.any(
    (row) => row.pairCode != null && row.pairCode!.isNotEmpty,
  );
  if (layout == RosterPairLayout.consecutiveRows && hasCodes) {
    layout = RosterPairLayout.single;
  }

  final doublesRows = [
    for (final r in rows)
      if (isDoublesFor(r.divisionName)) r,
  ];
  final otherRows = [
    for (final r in rows)
      if (!isDoublesFor(r.divisionName)) r,
  ];
  final paired = pairRowsByCode(
    applyPairLayout(doublesRows, layout, reading.separator),
  );
  // Nội dung đơn: giữ VĐV 2 của cột để server báo PLAYER2_NOT_ALLOWED; không ghép gì thêm.
  final singlesLayout = mapping.indexOf(RosterSlot.player2Name) != null
      ? RosterPairLayout.columns
      : RosterPairLayout.single;
  final others = applyPairLayout(otherRows, singlesLayout, reading.separator);
  return [...paired, ...others]
    ..sort((a, b) => a.sourceRowIndex.compareTo(b.sourceRowIndex));
}

// ---- Guard: có tin kết quả của luật không ----

/// Tỉ lệ dòng được thiếu tên trước khi nghi luật đọc sai: vài dòng là lỗi dữ liệu, nhiều hơn là đọc nhầm.
const double _maxNamelessShare = 0.2;

/// Cặp dòng cùng giá trị ở một cột chưa ánh xạ, từ ngưỡng này, cho thấy các dòng đi theo cặp.
const int _minSharedUnitPairs = 3;
const double _minSharedUnitShare = 0.7;

final RegExp _emailInCell = RegExp(
  r'[^\s@,;/|&+]+@[^\s@,;/|&+]+\.[^\s@,;/|&+]+',
);

Iterable<String> _emailsIn(String text) => _emailInCell
    .allMatches(text)
    .map((m) => m.group(0)!.replaceAll(RegExp(r'\.+$'), '').toLowerCase());

String _cell(List<String> cells, int? column) =>
    column == null || column >= cells.length ? '' : cells[column].trim();

/// Dấu hiệu các dòng đi theo cặp dù luật không tìm thấy cặp nào: vùng gộp đúng hai dòng, cùng STT ở hai
/// dòng liền nhau, cột gợi ý đồng đội có chữ, hoặc ≥ 3 cặp dòng liền kề cùng giá trị ở một cột chưa ánh xạ.
bool hasRosterPairSigns(RosterReading reading, List<RosterParsedRow> rows) {
  final twoRowMerge = reading.grid.mergedRegions.any((region) {
    final range = parseA1Range(region);
    return range != null && range.endRow - range.startRow == 1;
  });
  if (twoRowMerge) return true;
  final named = rows.where((row) => !row.singles).toList();
  for (var i = 0; i + 1 < named.length; i++) {
    if (named[i].fileIndex.isNotEmpty &&
        named[i].fileIndex == named[i + 1].fileIndex) {
      return true;
    }
  }
  final hintColumn = findPartnerHintColumn(reading.headers, reading.mapping);
  if (hintColumn != null &&
      reading.dataRows.any((cells) {
        final value = _cell(cells, hintColumn);
        return value.isNotEmpty && !isEmptyPartnerHint(value);
      })) {
    return true;
  }
  final used = reading.mapping.columns.values.toSet();
  final nameColumn = reading.mapping.indexOf(RosterSlot.player1Name);
  final records = [
    for (final cells in reading.dataRows)
      if (cells.any((c) => c.trim().isNotEmpty) &&
          !isSinglesSectionRow(cells) &&
          _cell(cells, nameColumn).isNotEmpty)
        cells,
  ];
  final width = reading.grid.rows.fold<int>(
    0,
    (m, r) => r.length > m ? r.length : m,
  );
  for (var column = 0; column < width; column++) {
    if (used.contains(column) || column == hintColumn) continue;
    final values = [for (final cells in records) _cell(cells, column)];
    final pairs = values.length ~/ 2;
    if (pairs == 0) continue;
    final shared = <String>{};
    var hits = 0;
    for (var i = 0; i + 1 < values.length; i += 2) {
      if (values[i].isNotEmpty && values[i] == values[i + 1]) {
        hits += 1;
        shared.add(values[i]);
      }
    }
    if (hits >= _minSharedUnitPairs &&
        hits / pairs >= _minSharedUnitShare &&
        shared.length >= 2) {
      return true;
    }
  }
  return false;
}

/// Email còn lại ngoài các cột email/ghi chú đã ánh xạ: một cột không có header, cột chưa ánh xạ, hoặc
/// khối mà dòng header không mô tả. Chỉ tính sheet có khối được bao gồm. Gợi ý, không phải lỗi.
int countUncapturedEmails(
  List<RosterGridSheet> grid,
  List<RosterReading> readings,
) {
  final missing = <String>{};
  for (final sheet in grid) {
    final sheetReadings = readings
        .where((r) => r.sheetName == sheet.name)
        .toList();
    if (sheetReadings.isEmpty) continue;
    final read = <String>{};
    var firstHeaderRow = 1 << 30;
    for (final reading in sheetReadings) {
      final headerIndex = reading.headerRowIndex + 1;
      if (headerIndex < firstHeaderRow) firstHeaderRow = headerIndex;
      for (final slot in const [
        RosterSlot.player1Email,
        RosterSlot.player2Email,
        RosterSlot.notes,
      ]) {
        final column = reading.mapping.indexOf(slot);
        if (column == null) continue;
        for (final cells in reading.dataRows) {
          read.addAll(_emailsIn(_cell(cells, column)));
        }
      }
    }
    final headerIndex = firstHeaderRow > 0 ? firstHeaderRow - 1 : 0;
    for (var r = 0; r < sheet.rows.length; r++) {
      final cells = sheet.rows[r];
      // Trên header chỉ dòng có từ hai ô trở lên mới tính, nên dòng `Liên hệ BTC: btc@…` thì không.
      if (r < headerIndex &&
          cells.where((c) => c.trim().isNotEmpty).length < 2) {
        continue;
      }
      for (final cell in cells) {
        for (final email in _emailsIn(cell)) {
          if (!read.contains(email)) missing.add(email);
        }
      }
    }
  }
  return missing.length;
}

/// Tin kết quả của luật, không hỏi AI: có khối được bao gồm, mọi khối có cột tên VĐV hoặc đội, ≤ 1/5 dòng
/// thiếu tên, không email nào nằm ngoài cột đã ánh xạ, và mọi sheet có bảng đều được đọc. Nội dung đôi mà
/// không tìm được cặp nào dù file có dấu hiệu cặp (xem [hasRosterPairSigns]) cũng là không tin.
/// Dòng chỉ có STT không bao giờ vào [RosterReading] nên không bị tính.
bool rosterRulesAreConfident(
  List<RosterGridSheet> grid,
  List<RosterReading> readings,
  bool Function(String? divisionName) isDoublesFor,
) {
  if (readings.isEmpty) return false;
  for (final reading in readings) {
    if (reading.mapping.indexOf(RosterSlot.player1Name) == null &&
        reading.mapping.indexOf(RosterSlot.teamName) == null) {
      return false;
    }
    final rows = assembleRosterRows(reading, isDoublesFor);
    final nameless = rows
        .where(
          (r) => (r.player1Name ?? '').isEmpty && (r.teamName ?? '').isEmpty,
        )
        .length;
    if (nameless > rows.length * _maxNamelessShare) return false;
    final doubles = rows.any((r) => isDoublesFor(r.divisionName));
    if (doubles &&
        rows.length > 1 &&
        !rows.any((r) => r.player2Name != null) &&
        hasRosterPairSigns(reading, reading.parse(reading.mapping))) {
      return false;
    }
  }
  final readSheets = readings.map((r) => r.sheetName).toSet();
  // Hai dòng từ hai ô trở lên là một bảng; dòng một ô (hướng dẫn, tiêu đề) thì không.
  final unread = grid.any(
    (sheet) =>
        !readSheets.contains(sheet.name) &&
        sheet.rows
                .where(
                  (cells) =>
                      cells.where((c) => c.trim().isNotEmpty).length >= 2,
                )
                .length >=
            2,
  );
  return !unread && countUncapturedEmails(grid, readings) == 0;
}

// ---- AI layout ----

/// Chỉ số cột từ chữ cái `A`..`ZZZ`; -1 khi không phải 1-3 chữ in hoa.
int _columnIndexOf(String letters) {
  if (!RegExp(r'^[A-Z]{1,3}$').hasMatch(letters)) return -1;
  var value = 0;
  for (final unit in letters.codeUnits) {
    value = value * 26 + (unit - 64);
  }
  return value - 1;
}

const List<RosterSlot> _personClaimOrder = [
  RosterSlot.player1Name,
  RosterSlot.player1Email,
  RosterSlot.player1Phone,
  RosterSlot.player2Name,
  RosterSlot.player2Email,
  RosterSlot.player2Phone,
  RosterSlot.teamName,
];

/// Slot -> cột theo chữ cái AI chọn. Chữ ngoài sheet hoặc sai dạng là không có cột. Một cột chỉ giữ một
/// giá trị: khi AI gán hai slot người vào cùng cột thì slot sau bị bỏ.
RosterColumnMapping _mappingFromLetters(
  Map<String, String> letters,
  int width,
) {
  final columns = <RosterSlot, int>{};
  for (final slot in RosterSlot.values) {
    final index = _columnIndexOf(letters[slot.name] ?? '');
    if (index >= 0 && index < width) columns[slot] = index;
  }
  final claimed = <int>{};
  for (final slot in _personClaimOrder) {
    final column = columns[slot];
    if (column == null) continue;
    if (!claimed.add(column)) columns.remove(slot);
  }
  return RosterColumnMapping(columns);
}

/// Cột đội chỉ gồm số 1-3 chữ số không phải tên đội: số lặp là mã cặp, số duy nhất là số thứ tự (bỏ cột).
RosterColumnMapping _withoutNumberingTeamColumn(
  RosterColumnMapping mapping,
  List<List<String>> dataRows,
) {
  final column = mapping.indexOf(RosterSlot.teamName);
  if (column == null) return mapping;
  final cells = [for (final r in dataRows) _cell(r, column)];
  final values = cells.where((c) => c.isNotEmpty).toList();
  if (values.isEmpty ||
      !values.every((v) => RegExp(r'^\d{1,3}$').hasMatch(v))) {
    return mapping;
  }
  final columns = Map<RosterSlot, int>.of(mapping.columns)
    ..remove(RosterSlot.teamName);
  if (mapping.indexOf(RosterSlot.pairCode) == null &&
      looksLikePairCodes(cells)) {
    columns[RosterSlot.pairCode] = column;
  }
  return RosterColumnMapping(columns);
}

/// Bằng chứng cặp cho `CONSECUTIVE_ROWS`: cột mã có mã, dòng tiêu đề `Cặp n`, vùng gộp đúng hai dòng trong
/// khối, hoặc hai dòng liền nhau cùng STT. Không đoán theo tên hay vị trí.
bool hasRosterPairEvidence(RosterReading reading, List<RosterParsedRow> rows) {
  final codeColumn = reading.mapping.indexOf(RosterSlot.pairCode);
  final hasCode =
      codeColumn != null &&
      reading.dataRows.any(
        (cells) => pairCodeKey(_cell(cells, codeColumn)).isNotEmpty,
      );
  if (hasCode) return true;
  if (reading.dataRows.any((cells) => titleRowCode(cells).isNotEmpty)) {
    return true;
  }
  final inBlock = reading.grid.mergedRegions.any((region) {
    final range = parseA1Range(region);
    return range != null &&
        range.endRow - range.startRow == 1 &&
        range.startRow + 1 >= reading.firstDataRowIndex + 1 &&
        range.endRow + 1 <= reading.lastRowIndex + 1;
  });
  if (inBlock) return true;
  for (var i = 0; i + 1 < rows.length; i++) {
    if (rows[i].fileIndex.isNotEmpty &&
        rows[i].fileIndex == rows[i + 1].fileIndex) {
      return true;
    }
  }
  return false;
}

RosterPairLayout _layoutOf(String name) => switch (name) {
  'COLUMNS' => RosterPairLayout.columns,
  'SAME_CELL' => RosterPairLayout.sameCell,
  'CONSECUTIVE_ROWS' => RosterPairLayout.consecutiveRows,
  _ => RosterPairLayout.single,
};

String _foldLabel(String text) => normalizeRosterHeader(text);

/// Tên nội dung AI đã nêu (đã chuẩn hóa): dòng chỉ có tên đó là tiêu đề, không phải VĐV.
Set<String> rosterTitleLabels(RosterLayout layout) => {
  for (final sheet in layout.sheets)
    for (final block in sheet.blocks)
      if (_foldLabel(block.divisionLabel).isNotEmpty)
        _foldLabel(block.divisionLabel),
};

/// Tên sheet AI dùng: `S<n>` là sheet thứ n của lưới, rồi đến tên thật.
int _gridIndexOf(List<RosterGridSheet> grid, String sheetName) {
  final digest = RegExp(r'^S(\d+)$').firstMatch(sheetName);
  final position = digest == null ? -1 : int.parse(digest.group(1)!) - 1;
  if (position >= 0 && position < grid.length) return position;
  return grid.indexWhere((s) => s.name == sheetName);
}

/// Áp bố cục AI lên lưới. Chỉ sheet `ROSTER` và khối có số dòng hợp lệ được dùng. CONSECUTIVE_ROWS chỉ được
/// giữ khi file có bằng chứng cặp ([hasRosterPairEvidence]); ngược lại hạ về `single`. `singlesFromRow`
/// chỉ nhận khi nằm sau dòng dữ liệu đầu và không quá dòng cuối.
List<RosterReading> applyRosterLayout(
  List<RosterGridSheet> rawGrid,
  RosterLayout layout,
) {
  final grid = [for (final sheet in rawGrid) fillRosterMerges(sheet)];
  final titleLabels = rosterTitleLabels(layout);
  final readings = <RosterReading>[];
  final used = <int>{};
  for (final layoutSheet in layout.sheets) {
    if (layoutSheet.kind != 'ROSTER') continue;
    final gridIndex = _gridIndexOf(grid, layoutSheet.sheetName);
    if (gridIndex < 0 || !used.add(gridIndex)) continue;
    final sheet = grid[gridIndex];
    final rowCount = sheet.rows.length;
    for (final block in layoutSheet.blocks) {
      final headerRow = block.headerRow;
      final first = block.firstDataRow;
      if (headerRow < 0 || headerRow > rowCount) continue;
      if (first < 1 || first > rowCount || first <= headerRow) continue;
      final last = block.lastDataRow.clamp(first, rowCount);
      final width = sheet.rows.fold<int>(
        0,
        (m, r) => r.length > m ? r.length : m,
      );
      final dataRows = sheet.rows.sublist(first - 1, last);
      var mapping = _withoutNumberingTeamColumn(
        _mappingFromLetters(block.columns, width),
        dataRows,
      );
      final headers = headerRow > 0
          ? sheet.rows[headerRow - 1]
          : const <String>[];
      mapping = confirmRosterColumns(dataRows, headers, mapping);
      final singles = block.singlesFromRow;
      var reading = RosterReading(
        grid: sheet,
        headerRowIndex: headerRow - 1,
        firstDataRowIndex: first - 1,
        lastRowIndex: last - 1,
        mapping: mapping,
        fromAi: true,
        layout: _layoutOf(block.pairLayout),
        separator: block.pairSeparator,
        divisionLabel: block.divisionLabel.trim(),
        singlesFromRow: singles != null && singles > first && singles <= last
            ? singles
            : 0,
        titleLabels: titleLabels,
      );
      if (reading.layout == RosterPairLayout.consecutiveRows &&
          !hasRosterPairEvidence(reading, reading.parse(mapping))) {
        reading = RosterReading(
          grid: reading.grid,
          headerRowIndex: reading.headerRowIndex,
          firstDataRowIndex: reading.firstDataRowIndex,
          lastRowIndex: reading.lastRowIndex,
          mapping: reading.mapping,
          fromAi: true,
          divisionLabel: reading.divisionLabel,
          singlesFromRow: reading.singlesFromRow,
          titleLabels: reading.titleLabels,
        );
      }
      if (reading.parse(reading.mapping).isEmpty) continue;
      readings.add(reading);
    }
  }
  return readings;
}
