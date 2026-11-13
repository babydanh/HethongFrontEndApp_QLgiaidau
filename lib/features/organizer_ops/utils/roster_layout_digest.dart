// Bản tóm tắt gửi AI layout. Thuần Dart. Port của web `rosterLayout.ts` (phần digest/che dữ liệu).
//
// AI chỉ nhận bố cục: email, SĐT, ngày, số dài và mọi chữ (tên, đơn vị) bị thay bằng token như
// `[TXT_1]`; nhãn cột chỉ giữ ở dòng header, tiêu đề nội dung chỉ giữ ở dòng tiêu đề.

import 'package:app_quanly_giaidau/core/services/roster_excel_reader.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';

const int _digestMaxSheets = 10;
const int _digestTotalChars = 20000;
const int _digestMinSheetChars = 1500;
const int _digestCellChars = 60;
const int _digestCellsPerRow = 30;
const int _digestFirstRows = 40;
const int _digestLastRows = 3;

final RegExp _emailInText = RegExp(r'[^\s@]+@[^\s@]+\.[^\s@]+');
final RegExp _formattedPhone = RegExp(
  r'(?<!\d)(?:\+84|0)(?:[\s.-]?\d){9}(?!\d)',
);
final RegExp _dateInText = RegExp(
  r'(?<!\d)(?:\d{4}[/.-]\d{1,2}[/.-]\d{1,2}|\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4})(?!\d)',
);
final RegExp _barePhone = RegExp(r'(?<!\d)\d{9,11}(?!\d)');
final RegExp _longNumber = RegExp(r'(?<!\d)\d{5,}(?!\d)');
final RegExp _tokenInText = RegExp(r'(\[(?:EMAIL|PHONE|NUM)_\d+\])');
final RegExp _separatorInText = RegExp(r'(\s*[/\-,&+|]\s*)');
final RegExp _hasLetter = RegExp(r'\p{L}', unicode: true);

/// Token đặt cho từng giá trị của một workbook: giá trị chuẩn hóa -> `[TXT_1]`.
class RosterMaskTokens {
  final Map<String, String> emails = {};
  final Map<String, String> phones = {};
  final Map<String, String> numbers = {};
  final Map<String, String> texts = {};
}

/// Ngữ cảnh của dòng: `header` (nhãn cột nhận diện được giữ nguyên), `title` (tiêu đề nội dung), `data`.
enum RosterCellContext { header, title, data }

/// Nhãn mô tả bố cục, chỉ giữ ở dòng header. Từ trùng tên người (Trần, Hằng, Phi) cố ý vắng mặt.
const Set<String> _structuralLabels = {
  'stt',
  'ten',
  'ho ten',
  'ho va ten',
  'ten vdv',
  'ten doi',
  'doi',
  'team',
  'team name',
  'vdv',
  'player',
  'email',
  'sdt',
  'so dien thoai',
  'dien thoai',
  'phone',
  'elo',
  'paid',
  'da dong',
  'ngay',
  'gio',
  'san',
  'lich',
  'vong',
  'bang',
  'nhom',
  'cap',
  'cot',
  'ket qua',
  'thu tu',
  'singles',
  'doubles',
  'mixed',
  'mixed doubles',
  'hon hop',
  'nam don',
  'nu don',
  'nam doi',
  'nu doi',
  'don nam',
  'don nu',
  'doi nam',
  'doi nu',
  'nam nu',
  'elo points',
  'no',
  'cap vdv',
  'cap doi',
  'diem',
  'diem elo',
  'diem trinh',
  'trinh do',
  'dupr',
  'diem dupr',
  'rating',
};

/// Từ chỉ tên cột, không bao giờ là tên người hay đội: dòng có hai từ như vậy là dòng header.
const Set<String> _headerAnchors = {
  'stt',
  'ten',
  'ho ten',
  'ho va ten',
  'ten vdv',
  'ten doi',
  'team name',
  'email',
  'sdt',
  'so dien thoai',
  'dien thoai',
  'phone',
  'elo',
  'thu tu',
  'paid',
  'da dong',
  'ket qua',
};

/// Ghi chú trong ngoặc sau nhãn cột, như `Email VĐV 1 (không bắt buộc)`; ngoặc khác bị che.
const Set<String> _headerHints = {
  'khong bat buoc',
  'tuy chon',
  'neu co',
  'bat buoc',
  'khong bat buoc khi thi doi',
  'bat buoc khi thi doi',
  'optional',
  'required',
  'if available',
  'required for doubles',
  'optional for doubles',
};

/// Tiêu đề nội dung, có dấu: chữ không dấu bị che nên họ `Bang` không lọt thành `Bảng`.
const Set<String> _titlePhrases = {
  'nam đơn',
  'nữ đơn',
  'đơn nam',
  'đơn nữ',
  'nam đôi',
  'nữ đôi',
  'đôi nam',
  'đôi nữ',
  'nam nữ',
  'hỗn hợp',
  'singles',
  'doubles',
  'mixed',
  'mixed doubles',
};

final RegExp _numberedTitle = RegExp(r'^(bảng|nhóm|vòng) (\d{1,2}|[a-z])$');

/// Từ nhãn trùng tên người: chỉ giữ khi viết đúng dạng có dấu.
const Map<String, List<String>> _nameLikeLabels = {
  'vong': ['vòng'],
  'gio': ['giờ'],
  'san': ['sân'],
  'bang': ['bảng'],
  'ngay': ['ngày'],
  'lich': ['lịch'],
  'nhom': ['nhóm'],
  'cap': ['cấp', 'cặp'],
  'cot': ['cột'],
  'phi': ['phí'],
  'trinh': ['trình'],
};

String _normalizeText(String text) =>
    normalizeRosterHeader(text).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

String? _withoutHint(String text) {
  final hint = RegExp(r'\s*\(([^()]*)\)\s*$').firstMatch(text);
  if (hint == null) return text;
  if (!_headerHints.contains(_normalizeText(hint.group(1)!))) return null;
  return text.substring(0, hint.start);
}

String _withoutPlayerNumber(String words) => words
    .replaceAllMapped(RegExp(r'(^| )\d{1,2}(?= |$)'), (m) => m.group(1)!)
    .replaceAll(RegExp(r' +'), ' ')
    .trim();

String? _labelKey(String text) {
  final label = _withoutHint(text);
  return label == null ? null : _withoutPlayerNumber(_normalizeText(label));
}

final Set<String> _aliasLabelKeys = {
  for (final phrase in rosterAliasPhrases())
    if ((_labelKey(phrase) ?? '').isNotEmpty) _labelKey(phrase)!,
};

final Set<String> _anchorKeys = {
  ..._headerAnchors,
  for (final phrase in rosterAliasPhrases(const [
    RosterSlot.teamName,
    RosterSlot.player1Name,
    RosterSlot.player1Email,
    RosterSlot.player1Phone,
    RosterSlot.player2Name,
    RosterSlot.player2Email,
    RosterSlot.player2Phone,
  ]))
    if ((_labelKey(phrase) ?? '').isNotEmpty) _labelKey(phrase)!,
};

bool _isNameLikeLabelSpelledRight(String text, String key) {
  final label = _withoutHint(text) ?? '';
  final spelled = _withoutPlayerNumber(
    label
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
        .trim(),
  );
  return _nameLikeLabels[key]!.contains(spelled);
}

bool _isHeaderLabel(String text) {
  final key = _labelKey(text);
  if (key == null || key.isEmpty) return false;
  if (_nameLikeLabels.containsKey(key)) {
    return _isNameLikeLabelSpelledRight(text, key);
  }
  return _structuralLabels.contains(key) || _aliasLabelKeys.contains(key);
}

bool _isTitle(String text) {
  final phrase = text.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  return _titlePhrases.contains(phrase) || _numberedTitle.hasMatch(phrase);
}

bool _carriesPersonalData(String cell) => [
  _emailInText,
  _formattedPhone,
  _dateInText,
  _barePhone,
  _longNumber,
].any((pattern) => pattern.hasMatch(cell));

/// Dòng một ô là tiêu đề nội dung, dòng có ≥ 2 nhãn neo là header, còn lại là dữ liệu.
RosterCellContext rosterRowContext(List<String> cells) {
  final filled = cells.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
  if (filled.length == 1 && _isTitle(filled.first)) {
    return RosterCellContext.title;
  }
  if (filled.any(_carriesPersonalData)) return RosterCellContext.data;
  final anchors = {
    for (final cell in filled)
      if (_labelKey(cell) case final key? when _anchorKeys.contains(key)) key,
  };
  return anchors.length >= 2
      ? RosterCellContext.header
      : RosterCellContext.data;
}

bool _keepsText(String text, RosterCellContext context) {
  if (!_hasLetter.hasMatch(text)) {
    return RegExp(r'^[\d\s:./-]+$').hasMatch(text) &&
        text.split(RegExp(r'\D+')).every((group) => group.length <= 4);
  }
  if (context == RosterCellContext.header) return _isHeaderLabel(text);
  if (context == RosterCellContext.title) return _isTitle(text);
  return false;
}

String _tokenFor(Map<String, String> map, String key, String label) {
  final known = map[key];
  if (known != null) return known;
  final token = '[${label}_${map.length + 1}]';
  map[key] = token;
  return token;
}

String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

/// 9 chữ số cuối: `0912345678`, `912345678` và `+84912345678` cùng một khóa.
String _phoneKey(String value) {
  final digits = _digits(value);
  return digits.length > 9 ? digits.substring(digits.length - 9) : digits;
}

String _maskPart(
  String part,
  RosterMaskTokens tokens,
  RosterCellContext context,
) {
  final core = part.trim();
  if (core.isEmpty || _keepsText(core, context)) return part;
  return part.replaceFirst(
    core,
    _tokenFor(tokens.texts, core.toLowerCase(), 'TXT'),
  );
}

String _maskPlainText(
  String segment,
  RosterMaskTokens tokens,
  RosterCellContext context,
) {
  if (segment.trim().isEmpty || _keepsText(segment.trim(), context)) {
    return segment;
  }
  return segment.splitMapJoin(
    _separatorInText,
    onMatch: (m) => m.group(0)!,
    onNonMatch: (part) => _maskPart(part, tokens, context),
  );
}

/// Thay email, SĐT, ngày, số dài và chữ bằng token. Nhãn chỉ đọc được ở ngữ cảnh `header`/`title`.
String maskRosterCellText(
  String text,
  RosterMaskTokens tokens, [
  RosterCellContext context = RosterCellContext.data,
]) {
  var masked = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  masked = masked
      .replaceAllMapped(
        _emailInText,
        (m) => _tokenFor(tokens.emails, m.group(0)!.toLowerCase(), 'EMAIL'),
      )
      .replaceAllMapped(
        _formattedPhone,
        (m) => _tokenFor(tokens.phones, _phoneKey(m.group(0)!), 'PHONE'),
      )
      .replaceAllMapped(
        _dateInText,
        (m) => _tokenFor(tokens.numbers, _digits(m.group(0)!), 'NUM'),
      )
      .replaceAllMapped(
        _barePhone,
        (m) => _tokenFor(tokens.phones, _phoneKey(m.group(0)!), 'PHONE'),
      )
      .replaceAllMapped(
        _longNumber,
        (m) => _tokenFor(tokens.numbers, _digits(m.group(0)!), 'NUM'),
      );
  return masked.splitMapJoin(
    _tokenInText,
    onMatch: (m) => m.group(0)!,
    onNonMatch: (segment) => _maskPlainText(segment, tokens, context),
  );
}

List<String> _maskedCells(
  List<String> row,
  RosterMaskTokens tokens,
  RosterCellContext context,
) {
  final cells = [
    for (final cell in row.take(_digestCellsPerRow))
      () {
        final value = maskRosterCellText(cell, tokens, context);
        return value.length > _digestCellChars
            ? value.substring(0, _digestCellChars)
            : value;
      }(),
  ];
  while (cells.isNotEmpty && cells.last.isEmpty) {
    cells.removeLast();
  }
  return cells;
}

class _DigestRow {
  const _DigestRow(this.r, this.cells);

  final int r;
  final List<String> cells;

  Map<String, dynamic> toJson() => {'r': r, 'cells': cells};
}

List<int> _priorityIndexes(List<_DigestRow> rows) {
  final order = <int>{};
  for (var i = 0; i < rows.length && i < _digestFirstRows; i++) {
    order.add(i);
  }
  for (
    var i = rows.length > _digestLastRows ? rows.length - _digestLastRows : 0;
    i < rows.length;
    i++
  ) {
    order.add(i);
  }
  for (var i = 0; i < rows.length; i++) {
    final filled = rows[i].cells.where((c) => c.isNotEmpty).length;
    if (filled == 1 && i + 1 < rows.length) {
      order
        ..add(i)
        ..add(i + 1);
    }
  }
  return order.toList();
}

String _jsonLength(_DigestRow row) =>
    '{"r":${row.r},"cells":[${row.cells.map((c) => '"${c.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"').join(',')}]}';

List<_DigestRow> _selectRows(List<_DigestRow> rows, int budget) {
  final chosen = <int>{};
  var used = 1;
  for (final index in _priorityIndexes(rows)) {
    final size = _jsonLength(rows[index]).length + 1;
    if (used + size > budget) break;
    chosen.add(index);
    used += size;
  }
  return [
    for (var i = 0; i < rows.length; i++)
      if (chosen.contains(i)) rows[i],
  ];
}

/// Bản tóm tắt gửi AI: tối đa 10 sheet, mỗi sheet 40 dòng đầu, 3 dòng cuối và dòng tiêu đề kèm dòng sau
/// (trong ngân sách ký tự), mọi ô đã che. Tên sheet là `S1`, `S2`... Kèm `mergedRegions` (chỉ địa chỉ)
/// khi sheet có vùng gộp qua nhiều dòng.
List<Map<String, dynamic>> buildRosterLayoutDigest(
  List<RosterGridSheet> grid, [
  RosterMaskTokens? maskTokens,
]) {
  final tokens = maskTokens ?? RosterMaskTokens();
  final sheets = grid.take(_digestMaxSheets).toList();
  if (sheets.isEmpty) return const [];
  final budget = _digestTotalChars ~/ sheets.length > _digestMinSheetChars
      ? _digestTotalChars ~/ sheets.length
      : _digestMinSheetChars;
  return [
    for (var i = 0; i < sheets.length; i++)
      () {
        final sheet = sheets[i];
        final rows = <_DigestRow>[];
        for (var r = 0; r < sheet.rows.length; r++) {
          final cells = _maskedCells(
            sheet.rows[r],
            tokens,
            rosterRowContext(sheet.rows[r]),
          );
          if (cells.isNotEmpty) rows.add(_DigestRow(r + 1, cells));
        }
        final columnCount = sheet.rows.fold<int>(
          0,
          (m, r) => r.length > m ? r.length : m,
        );
        return <String, dynamic>{
          'name': 'S${i + 1}',
          'rowCount': sheet.rows.isEmpty ? 1 : sheet.rows.length,
          'columnCount': columnCount < 1 ? 1 : columnCount,
          'rows': [for (final row in _selectRows(rows, budget)) row.toJson()],
          if (sheet.mergedRegions.isNotEmpty)
            'mergedRegions': sheet.mergedRegions
                .take(maxMergedRegions)
                .toList(),
        };
      }(),
  ];
}
