import 'package:app_quanly_giaidau/core/services/roster_excel_reader.dart';
import 'package:app_quanly_giaidau/domain/entities/roster_import.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_layout.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixture_workbook.dart';

List<RosterParsedRow> _readRows(List<RosterGridSheet> grid) => [
  for (final sheet in grid)
    if (readSheetByRules(sheet) case final reading?)
      ...assembleRosterRows(reading, (_) => true),
];

List<List<FixtureCell>> _scoreTable(List<List<FixtureCell>> body) => [
  ['STT', 'Họ và tên VĐV', 'Điểm trình'],
  ...body,
];

void main() {
  group('TC-APP-ROSTER-SCORE: đọc điểm trình kèm cờ cần xem', () {
    test(
      'TC-APP-ROSTER-SCORE-01 số dính chữ hoặc đứng sau Top/Giải/Năm không phải điểm',
      () {
        expect(parseRosterScore('4P 600'), (
          value: 600,
          source: 'ELO',
          flag: null,
        ));
        expect(parseRosterScore('Top 8 CCTV 610'), (
          value: 610,
          source: 'ELO',
          flag: null,
        ));
        expect(parseRosterScore('Giải 2 Robinson 620'), (
          value: 620,
          source: 'ELO',
          flag: null,
        ));
        expect(parseRosterScore('Năm 2025: 600'), (
          value: 600,
          source: 'ELO',
          flag: null,
        ));
        expect(parseRosterScore('tầm 6xx'), isNull);
        // `Nam` (nam giới) không phải chữ năm: hai điểm được đọc và ô mang cờ.
        expect(parseRosterScore('Nam 620 Nữ 605'), (
          value: 620,
          source: 'ELO',
          flag: 'MULTIPLE',
        ));
      },
    );

    test('TC-APP-ROSTER-SCORE-02 khoảng điểm lấy số đầu và mang cờ RANGE', () {
      expect(parseRosterScore('605-610'), (
        value: 605,
        source: 'ELO',
        flag: 'RANGE',
      ));
      expect(parseRosterScore('tầm 600 ~ 605'), (
        value: 600,
        source: 'ELO',
        flag: 'RANGE',
      ));
    });

    test(
      'TC-APP-ROSTER-SCORE-03 nhiều điểm khác nhau lấy điểm ELO đầu và mang cờ MULTIPLE',
      () {
        expect(parseRosterScore('600 4P, 600 BTN, tầm 605 CCTV'), (
          value: 600,
          source: 'ELO',
          flag: 'MULTIPLE',
        ));
        expect(parseRosterScore('DUPR 4.0, VTF 620'), (
          value: 620,
          source: 'ELO',
          flag: 'MULTIPLE',
        ));
        expect(parseRosterScore('600 4P, 600 BTN'), (
          value: 600,
          source: 'ELO',
          flag: null,
        ));
      },
    );

    test(
      'TC-APP-ROSTER-SCORE-04 ô 6.2 trong cột ba chữ số đọc 620 (CONVERTED); ô có số không đọc được mang UNREADABLE',
      () async {
        final rows = _readRows(
          await workbookFrom(
            _scoreTable([
              [1, fakeName(0), '620'],
              [2, fakeName(1), '6.2'],
              [3, fakeName(2), '605'],
              [4, fakeName(3), 'tầm 6xx'],
            ]),
          ),
        );
        expect(rows[1].elo, 620);
        expect(rows[1].eloSource, 'ELO');
        expect(rows[1].eloFlags, ['CONVERTED']);
        expect(rows[0].eloFlags, isEmpty);
        expect(rows[3].elo, isNull);
        expect(rows[3].eloFlags, ['UNREADABLE']);
      },
    );

    test('TC-APP-ROSTER-SCORE-05 cột phần lớn DUPR giữ nguyên thang', () async {
      final rows = _readRows(
        await workbookFrom(
          _scoreTable([
            [1, fakeName(0), '3.5'],
            [2, fakeName(1), '4.25'],
            [3, fakeName(2), '620'],
          ]),
        ),
      );
      expect([for (final row in rows) row.eloSource], ['DUPR', 'DUPR', 'ELO']);
      expect(rows.every((row) => row.eloFlags.isEmpty), isTrue);
    });

    test(
      'TC-APP-ROSTER-SCORE-06 đôi gộp từ hai dòng giữ điểm từng VĐV, hiện tổng và gửi player1Elo/player2Elo',
      () async {
        final rows = _readRows(
          await workbookFrom(
            _scoreTable([
              [1, fakeName(0), '620'],
              [1, fakeName(1), '605-610'],
              [2, fakeName(2), '630'],
              [2, fakeName(3), ''],
            ]),
          ),
        );
        expect(rows, hasLength(2));
        expect(
          [rows[0].player1Elo, rows[0].player2Elo, rows[0].elo],
          [620, 605, 613],
        );
        expect(rows[0].eloFlags, ['RANGE']);
        // Record chứa List không so bằng giá trị, nên so từng trường.
        final pair = rosterRowScores(rows[0]);
        expect(pair.parts, [620, 605]);
        expect(pair.total, 1225);
        final onlyFirst = rosterRowScores(rows[1]);
        expect(onlyFirst.parts, [630]);
        expect(onlyFirst.total, isNull);

        final json = RosterImportBatchItem(
          clientRowIndex: 0,
          player1Name: 'A',
          player2Name: 'B',
          teamName: '',
          elo: rows[0].elo,
          eloSource: rows[0].eloSource,
          player1Elo: rows[0].player1Elo,
          player2Elo: rows[0].player2Elo,
        ).toJson();
        expect(json['player1Elo'], 620);
        expect(json['player2Elo'], 605);
        expect(json['eloSource'], 'ELO');
        expect(json.containsKey('elo'), isFalse);
      },
    );

    test(
      'TC-APP-ROSTER-SCORE-07 bỏ VĐV 2 thì điểm của người đó không hiện',
      () async {
        final rows = _readRows(
          await workbookFrom(
            _scoreTable([
              [1, fakeName(0), '620'],
              [1, fakeName(1), '605'],
            ]),
          ),
        );
        final alone = rows.single.copyWith(
          clearPlayer2Name: true,
          clearPlayer2Email: true,
          clearPlayer2Phone: true,
          clearPlayer2Elo: true,
        );
        final scores = rosterRowScores(alone);
        expect(scores.parts, [620]);
        expect(scores.total, isNull);
        expect(alone.player2Elo, isNull);
      },
    );

    test(
      'TC-APP-ROSTER-SCORE-08 dòng không có điểm từng VĐV vẫn gửi elo như cũ',
      () {
        final json = const RosterImportBatchItem(
          clientRowIndex: 0,
          player1Name: 'A',
          teamName: '',
          elo: 620,
          eloSource: 'ELO',
        ).toJson();
        expect(json['elo'], 620);
        expect(json['eloSource'], 'ELO');
        expect(json.containsKey('player1Elo'), isFalse);
      },
    );
  });
}
