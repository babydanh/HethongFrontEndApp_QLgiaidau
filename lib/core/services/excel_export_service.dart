import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_event_model.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/date_formatter_utils.dart';

class ExcelExportService {
  static Future<void> exportMatchProtocol(MatchModel match) async {
    var excel = Excel.createExcel();
    
    // Sheet 1: Tổng quan trận đấu
    Sheet overviewSheet = excel['Tổng quan'];
    excel.setDefaultSheet('Tổng quan');
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    overviewSheet.appendRow([TextCellValue('BIÊN BẢN TRẬN ĐẤU')]);
    overviewSheet.appendRow([TextCellValue('Trạng thái:'), TextCellValue(AppConstants.statusNames[match.status] ?? match.status)]);
    overviewSheet.appendRow([TextCellValue('Vòng:'), IntCellValue(match.round)]);
    overviewSheet.appendRow([TextCellValue('Trận số:'), IntCellValue(match.matchNumber)]);
    overviewSheet.appendRow([TextCellValue('Thời gian bắt đầu:'), TextCellValue(match.startedAt != null ? DateFormatterUtils.formatDateTime(match.startedAt!) : 'Chưa bắt đầu')]);
    overviewSheet.appendRow([TextCellValue('Thời gian kết thúc:'), TextCellValue(match.completedAt != null ? DateFormatterUtils.formatDateTime(match.completedAt!) : 'Chưa kết thúc')]);
    overviewSheet.appendRow([TextCellValue('')]);
    
    overviewSheet.appendRow([
      TextCellValue('Đội 1'), 
      TextCellValue('Điểm số'), 
      TextCellValue('Đội 2')
    ]);
    overviewSheet.appendRow([
      TextCellValue(match.team1Name), 
      TextCellValue('${match.score1} - ${match.score2}'), 
      TextCellValue(match.team2Name)
    ]);
    overviewSheet.appendRow([TextCellValue('')]);
    overviewSheet.appendRow([
      TextCellValue('Đội thắng cuộc:'), 
      TextCellValue(match.winnerId == match.team1Id ? match.team1Name : (match.winnerId == match.team2Id ? match.team2Name : 'Chưa xác định'))
    ]);

    // Sheet 2: Lịch sử sự kiện (Timeline)
    Sheet timelineSheet = excel['Lịch sử sự kiện'];
    timelineSheet.appendRow([
      TextCellValue('Thời gian'),
      TextCellValue('Đội'),
      TextCellValue('Sự kiện'),
      TextCellValue('Điểm thay đổi'),
      TextCellValue('Ghi chú')
    ]);

    for (var event in match.events) {
      final teamName = event.teamId == match.team1Id ? match.team1Name : match.team2Name;
      final timeStr = DateFormatterUtils.formatTimeWithSeconds(event.timestamp);
      String eventTypeStr = 'Khác';
      switch (event.type) {
        case MatchEventType.score:
          eventTypeStr = 'Ghi điểm';
          break;
        case MatchEventType.foul:
          eventTypeStr = 'Lỗi';
          break;
        case MatchEventType.yellowCard:
          eventTypeStr = 'Thẻ vàng';
          break;
        case MatchEventType.redCard:
          eventTypeStr = 'Thẻ đỏ';
          break;
        case MatchEventType.injury:
          eventTypeStr = 'Y tế/Chấn thương';
          break;
        case MatchEventType.penalty:
          eventTypeStr = 'Thẻ phạt';
          break;
        case MatchEventType.other:
          eventTypeStr = 'Khác';
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

    final fileName = 'BienBan_${match.team1Name}_vs_${match.team2Name}_${DateFormatterUtils.formatFileTime(DateTime.now())}.xlsx'.replaceAll(' ', '_');

    if (kIsWeb) {
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(fileBytes), name: fileName, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        text: 'Biên bản trận đấu',
      );
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Biên bản trận đấu',
      );
    }
  }

  static Future<void> exportTournamentData(String tournamentName, List<MatchModel> matches) async {
    var excel = Excel.createExcel();
    
    // Sheet 1: Danh sách các trận đấu
    Sheet overviewSheet = excel['Kết quả toàn giải'];
    excel.setDefaultSheet('Kết quả toàn giải');
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    overviewSheet.appendRow([TextCellValue('TỔNG HỢP KẾT QUẢ GIẢI ĐẤU: $tournamentName')]);
    overviewSheet.appendRow([TextCellValue('')]);
    
    overviewSheet.appendRow([
      TextCellValue('Vòng'),
      TextCellValue('Trận số'),
      TextCellValue('Đội 1'),
      TextCellValue('Điểm 1'),
      TextCellValue('Điểm 2'),
      TextCellValue('Đội 2'),
      TextCellValue('Đội thắng'),
      TextCellValue('Trạng thái'),
      TextCellValue('Thời gian kết thúc'),
      TextCellValue('Trọng tài'),
    ]);

    for (var match in matches) {
      final winnerName = match.winnerId == match.team1Id 
          ? match.team1Name 
          : (match.winnerId == match.team2Id ? match.team2Name : '');

      overviewSheet.appendRow([
        IntCellValue(match.round),
        IntCellValue(match.matchNumber),
        TextCellValue(match.team1Name),
        IntCellValue(match.score1),
        IntCellValue(match.score2),
        TextCellValue(match.team2Name),
        TextCellValue(winnerName),
        TextCellValue(AppConstants.statusNames[match.status] ?? match.status),
        TextCellValue(match.completedAt != null ? DateFormatterUtils.formatDateTime(match.completedAt!) : ''),
        TextCellValue(match.refereeName ?? ''),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes == null) return;

    final fileName = 'KetQua_${tournamentName}_${DateFormatterUtils.formatFileTime(DateTime.now())}.xlsx'.replaceAll(' ', '_');

    if (kIsWeb) {
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(fileBytes), name: fileName, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        text: 'Kết quả giải đấu $tournamentName',
      );
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(fileBytes);
      
      if (Platform.isAndroid || Platform.isIOS) {
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path)], text: 'Kết quả giải đấu $tournamentName');
      }
    }
  }
}
