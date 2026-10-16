// Parser danh sách VĐV từ sheet Excel. Thuần Dart, không phụ thuộc Flutter.
//
// Bám theo web: `ROSTER_COLUMN_ALIASES`, `matchRosterColumn`, `detectRosterSheetCandidates`
// (src/utils/exportTournament.ts) và quy tắc kiểm tra cục bộ trong `rosterImportDraft.ts`.
// Lỗi kiểm tra từ phía máy chủ (PLAYER2_REQUIRED, DUPLICATE_IN_FILE, ...) không có ở đây.

import 'package:app_quanly_giaidau/core/services/roster_excel_reader.dart';

/// Các cột của file danh sách VĐV mà app nhận diện.
enum RosterSlot {
  teamName,
  player1Name,
  player1Email,
  player1Phone,
  player2Name,
  player2Email,
  player2Phone,
  elo,
  isPaid,
  divisionName,
  notes,
}

/// Ánh xạ slot sang chỉ số cột (cột A = 0). Chỉ chứa các slot tìm thấy.
class RosterColumnMapping {
  const RosterColumnMapping(this.columns);

  final Map<RosterSlot, int> columns;

  int? indexOf(RosterSlot slot) => columns[slot];
}

/// Một dòng đã đọc từ sheet, kèm mã lỗi kiểm tra cục bộ.
class RosterParsedRow {
  const RosterParsedRow({
    required this.sheetName,
    required this.sourceRowIndex,
    required this.localErrors,
    this.divisionName,
    this.teamName,
    this.player1Name,
    this.player1Email,
    this.player1Phone,
    this.player2Name,
    this.player2Email,
    this.player2Phone,
    this.elo,
    this.isPaid,
    this.notes,
  });

  final String sheetName;

  /// Số dòng 1-based trong sheet, dùng để báo lỗi cho người tổ chức.
  final int sourceRowIndex;

  final String? divisionName;
  final String? teamName;
  final String? player1Name;
  final String? player1Email;
  final String? player1Phone;
  final String? player2Name;
  final String? player2Email;
  final String? player2Phone;
  final num? elo;
  final bool? isPaid;

  /// Ghi chú gốc của người nhập, web gửi vào `customResponses.notes`.
  final String? notes;

  /// Mã lỗi cục bộ: MISSING_NAME, MISSING_EMAIL, INVALID_EMAIL. Rỗng nghĩa là không có lỗi.
  final List<String> localErrors;
}

/// Số dòng header được quét từ đầu sheet (giống `ROSTER_HEADER_SCAN_ROWS` của web).
const int _headerScanRows = 10;

/// Giới hạn số dòng dữ liệu mỗi sheet (giống `MAX_ROSTER_ROWS_PER_SHEET` của web).
const int _maxRowsPerSheet = 5000;

/// Thứ tự gán cột theo `ROSTER_COLUMN_SLOTS` của web. Bỏ `entryType` vì backend bỏ qua
/// trường này (`roster-import.dto.ts`). `notes` đứng cuối nên wildcard của nó không cướp cột khác.
const List<RosterSlot> _slotPriority = [
  RosterSlot.teamName,
  RosterSlot.player1Name,
  RosterSlot.player1Email,
  RosterSlot.player1Phone,
  RosterSlot.player2Name,
  RosterSlot.player2Email,
  RosterSlot.player2Phone,
  RosterSlot.divisionName,
  RosterSlot.elo,
  RosterSlot.isPaid,
  RosterSlot.notes,
];

/// Alias của từng slot, giống `ROSTER_COLUMN_ALIASES` của web.
/// `!x` là cột không được chứa từ x; `*x*` khớp theo ranh giới từ.
const Map<RosterSlot, List<String>> _rosterAliases = {
  RosterSlot.teamName: [
    '*tên đội*',
    '*tên cặp*',
    '*tên cặp đôi*',
    '*tên clb*',
    '*tên nhóm*',
    '*team name*',
    '*đội',
    'đội*',
    '*team',
    'team*',
    '*clb',
    '*club',
  ],
  RosterSlot.player1Name: [
    '!2',
    'họ và tên vđv 1',
    'họ tên vđv 1',
    'tên vđv 1',
    'họ và tên 1',
    'player 1 name',
    'player 1 full name',
    '*player 1*',
    '*vđv 1*',
    'họ và tên',
    'họ tên',
    'full name',
    '*tên 1*',
    'tên',
  ],
  RosterSlot.player1Email: [
    '!2',
    'player 1 email',
    'email vđv 1',
    'email 1',
    'gmail 1',
    '*email vđv*',
    'địa chỉ email',
    '*email*',
    '*gmail*',
    'thư điện tử',
  ],
  RosterSlot.player1Phone: [
    '!2',
    'player 1 phone',
    'số điện thoại 1',
    'sdt 1',
    'điện thoại 1',
    'phone 1',
    'mobile 1',
    '*sđt*',
    '*sdt*',
    '*điện thoại*',
    '*phone*',
    '*mobile*',
    'zalo',
  ],
  RosterSlot.player2Name: [
    '!1',
    'họ và tên vđv 2',
    'họ tên vđv 2',
    'tên vđv 2',
    'họ và tên 2',
    'player 2 name',
    'player 2 full name',
    '*player 2*',
    '*vđv 2*',
    'đồng đội',
    '*partner*',
    '*teammate*',
  ],
  RosterSlot.player2Email: [
    '!1',
    'player 2 email',
    'email vđv 2',
    'email 2',
    'gmail 2',
    'email đồng đội',
    'gmail đồng đội',
    'email partner',
    'email teammate',
  ],
  RosterSlot.player2Phone: [
    '!1',
    'player 2 phone',
    'số điện thoại 2',
    'sdt 2',
    'điện thoại 2',
    'phone 2',
    'mobile 2',
    'sđt vđv 2',
    'số điện thoại vđv 2',
    'điện thoại vđv 2',
    'sđt đồng đội',
    'số điện thoại đồng đội',
  ],
  RosterSlot.divisionName: [
    'nội dung thi',
    'nội dung đăng ký',
    'nội dung',
    'registration format',
    'bảng đấu',
    'hạng mục',
    '*division*',
    '*category*',
    'thể thức',
    '*nhóm thi*',
  ],
  RosterSlot.elo: [
    'điểm elo',
    'elo',
    'điểm trình',
    'trình độ',
    '*dupr*',
    '*rating*',
    'điểm',
    '*rank*',
    '*level*',
  ],
  RosterSlot.isPaid: [
    '!chua',
    'đã đóng lệ phí',
    'lệ phí',
    'đã đóng phí',
    'đã nộp phí',
    '*entry fee paid*',
    'đã thanh toán',
    '*paid*',
    '*thanh toán*',
  ],
  RosterSlot.notes: [
    'ghi chú',
    '*notes*',
    '*note*',
    '*comment*',
    'ý kiến',
  ],
};

/// Chữ có dấu tiếng Việt và vài chữ Latin thường gặp, quy về chữ cái gốc.
const Map<String, String> _baseLetters = {
  'a': 'àáảãạăằắẳẵặâầấẩẫậäå',
  'e': 'èéẻẽẹêềếểễệë',
  'i': 'ìíỉĩịîï',
  'o': 'òóỏõọôồốổỗộơờớởỡợöø',
  'u': 'ùúủũụưừứửữựûü',
  'y': 'ỳýỷỹỵÿ',
  'd': 'đ',
  'c': 'ç',
  'n': 'ñ',
};

final Map<String, String> _foldMap = {
  for (final entry in _baseLetters.entries)
    for (final rune in entry.value.runes) String.fromCharCode(rune): entry.key,
};

/// Chuẩn hóa header như `normalizeHeader` của web: bỏ dấu, chữ thường, gộp khoảng trắng.
String _normalizeHeader(String value) {
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    // Dấu tổ hợp U+0300..U+036F bị bỏ, tương ứng với web `[\u0300-\u036f]`.
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    final char = String.fromCharCode(rune);
    buffer.write(_foldMap[char] ?? char);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

Set<String> _tokensOf(String key) => key
    .split(RegExp(r'[^a-z0-9]+'))
    .where((token) => token.isNotEmpty)
    .toSet();

class _HeaderCandidate {
  _HeaderCandidate(this.index, this.key) : tokens = _tokensOf(key);

  final int index;
  final String key;
  final Set<String> tokens;
}

/// Alias có `*`: `*x` chỉ khớp đầu, `x*` chỉ khớp cuối, `*x*` khớp theo ranh giới từ.
class _EdgePattern {
  _EdgePattern(String alias)
    : target = _normalizeHeader(alias.replaceAll('*', '')),
      leading = alias.startsWith('*') && !alias.endsWith('*'),
      trailing = alias.endsWith('*') && !alias.startsWith('*');

  final String target;
  final bool leading;
  final bool trailing;

  bool matches(_HeaderCandidate candidate) {
    if (candidate.key == target) return true;
    final starts = candidate.key.startsWith('$target ');
    final ends = candidate.key.endsWith(' $target');
    if (leading) return starts;
    if (trailing) return ends;
    return starts || ends || candidate.tokens.contains(target);
  }
}

/// Tìm cột đầu tiên khớp slot trong [pool]. Thứ tự: khớp đúng, rồi ranh giới từ, rồi chứa chuỗi.
int? _matchSlot(RosterSlot slot, List<_HeaderCandidate> pool) {
  final aliases = _rosterAliases[slot]!;
  final guards = [
    for (final alias in aliases)
      if (alias.startsWith('!')) _tokensOf(_normalizeHeader(alias.substring(1))),
  ];
  final eligible = [
    for (final candidate in pool)
      if (guards.every(
        (guard) => guard.every((token) => !candidate.tokens.contains(token)),
      ))
        candidate,
  ];

  final patterns = aliases.where((alias) => !alias.startsWith('!')).toList();
  final loose = [
    for (final alias in patterns)
      if (!alias.contains('*')) _normalizeHeader(alias),
  ];
  final edges = [
    for (final alias in patterns)
      if (alias.contains('*')) _EdgePattern(alias),
  ];

  for (final target in loose) {
    for (final candidate in eligible) {
      if (candidate.key == target) return candidate.index;
    }
  }
  for (final edge in edges) {
    for (final candidate in eligible) {
      if (edge.matches(candidate)) return candidate.index;
    }
  }
  for (final target in loose) {
    for (final candidate in eligible) {
      if (candidate.key.contains(target)) return candidate.index;
    }
  }
  return null;
}

/// Ánh xạ các slot sang cột từ một dòng header. Mỗi cột chỉ gán cho một slot.
RosterColumnMapping detectRosterColumnMapping(List<String> headers) {
  final pool = <_HeaderCandidate>[];
  for (var i = 0; i < headers.length; i++) {
    final key = _normalizeHeader(headers[i]);
    if (key.isNotEmpty) pool.add(_HeaderCandidate(i, key));
  }

  final columns = <RosterSlot, int>{};
  final used = <int>{};
  for (final slot in _slotPriority) {
    final free = [
      for (final candidate in pool)
        if (!used.contains(candidate.index)) candidate,
    ];
    final index = _matchSlot(slot, free);
    if (index != null) {
      columns[slot] = index;
      used.add(index);
    }
  }
  return RosterColumnMapping(columns);
}

/// Dòng header trong 10 dòng đầu, chọn dòng khớp nhiều slot nhất và phải có tên VĐV 1.
/// Trả null nếu không có dòng nào thỏa. Hòa thì lấy dòng đứng trước.
int? detectRosterHeaderRow(RosterGridSheet sheet) {
  final scanEnd = sheet.rows.length < _headerScanRows
      ? sheet.rows.length
      : _headerScanRows;
  int? bestRow;
  var bestHits = 0;
  for (var r = 0; r < scanEnd; r++) {
    final cells = sheet.rows[r];
    final filled = cells.where((cell) => cell.trim().isNotEmpty).length;
    // Dòng một ô là banner hoặc nhãn lẻ, không phải header (web: headers.length < 2).
    if (filled < 2) continue;
    final mapping = detectRosterColumnMapping(cells);
    if (mapping.indexOf(RosterSlot.player1Name) == null) continue;
    if (mapping.columns.length > bestHits) {
      bestHits = mapping.columns.length;
      bestRow = r;
    }
  }
  return bestRow;
}

final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Số kiểu `1.250` hoặc `1,250` (dấu nghìn), chỉ khi các nhóm sau dấu đều đủ 3 chữ số.
final RegExp _thousandsElo = RegExp(r'^\d{1,3}([.,\s]\d{3})+$');

/// Số thập phân dùng dấu chấm hoặc phẩy, ví dụ `6.5` hoặc `6,5`.
final RegExp _decimalElo = RegExp(r'^\d+([.,]\d+)?$');

/// Giá trị đã chuẩn hóa được coi là "đã đóng" (giống `PAID_TRUE` của web).
const Set<String> _paidYes = {
  'yes',
  'true',
  'paid',
  '1',
  'co',
  'roi',
  'da dong',
  'da nop',
  'da thanh toan',
};

/// Giá trị đã chuẩn hóa được coi là "chưa đóng" (giống `PAID_FALSE` của web).
const Set<String> _paidNo = {
  'no',
  'false',
  'unpaid',
  '0',
  'chua',
  'khong',
  'chua dong',
  'chua nop',
};

num? _parseElo(String text) {
  if (_thousandsElo.hasMatch(text)) {
    return int.parse(text.replaceAll(RegExp(r'[.,\s]'), ''));
  }
  if (!_decimalElo.hasMatch(text)) return null;
  return double.parse(text.replaceAll(',', '.'));
}

bool? _parsePaid(String text) {
  final key = _normalizeHeader(text);
  if (_paidYes.contains(key)) return true;
  if (_paidNo.contains(key)) return false;
  return null;
}

/// Lỗi cục bộ của một dòng, cùng quy tắc với `revalidateLocally` của web.
List<String> _localErrors({
  required String? name,
  required String? email,
  required String? player2Email,
}) {
  final errors = <String>[];
  void add(String code) {
    if (!errors.contains(code)) errors.add(code);
  }

  if (name == null && email == null) add('MISSING_NAME');
  if (email == null) {
    add('MISSING_EMAIL');
  } else if (!_emailPattern.hasMatch(email.toLowerCase())) {
    add('INVALID_EMAIL');
  }
  if (player2Email != null &&
      !_emailPattern.hasMatch(player2Email.toLowerCase())) {
    add('INVALID_EMAIL');
  }
  return List.unmodifiable(errors);
}

/// Đọc các dòng dữ liệu nằm dưới [headerRowIndex] (0-based). Dòng trống và dòng phía trên bị bỏ.
List<RosterParsedRow> parseRosterSheet(
  RosterGridSheet sheet, {
  required int headerRowIndex,
  required RosterColumnMapping mapping,
}) {
  final parsed = <RosterParsedRow>[];
  for (var r = headerRowIndex + 1; r < sheet.rows.length; r++) {
    if (parsed.length >= _maxRowsPerSheet) break;
    final cells = sheet.rows[r];

    String? read(RosterSlot slot) {
      final column = mapping.indexOf(slot);
      if (column == null || column >= cells.length) return null;
      final text = cells[column].trim();
      return text.isEmpty ? null : text;
    }

    final teamName = read(RosterSlot.teamName);
    final player1Name = read(RosterSlot.player1Name);
    final player1Email = read(RosterSlot.player1Email);
    final player1Phone = read(RosterSlot.player1Phone);
    final player2Name = read(RosterSlot.player2Name);
    final player2Email = read(RosterSlot.player2Email);
    final player2Phone = read(RosterSlot.player2Phone);
    final eloText = read(RosterSlot.elo);
    final paidText = read(RosterSlot.isPaid);
    final divisionName = read(RosterSlot.divisionName);
    final notes = read(RosterSlot.notes);

    // Cùng quy tắc bỏ dòng với web (buildRosterDraftRows): không có tên, đội, email hay SĐT thì bỏ.
    final hasIdentity =
        teamName != null ||
        player1Name != null ||
        player1Email != null ||
        player1Phone != null ||
        player2Name != null ||
        player2Phone != null;
    if (!hasIdentity) continue;

    parsed.add(
      RosterParsedRow(
        sheetName: sheet.name,
        sourceRowIndex: r + 1,
        divisionName: divisionName,
        teamName: teamName,
        player1Name: player1Name,
        player1Email: player1Email,
        player1Phone: player1Phone,
        player2Name: player2Name,
        player2Email: player2Email,
        player2Phone: player2Phone,
        elo: eloText == null ? null : _parseElo(eloText),
        isPaid: paidText == null ? null : _parsePaid(paidText),
        notes: notes,
        localErrors: _localErrors(
          name: player1Name,
          email: player1Email,
          player2Email: player2Email,
        ),
      ),
    );
  }
  return parsed;
}
