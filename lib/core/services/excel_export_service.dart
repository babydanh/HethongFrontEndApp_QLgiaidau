import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_event_model.dart';
import 'package:app_quanly_giaidau/core/utils/date_formatter_utils.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';

class ExcelExportService {
  static Future<void> exportMatchProtocol(MatchModel match) async {
    final l10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);
    final team1Label = matchSideLabel(match, 1);
    final team2Label = matchSideLabel(match, 2);
    var excel = Excel.createExcel();

    // Sheet 1: Tổng quan trận đấu
    Sheet overviewSheet = excel[l10n.excelOverviewSheet];
    excel.setDefaultSheet(l10n.excelOverviewSheet);
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    overviewSheet.appendRow([TextCellValue(l10n.excelMatchProtocolTitle)]);
    overviewSheet.appendRow([
      TextCellValue(l10n.excelStatus),
      TextCellValue(
        StatusHelper.getStatusDisplayName(match.status, l10n: l10n),
      ),
    ]);
    overviewSheet.appendRow([
      TextCellValue(l10n.excelRound),
      IntCellValue(match.round),
    ]);
    overviewSheet.appendRow([
      TextCellValue(l10n.excelMatchNumber),
      IntCellValue(match.matchNumber),
    ]);
    overviewSheet.appendRow([
      TextCellValue(l10n.excelStartTime),
      TextCellValue(
        match.startedAt != null
            ? DateFormatterUtils.formatDateTime(match.startedAt!)
            : l10n.excelNotStarted,
      ),
    ]);
    overviewSheet.appendRow([
      TextCellValue(l10n.excelEndTime),
      TextCellValue(
        match.completedAt != null
            ? DateFormatterUtils.formatDateTime(match.completedAt!)
            : l10n.excelNotEnded,
      ),
    ]);
    overviewSheet.appendRow([TextCellValue('')]);

    overviewSheet.appendRow([
      TextCellValue(l10n.excelTeam1),
      TextCellValue(l10n.excelScore),
      TextCellValue(l10n.excelTeam2),
    ]);
    overviewSheet.appendRow([
      TextCellValue(team1Label),
      TextCellValue('${match.score1} - ${match.score2}'),
      TextCellValue(team2Label),
    ]);
    overviewSheet.appendRow([TextCellValue('')]);
    overviewSheet.appendRow([
      TextCellValue(l10n.excelWinner),
      TextCellValue(
        match.winnerId == match.team1Id
            ? team1Label
            : (match.winnerId == match.team2Id
                  ? team2Label
                  : l10n.excelUndetermined),
      ),
    ]);

    // Sheet 2: Lịch sử sự kiện (Timeline)
    Sheet timelineSheet = excel[l10n.excelTimelineSheet];
    timelineSheet.appendRow([
      TextCellValue(l10n.excelTime),
      TextCellValue(l10n.excelTeam),
      TextCellValue(l10n.excelEvent),
      TextCellValue(l10n.excelPointsChanged),
      TextCellValue(l10n.excelNotes),
    ]);

    for (var event in match.events) {
      final teamName = event.teamId == match.team1Id ? team1Label : team2Label;
      final timeStr = DateFormatterUtils.formatTimeWithSeconds(event.timestamp);
      String eventTypeStr = l10n.excelOtherEvent;
      switch (event.type) {
        case MatchEventType.score:
          eventTypeStr = l10n.excelScoreEvent;
          break;
        case MatchEventType.foul:
          eventTypeStr = l10n.excelFoulEvent;
          break;
        case MatchEventType.yellowCard:
          eventTypeStr = l10n.excelYellowCardEvent;
          break;
        case MatchEventType.redCard:
          eventTypeStr = l10n.excelRedCardEvent;
          break;
        case MatchEventType.injury:
          eventTypeStr = l10n.excelInjuryEvent;
          break;
        case MatchEventType.penalty:
          eventTypeStr = l10n.excelPenaltyEvent;
          break;
        case MatchEventType.other:
          eventTypeStr = l10n.excelOtherEvent;
          break;
      }

      timelineSheet.appendRow([
        TextCellValue(timeStr),
        TextCellValue(teamName),
        TextCellValue(eventTypeStr),
        IntCellValue(event.pointsChange),
        TextCellValue(event.description),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) return;

    final fileName =
        '${l10n.excelMatchProtocolFilePrefix}_${team1Label}_vs_${team2Label}_${DateFormatterUtils.formatFileTime(DateTime.now())}.xlsx'
            .replaceAll('/', '-')
            .replaceAll(' ', '_');

    if (kIsWeb) {
      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(fileBytes),
          name: fileName,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ], text: l10n.excelMatchProtocolShare);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile(filePath),
      ], text: l10n.excelMatchProtocolShare);
    }
  }

  static Future<void> exportTournamentData(
    String tournamentName,
    List<MatchModel> matches,
  ) async {
    final l10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);
    var excel = Excel.createExcel();

    // Sheet 1: Danh sách các trận đấu
    Sheet overviewSheet = excel[l10n.excelResultsSheet];
    excel.setDefaultSheet(l10n.excelResultsSheet);
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    overviewSheet.appendRow([
      TextCellValue(l10n.excelResultsTitle(tournamentName)),
    ]);
    overviewSheet.appendRow([TextCellValue('')]);

    overviewSheet.appendRow([
      TextCellValue(l10n.excelRound),
      TextCellValue(l10n.excelMatchNumber),
      TextCellValue(l10n.excelTeam1),
      TextCellValue(l10n.excelScore1),
      TextCellValue(l10n.excelScore2),
      TextCellValue(l10n.excelTeam2),
      TextCellValue(l10n.excelWinnerHeader),
      TextCellValue(l10n.excelStatusHeader),
      TextCellValue(l10n.excelEndTimeHeader),
      TextCellValue(l10n.excelReferee),
    ]);

    for (var match in matches) {
      final team1Label = matchSideLabel(match, 1);
      final team2Label = matchSideLabel(match, 2);
      final winnerName = match.winnerId == match.team1Id
          ? team1Label
          : (match.winnerId == match.team2Id ? team2Label : '');

      overviewSheet.appendRow([
        IntCellValue(match.round),
        IntCellValue(match.matchNumber),
        TextCellValue(team1Label),
        IntCellValue(match.score1),
        IntCellValue(match.score2),
        TextCellValue(team2Label),
        TextCellValue(winnerName),
        TextCellValue(
          StatusHelper.getStatusDisplayName(match.status, l10n: l10n),
        ),
        TextCellValue(
          match.completedAt != null
              ? DateFormatterUtils.formatDateTime(match.completedAt!)
              : '',
        ),
        TextCellValue(match.refereeName ?? ''),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) return;

    final fileName =
        '${l10n.excelResultsFilePrefix}_${tournamentName}_${DateFormatterUtils.formatFileTime(DateTime.now())}.xlsx'
            .replaceAll(' ', '_');

    if (kIsWeb) {
      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(fileBytes),
          name: fileName,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ], text: l10n.excelResultsShare(tournamentName));
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(fileBytes);

      if (Platform.isAndroid || Platform.isIOS) {
        // ignore: deprecated_member_use
        await Share.shareXFiles([
          XFile(file.path),
        ], text: l10n.excelResultsShare(tournamentName));
      }
    }
  }

  /// Ma trận lịch để in/xuất: hàng là từng khung 15 phút, cột là từng sân.
  ///
  /// Hàm thuần (không I/O) để kiểm thử được: trận nằm ở hàng đúng khung giờ bắt
  /// đầu và cột đúng sân của nó; ô còn lại để trống.
  static List<List<String>> buildScheduleMatrix({
    required List<String> courts,
    required List<MatchModel> matches,
    required int startHour,
    required int endHour,
  }) {
    final rows = <List<String>>[
      ['', ...courts],
    ];
    if (courts.isEmpty || endHour <= startHour) return rows;

    for (var minute = startHour * 60; minute < endHour * 60; minute += 15) {
      final label =
          '${(minute ~/ 60).toString().padLeft(2, '0')}:'
          '${(minute % 60).toString().padLeft(2, '0')}';
      final row = <String>[label];
      for (final court in courts) {
        row.add(_scheduleCellLabel(matches, court, minute));
      }
      rows.add(row);
    }
    return rows;
  }

  /// Tên trận bắt đầu trong khung [minute] ở [court], trống nếu không có.
  static String _scheduleCellLabel(
    List<MatchModel> matches,
    String court,
    int minute,
  ) {
    for (final match in matches) {
      final start = match.scheduledTime;
      if (start == null) continue;
      final matchCourt = (match.courtName?.trim().isNotEmpty ?? false)
          ? match.courtName!.trim()
          : match.court.trim();
      if (matchCourt != court) continue;
      if (start.hour * 60 + start.minute != minute) continue;
      final first = matchSideLabel(match, 1);
      final second = matchSideLabel(match, 2);
      return '${first.isEmpty ? '?' : first} - ${second.isEmpty ? '?' : second}';
    }
    return '';
  }

  /// Xuất lịch thi đấu ra Excel rồi mở bảng chia sẻ.
  static Future<void> exportSchedule({
    required String title,
    required List<String> courts,
    required List<MatchModel> matches,
    required int startHour,
    required int endHour,
  }) async {
    final l10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);
    final excel = Excel.createExcel();
    final sheet = excel[l10n.exportData];
    excel.setDefaultSheet(l10n.exportData);
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    for (final row in buildScheduleMatrix(
      courts: courts,
      matches: matches,
      startHour: startHour,
      endHour: endHour,
    )) {
      sheet.appendRow([for (final cell in row) TextCellValue(cell)]);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) return;

    final fileName =
        '${title.replaceAll(RegExp(r'[^A-Za-z0-9_\\-]'), '_')}'
        '_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    if (kIsWeb) {
      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile.fromData(
          Uint8List.fromList(fileBytes),
          name: fileName,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ], text: l10n.exportData);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(fileBytes);
      if (Platform.isAndroid || Platform.isIOS) {
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path)], text: l10n.exportData);
      }
    }
  }
}
