import 'dart:convert';

import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/match/screens/live_score_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_report_sheet.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/organizer_journey.dart';
import 'support/shot.dart';

/// Organizer journey for the schedule and settings area of the manage hub
/// (TC-QLGD-APP-60..79): venues and courts, schedule grid, court hours, multi
/// match scheduling, match action sheet, sponsors, referees, finance, share,
/// export and, last, tournament deletion. Real Backend, real taps.
///
/// Tests share one seeded tournament ("A") and run in file order: the venue test
/// creates the courts that the grid test needs. Payout uses its own COMPLETED
/// tournament and deletion its own throwaway tournament.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeAppForTests);

  testWidgets(
    'TC-QLGD-APP-60..63: Ban tổ chức tạo, sửa, đặt mặc định và xóa địa điểm cùng sân',
    (tester) async {
      final api = BackendApi();
      final seeded = await _seedA(api);
      final shooter = _Shooter(tester, binding, 'qlgd60');
      final container = await signInAsOrganizer(tester);
      await openManageHub(tester, container, seeded.tournamentId);
      await _openSettingsSection(tester, 'Địa điểm');
      Future<List<Map<String, dynamic>>> venuesUntil(
        bool Function(List<Map<String, dynamic>>) ok,
        String what,
      ) => _backendUntil(
        tester,
        () => api.listVenues(token: seeded.token, tournamentId: seeded.tournamentId),
        ok,
        what: what,
      );

      // TC-QLGD-APP-60: add dialog, close button and required-field constraint.
      await expectKey(tester, 'venue-add', step: 'màn Địa điểm & sân');
      await shooter.snap('60-man-dia-diem');
      await tapKey(tester, 'venue-add');
      await expectKey(tester, 'venue-dialog-name', step: 'dialog thêm địa điểm');
      await shooter.snap('60-dialog-them');
      expect(_isDisabled(tester, 'venue-dialog-submit'), isTrue, reason: 'Nút Thêm địa điểm phải khóa khi chưa nhập gì');
      await tester.enterText(find.byKey(const ValueKey('venue-dialog-name')), 'Chỉ có tên');
      await tester.pump();
      expect(_isDisabled(tester, 'venue-dialog-submit'), isTrue, reason: 'Thiếu địa chỉ thì nút Thêm địa điểm vẫn khóa');
      await tapKey(tester, 'venue-dialog-close');
      await _waitGone(tester, find.byKey(const ValueKey('venue-dialog-name')), 'dialog thêm địa điểm đóng');
      await shooter.snap('60-dialog-da-dong');

      // TC-QLGD-APP-61: create a default venue with two courts.
      final venueA = '${seeded.tag} Cụm sân A';
      await tapKey(tester, 'venue-add');
      await expectKey(tester, 'venue-dialog-name', step: 'dialog thêm địa điểm lần 2');
      await tester.enterText(find.byKey(const ValueKey('venue-dialog-name')), venueA);
      await tester.enterText(find.byKey(const ValueKey('venue-dialog-address')), '1 Đường E2E, Quận 1');
      await tester.enterText(find.byKey(const ValueKey('venue-dialog-count')), '2');
      await tester.enterText(find.byKey(const ValueKey('venue-dialog-prefix')), 'E2E');
      await tapKey(tester, 'venue-dialog-default');
      expect(
        tester.widget<CheckboxListTile>(find.byKey(const ValueKey('venue-dialog-default'))).value,
        isTrue,
        reason: 'Ô Đặt làm địa điểm mặc định phải được tick',
      );
      await shooter.snap('61-dialog-dien-day-du');
      await tapKey(tester, 'venue-dialog-submit');
      var venues = await venuesUntil(
        (list) => list.any((v) => v['name'] == venueA && _courtsOf(v).length == 2),
        'Backend có địa điểm "$venueA" với 2 sân',
      );
      expect(venues.firstWhere((v) => v['name'] == venueA)['isDefault'], isTrue, reason: 'Địa điểm vừa tạo phải là mặc định');
      await pumpUntilFound(tester, find.text(venueA), what: 'địa điểm "$venueA" trong danh sách');
      await shooter.snap('61-da-tao-dia-diem');

      // TC-QLGD-APP-62: add a court, open its camera sheet, remove it.
      final extraCourt = '${seeded.tag} Sân phụ';
      await tapKey(tester, 'venue-add-court');
      final dialogField = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
      await pumpUntilFound(tester, dialogField, what: 'dialog Thêm sân');
      await tester.enterText(dialogField.first, extraCourt);
      await shooter.snap('62-dialog-them-san');
      await _tap(tester, _inDialog('Lưu'));
      venues = await venuesUntil(
        (list) => list.any((v) => v['name'] == venueA && _courtsOf(v).any((c) => _courtName(c) == extraCourt)),
        'Backend có sân "$extraCourt"',
      );
      final extraId = _courtsOf(venues.firstWhere((v) => v['name'] == venueA))
          .firstWhere((c) => _courtName(c) == extraCourt)['id'] as String;
      await pumpUntilFound(tester, find.text(extraCourt), what: 'sân "$extraCourt" trong danh sách');
      await shooter.snap('62-da-them-san');
      await tapKey(tester, 'court-edit-$extraId');
      await expectKey(tester, 'court-camera-sheet-url', step: 'sheet camera của sân');
      await shooter.snap('62-sheet-camera');
      debugPrint('TC-QLGD-APP-62: sheet camera chỉ mở/đóng; lưu URL camera thuộc khu livestream, ngoài phạm vi ca này.');
      await _closeRoute(tester, find.byKey(const ValueKey('court-camera-sheet-url')));
      await _waitGone(tester, find.byKey(const ValueKey('court-camera-sheet-url')), 'sheet camera đóng');
      await tapKey(tester, 'court-menu-$extraId');
      await _tapText(tester, 'Xóa');
      await pumpUntilFound(tester, find.byType(AlertDialog), what: 'hộp xác nhận Xóa sân');
      await shooter.snap('62-xac-nhan-xoa-san');
      await _tap(tester, _inDialog('Xóa'));
      await venuesUntil(
        (list) => list.any(
          (v) => v['name'] == venueA && _courtsOf(v).length == 2 && !_courtsOf(v).any((c) => c['id'] == extraId),
        ),
        'Backend đã xóa sân phụ, còn 2 sân',
      );
      await _waitGone(tester, find.text(extraCourt), 'sân phụ biến khỏi danh sách');
      await shooter.snap('62-da-xoa-san');

      // TC-QLGD-APP-63: second venue: edit, set default both ways, remove.
      final venueB = '${seeded.tag} Cụm sân B';
      final venueBRenamed = '$venueB (đã sửa)';
      await tapKey(tester, 'venue-add');
      await expectKey(tester, 'venue-dialog-name', step: 'dialog thêm địa điểm thứ hai');
      await tester.enterText(find.byKey(const ValueKey('venue-dialog-name')), venueB);
      await tester.enterText(find.byKey(const ValueKey('venue-dialog-address')), '2 Đường E2E, Quận 3');
      await tapKey(tester, 'venue-dialog-submit');
      await venuesUntil((list) => list.any((v) => v['name'] == venueB), 'Backend có địa điểm "$venueB"');
      await pumpUntilFound(tester, find.text(venueB), what: 'địa điểm "$venueB" trong danh sách');
      await shooter.snap('63-co-hai-dia-diem');

      await _openVenueMenu(tester, venueB, 'Chỉnh sửa');
      await expectKey(tester, 'venue-dialog-name', step: 'dialog sửa địa điểm');
      await tester.enterText(find.byKey(const ValueKey('venue-dialog-name')), venueBRenamed);
      await shooter.snap('63-dialog-sua');
      await tapKey(tester, 'venue-dialog-submit');
      await venuesUntil((list) => list.any((v) => v['name'] == venueBRenamed), 'Backend đã đổi tên địa điểm B');
      await pumpUntilFound(tester, find.text(venueBRenamed), what: 'tên mới của địa điểm B');

      await _openVenueMenu(tester, venueBRenamed, 'Đặt làm địa điểm mặc định');
      await venuesUntil(
        (list) => list.any((v) => v['name'] == venueBRenamed && v['isDefault'] == true),
        'Backend đặt địa điểm B làm mặc định',
      );
      await shooter.snap('63-b-mac-dinh');
      await _openVenueMenu(tester, venueA, 'Đặt làm địa điểm mặc định');
      await venuesUntil(
        (list) => list.any((v) => v['name'] == venueA && v['isDefault'] == true),
        'Backend đặt lại địa điểm A làm mặc định',
      );
      await shooter.snap('63-a-mac-dinh-lai');

      await _openVenueMenu(tester, venueBRenamed, 'Xóa');
      await pumpUntilFound(tester, find.byType(AlertDialog), what: 'hộp xác nhận Xóa địa điểm');
      await shooter.snap('63-xac-nhan-xoa-dia-diem');
      await _tap(tester, _inDialog('Xóa'));
      await venuesUntil((list) => list.length == 1 && list.single['name'] == venueA, 'Backend chỉ còn địa điểm A');
      await _waitGone(tester, find.text(venueBRenamed), 'địa điểm B biến khỏi danh sách');
      await shooter.snap('63-da-xoa-dia-diem');
      await _closeSettingsSection(tester);
    },
  );

  testWidgets(
    'TC-QLGD-APP-64..69: Ban tổ chức xếp lịch trên lưới sân: giờ, ô trống, nhiều trận, sửa và gỡ lịch',
    (tester) async {
      final api = BackendApi();
      final seeded = await _seedA(api);
      final shooter = _Shooter(tester, binding, 'qlgd64');
      final venues = await api.listVenues(token: seeded.token, tournamentId: seeded.tournamentId);
      expect(venues, isNotEmpty, reason: 'Giải dùng chung chưa có địa điểm: chạy sau TC-QLGD-APP-60..63');
      final court = _courtsOf(venues.first).first;
      final courtName = _courtName(court);
      final courtId = court['id'] as String;
      await api.generateBracket(token: seeded.token, tournamentId: seeded.tournamentId, divisionId: seeded.divisionId);
      Future<List<Map<String, dynamic>>> matchesNow() =>
          api.listMatches(token: seeded.token, tournamentId: seeded.tournamentId, divisionId: seeded.divisionId);
      final matches = await _backendUntil(
        tester,
        matchesNow,
        (list) => list.length >= 3,
        what: 'Backend có 3 trận sau khi bốc thăm',
      );
      final playable = matches.where((m) => m['participant1Id'] is String && m['participant2Id'] is String).toList();
      expect(playable, hasLength(2), reason: 'Sơ đồ 4 VĐV phải có 2 trận bán kết đủ đối thủ');
      final first = playable[0]['id'] as String;
      final second = playable[1]['id'] as String;

      final container = await signInAsOrganizer(tester);
      await openManageHub(tester, container, seeded.tournamentId);
      await openHubTab(tester, 'Lịch thi đấu');
      await expectKey(tester, 'court-grid-fullscreen', step: 'lưới sân của tab Lịch thi đấu');
      await shooter.snap('64-luoi-san');

      // TC-QLGD-APP-64: multi-select mode toggle and court filter.
      await tapKey(tester, 'schedule-select-mode-button');
      await expectKey(tester, 'schedule-select-hint', step: 'chế độ Chọn nhiều ô');
      await shooter.snap('64-che-do-chon-nhieu');
      await tapKey(tester, 'schedule-select-mode-button');
      await _waitGone(tester, find.byKey(const ValueKey('schedule-select-hint')), 'thoát chế độ Chọn nhiều ô');
      final slotKey = 'schedule-slot-$courtName-0';
      await expectKey(tester, slotKey, step: 'ô trống đầu tiên của sân "$courtName"');
      await tapKey(tester, 'schedule-more-button');
      await tapKey(tester, 'court-picker-button');
      await tapKey(tester, 'court-picker-none');
      await shooter.snap('64-bo-chon-san');
      await _closeRoute(tester, find.byKey(const ValueKey('court-picker-none')));
      await _waitGone(tester, find.byKey(ValueKey(slotKey)), 'lưới ẩn sân khi bỏ chọn hết');
      await tapKey(tester, 'schedule-more-button');
      await tapKey(tester, 'court-picker-button');
      await tapKey(tester, 'court-picker-all');
      await _closeRoute(tester, find.byKey(const ValueKey('court-picker-all')));
      await expectKey(tester, slotKey, step: 'lưới hiện lại sân sau khi chọn tất cả');

      // TC-QLGD-APP-65: court hours sheet: cancel, constraint, save.
      await tapKey(tester, 'schedule-more-button');
      await tapKey(tester, 'schedule-settings-button');
      await expectKey(tester, 'schedule-settings-save', step: 'sheet cài đặt khung giờ');
      await shooter.snap('65-sheet-khung-gio');
      await _tapText(tester, 'Hủy');
      await _waitGone(tester, find.byKey(const ValueKey('schedule-settings-save')), 'sheet khung giờ đóng sau Hủy');
      await tapKey(tester, 'schedule-more-button');
      await tapKey(tester, 'schedule-settings-button');
      await expectKey(tester, 'schedule-settings-save', step: 'sheet cài đặt khung giờ lần 2');
      await tapKey(tester, 'schedule-settings-time-start');
      await _tapText(tester, '08:00');
      expect(
        tester.widget<DropdownButton<int>>(find.byKey(const ValueKey('schedule-settings-time-start'))).value,
        8 * 60,
        reason: 'Giờ bắt đầu phải đổi sang 08:00',
      );
      // The 48-entry end menu is long, so the end dropdown callback is invoked directly for the
      // constraint check (end before start) and for the valid end value.
      tester.widget<DropdownButton<int>>(find.byKey(const ValueKey('schedule-settings-time-end'))).onChanged!(7 * 60);
      await tester.pump();
      await expectKey(tester, 'schedule-settings-time-invalid', step: 'giờ kết thúc trước giờ bắt đầu');
      expect(_isDisabled(tester, 'schedule-settings-save'), isTrue, reason: 'Nút Lưu phải khóa khi giờ không hợp lệ');
      await shooter.snap('65-gio-khong-hop-le');
      tester.widget<DropdownButton<int>>(find.byKey(const ValueKey('schedule-settings-time-end'))).onChanged!(21 * 60);
      await tester.pump();
      await _waitGone(tester, find.byKey(const ValueKey('schedule-settings-time-invalid')), 'cảnh báo giờ biến mất');
      await tapKey(tester, 'schedule-settings-step-30');
      expect(
        tester.widget<ChoiceChip>(find.byKey(const ValueKey('schedule-settings-step-30'))).selected,
        isTrue,
        reason: 'Chip 30 phút phải được chọn',
      );
      await shooter.snap('65-gio-hop-le');
      await tapKey(tester, 'schedule-settings-save');
      await _waitGone(tester, find.byKey(const ValueKey('schedule-settings-save')), 'sheet khung giờ đóng sau Lưu');
      await pumpUntilFound(tester, find.text('Đã lưu cài đặt khung giờ.'), what: 'thông báo đã lưu khung giờ');
      final config = await _tournamentConfig(api, seeded);
      expect(config['operatingStart'], '08:00', reason: 'Backend phải lưu giờ mở sân');
      expect(config['operatingEnd'], '21:00', reason: 'Backend phải lưu giờ đóng sân');
      expect(config['stepMinutes'], 30, reason: 'Backend phải lưu bước ô 30 phút');
      await shooter.snap('65-da-luu-khung-gio');
      _clearSnackBars(tester);

      // TC-QLGD-APP-66: auto schedule sheet opens, print and export entries exist.
      await tapKey(tester, 'schedule-auto-button');
      await pumpUntilFound(tester, find.byType(BottomSheet), what: 'sheet xếp tự động');
      await shooter.snap('66-sheet-xep-tu-dong');
      await _closeRoute(tester, find.byType(BottomSheet));
      await _waitGone(tester, find.byType(BottomSheet), 'sheet xếp tự động đóng');
      await tapKey(tester, 'schedule-more-button');
      await expectKey(tester, 'schedule-print-button', step: 'mục In lịch');
      await expectKey(tester, 'schedule-export-button', step: 'mục Xuất lịch');
      debugPrint('TC-QLGD-APP-66: In lịch và Xuất lịch chỉ kiểm tồn tại, không bấm: mở hộp thoại in và chia sẻ file của hệ điều hành, không thao tác được trên emulator.');
      await shooter.snap('66-menu-in-xuat');
      await _closeRoute(tester, find.byKey(const ValueKey('schedule-print-button')));

      // TC-QLGD-APP-67: empty cell opens the multi-match picker; duration constraint.
      await tapKey(tester, slotKey);
      await expectKey(tester, 'schedule-multi-submit', step: 'sheet chọn nhiều trận từ ô trống');
      expect(find.textContaining('lúc 08:00'), findsWidgets, reason: 'Tiêu đề sheet phải nêu giờ 08:00 vừa cài đặt');
      await shooter.snap('67-sheet-chon-tran');
      await tapKey(tester, 'schedule-multi-toggle-visible');
      expect(find.text('Xếp 3 trận'), findsWidgets, reason: 'Chọn tất cả phải chọn đủ 3 trận chờ');
      await tapKey(tester, 'schedule-multi-toggle-visible');
      expect(find.text('Xếp 0 trận'), findsWidgets, reason: 'Bỏ chọn tất cả phải về 0 trận');
      expect(_isDisabled(tester, 'schedule-multi-submit'), isTrue, reason: 'Chưa chọn trận thì nút Xếp phải khóa');
      await tapKey(tester, 'schedule-picker-$first');
      await tapKey(tester, 'schedule-picker-$second');
      await tester.enterText(find.byKey(ValueKey('schedule-multi-duration-$first')), '7');
      await tester.pump();
      await expectKey(tester, 'schedule-multi-duration-error-$first', step: 'thời lượng 7 phút sai quy tắc 15..240 bước 5');
      expect(_isDisabled(tester, 'schedule-multi-submit'), isTrue, reason: 'Thời lượng sai thì nút Xếp phải khóa');
      await shooter.snap('67-thoi-luong-sai');

      // TC-QLGD-APP-68: schedule the two semi-finals back to back and check Backend.
      await tester.enterText(find.byKey(ValueKey('schedule-multi-duration-$first')), '30');
      await tester.pump();
      await _waitGone(tester, find.byKey(ValueKey('schedule-multi-duration-error-$first')), 'lỗi thời lượng biến mất');
      expect(find.text('Xếp 2 trận'), findsWidgets, reason: 'Phải đang chọn đúng 2 trận');
      await shooter.snap('68-truoc-khi-xep');
      await tapKey(tester, 'schedule-multi-submit');
      await _waitGone(tester, find.byKey(const ValueKey('schedule-multi-submit')), 'sheet chọn trận đóng sau khi xếp');
      final scheduled = await _backendUntil(
        tester,
        matchesNow,
        (list) => list.where((m) => _startOf(m) != null).length == 2,
        what: 'Backend có đúng 2 trận đã có giờ',
      );
      final m1 = scheduled.firstWhere((m) => m['id'] == first);
      final m2 = scheduled.firstWhere((m) => m['id'] == second);
      expect(m1['courtId'], courtId, reason: 'Trận 1 phải nằm ở sân đã chọn');
      expect(m2['courtId'], courtId, reason: 'Trận 2 phải nằm ở sân đã chọn');
      final start1 = _startOf(m1)!.toLocal();
      final start2 = _startOf(m2)!.toLocal();
      expect([start1.hour, start1.minute], [8, 0], reason: 'Trận đầu bắt đầu đúng 08:00 của ô đã chạm');
      expect(start2.difference(start1).inMinutes, greaterThanOrEqualTo(30), reason: 'Trận 2 phải nối tiếp sau trận 1 (30 phút)');
      await expectKey(tester, 'schedule-match-$first', step: 'thẻ trận 1 trên lưới');
      await expectKey(tester, 'schedule-match-$second', step: 'thẻ trận 2 trên lưới');
      _clearSnackBars(tester);
      await shooter.snap('68-da-xep-hai-tran');

      // TC-QLGD-APP-69: tap a scheduled match: save unchanged, then clear its schedule.
      await tapKey(tester, 'schedule-match-$second');
      await _expectText(tester, 'Xếp nhanh');
      await shooter.snap('69-sheet-xep-nhanh');
      await _tapText(tester, 'Lưu Thay Đổi');
      await _waitGone(tester, find.text('Xếp nhanh'), 'sheet Xếp nhanh đóng sau Lưu Thay Đổi');
      var after = await matchesNow();
      expect(_startOf(after.firstWhere((m) => m['id'] == second)), isNotNull, reason: 'Lưu Thay Đổi giữ nguyên lịch trận 2');
      _clearSnackBars(tester);
      await tapKey(tester, 'schedule-match-$second');
      await _expectText(tester, 'Xếp nhanh');
      await _tapText(tester, 'Gỡ lịch');
      await _backendUntil(
        tester,
        matchesNow,
        (list) => _startOf(list.firstWhere((m) => m['id'] == second)) == null,
        what: 'Backend đã gỡ giờ của trận 2',
      );
      await _waitGone(tester, find.byKey(ValueKey('schedule-match-$second')), 'thẻ trận 2 biến khỏi lưới');
      after = await matchesNow();
      expect(_startOf(after.firstWhere((m) => m['id'] == first)), isNotNull, reason: 'Trận 1 vẫn còn lịch');
      await shooter.snap('69-da-go-lich');
    },
  );

  testWidgets(
    'TC-QLGD-APP-70..73: Ban tổ chức dùng thanh quản lý lịch ở trang công khai và màn xếp lịch trận',
    (tester) async {
      final api = BackendApi();
      final seeded = await _seedA(api);
      final shooter = _Shooter(tester, binding, 'qlgd70');
      // The quick tournament is a Lite product, and the schedMgmt-* bar is hidden for Lite
      // (schedule_manager_bar.dart: scheduleManagerTournamentProvider). Mark the shared tournament as
      // non-Lite through PATCH /tournaments/:id (tournamentConfig is merged server side).
      await _RawApi(seeded.token).patchConfig(seeded.tournamentId, {'isLite': false});
      expect((await _tournamentConfig(api, seeded))['isLite'], isFalse, reason: 'Giải phải thành không phải Lite để hiện thanh quản lý lịch');
      final matches = await api.listMatches(token: seeded.token, tournamentId: seeded.tournamentId, divisionId: seeded.divisionId);
      expect(matches, isNotEmpty, reason: 'Giải dùng chung chưa có trận: chạy sau TC-QLGD-APP-64..69');

      final container = await signInAsOrganizer(tester);
      container.read(routerProvider).go('/tournament/${seeded.tournamentId}');
      await openHubTab(tester, 'Lịch thi đấu');
      await expectKey(tester, 'schedMgmt-courts', step: 'thanh quản lý lịch ở trang công khai');
      await shooter.snap('70-thanh-quan-ly-lich');

      // TC-QLGD-APP-70: schedMgmt-courts opens the venue and court screen.
      await tapKey(tester, 'schedMgmt-courts');
      await expectKey(tester, 'venue-add', step: 'màn Địa điểm & sân từ nút Tạo sân');
      await shooter.snap('70-man-tao-san');
      await _tap(tester, find.byTooltip('Quay lại'));
      await _waitGone(tester, find.byKey(const ValueKey('venue-add')), 'màn Địa điểm & sân đóng');

      // TC-QLGD-APP-71: schedMgmt-hours opens the hours sheet; save a new step.
      await tapKey(tester, 'schedMgmt-hours');
      await expectKey(tester, 'schedule-settings-save', step: 'sheet khung giờ từ thanh quản lý lịch');
      await tapKey(tester, 'schedule-settings-step-15');
      await shooter.snap('71-sheet-khung-gio');
      await tapKey(tester, 'schedule-settings-save');
      await _waitGone(tester, find.byKey(const ValueKey('schedule-settings-save')), 'sheet khung giờ đóng');
      await pumpUntilFound(tester, find.text('Đã lưu cài đặt khung giờ.'), what: 'thông báo đã lưu khung giờ');
      expect((await _tournamentConfig(api, seeded))['stepMinutes'], 15, reason: 'Backend phải lưu bước ô 15 phút');
      _clearSnackBars(tester);

      // TC-QLGD-APP-72: schedMgmt-arrange opens the scheduling screen; list view and action sheet.
      await tapKey(tester, 'schedMgmt-arrange');
      await expectKey(tester, 'ops-matches-view-list', step: 'màn xếp lịch trận');
      await _tap(tester, find.widgetWithText(ChoiceChip, 'Tất cả'));
      final card = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_OpsMatchCard',
        description: 'thẻ trận của màn điều hành',
      );
      await pumpUntilFound(tester, card, what: 'thẻ trận trong danh sách');
      await shooter.snap('72-danh-sach-tran');
      Future<void> openActions() async {
        await _tap(tester, find.descendant(of: card.first, matching: find.byType(InkWell)).first);
        await _expectText(tester, 'Mở bảng điểm');
      }

      await openActions();
      for (final label in const ['Thời gian xếp lịch', 'Mở bảng điểm', 'Mở bracket', 'Xử lý đặc biệt']) {
        await _expectText(tester, label);
      }
      await shooter.snap('72-sheet-hanh-dong');
      await _tapText(tester, 'Thời gian xếp lịch');
      await _expectText(tester, 'Xếp nhanh');
      await shooter.snap('72-thoi-gian-xep-lich');
      await _closeRoute(tester, find.text('Xếp nhanh'));
      await _waitGone(tester, find.text('Xếp nhanh'), 'sheet Xếp nhanh đóng');
      await openActions();
      await _tapText(tester, 'Mở bảng điểm');
      await pumpUntilFound(tester, find.byType(LiveScoreScreen), what: 'màn bàn điểm trực tiếp');
      await shooter.snap('72-ban-diem');
      container.read(routerProvider).pop();
      await _waitGone(tester, find.byType(LiveScoreScreen), 'quay lại từ bàn điểm');
      await openActions();
      await _tapText(tester, 'Mở bracket');
      await pumpUntilFound(tester, find.byType(BracketViewScreen), what: 'màn sơ đồ từ Mở bracket');
      await shooter.snap('72-so-do');
      container.read(routerProvider).pop();
      await _waitGone(tester, find.byType(BracketViewScreen), 'quay lại từ sơ đồ');
      await openActions();
      await _tapText(tester, 'Xử lý đặc biệt');
      final specialOps = find.byType(DropdownButtonFormField<String>);
      await pumpUntilFound(tester, specialOps, what: 'sheet Xử lý đặc biệt (ô chọn thao tác)');
      await shooter.snap('72-xu-ly-dac-biet');
      debugPrint('TC-QLGD-APP-72: sheet Xử lý đặc biệt chỉ mở/đóng, không gửi: thao tác đổi kết quả trận thật sẽ phá dữ liệu của các ca sau.');
      await _closeRoute(tester, specialOps);
      await _waitGone(tester, specialOps, 'sheet Xử lý đặc biệt đóng');
      await openActions();
      await _expectText(tester, 'BẮT ĐẦU TRẬN ĐẤU');
      await _tapText(tester, 'BẮT ĐẦU TRẬN ĐẤU');
      await pumpUntilFound(tester, find.byType(AlertDialog), what: 'hộp xác nhận bắt đầu trận');
      await shooter.snap('72-xac-nhan-bat-dau');
      debugPrint('TC-QLGD-APP-72: hộp bắt đầu trận chỉ mở rồi Hủy: bắt đầu thật đổi trạng thái trận, không cần cho ca xếp lịch.');
      await _tap(tester, _inDialog('Hủy'));
      await _waitGone(tester, find.byType(AlertDialog), 'hộp xác nhận bắt đầu trận đóng');

      // TC-QLGD-APP-73: switch the matches screen to the schedule grid.
      await tapKey(tester, 'ops-matches-view-grid');
      await expectKey(tester, 'court-grid-fullscreen', step: 'lưới sân trên màn xếp lịch trận');
      debugPrint('TC-QLGD-APP-73: nút toàn màn hình (court-grid-fullscreen) chỉ kiểm tồn tại: màn đó xoay hướng thiết bị, không ổn định trên emulator.');
      await shooter.snap('73-luoi-tren-man-xep-lich');
    },
  );

  testWidgets(
    'TC-QLGD-APP-74..75: Ban tổ chức thêm, ẩn hiện, lưu trữ nhà tài trợ và mời, thu hồi trọng tài',
    (tester) async {
      final api = BackendApi();
      final seeded = await _seedA(api);
      final shooter = _Shooter(tester, binding, 'qlgd74');
      final container = await signInAsOrganizer(tester);
      await openManageHub(tester, container, seeded.tournamentId);
      Future<List<Map<String, dynamic>>> sponsorsNow() =>
          api.listSponsors(token: seeded.token, tournamentId: seeded.tournamentId);

      // TC-QLGD-APP-74: sponsors.
      await _openSettingsSection(tester, 'Nhà tài trợ');
      await _tapText(tester, 'Thêm');
      await _expectText(tester, 'Thêm nhà tài trợ');
      final fields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
      expect(fields, findsNWidgets(3), reason: 'Dialog nhà tài trợ phải có 3 ô chữ: tên, website, mô tả (logo chọn bằng ảnh)');
      for (final tier in const ['GOLD', 'SILVER']) {
        await expectKey(tester, 'sponsor-tier-$tier', step: 'chip hạng $tier');
      }
      await shooter.snap('74-dialog-trong');
      await _tap(tester, _inDialog('Lưu'));
      expect(find.byType(AlertDialog), findsOneWidget, reason: 'Thiếu tên và logo thì dialog không được đóng');
      expect(await sponsorsNow(), isEmpty, reason: 'Thiếu tên và logo thì Backend không có nhà tài trợ nào');
      await shooter.snap('74-thieu-ten-logo');
      final sponsorName = '${seeded.tag} Tài trợ';
      await tester.enterText(fields.at(0), sponsorName);
      await tester.enterText(fields.at(1), 'https://example.com');
      await tester.enterText(fields.at(2), 'Nhà tài trợ do E2E tạo');
      await tester.pump();
      await tapKey(tester, 'sponsor-tier-SILVER');
      await _tap(tester, _inDialog('Lưu'));
      expect(find.byType(AlertDialog), findsOneWidget, reason: 'Có tên nhưng thiếu logo thì dialog vẫn không được đóng');
      expect(await sponsorsNow(), isEmpty, reason: 'Thiếu logo thì Backend không có nhà tài trợ nào');
      await shooter.snap('74-thieu-logo');
      // Logo chỉ chọn được bằng thư viện ảnh của hệ điều hành (không thao tác được trên emulator):
      // dựng nhà tài trợ bằng API rồi kiểm phần còn lại trên giao diện.
      await _tap(tester, _inDialog('Hủy'));
      await _waitGone(tester, find.byType(AlertDialog), 'dialog thêm nhà tài trợ đóng');
      debugPrint('TC-QLGD-APP-74: nút tải logo (bắt buộc) không thao tác được trên emulator: nhà tài trợ dựng bằng API.');
      final created = await _RawApi(seeded.token).createSponsor(seeded.tournamentId, sponsorName);
      await _closeSettingsSection(tester);
      await _openSettingsSection(tester, 'Nhà tài trợ');
      var sponsors = await _backendUntil(
        tester,
        sponsorsNow,
        (list) => list.any((s) => s['displayName'] == sponsorName),
        what: 'Backend có nhà tài trợ "$sponsorName"',
      );
      final sponsor = sponsors.firstWhere((s) => s['displayName'] == sponsorName);
      final sponsorId = sponsor['id'] as String;
      expect(sponsorId, created, reason: 'Id nhà tài trợ dựng bằng API');
      await pumpUntilFound(tester, find.text(sponsorName), what: 'nhà tài trợ trong danh sách');
      _clearSnackBars(tester);
      await shooter.snap('74-da-them');

      await tapKey(tester, 'sponsor-switch-$sponsorId');
      await _backendUntil(
        tester,
        sponsorsNow,
        (list) => !list.any((s) => s['id'] == sponsorId),
        what: 'Backend ẩn nhà tài trợ khỏi danh sách công khai',
      );
      await shooter.snap('74-da-an');
      await tapKey(tester, 'sponsor-switch-$sponsorId');
      await _backendUntil(
        tester,
        sponsorsNow,
        (list) => list.any((s) => s['id'] == sponsorId),
        what: 'Backend hiện lại nhà tài trợ công khai',
      );
      await _tapText(tester, 'Xem trước trang công khai');
      await pumpUntilFound(tester, find.byType(BottomSheet), what: 'sheet xem trước trang công khai');
      await shooter.snap('74-xem-truoc');
      await _closeRoute(tester, find.byType(BottomSheet));
      await _waitGone(tester, find.byType(BottomSheet), 'sheet xem trước đóng');
      await _tap(tester, find.text(sponsorName).first);
      await _expectText(tester, 'Sửa nhà tài trợ');
      await shooter.snap('74-dialog-sua');
      await tapKey(tester, 'sponsor-tier-SILVER');
      await _tap(tester, _inDialog('Lưu'));
      sponsors = await _backendUntil(
        tester,
        sponsorsNow,
        (list) => list.any((s) => s['id'] == sponsorId && '${s['tier']}'.toUpperCase() == 'SILVER'),
        what: 'Backend đổi hạng nhà tài trợ sang Bạc',
      );
      await _waitGone(tester, find.byType(AlertDialog), 'dialog sửa nhà tài trợ đóng sau Lưu');
      debugPrint('TC-QLGD-APP-74: tay nắm kéo thả sắp xếp (sponsor-handle-*) không kéo: cần ít nhất 2 nhà tài trợ và cử chỉ kéo sắp xếp lại, ngoài phạm vi.');
      await tester.drag(find.byKey(ValueKey('sponsor-row-$sponsorId')), const Offset(-600, 0));
      await tester.pump(const Duration(milliseconds: 500));
      await pumpUntilFound(tester, find.byType(AlertDialog), what: 'hộp xác nhận Lưu trữ nhà tài trợ');
      await shooter.snap('74-xac-nhan-luu-tru');
      await _tap(tester, _inDialog('Lưu trữ'));
      sponsors = await _backendUntil(
        tester,
        sponsorsNow,
        (list) => !list.any((s) => s['id'] == sponsorId),
        what: 'Backend đã lưu trữ nhà tài trợ',
      );
      expect(sponsors.any((s) => s['id'] == sponsorId), isFalse);
      await shooter.snap('74-da-luu-tru');
      await _closeSettingsSection(tester);

      // TC-QLGD-APP-75: referees (invite, validation, revoke).
      final raw = _RawApi(seeded.token);
      await _openSettingsSection(tester, 'Phân quyền & trọng tài');
      await expectKey(tester, 'permissions-invite-email', step: 'màn Phân quyền & trọng tài');
      await shooter.snap('75-man-phan-quyen');
      await tapKey(tester, 'permissions-role-REFEREE');
      expect(
        tester.widget<LavishChipButton>(find.byKey(const ValueKey('permissions-role-REFEREE'))).selected,
        isTrue,
        reason: 'Chip Trọng tài phải được chọn',
      );
      await tester.enterText(find.byKey(const ValueKey('permissions-invite-email')), 'khong-hop-le');
      await tapKey(tester, 'permissions-invite-send');
      await _expectText(tester, 'Email không hợp lệ.');
      await shooter.snap('75-email-khong-hop-le');
      await tester.enterText(find.byKey(const ValueKey('permissions-invite-email')), kPlayerEmail);
      await tapKey(tester, 'permissions-invite-send');
      await _backendUntil(
        tester,
        () => raw.list('/tournaments/${seeded.tournamentId}/referees'),
        // Backend hiện tạo trọng tài ACCEPTED ngay (BUG-REF-01 ở app-e2e-nhieu-tai-khoan), không có INVITED.
        (list) => list.any((r) => const ['INVITED', 'ACCEPTED'].contains('${r['status']}'.toUpperCase())),
        what: 'Backend có trọng tài vừa mời (INVITED hoặc ACCEPTED)',
      );
      _clearSnackBars(tester);
      await shooter.snap('75-da-moi-trong-tai');
      for (final role in const ['CO_ORGANIZER', 'SPECTATOR', 'REFEREE']) {
        await tapKey(tester, 'permissions-role-$role');
      }
      for (final filter in const ['ALL', 'CO_ORGANIZER', 'SPECTATOR', 'REFEREE']) {
        await tapKey(tester, 'permissions-filter-$filter');
      }
      final rowMenu = find.byWidgetPredicate(
        (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('permissions-row-menu-'),
        description: 'nút menu của dòng trọng tài',
      );
      await pumpUntilFound(tester, rowMenu, what: 'menu của dòng trọng tài vừa mời');
      await _tap(tester, rowMenu.first);
      await expectKey(tester, 'permissions-row-sheet-action', step: 'sheet thao tác trên dòng trọng tài');
      await shooter.snap('75-sheet-thu-hoi');
      await tapKey(tester, 'permissions-row-sheet-action');
      await pumpUntilFound(tester, find.byType(AlertDialog), what: 'hộp xác nhận Thu hồi/Gỡ');
      // Trọng tài ACCEPTED thì app hiện thao tác Gỡ (INVITED mới là Thu hồi); bấm đúng nút xác nhận (FilledButton).
      await _tap(tester, find.descendant(of: find.byType(AlertDialog), matching: find.byType(FilledButton)).last);
      await _backendUntil(
        tester,
        () => raw.list('/tournaments/${seeded.tournamentId}/referees'),
        (list) => !list.any((r) => const ['INVITED', 'ACCEPTED'].contains('${r['status']}'.toUpperCase())),
        what: 'Backend đã thu hồi/gỡ trọng tài vừa mời',
      );
      await shooter.snap('75-da-thu-hoi');
      _clearSnackBars(tester);
      await _closeSettingsSection(tester);
    },
  );

  testWidgets(
    'TC-QLGD-APP-76..77: Ban tổ chức chỉnh lệ phí bằng chip, kiểm tra ràng buộc rút tiền, không gửi yêu cầu thật',
    (tester) async {
      final api = BackendApi();
      // Backend không cho đổi lệ phí khi giải đã có người tham gia: dùng giải riêng chưa có VĐV.
      final seeded = await seedTournament(api, players: 0);
      final shooter = _Shooter(tester, binding, 'qlgd76');
      final container = await signInAsOrganizer(tester);
      await openManageHub(tester, container, seeded.tournamentId);

      // TC-QLGD-APP-76: quick fee chips and save; payout locked until the tournament is completed.
      await _openSettingsSection(tester, 'Tài chính & thanh toán');
      final feeField = find.byType(TextField);
      await pumpUntilFound(tester, feeField, what: 'ô Lệ phí tham gia');
      String feeText() => tester.widget<TextField>(feeField.first).controller!.text;
      await _expectText(tester, 'Chỉ có thể gửi yêu cầu thanh toán sau khi giải đấu hoàn tất.');
      await shooter.snap('76-tai-chinh');
      var expected = 0;
      for (final (label, amount) in const [('+20k', 20000), ('+50k', 50000), ('+100k', 100000), ('+200k', 200000)]) {
        await _tapText(tester, label);
        expected += amount;
        expect(feeText(), '$expected', reason: 'Chip $label phải cộng $amount vào lệ phí');
      }
      await shooter.snap('76-cong-chip');
      await _tapText(tester, '0đ');
      expect(feeText(), '0', reason: 'Chip 0đ đặt lệ phí về 0');
      await _tapText(tester, '+50k');
      await _tap(tester, find.text('Lưu lệ phí'));
      await _backendUntil(
        tester,
        () => api.getTournament(token: seeded.token, tournamentId: seeded.tournamentId),
        (t) => num.tryParse('${t['entryFee']}') == 50000,
        what: 'Backend lưu lệ phí 50.000',
      );
      await shooter.snap('76-da-luu-50k');
      _clearSnackBars(tester);
      await _tapText(tester, '0đ');
      await _tap(tester, find.text('Lưu lệ phí'));
      await _backendUntil(
        tester,
        () => api.getTournament(token: seeded.token, tournamentId: seeded.tournamentId),
        (t) => (num.tryParse('${t['entryFee']}') ?? 0) == 0,
        what: 'Backend đưa lệ phí về 0',
      );
      await shooter.snap('76-da-luu-mien-phi');
      _clearSnackBars(tester);
      await _closeSettingsSection(tester);

      // TC-QLGD-APP-77: payout rows on a COMPLETED tournament; dialog and constraints only.
      final done = await seedTournament(api, players: 2);
      await api.completeTournament(token: done.token, tournamentId: done.tournamentId);
      await openManageHub(tester, container, done.tournamentId);
      await _openSettingsSection(tester, 'Tài chính & thanh toán');
      await _expectText(tester, 'Gửi yêu cầu thanh toán');
      await shooter.snap('77-giai-da-ket-thuc');
      await _tapText(tester, 'Gửi yêu cầu thanh toán');
      await _expectText(tester, 'Yêu cầu thanh toán');
      final sheetFields = find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField));
      await pumpUntilFound(tester, sheetFields, what: 'các ô trong sheet yêu cầu thanh toán');
      expect(sheetFields, findsNWidgets(4), reason: 'Sheet rút tiền phải có 4 ô: ngân hàng, số tài khoản, chủ tài khoản, số tiền');
      final submit = find.descendant(of: find.byType(BottomSheet), matching: find.byType(FilledButton));
      await _tap(tester, submit.last);
      await _expectText(tester, 'Nhập đủ thông tin ngân hàng và số tiền tối thiểu 10.000 VND.');
      await shooter.snap('77-thieu-thong-tin');
      await tester.enterText(sheetFields.at(0), 'Ngân hàng E2E');
      await tester.enterText(sheetFields.at(1), '000000000');
      await tester.enterText(sheetFields.at(2), 'E2E TEST');
      await tester.enterText(sheetFields.at(3), '5000');
      await _tap(tester, submit.last);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AlertDialog), findsNothing, reason: 'Số tiền dưới 10.000 thì không được mở hộp xác nhận gửi yêu cầu');
      await shooter.snap('77-so-tien-nho-hon-toi-thieu');
      debugPrint('TC-QLGD-APP-77: không nhập số tiền hợp lệ, không bấm xác nhận: yêu cầu rút tiền thật chỉ kiểm dialog và ràng buộc.');
      await _closeRoute(tester, sheetFields.first);
      await _waitGone(tester, sheetFields, 'sheet yêu cầu thanh toán đóng');
      await _tapText(tester, 'Lịch sử thanh toán');
      await _expectText(tester, 'Chưa có yêu cầu thanh toán.');
      await shooter.snap('77-lich-su-thanh-toan');
      // Lịch sử thanh toán nằm ngay trên trang Tài chính (không phải sheet): không có gì để đóng.
    },
  );

  testWidgets(
    'TC-QLGD-APP-78: Ban tổ chức chia sẻ giải và xem các mục xuất dữ liệu',
    (tester) async {
      final api = BackendApi();
      final seeded = await _seedA(api);
      final shooter = _Shooter(tester, binding, 'qlgd78');
      final container = await signInAsOrganizer(tester);
      await openManageHub(tester, container, seeded.tournamentId);
      await openHubTab(tester, 'Cài đặt');
      await _scrollSettingsTo(tester, find.byKey(const ValueKey('lifecycle-share')));
      await expectKey(tester, 'lifecycle-share', step: 'dòng Chia sẻ ở tab Cài đặt');
      await shooter.snap('78-tab-cai-dat');

      Future<void> openShare() async {
        await tapKey(tester, 'lifecycle-share');
        await _expectText(tester, 'Sao chép link');
      }

      await openShare();
      await shooter.snap('78-sheet-chia-se');
      await _tapText(tester, 'Sao chép link');
      await _expectText(tester, 'Đã sao chép liên kết vào bộ nhớ tạm!');
      _clearSnackBars(tester);
      await shooter.snap('78-da-sao-chep');
      await openShare();
      await _tapText(tester, 'Mã QR');
      await pumpUntilFound(tester, find.byType(QrImageView), what: 'hộp thoại mã QR');
      await _expectText(tester, 'Mã QR Chia Sẻ');
      await shooter.snap('78-ma-qr');
      await _tap(tester, find.descendant(of: find.byType(AlertDialog), matching: find.text('Sao chép link')));
      if (find.byType(QrImageView).evaluate().isNotEmpty) {
        await _closeRoute(tester, find.byType(QrImageView));
      }
      await _waitGone(tester, find.byType(QrImageView), 'hộp thoại mã QR đóng');
      _clearSnackBars(tester);
      await openShare();
      await _expectText(tester, 'Chia sẻ qua App');
      debugPrint('TC-QLGD-APP-78: "Chia sẻ qua App" chỉ kiểm tồn tại, không bấm: mở khung chia sẻ của hệ điều hành, không thao tác được trên emulator.');
      await _tap(tester, find.byIcon(Icons.close_rounded).last);
      await _waitGone(tester, find.text('Chia sẻ qua App'), 'sheet chia sẻ đóng');

      await _tap(tester, find.byTooltip('HỆ THỐNG').first);
      for (final label in const ['Xuất dữ liệu giải đấu', 'Xuất danh sách VĐV', 'Xuất báo cáo', 'Xóa giải đấu']) {
        await _expectText(tester, label);
      }
      await shooter.snap('78-menu-he-thong');
      debugPrint('TC-QLGD-APP-78: "Xuất dữ liệu giải đấu" và "Xuất danh sách VĐV" chỉ kiểm tồn tại, không bấm: ghi file Excel rồi mở khung chia sẻ/lưu của hệ điều hành, không thao tác được trên emulator. "Xóa giải đấu" làm ở ca TC-QLGD-APP-79 trên giải riêng.');
      await _tapText(tester, 'Xuất báo cáo');
      await pumpUntilFound(tester, find.byType(TournamentReportSheet), what: 'sheet Xuất báo cáo');
      await _expectText(tester, 'Xuất báo cáo Excel');
      await shooter.snap('78-sheet-xuat-bao-cao');
      await _closeRoute(tester, find.byType(TournamentReportSheet));
      await _waitGone(tester, find.byType(TournamentReportSheet), 'sheet Xuất báo cáo đóng');
    },
  );

  // Last on purpose: deletes the tournament it creates. Never delete tournament "A".
  testWidgets(
    'TC-QLGD-APP-79: Ban tổ chức xóa giải bằng cách gõ lại đúng tên giải',
    (tester) async {
      final api = BackendApi();
      final doomed = await seedTournament(api, players: 0);
      final shooter = _Shooter(tester, binding, 'qlgd79');
      final container = await signInAsOrganizer(tester);
      await openManageHub(tester, container, doomed.tournamentId);
      await openHubTab(tester, 'Cài đặt');
      await _scrollSettingsTo(tester, find.byKey(const ValueKey('lifecycle-delete')));
      await expectKey(tester, 'lifecycle-delete', step: 'dòng Xóa giải đấu ở tab Cài đặt');
      await shooter.snap('79-tab-cai-dat');

      // Cancel path first: the tournament must survive.
      await tapKey(tester, 'lifecycle-delete');
      await expectKey(tester, 'delete-tournament-name', step: 'hộp xác nhận xóa giải');
      await _tap(tester, _inDialog('Hủy'));
      await _waitGone(tester, find.byKey(const ValueKey('delete-tournament-name')), 'hộp xóa giải đóng sau Hủy');
      final survivor = await api.getTournament(token: doomed.token, tournamentId: doomed.tournamentId);
      expect(survivor['name'], doomed.name, reason: 'Bấm Hủy thì giải vẫn còn trên Backend');

      // Wrong name keeps the confirm button locked; the exact name unlocks it.
      await tapKey(tester, 'lifecycle-delete');
      await expectKey(tester, 'delete-tournament-name', step: 'hộp xác nhận xóa giải lần 2');
      expect(_isDisabled(tester, 'delete-tournament-confirm'), isTrue, reason: 'Chưa gõ tên thì nút Xóa phải khóa');
      await tester.enterText(find.byKey(const ValueKey('delete-tournament-name')), '${doomed.name} sai');
      await tester.pump();
      expect(_isDisabled(tester, 'delete-tournament-confirm'), isTrue, reason: 'Gõ sai tên thì nút Xóa phải khóa');
      await shooter.snap('79-go-sai-ten');
      await tester.enterText(find.byKey(const ValueKey('delete-tournament-name')), doomed.name);
      await tester.pump();
      expect(_isDisabled(tester, 'delete-tournament-confirm'), isFalse, reason: 'Gõ đúng tên thì nút Xóa phải mở');
      await shooter.snap('79-go-dung-ten');
      await tapKey(tester, 'delete-tournament-confirm');
      await pumpUntilCondition(
        tester,
        () => container.read(routerProvider).routerDelegate.currentConfiguration.uri.path == '/dashboard',
        what: 'app về /dashboard sau khi xóa giải',
      );
      await _backendUntil(
        tester,
        () async {
          try {
            await api.getTournament(token: doomed.token, tournamentId: doomed.tournamentId);
            return false;
          } on BackendApiException {
            return true;
          }
        },
        (gone) => gone,
        what: 'GET /tournaments/${doomed.tournamentId} không còn truy cập được',
      );
      await shooter.snap('79-da-xoa-giai');
    },
  );
}

SeededTournament? _tournamentA;

/// Tournament shared by the first six tests; seeded once with four players.
Future<SeededTournament> _seedA(BackendApi api) async =>
    _tournamentA ??= await seedTournament(api, players: 4);

/// Takes a named screenshot; converts the surface once per test, on first use.
class _Shooter {
  _Shooter(this.tester, this.binding, this.prefix);

  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;
  final String prefix;
  bool _converted = false;

  Future<void> snap(String name) async {
    if (!_converted) {
      await binding.convertFlutterSurfaceToImage();
      _converted = true;
    }
    await tester.pump(const Duration(milliseconds: 300));
    await shot(binding, '$prefix-$name');
  }
}

/// Minimal direct Backend calls the shared [BackendApi] does not cover.
class _RawApi {
  _RawApi(this.token)
    : _dio = Dio(
        BaseOptions(
          baseUrl: kE2eApiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          contentType: Headers.jsonContentType,
          validateStatus: (_) => true,
        ),
      );

  final String token;
  final Dio _dio;

  Options get _auth => Options(headers: {'Authorization': 'Bearer $token'});

  /// `PATCH /tournaments/:id` with a partial `tournamentConfig` (merged by the Backend).
  Future<void> patchConfig(String tournamentId, Map<String, Object?> patch) async {
    final response = await _dio.patch<Object?>(
      '/tournaments/$tournamentId',
      data: {'tournamentConfig': patch},
      options: _auth,
    );
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      fail('PATCH /tournaments/$tournamentId -> HTTP $code: ${_clip(response.data)}');
    }
  }

  /// `POST /tournaments/:id/sponsors`: dựng nhà tài trợ có logo (giao diện chỉ chọn logo bằng thư viện ảnh).
  Future<String> createSponsor(String tournamentId, String name) async {
    final response = await _dio.post<Object?>(
      '/tournaments/$tournamentId/sponsors',
      data: {
        'displayName': name,
        'tier': 'GOLD',
        'logoUrl': 'https://cdn.example.com/e2e-logo.png',
        'websiteUrl': 'https://example.com',
        'shortDescription': 'Nhà tài trợ do E2E tạo',
        'displayOrder': 0,
        'status': 'PUBLISHED',
        'isPublic': true,
      },
      options: _auth,
    );
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      fail('POST /tournaments/$tournamentId/sponsors -> HTTP $code: ${_clip(response.data)}');
    }
    final body = response.data;
    final data = body is Map && body.containsKey('data') ? body['data'] : body;
    return (data as Map)['id'] as String;
  }

  Future<List<Map<String, dynamic>>> list(String path) async {
    final response = await _dio.get<Object?>(path, options: _auth);
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw BackendApiException(method: 'GET', path: path, statusCode: code, bodySnippet: _clip(response.data));
    }
    final body = response.data;
    final data = body is Map && body.containsKey('data') ? body['data'] : body;
    if (data is! List) {
      throw BackendApiException(method: 'GET', path: path, statusCode: code, bodySnippet: 'không phải danh sách: ${_clip(body)}');
    }
    return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static String _clip(Object? value) {
    final text = value is String ? value : jsonEncode(value);
    return text.length > 300 ? text.substring(0, 300) : text;
  }
}

/// Polls [fetch] until [ok] holds; fails with [what] and the last value or error after [attempts] seconds.
Future<T> _backendUntil<T>(
  WidgetTester tester,
  Future<T> Function() fetch,
  bool Function(T) ok, {
  required String what,
  int attempts = 25,
}) async {
  T? last;
  Object? lastError;
  for (var i = 0; i < attempts; i++) {
    try {
      final value = await fetch();
      last = value;
      if (ok(value)) return value;
    } on BackendApiException catch (error) {
      lastError = error;
    }
    await tester.pump(const Duration(seconds: 1));
  }
  fail('Backend chưa đạt sau ${attempts}s: $what. Giá trị cuối: $last. Lỗi cuối: $lastError');
}

Future<Map<String, dynamic>> _tournamentConfig(BackendApi api, SeededTournament seeded) async {
  final tournament = await api.getTournament(token: seeded.token, tournamentId: seeded.tournamentId);
  final config = tournament['tournamentConfig'];
  expect(config, isA<Map>(), reason: 'GET /tournaments/:id phải trả tournamentConfig');
  return Map<String, dynamic>.from(config as Map);
}

/// Backend trả tên sân ở trường `courtName`.
String _courtName(Map<String, dynamic> court) => (court['courtName'] ?? court['name']).toString();

/// Cuộn tab Cài đặt tới khi [finder] được dựng (danh sách lazy), tối đa 20 lần kéo.
Future<void> _scrollSettingsTo(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(TabBarView), const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

List<Map<String, dynamic>> _courtsOf(Map<String, dynamic> venue) {
  final courts = venue['courts'];
  expect(courts, isA<List>(), reason: 'Địa điểm từ Backend phải có danh sách courts: $venue');
  return (courts as List).whereType<Map>().map((c) => Map<String, dynamic>.from(c)).toList();
}

DateTime? _startOf(Map<String, dynamic> match) {
  final raw = match['scheduledTime'] ?? match['scheduledAt'];
  return raw is String ? DateTime.tryParse(raw) : null;
}

/// True when the button with `ValueKey(key)` has no `onPressed`.
bool _isDisabled(WidgetTester tester, String key) =>
    tester.widget<ButtonStyleButton>(find.byKey(ValueKey(key))).onPressed == null;

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(text));

/// Tap with the shared centering helper, then let the UI react.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await pumpUntilFound(tester, finder, what: 'widget cần bấm: ${finder.toString()}');
  await tapCentered(tester, finder);
  await tester.pump(const Duration(milliseconds: 400));
}

/// Wait for [text] and tap the last (top-most) match.
Future<void> _tapText(WidgetTester tester, String text) =>
    _tap(tester, find.text(text).last);

Future<void> _expectText(WidgetTester tester, String text) async {
  await pumpUntilFound(tester, find.text(text), what: 'chữ "$text"');
  expect(find.text(text), findsWidgets);
}

Future<void> _waitGone(WidgetTester tester, Finder finder, String what) =>
    pumpUntilCondition(tester, () => finder.evaluate().isEmpty, what: 'biến mất: $what');

/// Pops the route that hosts [inside] (sheet, dialog or popup menu).
Future<void> _closeRoute(WidgetTester tester, Finder inside) async {
  await pumpUntilFound(tester, inside, what: 'route cần đóng: ${inside.toString()}');
  Navigator.of(tester.element(inside.first)).pop();
  await tester.pump(const Duration(milliseconds: 500));
}

void _clearSnackBars(WidgetTester tester) {
  ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
}

/// Opens the Settings tab and the row titled [title] (mobile layout: full page section).
Future<void> _openSettingsSection(WidgetTester tester, String title) async {
  await openHubTab(tester, 'Cài đặt');
  final row = find.widgetWithText(LavishRow, title);
  await _scrollSettingsTo(tester, row);
  await pumpUntilFound(tester, row, what: 'dòng cài đặt "$title"');
  await tester.ensureVisible(row);
  await _tap(tester, row);
}

Future<void> _closeSettingsSection(WidgetTester tester) async {
  await _tap(tester, find.byTooltip('Quay lại'));
  await pumpUntilFound(tester, find.widgetWithText(Tab, 'Cài đặt'), what: 'hub quản lý sau khi đóng mục cài đặt');
}

/// Opens the popup menu of the venue row titled [venueName] and picks [item].
Future<void> _openVenueMenu(WidgetTester tester, String venueName, String item) async {
  final menu = find.descendant(
    of: find.widgetWithText(LavishRow, venueName),
    matching: find.byWidgetPredicate(
      (w) => w is PopupMenuButton<String> && w.key == null,
      description: 'menu địa điểm',
    ),
  );
  await _tap(tester, menu);
  await _tapText(tester, item);
}
