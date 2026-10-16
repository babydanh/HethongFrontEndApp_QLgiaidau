import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';

/// In lịch thi đấu ra PDF rồi mở hộp thoại in của hệ thống.
///
/// Dùng lại `ExcelExportService.buildScheduleMatrix` để bản in và bản Excel
/// không lệch nhau (một nguồn duy nhất cho ma trận giờ × sân).
class SchedulePrintService {
  static Future<void> printSchedule({
    required String title,
    required List<String> courts,
    required List<MatchModel> matches,
    required int startHour,
    required int endHour,
  }) async {
    final rows = ExcelExportService.buildScheduleMatrix(
      courts: courts,
      matches: matches,
      startHour: startHour,
      endHour: endHour,
    );
    if (rows.isEmpty) return;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(level: 0, text: title),
          pw.TableHelper.fromTextArray(
            headers: rows.first,
            data: [for (final row in rows.skip(1)) row],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }
}
