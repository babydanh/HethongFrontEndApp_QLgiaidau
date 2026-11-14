import 'package:app_quanly_giaidau/domain/entities/roster_import.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_division_match.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';

/// Giới hạn số dòng mỗi lần nhập, giống `MAX_BATCH_PARTICIPANTS` của web.
const int rosterMaxBatchParticipants = 500;

/// Mã kiểm tra cục bộ chặn dòng, giống `BLOCKING_ROW_STATUSES` của web (phần làm được ở app).
const Set<String> rosterLocalBlockingCodes = {
  'INVALID_EMAIL',
  'MISSING_NAME',
  'DUPLICATE_IN_FILE',
  'PLAYER2_REQUIRED',
  'PLAYER2_NOT_ALLOWED',
};

/// Mã server chặn dòng khi nhập. `MISSING_EMAIL` không chặn: dòng vẫn được nhập.
const Set<String> rosterServerBlockingCodes = {
  'INVALID_EMAIL',
  'MISSING_NAME',
  'DUPLICATE_IN_FILE',
  'DUPLICATE_IN_TOURNAMENT',
  'PLAYER2_REQUIRED',
  'PLAYER2_NOT_ALLOWED',
  'DIVISION_UNKNOWN',
};

final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Lựa chọn tài khoản của một người chơi. `auto` là chưa chọn: được tự liên kết
/// khi đúng một tài khoản khớp email chính xác (giống web `undecided`).
enum RosterLinkChoice { auto, unlinked, linked }

class RosterPlayerLink {
  const RosterPlayerLink._(this.choice, this.userId);
  const RosterPlayerLink.auto() : this._(RosterLinkChoice.auto, null);
  const RosterPlayerLink.unlinked() : this._(RosterLinkChoice.unlinked, null);
  const RosterPlayerLink.linked(String id)
    : this._(RosterLinkChoice.linked, id);

  final RosterLinkChoice choice;
  final String? userId;
}

/// Nội dung đích của một dòng. `divisionId` null nghĩa là không khớp giải.
class RosterDivisionTarget {
  const RosterDivisionTarget({
    required this.key,
    required this.label,
    required this.divisionId,
    required this.isDoubles,
  });

  factory RosterDivisionTarget.matched(TournamentDivision division) =>
      RosterDivisionTarget(
        key: division.id,
        label: division.name,
        divisionId: division.id,
        isDoubles: isDoublesType(division.matchType),
      );

  /// Khóa nhóm: id nội dung, hoặc `unmatched:<tên chuẩn hóa>` khi không khớp.
  final String key;
  final String label;
  final String? divisionId;
  final bool isDoubles;
}

/// Một dòng đọc từ Excel kèm trạng thái kiểm tra cục bộ và lựa chọn tài khoản.
class RosterDraftRow {
  RosterDraftRow({
    required this.index,
    required this.parsed,
    required this.target,
  });

  /// clientRowIndex: duy nhất trên toàn workbook.
  final int index;
  RosterParsedRow parsed;

  /// Nội dung đích; đổi được khi tạo hạng mục mới khớp tên trong file.
  RosterDivisionTarget target;
  List<String> localStatus = const [];
  RosterPlayerLink player1Link = const RosterPlayerLink.auto();
  RosterPlayerLink player2Link = const RosterPlayerLink.auto();

  bool get localEligible => !localStatus.any(rosterLocalBlockingCodes.contains);

  bool get hasPlayer2 => parsed.hasPlayer2;
}

class RosterDraftGroup {
  RosterDraftGroup(this.target);

  final RosterDivisionTarget target;
  final List<RosterDraftRow> rows = [];
}

class RosterRowCandidates {
  const RosterRowCandidates({required this.player1, required this.player2});

  final List<RosterImportBatchCandidate> player1;
  final List<RosterImportBatchCandidate> player2;
}

/// Payload đã dựng kèm khóa so sánh. Khóa đổi thì preview cũ không còn đúng.
class RosterPlan {
  const RosterPlan({required this.request, required this.key});

  final RosterImportBatchRequest request;
  final String key;
}

/// Kiểm tra cục bộ theo `revalidateLocally` của web: trùng email trong file và quy tắc VĐV 2.
List<String> rosterLocalStatusOf(
  RosterDraftRow row, {
  required bool duplicate,
}) {
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
bool rosterIsRowEligible(RosterImportBatchPreviewRow row) =>
    row.isEligible &&
    row.customResponseError == null &&
    !row.status.any(rosterServerBlockingCodes.contains);

/// Chỉ số các dòng có email hợp lệ xuất hiện nhiều lần trong file (cả VĐV 1
/// lẫn VĐV 2) — dùng khi đọc file và khi remap sau khi tạo hạng mục.
Set<int> rosterDuplicateRowIndices(List<RosterDraftRow> rows) {
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
String? rosterUniqueExactAccountId(
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
