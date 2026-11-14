import 'dart:io';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/roster_excel_reader.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_layout.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_excel_corpus.dart';

/// Đường đọc đầy đủ như màn nhập (không AI): luật đọc từng sheet rồi ghép cho nội dung đôi hoặc đơn.
Future<({List<RosterParsedRow> rows, int skippedSheets})> _readWorkbook(
  Uint8List bytes, {
  required bool doubles,
}) async {
  final sheets = await readRosterWorkbook(bytes);
  final rows = <RosterParsedRow>[];
  var skipped = 0;
  for (final sheet in sheets) {
    final reading = readSheetByRules(sheet);
    if (reading == null) {
      skipped++;
      continue;
    }
    rows.addAll(assembleRosterRows(reading, (_) => doubles));
  }
  return (rows: rows, skippedSheets: skipped);
}

int _errorCount(List<RosterParsedRow> rows, String code) =>
    rows.where((row) => row.localErrors.contains(code)).length;

void main() {
  group('TC-ROSTER-CORPUS: file Excel giả đi qua đường đọc của màn nhập', () {
    for (final item in rosterCorpus()) {
      test('TC-ROSTER-CORPUS ${item.id}: ${item.title}', () async {
        final result = await _readWorkbook(item.bytes, doubles: item.doubles);
        final rows = result.rows;

        if (item.expectNoReading) {
          expect(rows, isEmpty, reason: 'không có tiêu đề thì không có dòng');
          expect(result.skippedSheets, item.sheets.length);
          return;
        }
        if (item.expectedRows != null) {
          expect(rows.length, item.expectedRows, reason: 'số dòng');
        }
        if (item.expectedPairs != null) {
          expect(
            rows.where((row) => row.hasPlayer2).length,
            item.expectedPairs,
            reason: 'số dòng có VĐV 2',
          );
        }
        item.expectedErrors.forEach((code, count) {
          expect(_errorCount(rows, code), count, reason: 'lỗi $code');
        });
      });
    }
  });

  group('TC-ROSTER-CORPUS-RULES: quy tắc chi tiết trên file giả', () {
    test(
      'TC-ROSTER-CORPUS-RULES-01 cột nhạy cảm không lọt vào dòng nào',
      () async {
        final item = rosterCorpus().firstWhere(
          (c) => c.id == 'single-sensitive-columns',
        );
        final rows = (await _readWorkbook(item.bytes, doubles: false)).rows;
        final dump = [
          for (final row in rows)
            [
              row.player1Name,
              row.player1Email,
              row.player1Phone,
              row.notes,
              row.partnerHint,
            ].join('|'),
        ].join('\n');
        expect(dump, isNot(contains('079000000001')));
        expect(dump, isNot(contains('01/01/1990')));
        expect(dump, isNot(contains('Q1')));
      },
    );

    test(
      'TC-ROSTER-CORPUS-RULES-02 khoảng trắng thừa được cắt và email gọn',
      () async {
        final item = rosterCorpus().firstWhere(
          (c) => c.id == 'unicode-spacing',
        );
        final rows = (await _readWorkbook(item.bytes, doubles: false)).rows;
        expect(rows.first.player1Name, isNot(startsWith(' ')));
        expect(rows.first.player1Name, isNot(endsWith(' ')));
        expect(rows.first.player1Email?.trim(), rows.first.player1Email);
        expect(rows[1].player1Name, 'Đặng Quốc Việt');
      },
    );

    test(
      'TC-ROSTER-CORPUS-RULES-03 cột gợi ý đồng đội không thành VĐV 2',
      () async {
        final item = rosterCorpus().firstWhere(
          (c) => c.id == 'doubles-partner-hint',
        );
        final rows = (await _readWorkbook(item.bytes, doubles: true)).rows;
        expect(rows.every((row) => !row.hasPlayer2), isTrue);
        expect(rows.first.partnerHint, 'Anh Bình');
      },
    );

    test(
      'TC-ROSTER-CORPUS-RULES-04 dấu phí: x và số tiền là đã đóng, trống là chưa',
      () async {
        final item = rosterCorpus().firstWhere((c) => c.id == 'single-basic');
        final rows = (await _readWorkbook(item.bytes, doubles: false)).rows;
        // Dòng i có 'x' khi i chẵn (i = 1..5): dòng thứ 2 và 4.
        expect(rows.map((row) => row.isPaid).toList(), [
          false,
          true,
          false,
          true,
          false,
        ]);
      },
    );

    test(
      'TC-ROSTER-CORPUS-RULES-05 file hỏng (không phải xlsx) báo lỗi, không treo',
      () async {
        await expectLater(
          readRosterWorkbook(Uint8List.fromList(List.filled(64, 7))),
          throwsA(anything),
        );
      },
    );

    test('TC-ROSTER-CORPUS-RULES-06 file xlsx rỗng byte báo lỗi', () async {
      await expectLater(readRosterWorkbook(Uint8List(0)), throwsA(anything));
    });
  });

  // File thật của người dùng: chỉ chạy máy local, đường dẫn truyền qua biến môi trường, không commit
  // file, không in tên hay SĐT hay email, chỉ in số đếm. Đặt `ROSTER_REAL_XLSX` là danh sách đường dẫn
  // cách nhau dấu `;`.
  final real = Platform.environment['ROSTER_REAL_XLSX'];
  group(
    'TC-ROSTER-REAL: file Excel thật của người dùng (chỉ chạy khi có biến môi trường)',
    () {
      final paths = (real ?? '')
          .split(';')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      for (final path in paths) {
        for (final doubles in [false, true]) {
          test(
            'TC-ROSTER-REAL ${File(path).uri.pathSegments.last.hashCode.abs()} '
            '${doubles ? 'đôi' : 'đơn'}',
            () async {
              final bytes = await File(path).readAsBytes();
              final result = await _readWorkbook(bytes, doubles: doubles);
              final rows = result.rows;
              final notesWithLongDigits = rows
                  .where((r) => RegExp(r'\d{9,}').hasMatch(r.notes ?? ''))
                  .length;
              // ignore: avoid_print
              print(
                'REAL-SUMMARY file#${File(path).uri.pathSegments.last.hashCode.abs()} '
                '${doubles ? 'doubles' : 'singles'}: rows=${rows.length} '
                'pairs=${rows.where((r) => r.hasPlayer2).length} '
                'singlesFlag=${rows.where((r) => r.singles).length} '
                'skippedSheets=${result.skippedSheets} '
                'MISSING_NAME=${_errorCount(rows, 'MISSING_NAME')} '
                'MISSING_EMAIL=${_errorCount(rows, 'MISSING_EMAIL')} '
                'INVALID_EMAIL=${_errorCount(rows, 'INVALID_EMAIL')} '
                'paid=${rows.where((r) => r.isPaid).length} '
                'notesWithLongDigits=$notesWithLongDigits',
              );
              expect(rows.length, lessThanOrEqualTo(5200));
              expect(
                notesWithLongDigits,
                0,
                reason: 'ghi chú không được chứa dãy số dài như CCCD',
              );
            },
          );
        }
      }
      if (paths.isEmpty) {
        test(
          'TC-ROSTER-REAL bỏ qua: chưa đặt ROSTER_REAL_XLSX',
          () {},
          skip: true,
        );
      }
    },
  );
}
