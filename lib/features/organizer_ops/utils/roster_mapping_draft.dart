// Bản nháp ghép cột của popup Nhập Excel: bất biến, thuần Dart, không đụng Flutter. Popup giữ bản sao,
// mọi thao tác trả bản mới; màn Nhập Excel chỉ nhận kết quả khi người dùng bấm `Xong`.

import 'package:app_quanly_giaidau/core/services/roster_excel_reader.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_layout.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_pairing.dart';

/// Số ký tự tối đa của giá trị mẫu hiện cạnh tên cột.
const int _maxSampleLength = 40;

/// `normal` ghép được; `serial` (STT) và `sensitive` (ngày sinh, giấy tờ, địa chỉ) bị khóa, không lưu.
enum RosterColumnKind { normal, serial, sensitive }

class RosterMappingColumn {
  const RosterMappingColumn({
    required this.index,
    required this.header,
    required this.sample,
    required this.kind,
    required this.slot,
  });

  /// Cột A = 0.
  final int index;

  /// Rỗng khi ô tiêu đề trống: UI hiện chữ cột (A, B...).
  final String header;

  /// Giá trị không trống đầu tiên bên dưới dòng tiêu đề, cắt còn 40 ký tự.
  final String sample;
  final RosterColumnKind kind;

  /// Null là Ghi chú: cột không ghép vào trường nào thì đi vào ghi chú `Tên cột: giá trị`.
  final RosterSlot? slot;
}

class RosterMappingResult {
  const RosterMappingResult({
    required this.readings,
    required this.skippedSheets,
  });

  /// Gom bản nháp của popup: sheet bị bỏ qua mà giờ đã đủ nhận diện và có dòng thì thành khối đọc được.
  factory RosterMappingResult.fromDrafts(List<RosterMappingDraft> drafts) {
    final readings = <RosterReading>[];
    final skipped = <String>[];
    for (final draft in drafts) {
      if (!draft.wasSkipped || (draft.hasIdentity && draft.rowCount > 0)) {
        readings.add(draft.reading);
      } else {
        skipped.add(draft.reading.sheetName);
      }
    }
    return RosterMappingResult(readings: readings, skippedSheets: skipped);
  }

  final List<RosterReading> readings;

  /// Sheet vẫn bị bỏ qua sau khi sửa.
  final List<String> skippedSheets;
}

class RosterMappingDraft {
  RosterMappingDraft._(this.reading, this.wasSkipped, this._isDoublesFor);

  factory RosterMappingDraft.fromReading(
    RosterReading reading, {
    required bool Function(String? divisionName) isDoublesFor,
  }) => RosterMappingDraft._(reading, false, isDoublesFor);

  /// Sheet bị bỏ qua: hàng tiêu đề mặc định là dòng đầu có từ hai ô trở lên (không có thì dòng đầu).
  factory RosterMappingDraft.forSkippedSheet(
    RosterGridSheet grid, {
    required bool Function(String? divisionName) isDoublesFor,
  }) {
    final rows = grid.rows;
    final header = rows.length < 2
        ? -1
        : _firstRowWithCells(rows, 2).clamp(0, rows.length - 2);
    final headers = header >= 0 ? rows[header] : const <String>[];
    final dataRows = header >= 0 ? rows.sublist(header + 1) : const [];
    final reading = RosterReading(
      grid: grid,
      headerRowIndex: header,
      firstDataRowIndex: header + 1,
      lastRowIndex: rows.length - 1,
      mapping: header >= 0
          ? confirmRosterColumns(
              [for (final r in dataRows) r],
              headers,
              detectRosterColumnMapping(headers),
            )
          : const RosterColumnMapping({}),
      fromAi: false,
    );
    return RosterMappingDraft._(reading, true, isDoublesFor);
  }

  final RosterReading reading;
  final bool wasSkipped;
  final bool Function(String? divisionName) _isDoublesFor;

  late final List<RosterParsedRow> _parsed = reading.parse(reading.mapping);
  late final List<RosterMappingColumn> columns = _buildColumns();
  late final bool isDoubles = _parsed.any((r) => _isDoublesFor(r.divisionName));
  late final int rowCount = assembleRosterRows(reading, _isDoublesFor).length;

  bool get hasIdentity {
    final mapping = reading.mapping;
    return mapping.indexOf(RosterSlot.player1Name) != null ||
        mapping.indexOf(RosterSlot.teamName) != null ||
        mapping.indexOf(RosterSlot.player1Email) != null;
  }

  /// Cách ghép đang áp dụng: cái người dùng hoặc AI chọn, nếu không thì cái luật suy ra.
  RosterPairLayout get effectiveLayout {
    if (reading.layoutChosen || reading.layout != RosterPairLayout.single) {
      return reading.layout;
    }
    return resolvePairLayout(
      reading.dataRows,
      reading.mapping,
      doubles: isDoubles,
    ).layout;
  }

  /// Dòng tiêu đề nằm trong vùng gộp ngang: các cột thường bị lệch.
  bool get headerMayBeShifted {
    final header = reading.headerRowIndex;
    if (header < 0) return false;
    final grid = reading.grid;
    for (final region in [...grid.mergedRegions, ...grid.horizontalMerges]) {
      final range = parseA1Range(region);
      if (range == null || range.endColumn <= range.startColumn) continue;
      if (range.startRow <= header && header <= range.endRow) return true;
    }
    return false;
  }

  /// [headerRowIndex] 0-based, kẹp vào hàng hợp lệ; ánh xạ cột dò lại như Web.
  RosterMappingDraft withHeaderRow(int headerRowIndex) {
    final rows = reading.grid.rows;
    if (rows.length < 2) return this;
    final header = headerRowIndex.clamp(0, rows.length - 2);
    final firstData = header + 1;
    final lastRow = reading.fromAi && firstData <= reading.lastRowIndex
        ? reading.lastRowIndex
        : rows.length - 1;
    final moved = reading.copyWith(
      headerRowIndex: header,
      firstDataRowIndex: firstData,
      lastRowIndex: lastRow,
    );
    final headers = rows[header];
    return _with(
      moved.copyWith(
        mapping: confirmRosterColumns(
          moved.dataRows,
          headers,
          detectRosterColumnMapping(headers),
        ),
      ),
    );
  }

  /// Ghép [column] vào [slot]; null đưa cột về Ghi chú. Cột khóa không đổi. Mỗi trường chỉ một cột:
  /// cột đang giữ trường đó tự về Ghi chú.
  RosterMappingDraft assign(int column, RosterSlot? slot) {
    final locked = columns.any(
      (c) => c.index == column && c.kind != RosterColumnKind.normal,
    );
    if (locked) return this;
    final next = Map<RosterSlot, int>.of(reading.mapping.columns)
      ..removeWhere((key, value) => value == column || key == slot);
    if (slot != null) next[slot] = column;
    var updated = reading.copyWith(mapping: RosterColumnMapping(next));
    final wantsPlayer2 =
        slot == RosterSlot.player2Name ||
        slot == RosterSlot.player2Email ||
        slot == RosterSlot.player2Phone;
    if (wantsPlayer2 && effectiveLayout == RosterPairLayout.single) {
      updated = updated.copyWith(
        layout: RosterPairLayout.columns,
        layoutChosen: true,
      );
    }
    return _with(updated);
  }

  RosterMappingDraft withLayout(RosterPairLayout layout, {String? separator}) =>
      _with(
        reading.copyWith(
          layout: layout,
          layoutChosen: true,
          separator: separator,
        ),
      );

  RosterMappingDraft _with(RosterReading next) =>
      RosterMappingDraft._(next, wasSkipped, _isDoublesFor);

  List<RosterMappingColumn> _buildColumns() {
    final rows = reading.grid.rows;
    if (rows.length < 2) return const [];
    final headers = reading.headers;
    final dataRows = reading.dataRows;
    final width = rows.fold<int>(
      headers.length,
      (m, r) => r.length > m ? r.length : m,
    );
    final slotOf = {
      for (final entry in reading.mapping.columns.entries)
        if (entry.key != RosterSlot.notes) entry.value: entry.key,
    };
    final mapped = reading.mapping.columns.values.toSet();
    final result = <RosterMappingColumn>[];
    for (var c = 0; c < width; c++) {
      final header = c < headers.length ? headers[c].trim() : '';
      final sample = _sampleOf(dataRows, c);
      final slot = slotOf[c];
      if (header.isEmpty && sample.isEmpty && !mapped.contains(c)) continue;
      result.add(
        RosterMappingColumn(
          index: c,
          header: header,
          sample: sample,
          kind: _kindOf(header, mapped.contains(c)),
          slot: slot,
        ),
      );
    }
    return result;
  }

  static RosterColumnKind _kindOf(String header, bool isMapped) {
    if (isMapped) return RosterColumnKind.normal;
    if (isRosterIndexHeader(header)) return RosterColumnKind.serial;
    if (isSensitiveRosterHeader(header)) return RosterColumnKind.sensitive;
    return RosterColumnKind.normal;
  }

  static String _sampleOf(List<List<String>> dataRows, int column) {
    for (final cells in dataRows) {
      final text = column < cells.length ? cells[column].trim() : '';
      if (text.isEmpty) continue;
      return text.length > _maxSampleLength
          ? text.substring(0, _maxSampleLength)
          : text;
    }
    return '';
  }

  static int _firstRowWithCells(List<List<String>> rows, int minCells) {
    for (var r = 0; r < rows.length; r++) {
      if (rows[r].where((c) => c.trim().isNotEmpty).length >= minCells) {
        return r;
      }
    }
    return 0;
  }
}
