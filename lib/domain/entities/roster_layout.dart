/// Hợp đồng AI layout cho nhập Excel: `POST /ai/tournaments/:id/roster-layout`.
/// Khớp `RosterLayout*` trong web `src/features/tournaments/api.ts` và DTO Backend `roster-layout.dto.ts`.
/// App chỉ gửi bản tóm tắt đã che dữ liệu cá nhân và nhận lại bố cục, không bao giờ nhận giá trị VĐV.
library;

/// Slot cột AI có thể gán, đúng tên slot của web/Backend.
const List<String> rosterLayoutSlotNames = [
  'pairCode',
  'teamName',
  'player1Name',
  'player1Email',
  'player1Phone',
  'player2Name',
  'player2Email',
  'player2Phone',
  'divisionName',
  'isPaid',
  'elo',
  'notes',
];

const Set<String> _pairLayouts = {
  'SINGLE',
  'COLUMNS',
  'SAME_CELL',
  'CONSECUTIVE_ROWS',
};

/// Một khối VĐV trong sheet: hàng header, hàng dữ liệu, cột theo chữ cái và cách ghép đôi.
class RosterLayoutBlock {
  const RosterLayoutBlock({
    required this.divisionLabel,
    required this.headerRow,
    required this.firstDataRow,
    required this.lastDataRow,
    required this.columns,
    required this.pairLayout,
    required this.pairSeparator,
    this.singlesFromRow,
  });

  final String divisionLabel;

  /// Số dòng 1-based của header; 0 khi khối không có dòng header.
  final int headerRow;
  final int firstDataRow;
  final int lastDataRow;

  /// Chữ cái cột cho từng slot (`A`, `AB`), '' khi file không có cột đó.
  final Map<String, String> columns;
  final String pairLayout;
  final String pairSeparator;

  /// Dòng 1-based của VĐV lẻ đầu tiên chờ ghép (danh sách `chưa có cặp`); null khi không có.
  final int? singlesFromRow;

  factory RosterLayoutBlock.fromJson(Map<String, dynamic> json) {
    final rawColumns = json['columns'];
    final columns = <String, String>{
      for (final slot in rosterLayoutSlotNames)
        slot: rawColumns is Map && rawColumns[slot] is String
            ? rawColumns[slot] as String
            : '',
    };
    final layout = json['pairLayout'];
    final singles = json['singlesFromRow'];
    return RosterLayoutBlock(
      divisionLabel: json['divisionLabel'] is String
          ? json['divisionLabel'] as String
          : '',
      headerRow: _int(json['headerRow']),
      firstDataRow: _int(json['firstDataRow']),
      lastDataRow: _int(json['lastDataRow']),
      columns: columns,
      pairLayout: layout is String && _pairLayouts.contains(layout)
          ? layout
          : 'SINGLE',
      pairSeparator: json['pairSeparator'] is String
          ? json['pairSeparator'] as String
          : '',
      singlesFromRow: singles is int && singles > 0 ? singles : null,
    );
  }
}

class RosterLayoutSheet {
  const RosterLayoutSheet({
    required this.sheetName,
    required this.kind,
    required this.blocks,
  });

  /// Tên digest (`S1`, `S2`...) hoặc tên thật của sheet.
  final String sheetName;

  /// `ROSTER`, `BRACKET`, `SCHEDULE` hoặc `OTHER`.
  final String kind;
  final List<RosterLayoutBlock> blocks;

  factory RosterLayoutSheet.fromJson(Map<String, dynamic> json) {
    final blocks = json['blocks'];
    return RosterLayoutSheet(
      sheetName: json['sheetName'] is String ? json['sheetName'] as String : '',
      kind: json['kind'] is String ? json['kind'] as String : 'OTHER',
      blocks: blocks is List
          ? [
              for (final block in blocks)
                if (block is Map)
                  RosterLayoutBlock.fromJson(Map<String, dynamic>.from(block)),
            ]
          : const [],
    );
  }
}

class RosterLayout {
  const RosterLayout({required this.sheets, required this.notes});

  final List<RosterLayoutSheet> sheets;
  final List<String> notes;

  factory RosterLayout.fromJson(Map<String, dynamic> json) {
    final sheets = json['sheets'];
    final notes = json['notes'];
    return RosterLayout(
      sheets: sheets is List
          ? [
              for (final sheet in sheets)
                if (sheet is Map)
                  RosterLayoutSheet.fromJson(Map<String, dynamic>.from(sheet)),
            ]
          : const [],
      notes: notes is List ? [for (final n in notes) n.toString()] : const [],
    );
  }
}

/// Câu trả lời của server. `aiAvailable: false` đi với `layout: null`: không có model, không có lỗi.
class RosterLayoutResponse {
  const RosterLayoutResponse({required this.aiAvailable, required this.layout});

  final bool aiAvailable;
  final RosterLayout? layout;

  factory RosterLayoutResponse.fromJson(Map<String, dynamic> json) {
    final layout = json['layout'];
    return RosterLayoutResponse(
      aiAvailable: json['aiAvailable'] == true,
      layout: layout is Map
          ? RosterLayout.fromJson(Map<String, dynamic>.from(layout))
          : null,
    );
  }
}

int _int(Object? value) =>
    value is int ? value : (value is num ? value.toInt() : 0);
