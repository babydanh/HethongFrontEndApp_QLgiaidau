// Bản nháp ghép cột của popup "Ghép cột": giá trị bất biến, mỗi thao tác trả bản mới. Thuần Dart.
//
// Port của `handleMappingChange` / `handleHeaderRowChange` ở web (RosterImportModal.tsx).

import 'package:app_quanly_giaidau/core/services/roster_excel_reader.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_layout.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_pairing.dart';

/// Loại cột trong popup: cột khóa không đổi được và không bao giờ vào dữ liệu.
enum RosterColumnKind { normal, serial, sensitive }

/// Độ dài tối đa của ô mẫu hiện trong popup.
const int _maxSampleLength = 40;

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

  /// Rỗng khi ô tiêu đề trống: giao diện hiện chữ cột.
  final String header;

  /// Giá trị không trống đầu tiên bên dưới dòng tiêu đề, cắt 40 ký tự.
  final String sample;
  final RosterColumnKind kind;

  /// `null` nghĩa là cột đi vào Ghi chú.
  final RosterSlot? slot;
}

/// Kết quả của popup: các khối đọc được và các sheet vẫn chưa đọc được.
class RosterMappingResult {
  const RosterMappingResult({
    required this.readings,
    required this.skippedSheets,
  });

  /// Sheet bị bỏ qua mà đã đủ nhận diện thì thành khối đọc được, còn lại vẫn là sheet bị bỏ qua.
  factory RosterMappingResult.fromDrafts(List<RosterMappingDraft> drafts) {
    final readings = <RosterReading>[];
    final skipped = <String>[];
    for (final draft in drafts) {
      if (draft.wasSkipped && !draft.hasIdentity) {
        skipped.add(draft.reading.sheetName);
      } else {
        readings.add(draft.reading);
      }
    }
    return RosterMappingResult(
      readings: List.unmodifiable(readings),
      skippedSheets: List.unmodifiable(skipped),
    );
  }

  final List<RosterReading> readings;
  final List<String> skippedSheets;
}

class RosterMappingDraft {
  const RosterMappingDraft._(
    this.reading,
    this._isDoublesFor, {
    required this.wasSkipped,
  });

  factory RosterMappingDraft.fromReading(
    RosterReading reading, {
    required bool Function(String? divisionName) isDoublesFor,
  }) => RosterMappingDraft._(reading, isDoublesFor, wasSkipped: false);

  /// Sheet bị bỏ qua: hàng tiêu đề mặc định là dòng đầu có từ hai ô trở lên (hoặc dòng đầu).
  factory RosterMappingDraft.forSkippedSheet(
    RosterGridSheet grid, {
    required bool Function(String? divisionName) isDoublesFor,
  }) {
    final filled = fillRosterMerges(grid);
    if (filled.rows.length < 2) {
      return RosterMappingDraft._(
        RosterReading(
          grid: filled,
          headerRowIndex: -1,
          firstDataRowIndex: 0,
          lastRowIndex: filled.rows.length - 1,
          mapping: const RosterColumnMapping({}),
          fromAi: false,
        ),
        isDoublesFor,
        wasSkipped: true,
      );
    }
    final headerRow = _firstRowWithTwoCells(filled.rows);
    final reading = RosterReading(
      grid: filled,
      headerRowIndex: headerRow,
      firstDataRowIndex: headerRow + 1,
      lastRowIndex: filled.rows.length - 1,
      mapping: const RosterColumnMapping({}),
      fromAi: false,
    );
    return RosterMappingDraft._(
      reading.copyWith(mapping: _detectMapping(reading, headerRow)),
      isDoublesFor,
      wasSkipped: true,
    );
  }

  final RosterReading reading;
  final bool wasSkipped;
  final bool Function(String? divisionName) _isDoublesFor;

  RosterMappingDraft _with(RosterReading next) =>
      RosterMappingDraft._(next, _isDoublesFor, wasSkipped: wasSkipped);

  List<RosterMappingColumn> get columns {
    final rows = reading.grid.rows;
    if (rows.length < 2) return const [];
    final headers = reading.headers;
    final dataRows = reading.dataRows;
    final width = rows.fold<int>(
      headers.length,
      (max, row) => row.length > max ? row.length : max,
    );
    final slotOf = {
      for (final entry in reading.mapping.columns.entries)
        entry.value: entry.key,
    };
    return List.unmodifiable([
      for (var c = 0; c < width; c++)
        _columnAt(c, headers, dataRows, slotOf[c]),
    ]);
  }

  RosterMappingColumn _columnAt(
    int column,
    List<String> headers,
    List<List<String>> dataRows,
    RosterSlot? slot,
  ) {
    final header = column < headers.length ? headers[column].trim() : '';
    final kind = slot != null
        ? RosterColumnKind.normal
        : isRosterIndexHeader(header)
        ? RosterColumnKind.serial
        : isSensitiveRosterHeader(header)
        ? RosterColumnKind.sensitive
        : RosterColumnKind.normal;
    var sample = '';
    for (final cells in dataRows) {
      final value = column < cells.length ? cells[column].trim() : '';
      if (value.isEmpty) continue;
      sample = value.length > _maxSampleLength
          ? value.substring(0, _maxSampleLength)
          : value;
      break;
    }
    return RosterMappingColumn(
      index: column,
      header: header,
      sample: sample,
      kind: kind,
      slot: slot,
    );
  }

  /// Có dòng nào thuộc nội dung đôi.
  bool get isDoubles =>
      reading.parse(reading.mapping).any((r) => _isDoublesFor(r.divisionName));

  /// Cách ghép đang áp dụng: cái người dùng chọn, hoặc cái luật suy ra.
  RosterPairLayout get effectiveLayout {
    if (reading.layoutChosen) return reading.layout;
    if (reading.layout != RosterPairLayout.single) return reading.layout;
    return resolvePairLayout(
      reading.dataRows,
      reading.mapping,
      doubles: isDoubles,
    ).layout;
  }

  bool get hasIdentity =>
      reading.mapping.indexOf(RosterSlot.player1Name) != null ||
      reading.mapping.indexOf(RosterSlot.teamName) != null ||
      reading.mapping.indexOf(RosterSlot.player1Email) != null;

  int get rowCount => assembleRosterRows(reading, _isDoublesFor).length;

  /// Dòng tiêu đề nằm trong vùng gộp ngang: các cột có thể bị lệch.
  bool get headerMayBeShifted {
    final header = reading.headerRowIndex;
    if (header < 0) return false;
    return [
      ...reading.grid.mergedRegions,
      ...reading.grid.horizontalMerges,
    ].any((region) {
      final range = parseA1Range(region);
      return range != null &&
          range.startRow <= header &&
          header <= range.endRow &&
          range.endColumn > range.startColumn;
    });
  }

  /// [headerRowIndex] 0-based, kẹp vào [0, số dòng - 2].
  RosterMappingDraft withHeaderRow(int headerRowIndex) {
    final rows = reading.grid.rows;
    if (rows.length < 2) return this;
    final header = headerRowIndex.clamp(0, rows.length - 2);
    final last = reading.fromAi && header + 1 <= reading.lastRowIndex
        ? reading.lastRowIndex
        : rows.length - 1;
    final next = reading.copyWith(
      headerRowIndex: header,
      firstDataRowIndex: header + 1,
      lastRowIndex: last,
    );
    return _with(next.copyWith(mapping: _detectMapping(next, header)));
  }

  /// Gán [slot] cho [column]; `null` gỡ cột khỏi mọi slot (cột đi vào Ghi chú).
  RosterMappingDraft assign(int column, RosterSlot? slot) {
    final target = columns.where((c) => c.index == column).firstOrNull;
    if (target == null || target.kind != RosterColumnKind.normal) return this;
    final next = Map<RosterSlot, int>.of(reading.mapping.columns)
      ..removeWhere((key, value) => value == column || key == slot);
    if (slot != null) next[slot] = column;
    var updated = reading.copyWith(mapping: RosterColumnMapping(next));
    final player2 =
        slot == RosterSlot.player2Name ||
        slot == RosterSlot.player2Email ||
        slot == RosterSlot.player2Phone;
    if (player2 && effectiveLayout == RosterPairLayout.single) {
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
}

int _firstRowWithTwoCells(List<List<String>> rows) {
  for (var r = 0; r < rows.length; r++) {
    if (rows[r].where((cell) => cell.trim().isNotEmpty).length >= 2) return r;
  }
  return 0;
}

RosterColumnMapping _detectMapping(RosterReading reading, int headerRow) =>
    confirmRosterColumns(
      reading.grid.rows.sublist(
        headerRow + 1,
        (reading.lastRowIndex + 1).clamp(
          headerRow + 1,
          reading.grid.rows.length,
        ),
      ),
      reading.grid.rows[headerRow],
      detectRosterColumnMapping(reading.grid.rows[headerRow]),
    );
