import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/services/roster_excel_reader.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/roster_import.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_column_mapping_sheet.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_layout.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_mapping_draft.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_layout_digest.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Giới hạn số dòng mỗi lần nhập, giống `MAX_BATCH_PARTICIPANTS` của web.
const int _maxBatchParticipants = 500;

/// Mã kiểm tra cục bộ chặn dòng, giống `BLOCKING_ROW_STATUSES` của web (phần làm được ở app).
const Set<String> _localBlockingCodes = {
  'INVALID_EMAIL',
  'MISSING_NAME',
  'DUPLICATE_IN_FILE',
  'PLAYER2_REQUIRED',
  'PLAYER2_NOT_ALLOWED',
};

/// Mã server chặn dòng khi nhập. `MISSING_EMAIL` không chặn: dòng vẫn được nhập.
const Set<String> _serverBlockingCodes = {
  'INVALID_EMAIL',
  'MISSING_NAME',
  'DUPLICATE_IN_FILE',
  'DUPLICATE_IN_TOURNAMENT',
  'PLAYER2_REQUIRED',
  'PLAYER2_NOT_ALLOWED',
  'DIVISION_UNKNOWN',
};

const Set<String> _doublesMatchTypes = {'DOUBLES', 'MIXED_DOUBLES'};

/// Giá trị dropdown cho lựa chọn "để trống". UserId thật luôn khác rỗng.
const String _unlinkedValue = '';

final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Dấu tiếng Việt quy về chữ cái gốc, để so khớp tên nội dung không phân biệt dấu.
const Map<String, String> _accentBases = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

/// Chuẩn hóa tên nội dung: bỏ khoảng trắng thừa, chữ thường, bỏ dấu.
String _foldName(String value) {
  var result = value.trim().toLowerCase();
  for (final entry in _accentBases.entries) {
    for (final accented in entry.value.split('')) {
      result = result.replaceAll(accented, entry.key);
    }
  }
  return result.replaceAll(RegExp(r'\s+'), ' ');
}

bool _isDoublesType(String matchType) =>
    _doublesMatchTypes.contains(matchType.trim().toUpperCase());

/// Tokens chữ-số của tên hạng mục đã chuẩn hóa (`_foldName`), dùng để suy luận
/// kiểu thi đấu và giới tính từ tên trong file.
Set<String> _nameTokens(String value) => _foldName(
  value,
).split(RegExp(r'[^a-z0-9]+')).where((token) => token.isNotEmpty).toSet();

/// Cùng bộ từ, bất kể thứ tự (port `divisionLabelMatches` của web,
/// `rosterLayout.ts`): `Nam đơn` khớp `Đơn nam`, còn `Đôi nam` và `Nam` không
/// khớp `Đơn nam`. Dùng cho khớp tên hạng mục của dòng lẫn tái dùng khi tạo.
bool _divisionLabelMatches(String label, String divisionName) {
  final labelTokens = _nameTokens(label);
  final nameTokens = _nameTokens(divisionName);
  if (labelTokens.isEmpty || labelTokens.length != nameTokens.length) {
    return false;
  }
  return nameTokens.containsAll(labelTokens);
}

/// Suy kiểu thi đấu cho hạng mục mới từ tên trong file (port
/// `inferDivisionMatchType` của web, `pairLayout` web tương đương việc các dòng
/// có VĐV 2): "hỗn hợp"/mixed/nam+nữ → đôi nam nữ, có "đôi"/doubles hoặc có
/// dòng VĐV 2 → đôi, còn lại → đơn.
String _inferMatchType(String label, {required bool anyRowHasPlayer2}) {
  final folded = ' ${_foldName(label)} ';
  final tokens = _nameTokens(label);
  if (folded.contains(' hon hop ') ||
      tokens.contains('mixed') ||
      (tokens.contains('nam') && tokens.contains('nu'))) {
    return 'MIXED_DOUBLES';
  }
  if (tokens.contains('doi') ||
      tokens.contains('doubles') ||
      tokens.contains('double') ||
      anyRowHasPlayer2) {
    return 'DOUBLES';
  }
  return 'SINGLES';
}

/// Giới tính tên hạng mục tuyên bố (port `inferDivisionGender` của web);
/// null khi tên không nói gì (`Đôi Linh Hoạt`, `Doubles`) — hạng mục mở cho
/// mọi giới tính.
String? _inferGender(String label) {
  final folded = ' ${_foldName(label)} ';
  final tokens = _nameTokens(label);
  final male =
      tokens.contains('nam') ||
      tokens.contains('men') ||
      tokens.contains('male');
  final female =
      tokens.contains('nu') ||
      tokens.contains('women') ||
      tokens.contains('female');
  if (folded.contains(' hon hop ') ||
      tokens.contains('mixed') ||
      (male && female)) {
    return 'MIXED';
  }
  if (male) return 'MALE';
  if (female) return 'FEMALE';
  return null;
}

/// Lựa chọn tài khoản của một người chơi. `auto` là chưa chọn: được tự liên kết
/// khi đúng một tài khoản khớp email chính xác (giống web `undecided`).
enum _LinkChoice { auto, unlinked, linked }

class _PlayerLink {
  const _PlayerLink._(this.choice, this.userId);
  const _PlayerLink.auto() : this._(_LinkChoice.auto, null);
  const _PlayerLink.unlinked() : this._(_LinkChoice.unlinked, null);
  const _PlayerLink.linked(String id) : this._(_LinkChoice.linked, id);

  final _LinkChoice choice;
  final String? userId;
}

/// Nội dung đích của một dòng. `divisionId` null nghĩa là không khớp giải.
class _DivisionTarget {
  const _DivisionTarget({
    required this.key,
    required this.label,
    required this.divisionId,
    required this.isDoubles,
  });

  factory _DivisionTarget.matched(TournamentDivision division) =>
      _DivisionTarget(
        key: division.id,
        label: division.name,
        divisionId: division.id,
        isDoubles: _isDoublesType(division.matchType),
      );

  /// Khóa nhóm: id nội dung, hoặc `unmatched:<tên chuẩn hóa>` khi không khớp.
  final String key;
  final String label;
  final String? divisionId;
  final bool isDoubles;
}

/// Một dòng đọc từ Excel kèm trạng thái kiểm tra cục bộ và lựa chọn tài khoản.
class _DraftRow {
  _DraftRow({required this.index, required this.parsed, required this.target});

  /// clientRowIndex: duy nhất trên toàn workbook.
  final int index;
  final RosterParsedRow parsed;

  /// Nội dung đích; đổi được khi tạo hạng mục mới khớp tên trong file.
  _DivisionTarget target;
  List<String> localStatus = const [];
  _PlayerLink player1Link = const _PlayerLink.auto();
  _PlayerLink player2Link = const _PlayerLink.auto();

  bool get localEligible => !localStatus.any(_localBlockingCodes.contains);

  bool get hasPlayer2 => parsed.hasPlayer2;
}

/// Trạng thái hỏi AI về bố cục file: `rules` là luật đủ tin nên không hỏi.
///
/// `edited`: người dùng đã chỉnh cột ở popup Ghép cột, không còn là kết quả của luật hay AI.
enum _LayoutStatus {
  idle,
  rules,
  loading,
  done,
  unavailable,
  error,
  empty,
  edited,
}

class _DraftGroup {
  _DraftGroup(this.target);

  final _DivisionTarget target;
  final List<_DraftRow> rows = [];
}

class _ParsedWorkbook {
  const _ParsedWorkbook({
    required this.rows,
    required this.groups,
    required this.skippedSheets,
  });

  final List<_DraftRow> rows;
  final List<_DraftGroup> groups;
  final List<String> skippedSheets;
}

class _RowCandidates {
  const _RowCandidates({required this.player1, required this.player2});

  final List<RosterImportBatchCandidate> player1;
  final List<RosterImportBatchCandidate> player2;
}

/// Payload đã dựng kèm khóa so sánh. Khóa đổi thì preview cũ không còn đúng.
class _Plan {
  const _Plan({required this.request, required this.key});

  final RosterImportBatchRequest request;
  final String key;
}

/// Kiểm tra cục bộ theo `revalidateLocally` của web: trùng email trong file và quy tắc VĐV 2.
List<String> _localStatusOf(_DraftRow row, {required bool duplicate}) {
  final parsed = row.parsed;
  final codes = <String>[...parsed.localErrors];
  void add(String code) {
    if (!codes.contains(code)) codes.add(code);
  }

  if (parsed.player1Name == null) add('MISSING_NAME');
  if (duplicate) add('DUPLICATE_IN_FILE');
  // Quy tắc VĐV 2 chỉ áp dụng khi nội dung đã khớp giải; chưa khớp thì server báo DIVISION_UNKNOWN.
  if (row.target.divisionId != null) {
    if (row.target.isDoubles) {
      if (parsed.player2Name == null &&
          parsed.player2Email == null &&
          parsed.player2Phone != null) {
        add('PLAYER2_REQUIRED');
      }
    } else if (row.hasPlayer2) {
      add('PLAYER2_NOT_ALLOWED');
    }
  }
  return codes;
}

/// Dòng được server coi là đủ điều kiện nhập (giống `resolveRosterRowStates` của web).
bool _isRowEligible(RosterImportBatchPreviewRow row) =>
    row.isEligible &&
    row.customResponseError == null &&
    !row.status.any(_serverBlockingCodes.contains);

/// Chỉ số các dòng có email hợp lệ xuất hiện nhiều lần trong file (cả VĐV 1
/// lẫn VĐV 2) — dùng khi đọc file và khi remap sau khi tạo hạng mục.
Set<int> _duplicateRowIndices(List<_DraftRow> rows) {
  final owners = <String, List<int>>{};
  for (final row in rows) {
    for (final email in [row.parsed.player1Email, row.parsed.player2Email]) {
      if (email == null) continue;
      final key = email.trim().toLowerCase();
      if (!_emailPattern.hasMatch(key)) continue;
      owners.putIfAbsent(key, () => <int>[]).add(row.index);
    }
  }
  final duplicates = <int>{};
  for (final list in owners.values) {
    if (list.length > 1) duplicates.addAll(list);
  }
  return duplicates;
}

/// Tài khoản duy nhất có email khớp chính xác (trim, không phân biệt hoa thường).
String? _uniqueExactAccountId(
  String? email,
  List<RosterImportBatchCandidate>? candidates,
) {
  if (email == null || candidates == null) return null;
  final normalized = email.trim().toLowerCase();
  final matches = candidates
      .where((candidate) => candidate.email.trim().toLowerCase() == normalized)
      .toList(growable: false);
  return matches.length == 1 ? matches.first.userId : null;
}

String _statusLabel(AppLocalizations l10n, String code) {
  switch (code) {
    case 'FOUND':
      return l10n.rosterImportStatusFound;
    case 'NOT_FOUND':
      return l10n.rosterImportStatusNotFound;
    case 'INVALID_EMAIL':
      return l10n.rosterImportStatusInvalidEmail;
    case 'MISSING_EMAIL':
      return l10n.rosterImportStatusMissingEmail;
    case 'MISSING_NAME':
      return l10n.rosterImportStatusMissingName;
    case 'DUPLICATE_IN_FILE':
      return l10n.rosterImportStatusDuplicateInFile;
    case 'DUPLICATE_IN_TOURNAMENT':
      return l10n.rosterImportStatusDuplicateInTournament;
    case 'PLAYER2_REQUIRED':
      return l10n.rosterImportStatusPlayer2Required;
    case 'PLAYER2_NOT_ALLOWED':
      return l10n.rosterImportStatusPlayer2NotAllowed;
    case 'DIVISION_UNKNOWN':
      return l10n.rosterImportStatusDivisionUnknown;
    default:
      return l10n.rosterImportStatusUnknown;
  }
}

Widget _toneChip(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}

Widget _noticeText(String text, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

/// Màn nhập VĐV từ file Excel: chọn file, kiểm tra trên server, chọn tài khoản, rồi nhập các dòng đủ điều kiện.
class RosterImportSheet extends ConsumerStatefulWidget {
  const RosterImportSheet({
    super.key,
    required this.tournament,
    required this.defaultDivision,
    required this.onRefresh,
  });

  final Tournament tournament;

  /// Nội dung đang mở trên màn quản lý; dòng không có cột nội dung được nhập vào đây.
  final TournamentDivision defaultDivision;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<RosterImportSheet> createState() => _RosterImportSheetState();
}

class _RosterImportSheetState extends ConsumerState<RosterImportSheet> {
  List<_DraftRow> _rows = const [];
  List<_DraftGroup> _groups = const [];
  List<String> _skippedSheets = const [];

  /// Lưới đã điền ô gộp và các khối đang dùng (luật, rồi AI khi AI trả lời được).
  List<RosterGridSheet> _grid = const [];
  List<RosterReading> _readings = const [];
  _LayoutStatus _layoutStatus = _LayoutStatus.idle;

  /// Tăng mỗi lần đọc file hoặc hỏi AI để bỏ câu trả lời của lần cũ đến muộn.
  int _layoutRequest = 0;

  /// Tăng khi người dùng sửa dữ liệu (tài khoản, nội dung); câu trả lời AI đến sau đó bị bỏ.
  int _editRevision = 0;
  final Map<int, _RowCandidates> _candidates = {};
  String? _fileName;
  String? _fileError;
  String? _previewError;
  RosterImportBatchPreview? _preview;
  _Plan? _previewPlan;
  bool _reading = false;
  bool _previewing = false;
  bool _committing = false;
  bool _autoApprove = true;

  /// Bước xác nhận "tạo nội dung còn thiếu" đang chờ: tên nội dung trong file
  /// chưa khớp nội dung nào của giải. Đang chờ thì chưa chạy preview server.
  bool _pendingDivisionConfirm = false;

  /// Tên nội dung (đã fold) người dùng chọn tạo mới; mặc định chọn hết.
  Set<String> _createChoice = <String>{};

  /// Đang gọi createDivision cho các nội dung đã chọn.
  bool _creating = false;
  String? _createError;

  /// Nội dung vừa tạo trong phiên nhập này; `widget.tournament` không tự cập
  /// nhật nên phải gộp vào khi khớp tên nội dung của dòng.
  final List<TournamentDivision> _createdDivisions = [];

  /// Tăng mỗi lần chạy preview để bỏ kết quả của lần cũ đến muộn.
  int _previewGeneration = 0;

  @override
  void dispose() {
    _previewGeneration++;
    _layoutRequest++;
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Hạng mục có thể khớp: hạng mục của giải (theo thời điểm mở sheet) cộng
  /// hạng mục vừa tạo trong phiên nhập này.
  List<TournamentDivision> get _divisionPool => [
    ...widget.tournament.divisions,
    ..._createdDivisions,
  ];

  /// Nội dung đích: không có cột nội dung thì dùng nội dung đang mở; có tên mà
  /// không khớp (theo bộ từ, bất kể thứ tự — như web) thì không khớp giải.
  _DivisionTarget _targetFor(String? rawName) {
    if (rawName == null) return _DivisionTarget.matched(widget.defaultDivision);
    final folded = _foldName(rawName);
    for (final division in _divisionPool) {
      if (_divisionLabelMatches(rawName, division.name)) {
        return _DivisionTarget.matched(division);
      }
    }
    return _DivisionTarget(
      key: 'unmatched:$folded',
      label: rawName,
      divisionId: null,
      isDoubles: false,
    );
  }

  /// Nội dung đích là đôi? Nội dung của giải theo kiểu thật; nội dung chưa có (sẽ tạo từ tên trong file)
  /// theo kiểu suy từ tên, như web, để file `Đôi Nam` được ghép cặp trước cả khi nội dung được tạo.
  bool _isDoublesForLabel(String? divisionName) {
    final target = _targetFor(divisionName);
    if (target.divisionId != null) return target.isDoubles;
    return _isDoublesType(
      _inferMatchType(target.label, anyRowHasPlayer2: false),
    );
  }

  /// Đọc workbook bằng luật: từng sheet có dòng header thành một khối; sheet không có thì bị bỏ qua.
  ({List<RosterReading> readings, List<String> skipped}) _readByRules(
    List<RosterGridSheet> grid,
  ) {
    final readings = <RosterReading>[];
    final skipped = <String>[];
    for (final sheet in grid) {
      final reading = readSheetByRules(sheet);
      if (reading == null) {
        skipped.add(sheet.name);
      } else {
        readings.add(reading);
      }
    }
    return (readings: readings, skipped: skipped);
  }

  /// Ghép các dòng của mọi khối (cặp, VĐV lẻ) rồi dựng dòng nháp, kiểm tra cục bộ và nhóm theo nội dung.
  _ParsedWorkbook _assembleWorkbook(
    List<RosterReading> readings,
    List<String> skipped,
  ) {
    final rows = <_DraftRow>[];
    for (final reading in readings) {
      for (final parsed in assembleRosterRows(reading, _isDoublesForLabel)) {
        rows.add(
          _DraftRow(
            index: rows.length,
            parsed: parsed,
            target: _targetFor(parsed.divisionName),
          ),
        );
      }
    }

    // Email hợp lệ xuất hiện nhiều lần trong file (cả VĐV 1 lẫn VĐV 2) thì mọi dòng liên quan bị trùng.
    final duplicates = _duplicateRowIndices(rows);
    for (final row in rows) {
      row.localStatus = _localStatusOf(
        row,
        duplicate: duplicates.contains(row.index),
      );
    }

    final groupMap = <String, _DraftGroup>{};
    for (final row in rows) {
      groupMap
          .putIfAbsent(row.target.key, () => _DraftGroup(row.target))
          .rows
          .add(row);
    }
    return _ParsedWorkbook(
      rows: rows,
      groups: groupMap.values.toList(growable: false),
      skippedSheets: skipped,
    );
  }

  Future<void> _pickFile() async {
    if (_reading || _committing || _creating) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        // ignore: deprecated_member_use
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.first;
      // ignore: deprecated_member_use
      final bytes = picked.bytes;
      if (!mounted) return;
      if (bytes == null) {
        setState(() => _fileError = l10n.rosterImportReadFailed);
        return;
      }
      setState(() {
        _reading = true;
        _fileName = picked.name;
        _fileError = null;
      });
      final sheets = await readRosterWorkbook(bytes);
      if (!mounted) return;
      final requestId = ++_layoutRequest;
      _editRevision = 0;
      // Ô gộp được điền xuống trước khi đọc: cả hai dòng của một cặp mang STT và dấu thanh toán.
      final grid = [for (final sheet in sheets) fillRosterMerges(sheet)];
      final byRules = _readByRules(grid);
      _candidates.clear();
      _grid = grid;
      _readings = byRules.readings;
      final parsed = _assembleWorkbook(byRules.readings, byRules.skipped);
      // Luật đủ tin thì không chờ AI; không thì hỏi AI và giữ kết quả luật trên màn hình tới khi AI trả lời.
      final confident =
          grid.isEmpty ||
          rosterRulesAreConfident(grid, byRules.readings, _isDoublesForLabel);
      setState(() {
        _layoutStatus = confident ? _LayoutStatus.rules : _LayoutStatus.loading;
        _reading = false;
      });
      _installParsed(parsed);
      if (!confident) {
        unawaited(_requestAiLayout(requestId));
      } else if (!_pendingDivisionConfirm) {
        unawaited(_runPreview());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reading = false;
        _fileError = l10n.rosterImportReadFailed;
      });
    }
  }

  /// Số VĐV ở nội dung đôi chưa có VĐV 2: chờ BTC ghép cặp.
  int get _pendingPartnerCount => _rows
      .where(
        (row) => !row.hasPlayer2 && _isDoublesForLabel(row.parsed.divisionName),
      )
      .length;

  /// Đặt các dòng đọc được vào màn và mở bước xác nhận tạo nội dung nếu có tên chưa khớp.
  void _installParsed(_ParsedWorkbook parsed) {
    final unmatched = parsed.groups
        .where((group) => group.target.divisionId == null)
        .toList(growable: false);
    setState(() {
      _rows = parsed.rows;
      _groups = parsed.groups;
      _skippedSheets = parsed.skippedSheets;
      _preview = null;
      _previewPlan = null;
      _previewError = null;
      _createdDivisions.clear();
      // Có tên nội dung chưa khớp: dừng ở bước xác nhận tạo nội dung trước khi preview server.
      _pendingDivisionConfirm = unmatched.isNotEmpty;
      _createChoice = {
        for (final group in unmatched) _foldName(group.target.label),
      };
      _createError = null;
    });
  }

  /// Chưa đọc ra được người nào hoặc có sheet bị bỏ qua: gợi ý người dùng mở popup Ghép cột.
  bool get _mappingNeedsAttention =>
      _skippedSheets.isNotEmpty ||
      _rows.isEmpty ||
      !_readings.any(
        (reading) =>
            reading.mapping.indexOf(RosterSlot.player1Name) != null ||
            reading.mapping.indexOf(RosterSlot.teamName) != null,
      );

  /// Mở popup Ghép cột trên các khối đang dùng và các sheet bị bỏ qua; `Xong` mới đổi dữ liệu của màn.
  Future<void> _openMapping() async {
    final drafts = [
      for (final reading in _readings)
        RosterMappingDraft.fromReading(
          reading,
          isDoublesFor: _isDoublesForLabel,
        ),
      for (final name in _skippedSheets)
        for (final sheet in _grid)
          if (sheet.name == name)
            RosterMappingDraft.forSkippedSheet(
              sheet,
              isDoublesFor: _isDoublesForLabel,
            ),
    ];
    if (drafts.isEmpty) return;
    final result = await showRosterColumnMappingSheet(context, drafts: drafts);
    if (result == null || !mounted) return;
    _applyMapping(result);
  }

  /// Áp kết quả popup: dựng lại dòng từ các khối đã sửa. Không gọi `_installParsed` vì nó quên nội dung
  /// vừa tạo; liên kết tài khoản của dòng cũ mất vì chỉ số dòng không còn nghĩa.
  void _applyMapping(RosterMappingResult result) {
    _layoutRequest++;
    _editRevision++;
    _previewGeneration++;
    final parsed = _assembleWorkbook(result.readings, result.skippedSheets);
    final unmatched = parsed.groups
        .where((group) => group.target.divisionId == null)
        .toList(growable: false);
    setState(() {
      _readings = result.readings;
      _skippedSheets = parsed.skippedSheets;
      _layoutStatus = _LayoutStatus.edited;
      _rows = parsed.rows;
      _groups = parsed.groups;
      _preview = null;
      _previewPlan = null;
      _previewError = null;
      _previewing = false;
      _candidates.clear();
      _pendingDivisionConfirm = unmatched.isNotEmpty;
      _createChoice = {
        for (final group in unmatched) _foldName(group.target.label),
      };
      _createError = null;
    });
    if (!_pendingDivisionConfirm) unawaited(_runPreview());
  }

  /// Hỏi AI về bố cục khi luật không đủ tin. AI tắt (`aiAvailable: false`), hết lượt (429), lỗi (503) hay
  /// không tìm thấy bảng thì giữ kết quả luật và báo trạng thái. Câu trả lời đến sau khi người dùng đã sửa
  /// dữ liệu hoặc mở file khác bị bỏ. Một câu trả lời không có khối nào được hỏi lại một lần.
  Future<void> _requestAiLayout(int requestId) async {
    final repository = ref.read(rosterLayoutRepositoryProvider);
    final locale = Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'vi';
    final editRevision = _editRevision;
    _LayoutStatus outcome = _LayoutStatus.error;
    try {
      final digest = buildRosterLayoutDigest(_grid);
      for (var attempt = 0; attempt < 2; attempt++) {
        final response = await repository.analyzeRosterLayout(
          widget.tournament.id,
          sheets: digest,
          locale: locale,
          retryEmptyLayout: attempt > 0,
        );
        if (!mounted || requestId != _layoutRequest) return;
        final layout = response.layout;
        if (!response.aiAvailable || layout == null) {
          outcome = _LayoutStatus.unavailable;
          break;
        }
        if (_editRevision != editRevision) {
          outcome = _LayoutStatus.rules;
          break;
        }
        final readings = applyRosterLayout(_grid, layout);
        if (readings.isEmpty) {
          outcome = _LayoutStatus.empty;
          continue;
        }
        _readings = readings;
        setState(() => _layoutStatus = _LayoutStatus.done);
        _installParsed(_assembleWorkbook(readings, const []));
        if (!_pendingDivisionConfirm) unawaited(_runPreview());
        return;
      }
    } catch (_) {
      if (!mounted || requestId != _layoutRequest) return;
      outcome = _LayoutStatus.error;
    }
    if (!mounted || requestId != _layoutRequest) return;
    setState(() => _layoutStatus = outcome);
    if (!_pendingDivisionConfirm) unawaited(_runPreview());
  }

  /// Payload tạo hạng mục mới từ tên trong file, giống `createPendingDivision`
  /// của web (`RosterImportModal.tsx:1005-1008`): name + matchType suy từ tên
  /// (hoặc VĐV 2 của dòng). `genderRestriction` MIXED chỉ đi với
  /// MIXED_DOUBLES (Backend `tournament-input-policy.ts` từ chối MIXED cho
  /// đơn/đôi); với đơn/đôi chỉ gửi khi tên tuyên bố MALE/FEMALE rõ ràng.
  Map<String, dynamic> _divisionPayloadFor(_DraftGroup group) {
    final label = group.target.label;
    final matchType = _inferMatchType(
      label,
      anyRowHasPlayer2: group.rows.any((row) => row.hasPlayer2),
    );
    final String? gender;
    if (matchType == 'MIXED_DOUBLES') {
      gender = 'MIXED';
    } else {
      final inferred = _inferGender(label);
      gender = inferred == 'MALE' || inferred == 'FEMALE' ? inferred : null;
    }
    return {
      'name': label.trim(),
      'matchType': matchType,
      'genderRestriction': ?gender,
    };
  }

  /// Hạng mục trong pool trùng tên với [label] theo bộ từ bất kể thứ tự.
  TournamentDivision? _matchingDivision(
    List<TournamentDivision> pool,
    String label,
  ) {
    for (final division in pool) {
      if (_divisionLabelMatches(label, division.name)) return division;
    }
    return null;
  }

  /// Tạo các nội dung đã chọn ở bước xác nhận, rồi preview server như cũ.
  /// Hỏi server danh sách nội dung trước (như web): hạng mục trùng tên được tái
  /// dùng, không tạo lần hai. Thất bại thì quay lại bước xác nhận, các nội dung
  /// đã tạo giữ lại và không tạo trùng khi thử lại.
  Future<void> _createMissingDivisions() async {
    if (_creating || !_pendingDivisionConfirm) return;
    final l10n = AppLocalizations.of(context)!;
    final toCreate = [
      for (final group in _groups)
        if (group.target.divisionId == null &&
            _createChoice.contains(_foldName(group.target.label)))
          group,
    ];
    setState(() {
      _creating = true;
      _createError = null;
      _pendingDivisionConfirm = false;
    });
    try {
      if (toCreate.isNotEmpty) {
        final repository = ref.read(tournamentManagementRepositoryProvider);
        final available = <TournamentDivision>[..._divisionPool];
        final remote = await repository.getManageDivisions(
          widget.tournament.id,
        );
        for (final raw in remote) {
          available.add(
            TournamentDivision(
              id: raw['id']?.toString() ?? '',
              name: raw['name']?.toString() ?? '',
              matchType: raw['matchType']?.toString() ?? '',
            ),
          );
        }
        for (final group in toCreate) {
          final existing = _matchingDivision(available, group.target.label);
          if (existing != null) {
            _createdDivisions.add(existing);
            continue;
          }
          final payload = _divisionPayloadFor(group);
          final created = await repository.createDivision(
            widget.tournament.id,
            payload,
          );
          final division = TournamentDivision(
            id: created['id']?.toString() ?? '',
            name: (created['name'] ?? group.target.label).toString(),
            matchType: (created['matchType'] ?? payload['matchType'])
                .toString(),
          );
          available.add(division);
          _createdDivisions.add(division);
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _pendingDivisionConfirm = true;
        _createError = ErrorParser.parse(
          error,
          l10n.rosterImportCreateDivisionFailed,
          l10n,
        );
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _creating = false;
      _remapRows();
    });
    unawaited(_runPreview());
    await widget.onRefresh();
  }

  /// Bỏ qua bước tạo nội dung: preview như cũ, dòng chưa khớp bị server chặn.
  void _skipCreate() {
    if (_creating) return;
    setState(() => _pendingDivisionConfirm = false);
    unawaited(_runPreview());
  }

  /// Khớp lại nội dung đích của mọi dòng sau khi có hạng mục mới, tính lại
  /// trạng thái cục bộ (quy tắc VĐV 2 phụ thuộc nội dung đích) và nhóm.
  void _remapRows() {
    // Nội dung mới có thể là đôi: ghép lại các khối đang dùng theo nội dung đích mới.
    final parsed = _assembleWorkbook(_readings, _skippedSheets);
    _rows = parsed.rows;
    _groups = parsed.groups;
  }

  /// Dựng payload từ các dòng đạt kiểm tra cục bộ. Trả null khi không có gì để gửi.
  _Plan? _buildPlan() {
    if (_rows.isEmpty || _rows.length > _maxBatchParticipants) return null;
    final groups = <RosterImportBatchGroup>[];
    for (final group in _groups) {
      final items = <RosterImportBatchItem>[];
      for (final row in group.rows) {
        if (row.localEligible) items.add(_itemFor(row));
      }
      if (items.isEmpty) continue;
      groups.add(
        RosterImportBatchGroup(
          divisionId: group.target.divisionId,
          participants: items,
        ),
      );
    }
    if (groups.isEmpty) return null;
    final request = RosterImportBatchRequest(groups: groups);
    return _Plan(request: request, key: jsonEncode(request.toJson()));
  }

  RosterImportBatchItem _itemFor(_DraftRow row) {
    final parsed = row.parsed;
    final name1 = parsed.player1Name ?? '';
    final name2 = parsed.player2Name;
    final candidates = _candidates[row.index];
    final notes = parsed.notes;
    // Không có tên đội thì gửi rỗng; tuyệt đối không ghép tên VĐV.
    final teamName = parsed.teamName?.trim() ?? '';
    return RosterImportBatchItem(
      clientRowIndex: row.index,
      source: 'EXCEL',
      player1Name: name1,
      player1Email: parsed.player1Email,
      player1Phone: parsed.player1Phone,
      player2Name: name2,
      player2Email: parsed.player2Email,
      player2Phone: parsed.player2Phone,
      teamName: teamName,
      elo: parsed.elo,
      eloSource: parsed.eloSource,
      isPaid: parsed.isPaid,
      autoApprove: _autoApprove,
      sourceRowIndex: parsed.sourceRowIndex,
      sourceSheetName: parsed.sheetName,
      customResponses: notes == null || notes.isEmpty ? null : {'notes': notes},
      confirmedPlayer1UserId: _effectiveLink(
        row.player1Link,
        parsed.player1Email,
        candidates?.player1,
      ),
      confirmedPlayer2UserId: row.hasPlayer2
          ? _effectiveLink(
              row.player2Link,
              parsed.player2Email,
              candidates?.player2,
            )
          : null,
    );
  }

  /// Tài khoản thực sự gửi lên: lựa chọn của người dùng, hoặc tự liên kết khi chưa chọn.
  String? _effectiveLink(
    _PlayerLink link,
    String? email,
    List<RosterImportBatchCandidate>? candidates,
  ) {
    if (link.choice == _LinkChoice.linked) return link.userId;
    if (link.choice == _LinkChoice.unlinked) return null;
    return _uniqueExactAccountId(email, candidates);
  }

  void _absorbCandidates(RosterImportBatchPreview preview) {
    for (final group in preview.groups) {
      for (final row in group.rows) {
        _candidates[row.clientRowIndex] = _RowCandidates(
          player1: row.player1Candidates,
          player2: row.player2Candidates,
        );
      }
    }
  }

  /// Chạy preview. Nếu ứng viên mới làm thay đổi tài khoản tự liên kết, gửi lại như web (tối đa 3 lần).
  Future<void> _runPreview() async {
    final generation = ++_previewGeneration;
    if (_buildPlan() == null) {
      setState(() {
        _preview = null;
        _previewPlan = null;
        _previewing = false;
        _previewError = null;
      });
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.read(tournamentManagementRepositoryProvider);
    setState(() {
      _previewing = true;
      _previewError = null;
    });
    _Plan? sent;
    RosterImportBatchPreview? response;
    try {
      for (var attempt = 0; attempt < 3; attempt++) {
        final next = _buildPlan();
        if (next == null) break;
        if (sent != null && next.key == sent.key) break;
        sent = next;
        response = await repository.previewRosterImportBatch(
          widget.tournament.id,
          next.request,
        );
        if (!mounted || generation != _previewGeneration) return;
        _absorbCandidates(response);
      }
    } catch (error) {
      if (!mounted || generation != _previewGeneration) return;
      setState(() {
        _previewing = false;
        _preview = null;
        _previewPlan = null;
        _previewError = ErrorParser.parse(
          error,
          l10n.rosterImportPreviewFailed,
          l10n,
        );
      });
      return;
    }
    if (!mounted || generation != _previewGeneration) return;
    setState(() {
      _previewing = false;
      _preview = response;
      _previewPlan = sent;
    });
  }

  /// Nút mở popup Ghép cột: nổi bật khi chưa đọc ra người nào hoặc có sheet bị bỏ qua.
  Widget _mappingButton(AppLocalizations l10n, bool busy) {
    final onPressed = busy || _layoutStatus == _LayoutStatus.loading
        ? null
        : _openMapping;
    const icon = Icon(Icons.view_column_rounded);
    final label = Text(l10n.rosterMapOpen);
    const key = ValueKey('roster-import-open-mapping');
    return Align(
      alignment: Alignment.centerLeft,
      child: _mappingNeedsAttention
          ? FilledButton.icon(
              key: key,
              onPressed: onPressed,
              icon: icon,
              label: label,
            )
          : OutlinedButton.icon(
              key: key,
              onPressed: onPressed,
              icon: icon,
              label: label,
            ),
    );
  }

  void _setLink(_DraftRow row, int player, _PlayerLink link) {
    _editRevision++;
    setState(() {
      if (player == 1) {
        row.player1Link = link;
      } else {
        row.player2Link = link;
      }
    });
    unawaited(_runPreview());
  }

  void _chooseAccount(_DraftRow row, int player, String? value) {
    if (value == null) return;
    final link = value == _unlinkedValue
        ? const _PlayerLink.unlinked()
        : _PlayerLink.linked(value);
    _setLink(row, player, link);
  }

  void _setAutoApprove(bool value) {
    setState(() => _autoApprove = value);
    unawaited(_runPreview());
  }

  Set<int> _eligibleIndices(RosterImportBatchPreview preview) {
    final result = <int>{};
    for (final group in preview.groups) {
      for (final row in group.rows) {
        if (_isRowEligible(row)) result.add(row.clientRowIndex);
      }
    }
    return result;
  }

  Map<int, RosterImportBatchPreviewRow> _serverRowsByIndex(
    RosterImportBatchPreview? preview,
  ) {
    final result = <int, RosterImportBatchPreviewRow>{};
    if (preview == null) return result;
    for (final group in preview.groups) {
      for (final row in group.rows) {
        result[row.clientRowIndex] = row;
      }
    }
    return result;
  }

  /// Nhóm preview tương ứng với nhóm cục bộ. Nhóm không khớp giải được nhận diện qua dòng.
  RosterImportBatchPreviewGroup? _previewGroupFor(
    RosterImportBatchPreview preview,
    _DraftGroup group,
  ) {
    final divisionId = group.target.divisionId;
    final indices = {for (final row in group.rows) row.index};
    for (final previewGroup in preview.groups) {
      if (divisionId != null) {
        if (previewGroup.divisionId == divisionId) return previewGroup;
        continue;
      }
      if (previewGroup.divisionId != null) continue;
      if (previewGroup.rows.any(
        (row) => indices.contains(row.clientRowIndex),
      )) {
        return previewGroup;
      }
    }
    return null;
  }

  /// Lý do chặn commit: giải không khớp hoặc không đủ suất. Giống `capacityShortfall` của web.
  String? _blockReason(
    AppLocalizations l10n,
    RosterImportBatchPreview preview,
  ) {
    for (final group in _groups) {
      final previewGroup = _previewGroupFor(preview, group);
      if (previewGroup != null && !previewGroup.divisionMatched) {
        return l10n.rosterImportDivisionUnmatched(group.target.label);
      }
    }
    for (final group in _groups) {
      final previewGroup = _previewGroupFor(preview, group);
      if (previewGroup != null && !previewGroup.capacityFits) {
        return l10n.rosterImportCapacityShortfall(group.target.label);
      }
    }
    return null;
  }

  Future<void> _commit() async {
    final preview = _preview;
    final previewPlan = _previewPlan;
    if (_committing || preview == null || previewPlan == null) return;
    final l10n = AppLocalizations.of(context)!;
    final eligible = _eligibleIndices(preview);
    // Chỉ gửi dòng đủ điều kiện, giữ nguyên tài khoản đã xác định trong lần preview.
    final groups = <RosterImportBatchGroup>[];
    for (final group in previewPlan.request.groups) {
      final items = group.participants
          .where((item) => eligible.contains(item.clientRowIndex))
          .toList(growable: false);
      if (items.isEmpty) continue;
      groups.add(
        RosterImportBatchGroup(
          divisionId: group.divisionId,
          participants: items,
        ),
      );
    }
    if (groups.isEmpty) {
      _showMessage(l10n.rosterImportNoEligibleRows);
      return;
    }
    final request = RosterImportBatchRequest(groups: groups);
    final repository = ref.read(tournamentManagementRepositoryProvider);
    setState(() => _committing = true);

    RosterImportBatchResult? result;
    Object? failure;
    try {
      result = await repository.importRosterBatch(
        widget.tournament.id,
        request,
      );
    } catch (error) {
      failure = error;
    }
    if (!mounted) return;
    if (result == null) {
      // Giữ nguyên preview để thử lại đúng payload (cùng nội dung thì cùng Idempotency-Key).
      setState(() => _committing = false);
      _showMessage(
        ErrorParser.parse(failure, l10n.rosterImportCommitFailed, l10n),
      );
      return;
    }
    _showMessage(
      result.replayed
          ? l10n.rosterImportReplayed
          : l10n.rosterImportImported(result.importedCount),
    );
    await widget.onRefresh();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final total = _rows.length;
    final preview = _preview;
    final previewPlan = _previewPlan;
    final currentPlan = _buildPlan();
    final previewCurrent =
        preview != null &&
        previewPlan != null &&
        currentPlan != null &&
        currentPlan.key == previewPlan.key;
    final eligibleIndices = preview != null && previewCurrent
        ? _eligibleIndices(preview)
        : null;
    final eligibleCount =
        eligibleIndices?.length ??
        _rows.where((row) => row.localEligible).length;

    String? footerReason;
    if (total > _maxBatchParticipants) {
      footerReason = l10n.rosterImportTooManyRows(total, _maxBatchParticipants);
    } else if (currentPlan == null && total > 0) {
      footerReason = l10n.rosterImportNoEligibleRows;
    } else if (preview != null && previewCurrent) {
      footerReason =
          _blockReason(l10n, preview) ??
          (eligibleIndices != null && eligibleIndices.isEmpty
              ? l10n.rosterImportNoEligibleRows
              : null);
    }

    final canCommit =
        !_committing &&
        !_previewing &&
        previewCurrent &&
        eligibleIndices != null &&
        eligibleIndices.isNotEmpty &&
        footerReason == null;

    final busy = _reading || _committing || _creating;
    final fileError = _fileError;
    final previewError = _previewError;
    final createError = _createError;
    final serverRows = _serverRowsByIndex(preview);
    final createCount = _pendingDivisionConfirm
        ? _groups
              .where(
                (group) =>
                    group.target.divisionId == null &&
                    _createChoice.contains(_foldName(group.target.label)),
              )
              .length
        : 0;

    final top = <Widget>[
      Row(
        children: [
          FilledButton.icon(
            key: const ValueKey('roster-import-pick-file'),
            onPressed: busy ? null : _pickFile,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(l10n.rosterImportPickFile),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _reading ? l10n.rosterImportReading : (_fileName ?? ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      if (_fileName != null) ...[
        const SizedBox(height: 8),
        _mappingButton(l10n, busy),
      ],
      const SizedBox(height: 8),
      if (_fileName == null && !_reading)
        Text(
          l10n.rosterImportHint,
          style: TextStyle(color: colors.textMuted, fontSize: 13),
        ),
      if (fileError != null) _noticeText(fileError, colors.error),
      for (final sheet in _skippedSheets)
        _noticeText(l10n.rosterImportNoSheetHeader(sheet), colors.warning),
      if (_fileName != null && !_reading && _rows.isEmpty)
        _noticeText(l10n.rosterImportNoRows, colors.warning),
      if (_layoutStatus == _LayoutStatus.loading)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            key: const ValueKey('roster-import-ai-checking'),
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.rosterImportAiChecking,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      if (_layoutStatus == _LayoutStatus.done)
        _noticeText(l10n.rosterImportAiDone, colors.success),
      if (_layoutStatus == _LayoutStatus.unavailable)
        _noticeText(l10n.rosterImportAiUnavailable, colors.warning),
      if (_layoutStatus == _LayoutStatus.error)
        _noticeText(l10n.rosterImportAiError, colors.warning),
      if (_layoutStatus == _LayoutStatus.empty)
        _noticeText(l10n.rosterImportAiEmpty, colors.warning),
      if (_pendingPartnerCount > 0)
        _noticeText(
          l10n.rosterImportPendingPartnerCount(_pendingPartnerCount),
          colors.textSecondary,
        ),
      if (_pendingDivisionConfirm) ...[
        _noticeText(l10n.rosterImportCreateTitle, colors.warning),
        Text(
          l10n.rosterImportCreateHint,
          style: TextStyle(color: colors.textMuted, fontSize: 13),
        ),
        for (final group in _groups)
          if (group.target.divisionId == null)
            CheckboxListTile(
              key: ValueKey('roster-import-create-${group.target.key}'),
              value: _createChoice.contains(_foldName(group.target.label)),
              onChanged: (value) => setState(() {
                final folded = _foldName(group.target.label);
                if (value ?? false) {
                  _createChoice.add(folded);
                } else {
                  _createChoice.remove(folded);
                }
              }),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.rosterImportCreateRow(group.target.label),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                key: const ValueKey('roster-import-create-divisions'),
                onPressed: createCount == 0 ? null : _createMissingDivisions,
                child: Text(l10n.rosterImportCreateAndCheck(createCount)),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              key: const ValueKey('roster-import-skip-create'),
              onPressed: _skipCreate,
              child: Text(l10n.rosterImportSkipCreate),
            ),
          ],
        ),
        if (createError != null) _noticeText(createError, colors.error),
      ],
      // Đang tạo hạng mục: khối xác nhận đã tắt (_pendingDivisionConfirm =
      // false), spinner này là feedback duy nhất của bước tạo.
      if (_creating)
        Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.rosterImportCreatingDivisions,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      if (_rows.isNotEmpty) ...[
        Row(
          children: [
            Checkbox(
              value: _autoApprove,
              onChanged: busy
                  ? null
                  : (value) => _setAutoApprove(value ?? false),
            ),
            Expanded(
              child: Text(
                l10n.rosterImportAutoApprove,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
      if (_previewing)
        Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.rosterImportChecking,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      if (previewError != null)
        Row(
          children: [
            Expanded(
              child: Text(
                previewError,
                style: TextStyle(color: colors.error, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _runPreview,
              child: Text(l10n.rosterImportRetry),
            ),
          ],
        ),
    ];

    final items = <Widget>[];
    for (final group in _groups) {
      items.add(_groupHeader(context, group, preview));
      for (final row in group.rows) {
        items.add(_rowCard(context, row, serverRows[row.index]));
      }
    }

    return PopScope(
      canPop: !_committing && !_creating,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SizedBox.expand(
                  child: Material(
                    key: const ValueKey('roster-import-sheet'),
                    color: colors.bgCard,
                    clipBehavior: Clip.antiAlias,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.rosterImportTitle,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.rosterImportClose,
                                onPressed: _committing || _creating
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: CustomScrollView(
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    4,
                                    16,
                                    8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: top,
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (_, index) => items[index],
                                    childCount: items.length,
                                  ),
                                ),
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: colors.border),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (footerReason != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    footerReason,
                                    style: TextStyle(
                                      color: colors.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.rosterImportSummary(
                                        eligibleCount,
                                        total,
                                      ),
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: FilledButton(
                                      key: const ValueKey(
                                        'roster-import-commit',
                                      ),
                                      onPressed: canCommit ? _commit : null,
                                      child: Text(
                                        _committing
                                            ? l10n.rosterImportCommitting
                                            : l10n.rosterImportCommit(
                                                eligibleCount,
                                              ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _groupHeader(
    BuildContext context,
    _DraftGroup group,
    RosterImportBatchPreview? preview,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final previewGroup = preview == null
        ? null
        : _previewGroupFor(preview, group);
    final remaining = previewGroup?.capacityRemaining;
    final label = group.target.label;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (previewGroup != null && !previewGroup.divisionMatched)
            _noticeText(l10n.rosterImportDivisionUnmatched(label), colors.error)
          else ...[
            if (previewGroup != null && remaining != null)
              _noticeText(
                l10n.rosterImportCapacityInfo(
                  previewGroup.requestedTeamSlots.toInt(),
                  remaining.toInt(),
                ),
                colors.textSecondary,
              ),
            if (previewGroup != null && !previewGroup.capacityFits)
              _noticeText(
                l10n.rosterImportCapacityShortfall(label),
                colors.error,
              ),
          ],
        ],
      ),
    );
  }

  Widget _rowCard(
    BuildContext context,
    _DraftRow row,
    RosterImportBatchPreviewRow? server,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final parsed = row.parsed;
    final names = [
      parsed.player1Name,
      parsed.player2Name,
    ].whereType<String>().join(' / ');
    final emails = [
      parsed.player1Email,
      parsed.player2Email,
    ].whereType<String>().join(', ');
    final eligible = server != null && _isRowEligible(server);
    final codes = server != null ? server.status : row.localStatus;
    final candidates = _candidates[row.index];
    final customError = server?.customResponseError;
    return Container(
      key: ValueKey('roster-row-${row.index}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      names.isEmpty ? emails : names,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (emails.isNotEmpty)
                      Text(
                        emails,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      l10n.rosterImportRowSource(
                        parsed.sourceRowIndex,
                        parsed.sheetName,
                      ),
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                eligible ? Icons.check_circle_rounded : Icons.block_rounded,
                color: eligible ? colors.success : colors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                eligible
                    ? l10n.rosterImportWillImport
                    : l10n.rosterImportWillSkip,
                style: TextStyle(
                  color: eligible ? colors.success : colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (codes.isNotEmpty || customError != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final code in codes)
                  _toneChip(
                    _statusLabel(l10n, code),
                    _statusTone(context, code),
                  ),
                if (customError != null)
                  _toneChip(
                    l10n.rosterImportCustomResponseInvalid,
                    colors.error,
                  ),
              ],
            ),
          ],
          if (server != null) ...[
            _accountRow(
              context,
              row,
              1,
              candidates?.player1 ?? const <RosterImportBatchCandidate>[],
              parsed.player1Email,
            ),
            if (row.hasPlayer2)
              _accountRow(
                context,
                row,
                2,
                candidates?.player2 ?? const <RosterImportBatchCandidate>[],
                parsed.player2Email,
              ),
          ],
        ],
      ),
    );
  }

  Color _statusTone(BuildContext context, String code) {
    final colors = context.colors;
    if (code == 'FOUND') return colors.success;
    if (_serverBlockingCodes.contains(code) ||
        _localBlockingCodes.contains(code)) {
      return colors.error;
    }
    return colors.warning;
  }

  Widget _accountRow(
    BuildContext context,
    _DraftRow row,
    int player,
    List<RosterImportBatchCandidate> candidates,
    String? email,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    if (candidates.isEmpty) {
      if (email == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          l10n.rosterImportNoAccountMatch,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    final link = player == 1 ? row.player1Link : row.player2Link;
    final effective = _effectiveLink(link, email, candidates);
    final String? selected;
    if (link.choice == _LinkChoice.unlinked) {
      selected = _unlinkedValue;
    } else if (effective != null &&
        candidates.any((candidate) => candidate.userId == effective)) {
      selected = effective;
    } else {
      selected = null;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text(
            l10n.rosterImportAccountLabel(player),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              key: ValueKey('roster-account-${row.index}-$player'),
              isExpanded: true,
              value: selected,
              hint: Text(
                l10n.rosterImportChooseAccount,
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: _unlinkedValue,
                  child: Text(
                    l10n.rosterImportLeaveUnlinked,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                for (final candidate in candidates)
                  DropdownMenuItem<String>(
                    value: candidate.userId,
                    child: Text(
                      l10n.rosterImportCandidateLabel(
                        candidate.fullName,
                        candidate.email,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => _chooseAccount(row, player, value),
            ),
          ),
        ],
      ),
    );
  }
}
