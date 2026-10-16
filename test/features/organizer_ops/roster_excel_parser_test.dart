import 'package:app_quanly_giaidau/core/services/roster_excel_reader.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Header tiếng Việt đúng như file mẫu của web (12 cột).
const _headersVi = <String>[
  'STT',
  'Họ và tên VĐV 1',
  'Email VĐV 1 (không bắt buộc)',
  'Số điện thoại 1',
  'Họ và tên VĐV 2',
  'Email VĐV 2 (không bắt buộc)',
  'Số điện thoại 2',
  'Tên Đội (Tùy chọn)',
  'Nội dung đăng ký',
  'Điểm ELO (nếu có)',
  'Đã đóng lệ phí',
  'Ghi chú',
];

/// Header tiếng Anh đúng như file mẫu của web, cùng vị trí cột với bản tiếng Việt.
const _headersEn = <String>[
  'No.',
  'Player 1 name',
  'Player 1 email (optional)',
  'Player 1 phone',
  'Player 2 name',
  'Player 2 email (optional)',
  'Player 2 phone',
  'Team name (Optional)',
  'Registration format',
  'ELO points (if available)',
  'Entry fee paid',
  'Notes',
];

RosterGridSheet _sheet(List<List<String>> rows) =>
    RosterGridSheet(name: 'Danh sách', rows: rows);

/// Một dòng dữ liệu 12 ô theo đúng thứ tự cột của [_headersVi] và [_headersEn].
List<String> _dataRow({
  String name = '',
  String email = '',
  String phone = '',
  String player2Name = '',
  String player2Email = '',
  String player2Phone = '',
  String team = '',
  String division = '',
  String elo = '',
  String paid = '',
}) => [
  '1',
  name,
  email,
  phone,
  player2Name,
  player2Email,
  player2Phone,
  team,
  division,
  elo,
  paid,
  '',
];

/// Parse đúng một dòng dữ liệu nằm ngay dưới header [headers].
RosterParsedRow _parseOne(
  List<String> dataRow, {
  List<String> headers = _headersVi,
}) {
  final sheet = _sheet([headers, dataRow]);
  return parseRosterSheet(
    sheet,
    headerRowIndex: 0,
    mapping: detectRosterColumnMapping(headers),
  ).single;
}

void main() {
  group('detectRosterColumnMapping', () {
    test('nhận đúng cột với header tiếng Việt', () {
      final mapping = detectRosterColumnMapping(_headersVi);

      expect(mapping.indexOf(RosterSlot.player1Name), 1);
      expect(mapping.indexOf(RosterSlot.player1Email), 2);
      expect(mapping.indexOf(RosterSlot.player1Phone), 3);
      expect(mapping.indexOf(RosterSlot.player2Name), 4);
      expect(mapping.indexOf(RosterSlot.player2Email), 5);
      expect(mapping.indexOf(RosterSlot.player2Phone), 6);
      expect(mapping.indexOf(RosterSlot.teamName), 7);
      expect(mapping.indexOf(RosterSlot.divisionName), 8);
      expect(mapping.indexOf(RosterSlot.elo), 9);
      expect(mapping.indexOf(RosterSlot.isPaid), 10);
    });

    test('nhận đúng cột với header tiếng Anh', () {
      final mapping = detectRosterColumnMapping(_headersEn);

      expect(mapping.indexOf(RosterSlot.player1Name), 1);
      expect(mapping.indexOf(RosterSlot.player1Email), 2);
      expect(mapping.indexOf(RosterSlot.player1Phone), 3);
      expect(mapping.indexOf(RosterSlot.player2Name), 4);
      expect(mapping.indexOf(RosterSlot.player2Email), 5);
      expect(mapping.indexOf(RosterSlot.player2Phone), 6);
      expect(mapping.indexOf(RosterSlot.teamName), 7);
      expect(mapping.indexOf(RosterSlot.divisionName), 8);
      expect(mapping.indexOf(RosterSlot.elo), 9);
      expect(mapping.indexOf(RosterSlot.isPaid), 10);
    });

    test('cột "Họ và tên VĐV 2" không bị gán cho VĐV 1', () {
      final mapping = detectRosterColumnMapping([
        'Họ và tên VĐV 1',
        'Họ và tên VĐV 2',
      ]);

      expect(mapping.indexOf(RosterSlot.player1Name), 0);
      expect(mapping.indexOf(RosterSlot.player2Name), 1);
    });

    test('một cột chỉ được gán cho đúng một slot', () {
      for (final headers in [_headersVi, _headersEn]) {
        final columns = detectRosterColumnMapping(headers).columns.values
            .toList();

        expect(columns.toSet().length, columns.length);
      }
    });

    test('cột "Chưa đóng lệ phí" không bị đọc thành cột đã đóng phí', () {
      final mapping = detectRosterColumnMapping([
        'Họ và tên VĐV 1',
        'Chưa đóng lệ phí',
      ]);

      expect(mapping.indexOf(RosterSlot.isPaid), isNull);
    });
  });

  group('detectRosterHeaderRow', () {
    test('tìm đúng dòng header khi phía trên có dòng tiêu đề phụ', () {
      final sheet = _sheet([
        ['DANH SÁCH ĐĂNG KÝ GIẢI'],
        ['Giải Pickleball mùa thu 2026', ''],
        ['Họ và tên VĐV 1', 'Email VĐV 1', 'Số điện thoại 1'],
        ['Nguyễn Văn A', 'a@example.com', '0901234567'],
      ]);

      expect(detectRosterHeaderRow(sheet), 2);
    });

    test('không có cột tên VĐV 1 thì không nhận dòng nào làm header', () {
      final sheet = _sheet([
        ['Email', 'Điện thoại'],
        ['a@example.com', '0901234567'],
      ]);

      expect(detectRosterHeaderRow(sheet), isNull);
    });
  });

  group('parseRosterSheet', () {
    test('bỏ dòng trống và giữ sourceRowIndex theo dòng thật của sheet', () {
      final sheet = _sheet([
        ['Họ và tên VĐV 1', 'Email VĐV 1'], // dòng 1: header
        ['Nguyễn Văn A', 'a@example.com'], // dòng 2
        ['', ''], // dòng 3: trống
        ['  ', ''], // dòng 4: chỉ có khoảng trắng
        ['Trần Văn B', 'b@example.com'], // dòng 5
      ]);

      final rows = parseRosterSheet(
        sheet,
        headerRowIndex: 0,
        mapping: detectRosterColumnMapping(sheet.rows[0]),
      );

      expect(rows.map((row) => row.sourceRowIndex), [2, 5]);
      expect(rows.map((row) => row.player1Name), [
        'Nguyễn Văn A',
        'Trần Văn B',
      ]);
      expect(rows.every((row) => row.sheetName == 'Danh sách'), isTrue);
    });

    test('dòng phía trên header bị bỏ ngay cả khi có dữ liệu', () {
      final sheet = _sheet([
        ['Nguyễn Văn Z', 'z@example.com'],
        ['Họ và tên VĐV 1', 'Email VĐV 1'],
        ['A Văn', 'a@example.com'],
      ]);

      final rows = parseRosterSheet(
        sheet,
        headerRowIndex: 1,
        mapping: detectRosterColumnMapping(sheet.rows[1]),
      );

      expect(rows.length, 1);
      expect(rows.single.player1Name, 'A Văn');
      expect(rows.single.sourceRowIndex, 3);
    });
  });

  group('kiểm tra cục bộ (localErrors)', () {
    test('thiếu cả tên lẫn email thì báo MISSING_NAME và MISSING_EMAIL', () {
      final row = _parseOne(_dataRow(phone: '0901234567'));

      expect(row.localErrors, unorderedEquals(['MISSING_NAME', 'MISSING_EMAIL']));
    });

    test('có tên nhưng thiếu email thì chỉ báo MISSING_EMAIL', () {
      final row = _parseOne(_dataRow(name: 'Nguyễn Văn A'));

      expect(row.localErrors, ['MISSING_EMAIL']);
    });

    test('có email nhưng thiếu tên không báo MISSING_NAME, đúng như web', () {
      final row = _parseOne(_dataRow(email: 'a@example.com'));

      expect(row.localErrors, isEmpty);
    });

    test('email sai định dạng thì báo INVALID_EMAIL', () {
      final row = _parseOne(
        _dataRow(name: 'Nguyễn Văn A', email: 'nguyenvana.example.com'),
      );

      expect(row.localErrors, ['INVALID_EMAIL']);
    });

    test('email hợp lệ không phân biệt hoa thường thì không báo lỗi', () {
      final row = _parseOne(
        _dataRow(name: 'Nguyễn Văn A', email: 'NguyenVanA@Example.com'),
      );

      expect(row.localErrors, isEmpty);
    });

    test('VĐV 2 có tên nhưng thiếu email vẫn hợp lệ cục bộ', () {
      final row = _parseOne(
        _dataRow(name: 'Nguyễn Văn A', email: 'a@example.com', player2Name: 'Trần Văn B'),
      );

      expect(row.localErrors, isEmpty);
    });

    test('email VĐV 2 sai định dạng thì báo INVALID_EMAIL', () {
      final row = _parseOne(
        _dataRow(
          name: 'Nguyễn Văn A',
          email: 'a@example.com',
          player2Name: 'Trần Văn B',
          player2Email: 'khong-hop-le',
        ),
      );

      expect(row.localErrors, ['INVALID_EMAIL']);
    });
  });

  group('divisionName', () {
    test('đọc đúng nội dung thi của từng dòng và để trống khi ô trống', () {
      final sheet = _sheet([
        _headersVi,
        _dataRow(name: 'A', email: 'a@example.com', division: 'Đơn Nam'),
        _dataRow(name: 'B', email: 'b@example.com', division: 'Đôi Nam Nữ'),
        _dataRow(name: 'C', email: 'c@example.com'),
      ]);

      final rows = parseRosterSheet(
        sheet,
        headerRowIndex: 0,
        mapping: detectRosterColumnMapping(_headersVi),
      );

      expect(rows.map((row) => row.divisionName), [
        'Đơn Nam',
        'Đôi Nam Nữ',
        isNull,
      ]);
    });
  });

  group('ghi chú (notes)', () {
    test('đọc ghi chú của từng dòng và để null khi ô trống', () {
      final sheet = _sheet([
        ['Họ và tên VĐV 1', 'Email VĐV 1', 'Ghi chú'],
        ['Nguyễn Văn A', 'a@example.com', 'Đăng ký muộn'],
        ['Trần Văn B', 'b@example.com', ''],
      ]);

      final rows = parseRosterSheet(
        sheet,
        headerRowIndex: 0,
        mapping: detectRosterColumnMapping(sheet.rows[0]),
      );

      expect(rows.map((r) => r.notes), ['Đăng ký muộn', null]);
    });

    test('nhận cột Notes tiếng Anh', () {
      final sheet = _sheet([
        ['Họ và tên VĐV 1', 'Email VĐV 1', 'Notes'],
        ['Nguyễn Văn A', 'a@example.com', 'Late registration'],
      ]);

      final rows = parseRosterSheet(
        sheet,
        headerRowIndex: 0,
        mapping: detectRosterColumnMapping(sheet.rows[0]),
      );

      expect(rows.single.notes, 'Late registration');
    });
  });

  group('elo và isPaid', () {
    test('elo đọc số nguyên, dấu nghìn, thập phân; không đọc được thì null', () {
      const cases = <String, num?>{
        '1250': 1250,
        '1.250': 1250,
        '1,250': 1250,
        '6.5': 6.5,
        '6,5': 6.5,
        'abc': null,
      };

      for (final entry in cases.entries) {
        final row = _parseOne(
          _dataRow(name: 'A', email: 'a@example.com', elo: entry.key),
        );

        expect(row.elo, entry.value, reason: 'elo "${entry.key}"');
      }
    });

    test('isPaid nhận giá trị như web, không rõ thì null', () {
      const cases = <String, bool?>{
        'Có': true,
        'Không': false,
        'Yes': true,
        'No': false,
        'Đã thanh toán': true,
        'Chưa đóng': false,
        'abc': null,
      };

      for (final entry in cases.entries) {
        final row = _parseOne(
          _dataRow(name: 'A', email: 'a@example.com', paid: entry.key),
        );

        expect(row.isPaid, entry.value, reason: 'paid "${entry.key}"');
      }
    });
  });
}
