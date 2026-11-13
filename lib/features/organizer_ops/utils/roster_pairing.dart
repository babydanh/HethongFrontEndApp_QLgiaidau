// Ghép cặp cho danh sách VĐV đọc từ Excel. Thuần Dart, không phụ thuộc Flutter.
//
// Port của web `rosterPairing.ts` và phần ghép cặp trong `rosterLayout.ts` / `rosterImportDraft.ts`.
// Hai VĐV chỉ thành một cặp khi file nói rõ: hai cột VĐV, mã cặp, dòng tiêu đề "Cặp n", hai tên
// trong một ô, STT gộp/trùng ở hai dòng liền nhau, hoặc cột gợi ý đồng đội khớp tên mờ.

import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';

/// Giới hạn ghi chú, giống `ROSTER_NOTES_MAX` của web.
const int rosterNotesMax = 2000;

/// Dấu ngăn hai VĐV trong một ô, giống `SAME_CELL_SEPARATORS` của web.
const List<String> sameCellSeparators = [
  '\n',
  ' - ',
  ' – ',
  ' & ',
  ' / ',
  ' + ',
  ' và ',
  ' and ',
  ' với ',
  ' with ',
];

/// Tỉ lệ ô tên có đúng một dấu ngăn để cả sheet được đọc là "hai người một ô".
const double sameCellMinShare = 0.8;

final RegExp _codeValue = RegExp(
  r'^(?:(?:ma|stt|so|cap|doi|pair|team|p)\s*)*(\d{1,3})$',
);
final RegExp _pairTitle = RegExp(r'^(cap|doi|pair|team)\s*(\d{1,3})$');
final RegExp _trailingUnit = RegExp(r'\s*\(([^()]*)\)\s*$');

String _words(String value) =>
    normalizeRosterHeader(value).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

/// Mã cặp một ô chứa (`1`, `01`, `Cặp 1`, `P1`, `Pair 1` đều là `1`), hoặc '' khi không có.
String normalizePairCode(String value) {
  final match = _codeValue.firstMatch(_words(value));
  final code = match == null ? 0 : int.parse(match.group(1)!);
  return code > 0 ? '$code' : '';
}

/// Mã của tiêu đề cặp (`Cặp 1`, `Đôi 2`, `Pair 3`, `Team 4`), '' với chữ khác.
String pairTitleCode(String value) {
  final match = _pairTitle.firstMatch(_words(value));
  final code = match == null ? 0 : int.parse(match.group(2)!);
  return code > 0 ? '$code' : '';
}

/// Mã của dòng chỉ là tiêu đề cặp: đúng một ô có chữ và ô đó đọc là tiêu đề cặp.
String titleRowCode(List<String> cells) {
  final filled = cells.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
  return filled.length == 1 ? pairTitleCode(filled.first) : '';
}

/// Mọi ô có chữ đều là mã và có mã lặp: số lặp ghép dòng, số duy nhất là STT.
bool looksLikePairCodes(List<String> cells) {
  final codes = cells
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .map(normalizePairCode)
      .toList();
  if (codes.isEmpty || codes.any((code) => code.isEmpty)) return false;
  return codes.toSet().length < codes.length;
}

const int _pairCodeMaxLength = 6;
const double _pairCodeMinShare = 0.8;

/// Khóa của ô trong cột mã cặp: mã số hoặc token ngắn không khoảng trắng (`A1`), '' với chữ khác.
String pairCodeKey(String value) {
  final numbered = normalizePairCode(value);
  if (numbered.isNotEmpty) return numbered;
  final text = value.trim();
  return text.length <= _pairCodeMaxLength && !RegExp(r'\s').hasMatch(text)
      ? normalizeRosterHeader(text).toUpperCase()
      : '';
}

/// Ít nhất 80% ô có chữ đọc được là mã; cột rỗng không phản chứng.
bool looksLikeCodeColumn(List<String> values) {
  final filled = values
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .toList();
  if (filled.isEmpty) return true;
  return filled.where((v) => pairCodeKey(v).isNotEmpty).length /
          filled.length >=
      _pairCodeMinShare;
}

/// Dấu ngăn xuất hiện đầu tiên trong ô, '' khi không có.
String firstSeparatorIn(String value) {
  var found = '';
  var at = 1 << 30;
  for (final separator in sameCellSeparators) {
    final index = value.indexOf(separator);
    if (index >= 0 && index < at) {
      at = index;
      found = separator;
    }
  }
  return found;
}

/// Ít nhất 80% giá trị có tên chứa đúng một dấu ngăn: cả sheet ghi hai người một ô.
bool looksLikeSameCell(List<String> values) {
  final named = values.map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
  if (named.isEmpty) return false;
  final single = named.where((value) {
    var total = 0;
    for (final separator in sameCellSeparators) {
      total += value.split(separator).length - 1;
    }
    return total == 1;
  }).length;
  return single / named.length >= sameCellMinShare;
}

/// Tách ô tại [separator] (hoặc dấu ngăn đầu tiên); null khi không có.
({String first, String second})? splitSameCellText(
  String value, [
  String? separator,
]) {
  final sep = separator ?? firstSeparatorIn(value);
  final at = sep.isEmpty ? -1 : value.indexOf(sep);
  if (at < 0) return null;
  return (
    first: value.substring(0, at).trim(),
    second: value.substring(at + sep.length).trim(),
  );
}

/// Bỏ `(…)` cuối tên; phần trong ngoặc là đơn vị để chuyển sang ghi chú.
({String name, String unit}) splitUnit(String name) {
  final trimmed = name.trim();
  final match = _trailingUnit.firstMatch(trimmed);
  final rest = match == null ? '' : trimmed.substring(0, match.start).trim();
  if (match == null || rest.isEmpty || match.group(1)!.trim().isEmpty) {
    return (name: trimmed, unit: '');
  }
  return (name: rest, unit: match.group(1)!.trim());
}

/// Thêm một mục vào ghi chú, nối bằng ` · `, giữ trong giới hạn.
String appendNote(String notes, String entry) {
  if (entry.isEmpty) return notes;
  final joined = [notes, entry].where((s) => s.isNotEmpty).join(' · ');
  return joined.length > rosterNotesMax
      ? joined.substring(0, rosterNotesMax)
      : joined;
}

// ---- Phần VĐV lẻ, STT và gợi ý đồng đội ----

final RegExp _singlesSection = RegExp(
  r'\b(?:chua co (?:cap|doi)|chua (?:duoc )?(?:ghep|xep)(?: cap| doi)?|cho ghep|danh le|vdv le|vdv tu do|danh sach tu do|nhom tu do|tu do ghep)\b',
);

/// Dòng chỉ có một ô là tiêu đề phần VĐV chưa có cặp (`DANH SÁCH VĐV CHƯA CÓ CẶP`, `chờ ghép`,
/// `đánh lẻ`, `VĐV tự do`). Tên người hay dòng dữ liệu không bao giờ khớp.
bool isSinglesSectionRow(List<String> cells) {
  final filled = cells.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
  if (filled.length != 1) return false;
  return _singlesSection.hasMatch(_words(filled.first));
}

/// Ít nhất 80% dòng nằm trong nhóm hai dòng thì STT mới là số cặp.
const double _sttMinPairShare = 0.8;

bool _isPairable(RosterParsedRow row) =>
    (row.pairCode == null || row.pairCode!.isEmpty) &&
    row.player2Name == null &&
    !row.singles;

/// Mã cặp từ STT của file: hai dòng có tên liền nhau cùng STT (ghi hai lần, ô gộp, hoặc chỉ ghi ở
/// dòng trên) là một cặp. Chỉ khi ≥ 80% dòng nằm trong nhóm hai dòng; danh sách đánh số thì không ghép.
/// Dòng thuộc phần lẻ và dòng đã có mã riêng được bỏ qua.
List<RosterParsedRow> assignSttPairCodes(List<RosterParsedRow> rows) {
  if (rows.any((r) => r.pairCode != null && r.pairCode!.isNotEmpty)) {
    return List.of(rows);
  }
  final candidates = rows.where(_isPairable).toList();
  if (candidates.every((r) => r.fileIndex.isEmpty)) return List.of(rows);

  final groups = <List<RosterParsedRow>>[];
  var openStt = '';
  for (final row in candidates) {
    final joins =
        groups.isNotEmpty &&
        (row.fileIndex.isEmpty ? openStt.isNotEmpty : row.fileIndex == openStt);
    if (joins) {
      groups.last.add(row);
    } else {
      groups.add([row]);
      openStt = row.fileIndex;
    }
  }
  final pairs = groups.where((g) => g.length == 2).toList();
  if (pairs.isEmpty ||
      pairs.length * 2 < candidates.length * _sttMinPairShare) {
    return List.of(rows);
  }
  final codeOf = <int, String>{};
  for (final pair in pairs) {
    final code = 'stt:${pair.first.sourceRowIndex}';
    codeOf[pair.first.sourceRowIndex] = code;
    codeOf[pair.last.sourceRowIndex] = code;
  }
  return [
    for (final row in rows)
      codeOf.containsKey(row.sourceRowIndex)
          ? row.copyWith(pairCode: codeOf[row.sourceRowIndex])
          : row,
  ];
}

final RegExp _noHint = RegExp(
  r'^(?:chua(?: co)?|khong(?: co)?|\d+ nguoi|n a|none|[-–—]*)$',
);

/// Họ phổ biến và từ đệm: trùng một từ như vậy không xác định được người.
const Set<String> _commonNameWords = {
  'nguyen',
  'tran',
  'le',
  'pham',
  'hoang',
  'huynh',
  'phan',
  'vu',
  'vo',
  'dang',
  'bui',
  'do',
  'ho',
  'ngo',
  'duong',
  'ly',
  'van',
  'thi',
  'anh',
  'chi',
  'em',
  'ban',
  'ong',
  'ba',
};

List<String> _nameWords(String text) =>
    _words(text).split(' ').where((w) => w.isNotEmpty).toList();

/// Giá trị không nêu ai: `chưa`, `chưa có`, `không`, `2 người`, gạch ngang, trống.
bool isEmptyPartnerHint(String hint) =>
    _noHint.hasMatch(_nameWords(hint).join(' '));

/// Khớp mờ gợi ý đồng đội (thường là biệt danh như `Cường tsc`) với tên đầy đủ: bỏ dấu, và một từ
/// của tên không phải họ phổ biến xuất hiện trong gợi ý. Từ cuối (tên riêng) có thể chỉ một chữ cái.
bool partnerHintMatchesName(String hint, String fullName) {
  if (isEmptyPartnerHint(hint)) return false;
  final hintWords = _nameWords(hint).toSet();
  final words = _nameWords(fullName);
  for (var i = 0; i < words.length; i++) {
    final word = words[i];
    if (hintWords.contains(word) &&
        !_commonNameWords.contains(word) &&
        (word.length >= 2 || i == words.length - 1)) {
      return true;
    }
  }
  return false;
}

/// Ghép qua cột gợi ý đồng đội. Gợi ý chỉ nối hai dòng đã có và chưa có cặp: nó nêu đúng MỘT dòng khác
/// theo khớp mờ, và dòng đó nêu lại dòng đầu hoặc không nêu ai. Gợi ý nêu hai dòng, dòng đã ghép theo
/// STT/mã, hay dòng thuộc phần lẻ đều bị bỏ; không bao giờ tạo VĐV từ chữ trong gợi ý.
List<RosterParsedRow> assignHintPairCodes(List<RosterParsedRow> rows) {
  final candidates = rows.where(_isPairable).toList();
  final target = <int, int>{};
  for (final row in candidates) {
    final hint = row.partnerHint ?? '';
    if (hint.isEmpty || isEmptyPartnerHint(hint)) continue;
    final matches = candidates
        .where(
          (other) =>
              other.sourceRowIndex != row.sourceRowIndex &&
              partnerHintMatchesName(hint, other.player1Name ?? ''),
        )
        .toList();
    if (matches.length == 1) {
      target[row.sourceRowIndex] = matches.first.sourceRowIndex;
    }
  }
  final hitCount = <int, int>{};
  for (final to in target.values) {
    hitCount[to] = (hitCount[to] ?? 0) + 1;
  }
  final codeOf = <int, String>{};
  for (final entry in target.entries) {
    final from = entry.key;
    final to = entry.value;
    if (codeOf.containsKey(from) || codeOf.containsKey(to)) continue;
    final back = target[to];
    final mutual = back == from;
    if (!mutual && (back != null || hitCount[to] != 1)) continue;
    final code = 'hint:${from < to ? from : to}';
    codeOf[from] = code;
    codeOf[to] = code;
  }
  return [
    for (final row in rows)
      codeOf.containsKey(row.sourceRowIndex)
          ? row.copyWith(pairCode: codeOf[row.sourceRowIndex])
          : row,
  ];
}

// ---- Gộp hai dòng thành một cặp ----

/// Điểm của cặp: trung bình các điểm đọc được cùng thang (làm tròn; DUPR 2 số lẻ), hoặc điểm duy nhất
/// đọc được; hai thang khác nhau thì không trộn. Đã trả nếu file xác nhận một trong hai VĐV.
({bool isPaid, num? elo, String? eloSource}) mergePairFileData(
  RosterParsedRow first,
  RosterParsedRow second,
) {
  final paid = first.isPaid || second.isPaid;
  if (first.elo == null || second.elo == null) {
    final only = first.elo == null ? second : first;
    return (isPaid: paid, elo: only.elo, eloSource: only.eloSource);
  }
  if (first.eloSource != second.eloSource) {
    return (isPaid: paid, elo: null, eloSource: null);
  }
  final mean = (first.elo! + second.elo!) / 2;
  final value = first.eloSource == 'DUPR'
      ? (mean * 100).round() / 100
      : mean.round();
  return (isPaid: paid, elo: value, eloSource: first.eloSource);
}

RosterParsedRow _absorbPartner(RosterParsedRow row, RosterParsedRow second) {
  final merged = mergePairFileData(row, second);
  final notes = appendNote(row.notes ?? '', second.notes ?? '');
  return row.copyWith(
    clearTeamName: row.teamName != null && row.teamName == row.player1Name,
    player2Name: second.player1Name,
    player2Email: second.player1Email,
    player2Phone: second.player1Phone,
    notes: notes.isEmpty ? null : notes,
    clearNotes: notes.isEmpty,
    isPaid: merged.isPaid,
    elo: merged.elo,
    eloSource: merged.eloSource,
    clearElo: merged.elo == null,
  );
}

/// Ghép các dòng cùng mã cặp, bất kể thứ tự. Nhóm đúng hai dòng thành một: dòng đầu giữ nguồn gốc và nhận
/// VĐV, ghi chú của dòng sau. Nhóm khác hai dòng giữ riêng và mọi thành viên nhận `pairCodeSize`.
/// Dòng đã có VĐV 2 giữ nguyên và bỏ qua mã.
List<RosterParsedRow> pairRowsByCode(List<RosterParsedRow> rows) {
  final groups = <String, List<int>>{};
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final code = row.pairCode;
    if (code == null || code.isEmpty || row.player2Name != null) continue;
    groups.putIfAbsent(code, () => <int>[]).add(i);
  }
  final sizeOf = <int, int>{};
  final partnerOf = <int, int>{};
  final absorbed = <int>{};
  for (final members in groups.values) {
    for (final index in members) {
      sizeOf[index] = members.length;
    }
    if (members.length == 2) {
      partnerOf[members[0]] = members[1];
      absorbed.add(members[1]);
    }
  }
  final result = <RosterParsedRow>[];
  for (var i = 0; i < rows.length; i++) {
    if (absorbed.contains(i)) continue;
    final partner = partnerOf[i];
    if (partner != null) {
      result.add(_absorbPartner(rows[i], rows[partner]));
      continue;
    }
    final size = sizeOf[i];
    result.add(size == null ? rows[i] : rows[i].copyWith(pairCodeSize: size));
  }
  return result;
}

/// Cách ghép cặp của một khối, như `RosterPairLayout` của web.
enum RosterPairLayout { single, columns, sameCell, consecutiveRows }

/// Hàng 1+2, 3+4...: dòng thứ hai thành VĐV 2; dòng lẻ cuối giữ nguyên. Dòng phần lẻ không bao giờ ghép.
List<RosterParsedRow> pairConsecutiveRows(List<RosterParsedRow> rows) {
  final paired = <RosterParsedRow>[];
  var index = 0;
  while (index < rows.length) {
    final first = rows[index];
    final second = index + 1 < rows.length ? rows[index + 1] : null;
    if (first.singles || second == null || second.singles) {
      paired.add(first);
      index += 1;
      continue;
    }
    final merged = mergePairFileData(first, second);
    paired.add(
      first.copyWith(
        teamName: first.teamName ?? second.teamName,
        player2Name: second.player1Name,
        player2Email: second.player1Email,
        player2Phone: second.player1Phone,
        isPaid: merged.isPaid,
        elo: merged.elo,
        eloSource: merged.eloSource,
        clearElo: merged.elo == null,
      ),
    );
    index += 2;
  }
  return paired;
}

final RegExp _formattedPhone = RegExp(
  r'(?<!\d)(?:\+84|0)(?:[\s.-]?\d){9}(?!\d)',
);
final RegExp _emailInCell = RegExp(
  r'[^\s@,;/|&+]+@[^\s@,;/|&+]+\.[^\s@,;/|&+]+',
);

/// Một ô chứa cả hai VĐV: tách tên tại dấu ngăn đầu tiên, chuyển `(…)` vào ghi chú, và tách email/SĐT thứ hai.
RosterParsedRow splitSameCell(RosterParsedRow row, String separator) {
  var next = row;
  final name = row.player1Name ?? '';
  final parts = splitSameCellText(
    name,
    separator.isEmpty ? firstSeparatorIn(name) : separator,
  );
  if (parts != null && parts.first.isNotEmpty && parts.second.isNotEmpty) {
    final first = splitUnit(parts.first);
    final second = splitUnit(parts.second);
    var notes = row.notes ?? '';
    for (final part in [first, second]) {
      if (part.unit.isNotEmpty) {
        notes = appendNote(notes, '${part.name} (${part.unit})');
      }
    }
    next = next.copyWith(
      player1Name: first.name,
      player2Name: next.player2Name ?? second.name,
      clearTeamName: row.teamName != null && row.teamName == row.player1Name,
      notes: notes.isEmpty ? null : notes,
      clearNotes: notes.isEmpty,
    );
  }
  final emails = _emailInCell
      .allMatches(row.player1Email ?? '')
      .map((m) => m.group(0)!)
      .toList();
  if (emails.length >= 2) {
    next = next.copyWith(
      player1Email: emails[0],
      player2Email: next.player2Email ?? emails[1],
    );
  }
  final phones = _formattedPhone
      .allMatches(row.player1Phone ?? '')
      .map((m) => m.group(0)!)
      .toList();
  if (phones.length >= 2) {
    next = next.copyWith(
      player1Phone: phones[0],
      player2Phone: next.player2Phone ?? phones[1],
    );
  }
  return next;
}

/// Áp quy tắc ghép của một khối cho các dòng đã dựng. Gọi sau mỗi lần dựng lại dòng.
List<RosterParsedRow> applyPairLayout(
  List<RosterParsedRow> rows,
  RosterPairLayout layout,
  String separator,
) {
  switch (layout) {
    case RosterPairLayout.single:
      return [
        for (final row in rows)
          row.copyWith(
            clearPlayer2Name: true,
            clearPlayer2Email: true,
            clearPlayer2Phone: true,
          ),
      ];
    case RosterPairLayout.columns:
      return rows;
    case RosterPairLayout.sameCell:
      return [for (final row in rows) splitSameCell(row, separator)];
    case RosterPairLayout.consecutiveRows:
      return pairConsecutiveRows(rows);
  }
}

/// Cách ghép của một sheet đọc bằng luật, cho nội dung đôi. Hai cột VĐV là `columns`; ≥ 80% tên có một dấu
/// ngăn là `sameCell`; còn lại là `single`: không ghép khi không có bằng chứng.
({RosterColumnMapping mapping, RosterPairLayout layout}) resolvePairLayout(
  List<List<String>> dataRows,
  RosterColumnMapping mapping, {
  required bool doubles,
}) {
  if (mapping.indexOf(RosterSlot.player2Name) != null) {
    return (mapping: mapping, layout: RosterPairLayout.columns);
  }
  final nameSlot = mapping.indexOf(RosterSlot.player1Name) != null
      ? RosterSlot.player1Name
      : RosterSlot.teamName;
  final column = mapping.indexOf(nameSlot);
  if (column == null || !doubles) {
    return (mapping: mapping, layout: RosterPairLayout.single);
  }
  final names = [
    for (final cells in dataRows) column < cells.length ? cells[column] : '',
  ];
  if (!looksLikeSameCell(names)) {
    return (mapping: mapping, layout: RosterPairLayout.single);
  }
  if (nameSlot == RosterSlot.player1Name) {
    return (mapping: mapping, layout: RosterPairLayout.sameCell);
  }
  final columns = Map<RosterSlot, int>.of(mapping.columns)
    ..remove(RosterSlot.teamName)
    ..[RosterSlot.player1Name] = column;
  return (
    mapping: RosterColumnMapping(columns),
    layout: RosterPairLayout.sameCell,
  );
}
