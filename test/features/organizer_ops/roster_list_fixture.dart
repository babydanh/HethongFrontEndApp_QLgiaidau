import 'package:app_quanly_giaidau/domain/entities/roster_import.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_import_draft.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';

import 'roster_fixture_workbook.dart';

/// Nội dung đích giả. `divisionId` null = không khớp giải.
RosterDivisionTarget fakeTarget({
  bool isDoubles = true,
  String? divisionId = 'd1',
}) => RosterDivisionTarget(
  key: divisionId ?? 'unmatched:x',
  label: isDoubles ? 'Đôi nam' : 'Đơn nam',
  divisionId: divisionId,
  isDoubles: isDoubles,
);

/// Dòng nháp dựng giả: dữ liệu từ `fakeName`/`fakePhone`, không dùng người thật.
RosterDraftRow fakeDraftRow({
  int index = 0,
  String? name1,
  String? email1,
  String? phone1,
  String? name2,
  String? email2,
  String? phone2,
  List<String> localStatus = const [],
  RosterDivisionTarget? target,
}) {
  final row = RosterDraftRow(
    index: index,
    parsed: RosterParsedRow(
      sheetName: 'Sheet1',
      sourceRowIndex: index + 2,
      localErrors: const [],
      player1Name: name1 ?? fakeName(index * 2),
      player1Email: email1,
      player1Phone: phone1 ?? fakePhone(index * 2),
      player2Name: name2,
      player2Email: email2,
      player2Phone: phone2,
    ),
    target: target ?? fakeTarget(),
  );
  row.localStatus = localStatus;
  return row;
}

/// Một dòng kết quả preview của server.
RosterImportBatchPreviewRow fakeServerRow({
  int index = 0,
  List<String> status = const [],
  bool isEligible = true,
  String? customResponseError,
  List<RosterImportBatchCandidate> candidates1 = const [],
  List<RosterImportBatchCandidate> candidates2 = const [],
}) => RosterImportBatchPreviewRow(
  clientRowIndex: index,
  rowIndex: index,
  player1Email: 'a$index@example.com',
  player2Email: null,
  status: status,
  isEligible: isEligible,
  capacityDelta: 1,
  customResponses: const {},
  customResponseError: customResponseError,
  player1Candidates: candidates1,
  player2Candidates: candidates2,
  confirmedPlayer1UserId: null,
  confirmedPlayer2UserId: null,
);
