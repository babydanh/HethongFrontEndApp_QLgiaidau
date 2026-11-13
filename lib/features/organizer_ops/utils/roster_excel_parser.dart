// Parser danh sách VĐV từ sheet Excel. Thuần Dart, không phụ thuộc Flutter.
//
// Bám theo web: `ROSTER_COLUMN_ALIASES`, `matchRosterColumn`, `detectRosterSheetCandidates`
// (src/utils/exportTournament.ts) và quy tắc kiểm tra cục bộ trong `rosterImportDraft.ts`.
// Lỗi kiểm tra từ phía máy chủ (PLAYER2_REQUIRED, DUPLICATE_IN_FILE, ...) không có ở đây.
//
// Ghép cặp (STT gộp, phần VĐV lẻ, gợi ý đồng đội) nằm ở `roster_pairing.dart`; guard và AI layout ở
// `roster_layout.dart`.

import 'package:app_quanly_giaidau/core/services/roster_excel_reader.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_pairing.dart';

/// Các cột của file danh sách VĐV mà app nhận diện.
enum RosterSlot {
  pairCode,
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

/// Một dòng đã đọc từ sheet, kèm mã lỗi kiểm tra cục bộ. Bất biến: ghép cặp trả về bản sao.
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
    this.eloSource,
    this.isPaid = false,
    this.notes,
    this.fileIndex = '',
    this.pairCode,
    this.pairCodeSize,
    this.singles = false,
    this.partnerHint,
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

  /// Điểm của VĐV (cặp mang điểm trung bình); null khi không đọc được số.
  final num? elo;

  /// Thang của điểm: `ELO` (100–3000) hoặc `DUPR` (2–8); null khi không có điểm.
  final String? eloSource;

  /// Đã thanh toán theo file. Mặc định chưa: file không xác nhận thì không ai được đánh dấu.
  final bool isPaid;

  /// Ghi chú gốc của người nhập, web gửi vào `customResponses.notes`.
  final String? notes;

  /// Số thứ tự của file (cột STT), '' khi sheet không có. Không phải dữ liệu VĐV.
  final String fileIndex;

  /// Mã cặp của file, mã kế thừa từ ô gộp, hoặc mã suy từ STT/gợi ý (`stt:…`, `hint:…`).
  final String? pairCode;

  /// Số dòng của nhóm mã khi khác hai: giao diện cảnh báo cặp chưa đủ.
  final int? pairCodeSize;

  /// Dòng thuộc danh sách VĐV chưa có cặp: không bao giờ ghép theo STT hay vị trí.
  final bool singles;

  /// Chữ ở cột gợi ý đồng đội: chỉ là manh mối ghép, không phải tên VĐV.
  final String? partnerHint;

  /// Mã lỗi cục bộ: MISSING_NAME, MISSING_EMAIL, INVALID_EMAIL. Rỗng nghĩa là không có lỗi.
  final List<String> localErrors;

  /// Dòng này đã có VĐV 2 (từ cột, ô chung hoặc ghép cặp).
  bool get hasPlayer2 =>
      player2Name != null || player2Email != null || player2Phone != null;

  RosterParsedRow copyWith({
    String? teamName,
    bool clearTeamName = false,
    String? player1Name,
    String? player1Email,
    String? player1Phone,
    String? player2Name,
    bool clearPlayer2Name = false,
    String? player2Email,
    bool clearPlayer2Email = false,
    String? player2Phone,
    bool clearPlayer2Phone = false,
    num? elo,
    bool clearElo = false,
    String? eloSource,
    bool? isPaid,
    String? notes,
    bool clearNotes = false,
    String? pairCode,
    int? pairCodeSize,
    List<String>? localErrors,
  }) {
    return RosterParsedRow(
      sheetName: sheetName,
      sourceRowIndex: sourceRowIndex,
      localErrors: localErrors ?? this.localErrors,
      divisionName: divisionName,
      teamName: clearTeamName ? null : (teamName ?? this.teamName),
      player1Name: player1Name ?? this.player1Name,
      player1Email: player1Email ?? this.player1Email,
      player1Phone: player1Phone ?? this.player1Phone,
      player2Name: clearPlayer2Name ? null : (player2Name ?? this.player2Name),
      player2Email: clearPlayer2Email
          ? null
          : (player2Email ?? this.player2Email),
      player2Phone: clearPlayer2Phone
          ? null
          : (player2Phone ?? this.player2Phone),
      elo: clearElo ? null : (elo ?? this.elo),
      eloSource: clearElo ? null : (eloSource ?? this.eloSource),
      isPaid: isPaid ?? this.isPaid,
      notes: clearNotes ? null : (notes ?? this.notes),
      fileIndex: fileIndex,
      pairCode: pairCode ?? this.pairCode,
      pairCodeSize: pairCodeSize ?? this.pairCodeSize,
      singles: singles,
      partnerHint: partnerHint,
    );
  }
}

/// Số dòng header được quét từ đầu sheet (giống `ROSTER_HEADER_SCAN_ROWS` của web).
const int _headerScanRows = 10;

/// Giới hạn số dòng dữ liệu mỗi sheet (giống `MAX_ROSTER_ROWS_PER_SHEET` của web).
const int _maxRowsPerSheet = 5000;

/// Thứ tự gán cột theo `ROSTER_COLUMN_SLOTS` của web. Bỏ `entryType` vì backend bỏ qua
/// trường này (`roster-import.dto.ts`). `notes` đứng cuối nên wildcard của nó không cướp cột khác.
const List<RosterSlot> _slotPriority = [
  RosterSlot.pairCode,
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
  RosterSlot.pairCode: [
    'mã cặp',
    'số cặp',
    'cặp số',
    'stt cặp',
    'đôi số',
    'số đôi',
    'team no',
    'team number',
    'pair no',
    'pair number',
    'pair id',
    'pair #',
    'doubles pair',
    '*cặp',
    '*pair*',
  ],
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
    'số điện thoại liên hệ',
    'sđt liên hệ',
    'điện thoại liên hệ',
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
    'trình điểm',
    'trình độ',
    '*trình',
    '*dupr*',
    '*rating*',
    'điểm',
    '*rank*',
    '*level*',
  ],
  RosterSlot.isPaid: [
    '!chua',
    'đã đóng lệ phí',
    'xác nhận btc',
    'btc xác nhận',
    'lệ phí',
    'đã đóng phí',
    'đóng phí',
    'đã nộp phí',
    'đã đóng',
    'chuyển khoản',
    'thanh toán',
    'đã thanh toán',
    '*entry fee paid*',
    '*paid*',
    '*payment*',
    '*thanh toán*',
    '*xác nhận*',
    '*ck*',
    '*phí*',
  ],
  RosterSlot.notes: ['ghi chú', '*notes*', '*note*', '*comment*', 'ý kiến'],
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
String normalizeRosterHeader(String value) {
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    // Dấu tổ hợp U+0300..U+036F bị bỏ, tương ứng với web `[\u0300-\u036f]`.
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    final char = String.fromCharCode(rune);
    buffer.write(_foldMap[char] ?? char);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

Set<String> _tokensOf(String key) =>
    key.split(RegExp(r'[^a-z0-9]+')).where((token) => token.isNotEmpty).toSet();

class _HeaderCandidate {
  _HeaderCandidate(this.index, this.key) : tokens = _tokensOf(key);

  final int index;
  final String key;
  final Set<String> tokens;
}

/// Alias có `*`: `*x` chỉ khớp đầu, `x*` chỉ khớp cuối, `*x*` khớp theo ranh giới từ.
class _EdgePattern {
  _EdgePattern(String alias)
    : target = normalizeRosterHeader(alias.replaceAll('*', '')),
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
      if (alias.startsWith('!'))
        _tokensOf(normalizeRosterHeader(alias.substring(1))),
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
      if (!alias.contains('*')) normalizeRosterHeader(alias),
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
    final key = normalizeRosterHeader(headers[i]);
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

/// Số đầu tiên trong chữ tự do (`620 Robinson , 625-630 CCTV` cho 620).
final RegExp _firstNumber = RegExp(r'\d+(?:[.,]\d+)?');

/// Ô chỉ là một số: chữ của ô không cần ghi chú khi số đã đọc được.
final RegExp _bareNumber = RegExp(r'^\d+(?:[.,]\d+)?$');

/// Giá trị đã chuẩn hóa được coi là "đã đóng" (giống `PAID_TRUE` của web).
const Set<String> _paidYes = {
  'yes',
  'true',
  'paid',
  '1',
  'x',
  'v',
  'ok',
  'co',
  'roi',
  'da',
  '✓',
  '✔',
  '✅',
  'da dong',
  'da nop',
  'da thanh toan',
  'da ck',
  'da chuyen khoan',
  'da dong phi',
  'da nop phi',
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

/// Số tiền: chữ số với dấu `.`/`,` ngăn nhóm và đơn vị tùy chọn (`500000`, `500.000đ`, `300k`).
final RegExp _moneyAmount = RegExp(r'^\d[\d.,\s]*(?:k|tr|d|vnd|vnđ|đ)?$');

/// Điểm trong một ô: số đầu tiên từ 2.0 đến 8.0 là DUPR, từ 100 đến 999 là ELO. Ô chỉ có số nghìn
/// (`1.250`, `1250`) là ELO đến 3000. Không có số hợp lệ thì trả null và người gọi giữ chữ làm ghi chú.
({num value, String source})? parseRosterScore(String text) {
  final trimmed = text.trim();
  if (_thousandsElo.hasMatch(trimmed)) {
    final value = int.parse(trimmed.replaceAll(RegExp(r'[.,\s]'), ''));
    return value >= 100 && value <= 3000 ? (value: value, source: 'ELO') : null;
  }
  final match = _firstNumber.firstMatch(trimmed);
  if (match == null) return null;
  final value = double.tryParse(match.group(0)!.replaceAll(',', '.'));
  if (value == null) return null;
  final isInteger = value == value.roundToDouble();
  if (isInteger && value >= 100 && value <= 999) {
    return (value: value.round(), source: 'ELO');
  }
  // Một số trần 1000–3000 (`1250`) là ELO; trong chữ tự do thì không đủ chắc.
  if (isInteger &&
      value >= 1000 &&
      value <= 3000 &&
      _bareNumber.hasMatch(trimmed)) {
    return (value: value.round(), source: 'ELO');
  }
  if (value >= 2 && value <= 8) return (value: value, source: 'DUPR');
  return null;
}

/// Dấu thanh toán của một ô: `x`, `✓`, `đã ck`, `paid`, `1` và số tiền lớn hơn 0 là đã trả; `chưa`,
/// `không`, `no`, `0` là chưa. Chữ khác (hoặc trống) giữ [fallback]: nhập từ file dùng false.
bool parseRosterPaid(String text, {bool fallback = false}) {
  final key = normalizeRosterHeader(text);
  if (_paidYes.contains(key)) return true;
  if (_paidNo.contains(key)) return false;
  if (key.isEmpty) return fallback;
  if (_moneyAmount.hasMatch(key)) {
    final amount = int.tryParse(key.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    if (amount > 0) return true;
  }
  return fallback;
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

/// Header là số thứ tự của file, không phải dữ liệu VĐV (so sau `normalizeRosterHeader`).
const Set<String> _indexHeaders = {
  'stt',
  'tt',
  'so tt',
  'so thu tu',
  'no',
  'no.',
  '#',
};

/// Dữ liệu cá nhân không bao giờ giữ, kể cả làm ghi chú: ngày sinh, giấy tờ, địa chỉ.
const List<String> _sensitiveHeaderWords = [
  'ngay sinh',
  'nam sinh',
  'sinh nhat',
  'dob',
  'birth',
  'cccd',
  'cmnd',
  'can cuoc',
  'chung minh',
  'dinh danh',
  'ho chieu',
  'passport',
  'giay to',
  'id number',
  'id card',
  'national id',
  'identity',
  'citizen',
  'dia chi',
  'address',
  'noi o',
  'thuong tru',
  'tam tru',
  'que quan',
  'ma so thue',
];

/// Cột gợi ý đồng đội (`VĐV đăng ký đứng chung`, `đồng đội`, `partner`): manh mối ghép, không phải slot.
const List<String> _partnerHintKeys = [
  'dang ky dung chung',
  'dung chung',
  'dang ky cung',
  'dong doi',
  'partner',
  'ghep voi',
  'ghep cap voi',
];

bool isPartnerHintHeader(String header) {
  final key = normalizeRosterHeader(header);
  return _partnerHintKeys.any(key.contains);
}

/// Cột gợi ý đồng đội: header giống gợi ý mà chưa slot nào lấy; null khi không có.
int? findPartnerHintColumn(List<String> headers, RosterColumnMapping mapping) {
  final used = mapping.columns.values.toSet();
  for (var i = 0; i < headers.length; i++) {
    if (!used.contains(i) && isPartnerHintHeader(headers[i])) return i;
  }
  return null;
}

/// Kiểm tra cột mã cặp và cột đồng đội. Cột mã cặp chỉ giữ khi ≥ 80% ô đọc được là mã (`Cặp đôi` trên
/// cột tên không phải cột mã). Cột `đồng đội`/`partner` (slot VĐV 2 hoặc tên đội) mà ≥ 50% giá trị là
/// biệt danh của dòng khác thì là cột gợi ý: slot đó bị bỏ.
RosterColumnMapping confirmRosterColumns(
  List<List<String>> dataRows,
  List<String> headers,
  RosterColumnMapping mapping,
) {
  final columns = Map<RosterSlot, int>.of(mapping.columns);
  String cell(List<String> cells, int column) =>
      column < cells.length ? cells[column] : '';

  final pairColumn = columns[RosterSlot.pairCode];
  if (pairColumn != null &&
      !looksLikeCodeColumn([for (final r in dataRows) cell(r, pairColumn)])) {
    columns.remove(RosterSlot.pairCode);
    final hasName =
        columns.containsKey(RosterSlot.player1Name) ||
        columns.containsKey(RosterSlot.teamName);
    final values = [for (final r in dataRows) cell(r, pairColumn)];
    // `A / B` dưới tiêu đề `Cặp VĐV`, sheet chưa có cột tên và đã có cột nội dung: đó là cột VĐV.
    if (!hasName &&
        columns.containsKey(RosterSlot.divisionName) &&
        looksLikeSameCell(values)) {
      columns[RosterSlot.player1Name] = pairColumn;
    }
  }

  final nameColumn =
      columns[RosterSlot.player1Name] ?? columns[RosterSlot.teamName];
  if (nameColumn != null) {
    final names = [
      for (final r in dataRows)
        if (cell(r, nameColumn).trim().isNotEmpty) cell(r, nameColumn),
    ];
    bool isNicknameColumn(int? column) {
      if (column == null || column >= headers.length) return false;
      if (!isPartnerHintHeader(headers[column])) return false;
      final hints = [
        for (final r in dataRows)
          if (cell(r, column).trim().isNotEmpty &&
              !isEmptyPartnerHint(cell(r, column)))
            cell(r, column),
      ];
      if (hints.isEmpty) return false;
      final nickname = hints
          .where((h) => names.any((n) => partnerHintMatchesName(h, n)))
          .length;
      return nickname * 2 >= hints.length;
    }

    if (isNicknameColumn(columns[RosterSlot.player2Name])) {
      columns.remove(RosterSlot.player2Name);
    }
    if (columns.containsKey(RosterSlot.player1Name) &&
        isNicknameColumn(columns[RosterSlot.teamName])) {
      columns.remove(RosterSlot.teamName);
    }
  }
  return RosterColumnMapping(columns);
}

/// Điền ô gộp dọc: giá trị ô neo được chép xuống các ô trống bên dưới, để cả hai dòng của một cặp mang
/// STT và dấu thanh toán. Gộp một dòng (tiêu đề) giữ nguyên, và gộp bắt đầu ở dòng header bị bỏ qua.
RosterGridSheet fillRosterMerges(RosterGridSheet sheet) {
  if (sheet.mergedRegions.isEmpty) return sheet;
  final rows = [for (final r in sheet.rows) List<String>.of(r)];
  for (final region in sheet.mergedRegions) {
    final range = parseA1Range(region);
    if (range == null || range.endRow <= range.startRow) continue;
    if (range.startRow >= rows.length) continue;
    if (_isHeaderLikeRow(rows[range.startRow])) continue;
    for (var c = range.startColumn; c <= range.endColumn; c++) {
      final anchor = c < rows[range.startRow].length
          ? rows[range.startRow][c]
          : '';
      if (anchor.isEmpty) continue;
      for (
        var r = range.startRow + 1;
        r <= range.endRow && r < rows.length;
        r++
      ) {
        final cells = rows[r];
        while (cells.length <= c) {
          cells.add('');
        }
        if (cells[c].isEmpty) cells[c] = anchor;
      }
    }
  }
  return RosterGridSheet(
    name: sheet.name,
    rows: rows,
    mergedRegions: sheet.mergedRegions,
  );
}

/// Dòng có ít nhất hai nhãn cột nhận diện được: dòng header, không điền ô gộp từ đây.
bool _isHeaderLikeRow(List<String> cells) {
  final filled = cells.where((c) => c.trim().isNotEmpty).length;
  if (filled < 2) return false;
  final mapping = detectRosterColumnMapping(cells);
  return mapping.indexOf(RosterSlot.player1Name) != null &&
      mapping.columns.length >= 2;
}

String _cellAt(List<String> cells, int? column) {
  if (column == null || column >= cells.length) return '';
  return cells[column].trim();
}

/// Đọc các dòng dữ liệu nằm dưới [headerRowIndex] (0-based; -1 nghĩa là không có dòng header). Dòng trống
/// và dòng chỉ có STT bị bỏ; dòng tiêu đề phần `DANH SÁCH VĐV CHƯA CÓ CẶP` bắt đầu phần VĐV lẻ (cờ
/// `singles`); dòng tiêu đề `Cặp n` đặt mã cho các dòng sau. Mã cặp lấy từ cột mã cặp (ô trống kế thừa mã
/// dòng trên), STT và gợi ý đồng đội; việc gộp hai dòng thành cặp do `pairRowsByCode` làm sau khi biết nội dung đôi.
/// [singlesFromRow] (1-based) đánh dấu mọi dòng từ đó trở đi là VĐV lẻ (do AI chỉ ra).
List<RosterParsedRow> parseRosterSheet(
  RosterGridSheet sheet, {
  required int headerRowIndex,
  required RosterColumnMapping mapping,
  int? firstDataRowIndex,
  int? lastRowIndex,
  int singlesFromRow = 0,
  bool defaultPaid = false,
  String defaultDivisionLabel = '',
  Set<String> titleLabels = const {},
}) {
  final headers = headerRowIndex >= 0
      ? sheet.rows[headerRowIndex]
      : const <String>[];
  String headerOf(int column) =>
      column < headers.length && headers[column].trim().isNotEmpty
      ? headers[column].trim()
      : '[${_columnLetter(column)}]';
  final width = sheet.rows.fold<int>(
    headers.length,
    (m, r) => r.length > m ? r.length : m,
  );

  final usedColumns = mapping.columns.values.toSet();
  final hintColumn = findPartnerHintColumn(headers, mapping);
  final indexColumn = _firstWhereIndex(
    headers,
    (h) => _indexHeaders.contains(normalizeRosterHeader(h)),
  );
  final notedColumns = <int>[];
  for (var c = 0; c < width; c++) {
    if (usedColumns.contains(c) || c == hintColumn) continue;
    final key = normalizeRosterHeader(c < headers.length ? headers[c] : '');
    if (key.isEmpty || _indexHeaders.contains(key)) continue;
    if (_sensitiveHeaderWords.any(key.contains)) continue;
    notedColumns.add(c);
  }

  // Cột mã cặp, hoặc cột đội gồm toàn mã lặp (header kiểu `Đôi`).
  final pairColumn = mapping.indexOf(RosterSlot.pairCode);
  final teamColumn = mapping.indexOf(RosterSlot.teamName);
  final bodyStart = firstDataRowIndex ?? headerRowIndex + 1;
  final bodyEnd = (lastRowIndex ?? sheet.rows.length - 1).clamp(
    -1,
    sheet.rows.length - 1,
  );
  final teamCells = [
    for (var r = bodyStart; r <= bodyEnd; r++)
      _cellAt(sheet.rows[r], teamColumn),
  ];
  final codeColumn =
      pairColumn ??
      (teamColumn != null && looksLikePairCodes(teamCells) ? teamColumn : null);

  final parsed = <RosterParsedRow>[];
  var pairTitle = '';
  var previousCode = '';
  var inSinglesSection = false;
  for (var r = bodyStart; r <= bodyEnd; r++) {
    if (parsed.length >= _maxRowsPerSheet) break;
    final cells = sheet.rows[r];
    final sourceRow = r + 1;

    String? read(RosterSlot slot) {
      final text = _cellAt(cells, mapping.indexOf(slot));
      return text.isEmpty ? null : text;
    }

    // Dòng chỉ có tên một nội dung do AI nêu là tiêu đề, không phải VĐV.
    final filledCells = cells.where((c) => c.trim().isNotEmpty).toList();
    if (filledCells.length == 1 &&
        titleLabels.contains(normalizeRosterHeader(filledCells.first))) {
      continue;
    }
    if (isSinglesSectionRow(cells)) {
      inSinglesSection = true;
      pairTitle = '';
      previousCode = '';
      continue;
    }
    final titleOfRow = titleRowCode(cells);
    if (titleOfRow.isNotEmpty) {
      pairTitle = titleOfRow;
      previousCode = '';
      continue;
    }

    final teamName = codeColumn == teamColumn && teamColumn != null
        ? null
        : read(RosterSlot.teamName);
    final player1Name = read(RosterSlot.player1Name);
    final player1Email = read(RosterSlot.player1Email);
    final player1Phone = read(RosterSlot.player1Phone);
    final player2Name = read(RosterSlot.player2Name);
    final player2Email = read(RosterSlot.player2Email);
    final player2Phone = read(RosterSlot.player2Phone);

    // Tiêu đề lặp giữa dữ liệu (`Họ và tên VĐV` ở ô tên) không phải VĐV.
    final nameColumn = mapping.indexOf(RosterSlot.player1Name) ?? teamColumn;
    final nameCell = _cellAt(cells, nameColumn);
    if (nameCell.isNotEmpty &&
        nameColumn != null &&
        nameColumn < headers.length &&
        normalizeRosterHeader(nameCell) ==
            normalizeRosterHeader(headers[nameColumn])) {
      previousCode = '';
      continue;
    }

    // Cùng quy tắc bỏ dòng với web: không có tên, đội, email hay SĐT thì bỏ (dòng chỉ có STT).
    final hasIdentity =
        teamName != null ||
        player1Name != null ||
        player1Email != null ||
        player1Phone != null ||
        player2Name != null ||
        player2Phone != null;
    if (!hasIdentity) {
      previousCode = '';
      continue;
    }

    // Ô mã trống dưới dòng tự ghi mã thì kế thừa mã đó (ô gộp): một bước.
    final codeCell = codeColumn == null ? '' : _cellAt(cells, codeColumn);
    final ownCode = pairColumn != null
        ? pairCodeKey(codeCell)
        : normalizePairCode(codeCell);
    var code = '';
    if (player2Name == null) {
      if (ownCode.isNotEmpty) {
        code = ownCode;
      } else {
        final inherited = codeCell.isNotEmpty ? '' : previousCode;
        code = inherited.isNotEmpty ? inherited : pairTitle;
      }
    }
    previousCode = player2Name != null ? '' : ownCode;

    final singles =
        inSinglesSection || (singlesFromRow > 0 && sourceRow >= singlesFromRow);
    final scoreText = _cellAt(cells, mapping.indexOf(RosterSlot.elo));
    final score = scoreText.isEmpty ? null : parseRosterScore(scoreText);
    final scoreHeader = mapping.indexOf(RosterSlot.elo);
    // Điểm không phải một số trần (hoặc không đọc được) thì chữ giữ trong ghi chú để không mất tin.
    final scoreNote =
        scoreText.isNotEmpty &&
            scoreHeader != null &&
            (score == null || !_bareNumber.hasMatch(scoreText))
        ? '${headerOf(scoreHeader)}: $scoreText'
        : '';
    final extras = [
      for (final c in notedColumns)
        if (_cellAt(cells, c).isNotEmpty)
          '${headerOf(c)}: ${_cellAt(cells, c)}',
    ];
    final notes = [
      read(RosterSlot.notes) ?? '',
      ...extras,
      scoreNote,
    ].where((n) => n.isNotEmpty).join(' · ');
    final hint = hintColumn == null ? '' : _cellAt(cells, hintColumn);

    parsed.add(
      RosterParsedRow(
        sheetName: sheet.name,
        sourceRowIndex: sourceRow,
        divisionName:
            read(RosterSlot.divisionName) ??
            (defaultDivisionLabel.isEmpty ? null : defaultDivisionLabel),
        teamName: teamName,
        player1Name: player1Name,
        player1Email: player1Email,
        player1Phone: player1Phone,
        player2Name: player2Name,
        player2Email: player2Email,
        player2Phone: player2Phone,
        elo: score?.value,
        eloSource: score?.source,
        isPaid: parseRosterPaid(
          _cellAt(cells, mapping.indexOf(RosterSlot.isPaid)),
          fallback: defaultPaid,
        ),
        notes: notes.isEmpty
            ? null
            : (notes.length > rosterNotesMax
                  ? notes.substring(0, rosterNotesMax)
                  : notes),
        fileIndex: indexColumn == null ? '' : _cellAt(cells, indexColumn),
        pairCode: code.isNotEmpty && !singles ? code : null,
        singles: singles,
        partnerHint: hint.isEmpty ? null : hint,
        localErrors: _localErrors(
          name: player1Name,
          email: player1Email,
          player2Email: player2Email,
        ),
      ),
    );
  }
  // Mã từ số thứ tự của file trước, rồi gợi ý đồng đội cho các dòng còn chưa có cặp.
  return assignHintPairCodes(assignSttPairCodes(parsed));
}

int? _firstWhereIndex(List<String> items, bool Function(String) test) {
  for (var i = 0; i < items.length; i++) {
    if (test(items[i])) return i;
  }
  return null;
}

/// `A` = 0, `Z` = 25, `AA` = 26: tên cột ở dạng chữ.
String _columnLetter(int index) {
  var letters = '';
  for (var value = index + 1; value > 0; value = (value - 1) ~/ 26) {
    letters = String.fromCharCode(65 + ((value - 1) % 26)) + letters;
  }
  return letters;
}

/// Cụm alias (không dấu `*`, không `!`) của các slot, đã chuẩn hóa: nhãn cột mà bộ nhận diện của app
/// đọc được. Dùng cho digest AI để nhãn cột không bị che.
List<String> rosterAliasPhrases([Iterable<RosterSlot>? slots]) => [
  for (final slot in slots ?? RosterSlot.values)
    for (final alias in _rosterAliases[slot] ?? const <String>[])
      if (!alias.startsWith('!'))
        normalizeRosterHeader(alias.replaceAll('*', '')),
];
