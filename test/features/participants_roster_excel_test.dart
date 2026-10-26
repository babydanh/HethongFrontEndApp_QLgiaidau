import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  // Task 3.9 (TC-WP-03-14): sheet roster của xuất Excel danh sách VĐV —
  // tên, liên hệ, hạng mục, trạng thái, seed, thanh toán.
  test('header row lists the six roster columns', () {
    expect(ExcelExportService.participantsHeaderRow(l10n), [
      'Họ tên',
      'Liên hệ',
      'Hạng mục',
      'Trạng thái',
      'Seed',
      'Thanh toán',
    ]);
  });

  test('approved single with member contact, division, seed and fee', () {
    final row = ExcelExportService.participantsRow(
      participant: OrganizerOpsParticipant.fromJson({
        'id': 'p1',
        'teamStatus': 'COMPLETE',
        'isPaid': true,
        'entryFee': 150000,
        'seed': 3,
        'tournamentDivisionId': 'div-1',
        'members': [
          {
            'userId': 'u1',
            'fullName': 'Nguyễn Văn A',
            'email': 'a@mail.com',
            'phoneNumber': '0901234567',
          },
        ],
        'players': [
          {'slot': 1, 'fullName': 'Nguyễn Văn A', 'userId': 'u1'},
        ],
      }),
      divisionNameById: const {'div-1': 'Đơn nam'},
      l10n: l10n,
    );

    expect(row, [
      'Nguyễn Văn A',
      'a@mail.com; 0901234567',
      'Đơn nam',
      'Đã duyệt',
      '3',
      'Đã thanh toán',
    ]);
  });

  test('pending guest pair reads contacts from playerNEmail/playerNPhone', () {
    final row = ExcelExportService.participantsRow(
      participant: OrganizerOpsParticipant.fromJson({
        'id': 'p2',
        'teamStatus': 'PENDING_APPROVAL',
        'isPaid': false,
        'tournamentDivisionId': 'div-2',
        'players': [
          {'slot': 1, 'fullName': 'Trần B', 'userId': null},
          {'slot': 2, 'fullName': 'Lê C', 'userId': null},
        ],
        'customResponses': {
          'player1Email': 'b@mail.com',
          'player2Phone': '0987654321',
          'notes': 'ghi chú nội bộ',
        },
      }),
      divisionNameById: const {'div-1': 'Đơn nam'},
      l10n: l10n,
    );

    expect(row, [
      'Trần B / Lê C',
      'b@mail.com; 0987654321',
      // Hạng mục không tìm thấy trong danh sách giải -> để trống.
      '',
      'Chờ duyệt',
      '',
      'Chưa thanh toán',
    ]);
  });

  test('team row shows free entry, pending partner and rejected labels', () {
    OrganizerOpsParticipant participant(String teamStatus) =>
        OrganizerOpsParticipant.fromJson({
          'id': 'p3',
          'teamName': 'Đội ABC',
          'teamStatus': teamStatus,
          'isPaid': true,
          'entryFee': 0,
          'seed': 5,
          'tournamentDivisionId': 'div-1',
          'members': <Object>[],
        });

    expect(
      ExcelExportService.participantsRow(
        participant: participant('PENDING_PARTNER'),
        divisionNameById: const {'div-1': 'Đôi nam'},
        l10n: l10n,
      ),
      ['Đội ABC', '', 'Đôi nam', 'Chờ ghép', '5', 'Miễn phí'],
    );
    expect(
      ExcelExportService.participantsRow(
        participant: participant('REJECTED'),
        divisionNameById: const {'div-1': 'Đôi nam'},
        l10n: l10n,
      ),
      ['Đội ABC', '', 'Đôi nam', 'Đã từ chối', '5', 'Miễn phí'],
    );
  });

  test(
    'kicked and unknown statuses, empty name, no seed, duplicated contact',
    () {
      OrganizerOpsParticipant participant(String teamStatus) =>
          OrganizerOpsParticipant.fromJson({
            'id': 'p4',
            'teamStatus': teamStatus,
            'isPaid': true,
            'members': [
              {'userId': 'u1', 'fullName': 'A', 'email': 'a@mail.com'},
              {'userId': 'u2', 'fullName': 'B', 'email': 'a@mail.com'},
            ],
            'players': [
              {'slot': 1, 'fullName': 'A', 'userId': 'u1'},
              {'slot': 2, 'fullName': 'B', 'userId': 'u2'},
            ],
          });

      expect(
        ExcelExportService.participantsRow(
          participant: participant('KICKED'),
          divisionNameById: const {},
          l10n: l10n,
        ),
        ['A / B', 'a@mail.com', '', 'Đã xóa', '', 'Miễn phí'],
      );
      expect(
        ExcelExportService.participantsRow(
          participant: participant('SOMETHING_ELSE'),
          divisionNameById: const {},
          l10n: l10n,
        ),
        ['A / B', 'a@mail.com', '', 'Trạng thái khác', '', 'Miễn phí'],
      );
    },
  );

  test('contact list covers member email, phone and guest slots', () {
    final contacts = ExcelExportService.participantContacts(
      OrganizerOpsParticipant.fromJson({
        'id': 'p5',
        'teamStatus': 'COMPLETE',
        'isPaid': true,
        'members': [
          {'userId': 'u1', 'fullName': 'A', 'phoneNumber': '0901112223'},
        ],
        'players': [
          {'slot': 1, 'fullName': 'A', 'userId': 'u1'},
          {'slot': 2, 'fullName': 'Khách', 'userId': null},
        ],
        'customResponses': {'player2Email': 'guest@mail.com'},
      }),
    );

    expect(contacts, ['0901112223', 'guest@mail.com']);
  });

  group('rosterFileName', () {
    final at = DateTime(2026, 10, 26);

    test('keeps only [A-Za-z0-9_.-] and strips path tricks', () {
      final name = ExcelExportService.rosterFileName(
        prefix: 'Participants',
        tournamentName: r'../../Giải Đấu: A/B\C?*"<>|',
        at: at,
      );
      expect(name, matches(RegExp(r'^[A-Za-z0-9_.-]+\.xlsx$')));
      expect(name, isNot(contains('..')));
      expect(name, startsWith('Participants_'));
      expect(name, endsWith('_20261026.xlsx'));
    });

    test('plain ASCII names stay readable with spaces turned to _', () {
      expect(
        ExcelExportService.rosterFileName(
          prefix: 'Participants',
          tournamentName: 'Open 2026',
          at: at,
        ),
        'Participants_Open_2026_20261026.xlsx',
      );
    });
  });
}
