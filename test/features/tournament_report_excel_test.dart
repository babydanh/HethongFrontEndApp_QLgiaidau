import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

OrganizerOpsParticipant _participant(String id, String name) =>
    OrganizerOpsParticipant.fromJson({
      'id': id,
      'teamStatus': 'COMPLETE',
      'isPaid': false,
      'tournamentDivisionId': 'div-1',
      'players': [
        {'slot': 1, 'fullName': name, 'userId': null},
      ],
    });

MatchModel _match(String id) => MatchModel.fromJson({
  'id': id,
  'tournamentId': 't-1',
  'round': 1,
  'matchNumber': 1,
  'status': 'SCHEDULED',
  'team1Name': 'Doi A',
  'team2Name': 'Doi B',
}, id);

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));
  final participants = [
    _participant('p1', 'Nguoi Thu Nghiem Mot'),
    _participant('p2', 'Nguoi Thu Nghiem Hai'),
  ];
  final matches = [_match('m1'), _match('m2'), _match('m3')];

  test('report holds one sheet per ticked item and drops the default sheet', () {
    final excel = ExcelExportService.buildTournamentReport(
      sheets: TournamentReportSection.values.toSet(),
      tournamentName: 'Giai thu nghiem',
      participants: participants,
      divisionNameById: const {'div-1': 'Don nam'},
      matches: matches,
      l10n: l10n,
    );

    expect(excel.tables.keys.toList(), [
      l10n.excelRosterSheet,
      l10n.excelResultsSheet,
    ]);
    // Title row + blank row + header row + one row per record.
    expect(excel.tables[l10n.excelRosterSheet]!.maxRows, 3 + 2);
    expect(excel.tables[l10n.excelResultsSheet]!.maxRows, 3 + 3);
  });

  test('unticked sheets are left out', () {
    final excel = ExcelExportService.buildTournamentReport(
      sheets: {TournamentReportSection.matches},
      tournamentName: 'Giai thu nghiem',
      participants: participants,
      divisionNameById: const {},
      matches: matches,
      l10n: l10n,
    );

    expect(excel.tables.keys.toList(), [l10n.excelResultsSheet]);
  });

  test('an empty selection is refused', () {
    expect(
      () => ExcelExportService.buildTournamentReport(
        sheets: const {},
        tournamentName: 'Giai thu nghiem',
        participants: participants,
        divisionNameById: const {},
        matches: matches,
        l10n: l10n,
      ),
      throwsArgumentError,
    );
  });
}
