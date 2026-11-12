import 'dart:convert';

import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/organizer_journey.dart';
import 'support/shot.dart';

/// TC-QLGD-APP-01..19: Ban tổ chức dựng giải, nội dung thi đấu và VĐV trên App, Backend thật.
/// Giải đơn (S) và giải đôi (D) dựng một lần bằng API; chỉ bước tạo giải đi qua form /tournaments/create.
void main() {
  _binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final api = BackendApi();
  late SeededTournament single;
  late String doubleId;
  late String doubleDivisionId;
  late String doubleTag;

  setUpAll(() async {
    await initializeAppForTests();
    // S: 4 VĐV đã duyệt và đóng phí, thêm 4 đơn chờ duyệt cho các ca duyệt/từ chối.
    single = await seedTournament(api, players: 4, maxParticipants: 16);
    await _importRaw(single.token, single.tournamentId, single.divisionId, [
      for (var i = 1; i <= 4; i++)
        _soloEntry('${single.tag} Cho $i', autoApprove: false),
    ]);
    // D: 2 cặp đã ghép sẵn và 4 VĐV lẻ chờ đối tác (PENDING_PARTNER).
    doubleTag = '${single.tag}D';
    final created = await api.createLiteTournament(
      token: single.token,
      name: '$doubleTag Giải đôi',
      matchType: 'DOUBLES',
      maxParticipants: 16,
    );
    doubleId = created.tournamentId;
    doubleDivisionId = created.divisionId;
    await api.approveTournamentAsAdmin(doubleId);
    await api.importRoster(
      token: single.token,
      tournamentId: doubleId,
      divisionId: doubleDivisionId,
      tag: doubleTag,
      count: 2,
      singles: false,
    );
    await _importRaw(single.token, doubleId, doubleDivisionId, [
      for (var i = 1; i <= 4; i++)
        _soloEntry('$doubleTag Le $i', autoApprove: true),
    ]);
  });

  testWidgets(
    'TC-QLGD-APP-01..02: BTC tạo giải nhanh trên form, hub mở và Backend có giải đúng tên',
    (tester) async {
      final name = '${single.tag} Giải nhanh UI';
      final container = await signInAsOrganizer(tester);

      // TC-01: form tạo giải nhanh, thêm một nội dung đơn, bỏ nội dung mặc định "Đôi tự do".
      // Router có thể còn chuyển về trang chủ sau đăng nhập: gọi go() lại tới khi form hiện.
      // Form đăng nhập cũng có TextFormField: nhận form tạo giải bằng tiêu đề "Tạo giải nhanh" của nó.
      await pumpUntilCondition(tester, () {
        if (find.text('Tạo giải nhanh').evaluate().isEmpty) {
          container.read(routerProvider).go('/tournaments/create');
        }
        return find.text('Tạo giải nhanh').evaluate().isNotEmpty &&
            find.byType(TextFormField).evaluate().isNotEmpty;
      }, what: 'form Tạo giải nhanh (ô tên giải)');
      await snap(tester, 'form-tao-giai-nhanh');
      await tester.enterText(find.byType(TextFormField).first, name);
      await tester.pump();

      await scrollToText(tester, 'Thêm nội dung');
      await tester.tap(find.text('Thêm nội dung').first);
      await pumpUntilCondition(
        tester,
        () => find.text('Thêm nội dung').evaluate().length >= 2,
        what: 'bottom sheet thêm nội dung',
      );
      await snap(tester, 'sheet-them-noi-dung-form-tao-giai');
      await tester.tap(find.text('Thêm nội dung').last);
      await tester.pump(const Duration(seconds: 1));
      // Giữ cả "Đôi tự do" và nội dung đơn thì Backend từ chối tạo sơ đồ; bỏ tick nội dung mặc định.
      await scrollToText(tester, 'Đôi tự do');
      await tapCentered(tester, find.text('Đôi tự do').first);
      await tester.pump(const Duration(milliseconds: 500));

      // The start field opens SocialDateTimePickerSheet; its default (now + 7 days) is in range.
      await scrollToText(tester, 'Thời gian bắt đầu *');
      await tapCentered(
        tester,
        find.byKey(const ValueKey('quick-schedule-start')),
      );
      await pumpUntilFound(
        tester,
        find.text('Chọn ngày và giờ'),
        what: 'sheet chọn ngày giờ bắt đầu',
      );
      await snap(tester, 'sheet-chon-ngay-gio-bat-dau');
      await tester.tap(find.text('Xác nhận'));
      await tester.pump(const Duration(seconds: 1));
      await snap(tester, 'form-tao-giai-da-dien');

      final submit = find.widgetWithText(FilledButton, 'Tạo giải đấu');
      await pumpUntilFound(
        tester,
        submit,
        what: 'nút Tạo giải đấu ở thanh dưới',
      );
      await tester.tap(submit);
      await tester.pump();

      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('tournament-overview-name-edit')),
        timeout: const Duration(seconds: 60),
        what: 'trang quản lý giải vừa tạo (hub, tên giải)',
      );
      await snap(tester, 'hub-giai-vua-tao');
      final location = container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .toString();
      final id = RegExp(
        r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
      ).firstMatch(location)?.group(0);
      expect(
        id,
        isNotNull,
        reason: 'Không đọc được id giải từ đường dẫn: $location',
      );

      // TC-02: Backend có giải đúng tên và đúng một nội dung.
      await api.approveTournamentAsAdmin(id!);
      final tournament = await api.getTournament(
        token: single.token,
        tournamentId: id,
      );
      expect(tournament['name'], name, reason: 'Tên giải trên Backend');
      final divisions = await api.listDivisions(id);
      expect(
        divisions,
        hasLength(1),
        reason: 'Giải tạo nhanh phải có đúng 1 nội dung',
      );
      expect(
        find.text(name),
        findsWidgets,
        reason: 'Hub phải hiện tên giải vừa tạo',
      );
    },
    timeout: _testTimeout,
  );

  testWidgets(
    'TC-QLGD-APP-03: BTC sửa tên giải ở tổng quan và Backend đổi tên',
    (tester) async {
      final container = await signInAsOrganizer(tester);
      await openManageHub(tester, container, single.tournamentId);
      await snap(tester, 'hub-tong-quan');

      final newName = '${single.tag} Giải BTC đã sửa';
      await press(
        tester,
        'tournament-overview-name-edit',
        step: 'bấm tên giải',
      );
      final field = find.widgetWithText(TextField, 'Tên giải đấu');
      await pumpUntilFound(
        tester,
        field,
        what: 'popup sửa tên (ô Tên giải đấu)',
      );
      await tester.enterText(field.first, newName);
      await tester.pump();
      await snap(tester, 'popup-sua-ten-da-nhap');
      await pressText(tester, 'Lưu thay đổi');

      await waitFor(
        tester,
        () => api.getTournament(
          token: single.token,
          tournamentId: single.tournamentId,
        ),
        (t) => t['name'] == newName,
        what: 'tên giải đổi thành "$newName"',
      );
      await pumpUntilFound(
        tester,
        find.text(newName),
        what: 'tên mới trên hub',
      );
    },
    timeout: _testTimeout,
  );

  testWidgets(
    'TC-QLGD-APP-04..09: BTC xem, thêm, sửa, khoá, đóng/mở hàng loạt và xóa nội dung thi đấu',
    (tester) async {
      final container = await signInAsOrganizer(tester);
      await openManageHub(tester, container, single.tournamentId);
      await openHubTab(tester, 'Nội dung');

      // TC-04: hàng nội dung có sẵn, chạm để mở rộng hiện thông tin.
      final originalRow = find.byKey(
        ValueKey('division-row-${single.divisionId}'),
      );
      await pumpUntilFound(
        tester,
        originalRow,
        what: 'hàng nội dung dựng bằng API',
      );
      await tapCentered(
        tester,
        find.descendant(of: originalRow, matching: find.byType(InkWell)).first,
      );
      await pumpUntilFound(
        tester,
        find.text('Thể thức'),
        what: 'panel thông tin nội dung (nhãn Thể thức)',
      );
      await snap(tester, 'noi-dung-mo-rong');

      // TC-05: thêm nội dung Đôi nam + Vòng tròn qua DivisionEditorSheet.
      final addedName = '${single.tag} Đôi nam';
      await press(tester, 'division-add-tile', step: 'thêm nội dung');
      await expectKey(
        tester,
        'division-editor-save',
        step: 'sheet thêm nội dung',
      );
      await press(tester, 'division-editor-format-MALE_DOUBLES');
      await tester.enterText(
        find.byKey(const ValueKey('division-editor-name')),
        addedName,
      );
      await tester.pump();
      await press(tester, 'division-editor-bracket-ROUND_ROBIN');
      await press(tester, 'division-editor-save');
      final added = await waitFor(
        tester,
        () => api.listDivisions(single.tournamentId),
        (list) => list.any((d) => d['name'] == addedName),
        what: 'nội dung "$addedName" trên Backend',
      );
      final newDivision = added.firstWhere((d) => d['name'] == addedName);
      final newId = newDivision['id'] as String;
      expect(newDivision['matchType']?.toString().toUpperCase(), 'DOUBLES');
      expect(
        newDivision['bracketType']?.toString().toUpperCase(),
        'ROUND_ROBIN',
      );
      await expectKey(
        tester,
        'division-row-$newId',
        step: 'hàng nội dung mới trên hub',
      );

      // TC-06: mở sửa nội dung gốc rồi Hủy; sửa nội dung mới sang Vòng bảng rồi loại trực tiếp.
      // Not Loại kép: editing Vòng tròn -> Loại kép keeps the stale groupsConfig (numGroups 1)
      // and Backend answers 400 "vòng bảng + loại trực tiếp phải có ít nhất 2 bảng" (product bug).
      await press(tester, 'division-edit-${single.divisionId}');
      await expectKey(
        tester,
        'division-editor-save',
        step: 'sheet sửa nội dung gốc',
      );
      await press(tester, 'division-editor-cancel');
      await expectGone(tester, 'division-editor-save', step: 'Hủy đóng sheet sửa');
      await press(tester, 'division-edit-$newId');
      await expectKey(
        tester,
        'division-editor-save',
        step: 'sheet sửa nội dung mới',
      );
      await press(tester, 'division-editor-bracket-GROUP_STAGE_KNOCKOUT');
      await press(tester, 'division-editor-save');
      await waitFor(
        tester,
        () => api.listDivisions(single.tournamentId),
        (list) => list.any(
          (d) =>
              d['id'] == newId &&
              d['bracketType']?.toString().toUpperCase() ==
                  'GROUP_STAGE_KNOCKOUT',
        ),
        what: 'bracketType của nội dung mới đổi thành GROUP_STAGE_KNOCKOUT',
      );

      // TC-07: menu 3 chấm, Khoá đăng ký rồi Mở lại đăng ký.
      await pressMenuItem(tester, newId, 'Khoá đăng ký');
      await waitFor(
        tester,
        () => api.listDivisions(single.tournamentId),
        (list) => list.any(
          (d) => d['id'] == newId && d['isRegistrationLocked'] == true,
        ),
        what: 'nội dung mới bị khoá đăng ký',
      );
      await pressMenuItem(tester, newId, 'Mở lại đăng ký');
      await waitFor(
        tester,
        () => api.listDivisions(single.tournamentId),
        (list) => list.any(
          (d) => d['id'] == newId && d['isRegistrationLocked'] != true,
        ),
        what: 'nội dung mới được mở lại đăng ký',
      );

      // TC-08: menu "Đăng ký" mở sheet đóng/mở hàng loạt. Chỉ chọn tất cả rồi Hủy để không đổi trạng thái giải.
      await pressMenuItem(tester, newId, 'Đăng ký');
      await expectKey(
        tester,
        'division-bulk-mode',
        step: 'sheet đóng/mở theo hạng mục',
      );
      await press(tester, 'division-bulk-select-all');
      debugPrint(
        'TC-QLGD-APP-08: không bấm division-bulk-confirm vì sẽ đóng đăng ký cả giải dùng cho các ca sau.',
      );
      await press(tester, 'division-bulk-cancel');
      await expectGone(
        tester,
        'division-bulk-mode',
        step: 'Hủy đóng sheet hàng loạt',
      );

      // TC-09: menu Xóa + xác nhận, Backend chỉ còn nội dung gốc.
      await pressMenuItem(tester, newId, 'Xóa');
      await confirmDialog(tester, 'xóa nội dung');
      await waitFor(
        tester,
        () => api.listDivisions(single.tournamentId),
        (list) => list.length == 1 && list.first['id'] == single.divisionId,
        what: 'chỉ còn nội dung gốc sau khi xóa',
      );
    },
    timeout: _testTimeout,
  );

  testWidgets(
    'TC-QLGD-APP-80: BTC bật luật chuẩn, đổi điểm mỗi set, tắt thắng cách 2 điểm và Backend lưu đúng',
    (tester) async {
      final container = await signInAsOrganizer(tester);
      await openManageHub(tester, container, single.tournamentId);
      await openHubTab(tester, 'Nội dung');
      await press(
        tester,
        'division-edit-${single.divisionId}',
        step: 'mở sheet sửa nội dung',
      );
      await expectKey(tester, 'division-editor-save', step: 'sheet nội dung');
      final before = (await api.listDivisions(single.tournamentId))
          .firstWhere((d) => d['id'] == single.divisionId);
      debugPrint('TC-80: roundConfig trước: ${jsonEncode(before['roundConfig'])}');

      // Mục luật luôn hiện công tắc "Luật chuẩn" (không phải accordion): bật nó (nếu đang ở chế độ Lite), đặt 15 điểm/set, tắt thắng cách 2.
      await expectKey(
        tester,
        'division-editor-standard-rules',
        step: 'công tắc luật chuẩn',
      );
      final points = find.byKey(const ValueKey('division-editor-points-per-set'));
      if (points.evaluate().isEmpty) {
        await tapSwitch(tester, 'division-editor-standard-rules');
      }
      await pumpUntilFound(tester, points, what: 'ô điểm mỗi set (luật chuẩn)');
      await tester.ensureVisible(points);
      await tester.enterText(points, '15');
      await tester.pump();
      final winByTwo = find.descendant(
        of: find.byKey(const ValueKey('division-editor-win-by-two')),
        matching: find.byType(LavishSwitch),
      );
      await tester.ensureVisible(winByTwo);
      final winByTwoBefore = tester.widget<LavishSwitch>(winByTwo).value;
      await tapSwitch(tester, 'division-editor-win-by-two');
      expect(
        tester.widget<LavishSwitch>(winByTwo).value,
        !winByTwoBefore,
        reason: 'Công tắc thắng cách 2 điểm phải đổi trạng thái sau khi bấm',
      );
      await snap(tester, 'noi-dung-luat-chuan');
      await press(tester, 'division-editor-save');

      final saved = await waitFor(
        tester,
        () async => (await api.listDivisions(single.tournamentId))
            .firstWhere((d) => d['id'] == single.divisionId),
        (d) => jsonEncode(d['roundConfig']).contains('STRICT'),
        what: 'roundConfig có luật chuẩn (STRICT) trên Backend',
      );
      debugPrint('TC-80: roundConfig sau: ${jsonEncode(saved['roundConfig'])}');
      final rules = saved['roundConfig'] as Map<String, dynamic>;
      expect(rules['mode'], 'STRICT', reason: 'Luật chuẩn phải được lưu');
      expect(rules['pointsPerSet'], 15, reason: 'Điểm mỗi set 15 phải được lưu');
      expect(
        rules['winByTwo'],
        !winByTwoBefore,
        reason: 'Thắng cách 2 điểm phải đảo so với lúc mở sheet',
      );
    },
    timeout: _testTimeout,
  );

  testWidgets(
    'TC-QLGD-APP-10: menu Cấu hình từng vòng mở sheet khi nội dung đã có sơ đồ',
    (tester) async {
      // Mục menu chỉ hiện khi nội dung đã sinh sơ đồ, nên dựng giải riêng và sinh sơ đồ bằng API.
      final bracketed = await seedTournament(
        api,
        players: 4,
        maxParticipants: 8,
      );
      await api.generateBracket(
        token: bracketed.token,
        tournamentId: bracketed.tournamentId,
        divisionId: bracketed.divisionId,
      );
      await waitFor(
        tester,
        () => api.listMatches(
          token: bracketed.token,
          tournamentId: bracketed.tournamentId,
          divisionId: bracketed.divisionId,
        ),
        (matches) => matches.isNotEmpty,
        what: 'trận của sơ đồ vừa sinh',
      );

      final container = await signInAsOrganizer(tester);
      await openManageHub(tester, container, bracketed.tournamentId);
      await openHubTab(tester, 'Nội dung');
      await expectKey(
        tester,
        'division-row-${bracketed.divisionId}',
        step: 'hàng nội dung đã có sơ đồ',
      );
      // Danh sách trận tải bất đồng bộ; menu dựng mục theo dữ liệu lúc mở, nên chờ trận về trước.
      await tester.pump(const Duration(seconds: 5));
      await pressMenuItem(tester, bracketed.divisionId, 'Cấu hình từng vòng');
      await expectKey(
        tester,
        'stage-round-cancel',
        step: 'sheet cấu hình từng vòng',
      );
      await press(tester, 'stage-round-cancel');
      await expectGone(
        tester,
        'stage-round-cancel',
        step: 'Hủy đóng sheet cấu hình vòng',
      );
    },
    timeout: _testTimeout,
  );

  testWidgets(
    'TC-QLGD-APP-11..13: BTC xem, lọc, tìm VĐV và thêm VĐV khách và VĐV có tài khoản',
    (tester) async {
      final container = await signInAsOrganizer(tester);
      await openManageHub(tester, container, single.tournamentId);
      await openHubTab(tester, 'VĐV');

      // TC-11: danh sách theo trạng thái. Bộ lọc Đã duyệt ẩn đơn chờ; Chờ duyệt ẩn VĐV đã duyệt; tìm theo tên.
      final roster = await _fetchManage(single.token, single.tournamentId);
      final approvedRow = _rowOf(_byMarker(roster, '${single.tag} VDV 2'));
      final otherRow = _rowOf(_byMarker(roster, '${single.tag} VDV 1'));
      final pendingRow = _rowOf(_byMarker(roster, '${single.tag} Cho 1'));
      await pumpUntilFound(
        tester,
        approvedRow,
        what: 'hàng VĐV đã duyệt "VDV 2"',
      );
      expect(
        pendingRow,
        findsOneWidget,
        reason: 'Bộ lọc Tất cả phải hiện cả đơn chờ duyệt',
      );
      await press(tester, 'participant-filter-menu');
      await press(tester, 'participant-filter-approved');
      await pumpUntilCondition(
        tester,
        () => pendingRow.evaluate().isEmpty,
        what: 'đơn chờ duyệt biến mất khi lọc Đã duyệt',
      );
      expect(approvedRow, findsOneWidget);
      await press(tester, 'participant-filter-menu');
      await press(tester, 'participant-filter-pending');
      await pumpUntilCondition(
        tester,
        () => approvedRow.evaluate().isEmpty,
        what: 'VĐV đã duyệt biến mất khi lọc Chờ duyệt',
      );
      expect(pendingRow, findsOneWidget);
      await press(tester, 'participant-filter-menu');
      await press(tester, 'participant-filter-all');
      await pumpUntilFound(
        tester,
        approvedRow,
        what: 'lọc Tất cả hiện lại VĐV đã duyệt',
      );
      await tester.enterText(
        find.byKey(const ValueKey('participant-search')),
        'VDV 2',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await snap(tester, 'tim-vdv-2');
      expect(approvedRow, findsOneWidget, reason: 'Tìm "VDV 2" phải còn VDV 2');
      expect(otherRow, findsNothing, reason: 'Tìm "VDV 2" phải ẩn VDV 1');
      await tester.enterText(
        find.byKey(const ValueKey('participant-search')),
        '',
      );
      await tester.pump(const Duration(milliseconds: 500));

      // TC-12: Thêm VĐV (tab Nhập tên): thêm vào danh sách rồi gỡ, sau đó gửi VĐV khách.
      final before = _activeCount(roster);
      final guestName = '${single.tag} Khach UI';
      clearSnackBars(tester);
      await tapCentered(tester, _addAthleteBox(single.divisionId));
      await expectKey(tester, 'add-athlete-sheet', step: 'sheet Thêm VĐV');
      await snap(tester, 'sheet-them-vdv');
      await _fillGuest(
        tester,
        name: '${single.tag} Nhap tam',
        email: '${single.tag.toLowerCase()}-tam@example.com',
      );
      await press(tester, 'add-athlete-score-source');
      await pressText(tester, 'DUPR', last: true);
      await tester.enterText(
        find.byKey(const ValueKey('add-athlete-direct-score')),
        '4.5',
      );
      await press(tester, 'add-athlete-direct-queue');
      await expectKey(
        tester,
        'add-athlete-draft-1',
        step: 'VĐV nằm trong danh sách chờ gửi',
      );
      await press(tester, 'add-athlete-draft-remove-1');
      await expectGone(
        tester,
        'add-athlete-draft-1',
        step: 'gỡ VĐV khỏi danh sách chờ',
      );
      await _fillGuest(
        tester,
        name: guestName,
        email: '${single.tag.toLowerCase()}-khach@example.com',
      );
      await press(tester, 'add-athlete-direct-submit');
      await waitFor(
        tester,
        () => _fetchManage(single.token, single.tournamentId),
        (list) =>
            list.any((p) => jsonEncode(p).contains(guestName)) &&
            _activeCount(list) == before + 1,
        what: 'VĐV khách "$guestName" trên Backend (tổng +1)',
      );

      // TC-13: email thuộc tài khoản bị Backend từ chối, bấm "Tìm tài khoản" rồi chọn tài khoản để thêm.
      await _fillGuest(
        tester,
        name: '${single.tag} Tai khoan',
        email: kPlayerEmail,
      );
      // Lần gửi TC-12 có thể còn đang hoàn tất trên giao diện (nút gửi tạm khóa): bấm lại tới 3 lần
      // cho tới khi hộp "Tìm tài khoản" hiện.
      final findAccount = find.byKey(const ValueKey('add-athlete-find-account'));
      for (var attempt = 0; attempt < 3 && findAccount.evaluate().isEmpty; attempt++) {
        await press(tester, 'add-athlete-direct-submit');
        for (var i = 0; i < 16 && findAccount.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
      }
      await expectKey(
        tester,
        'add-athlete-find-account',
        step: 'Backend từ chối email thuộc tài khoản',
      );
      await press(tester, 'add-athlete-find-account');
      final candidate = _keyStartsWith('add-athlete-candidate-select-');
      await pumpUntilFound(
        tester,
        candidate,
        what: 'kết quả tìm tài khoản theo email $kPlayerEmail',
      );
      await tapCentered(tester, candidate);
      await snap(tester, 'da-chon-tai-khoan');
      await press(tester, 'add-athlete-candidate-submit');
      await waitFor(
        tester,
        () => _fetchManage(single.token, single.tournamentId),
        (list) => _activeCount(list) == before + 2,
        what: 'VĐV có tài khoản được thêm (tổng +2)',
      );
      await press(tester, 'add-athlete-close');
      await expectGone(
        tester,
        'add-athlete-sheet',
        step: 'đóng sheet Thêm VĐV',
      );
    },
    timeout: _testTimeout,
  );

  testWidgets(
    'TC-QLGD-APP-14..16: BTC duyệt, từ chối đơn, mở chi tiết VĐV, check-in, phí, ghi chú, liên hệ và loại khỏi giải',
    (tester) async {
      final container = await signInAsOrganizer(tester);
      await openManageHub(tester, container, single.tournamentId);
      await openHubTab(tester, 'VĐV');
      final roster = await _fetchManage(single.token, single.tournamentId);
      String idOf(String marker) => _byMarker(roster, marker)['id'] as String;
      Future<Map<String, dynamic>> waitParticipant(
        String id,
        bool Function(Map<String, dynamic>) ok,
        String what,
      ) => waitFor(
        tester,
        () async => (await _fetchManage(
          single.token,
          single.tournamentId,
        )).firstWhere(
          (p) => p['id'] == id,
          // Backend drops rejected/kicked entries from manage/participants.
          orElse: () => {'id': id, 'teamStatus': 'ABSENT'},
        ),
        ok,
        what: what,
      );
      Future<void> waitStatus(String id, String status) => waitParticipant(
        id,
        (p) =>
            p['teamStatus'] == status ||
            (const {'REJECTED', 'KICKED'}.contains(status) &&
                p['teamStatus'] == 'ABSENT'),
        'đơn $id có trạng thái $status (hoặc đã rời danh sách)',
      );

      // TC-14: duyệt và từ chối ngay trên hàng danh sách (từ chối có hộp xác nhận).
      final cho1 = idOf('${single.tag} Cho 1');
      final cho2 = idOf('${single.tag} Cho 2');
      await pumpUntilFound(
        tester,
        find.byKey(ValueKey('athlete-team-row-$cho1')),
        what: 'hàng đơn chờ duyệt Cho 1',
      );
      await press(tester, 'participant-approve-$cho1');
      await waitStatus(cho1, 'COMPLETE');
      await press(tester, 'participant-reject-$cho2');
      await confirmDialog(tester, 'từ chối đăng ký');
      await waitStatus(cho2, 'REJECTED');

      // TC-15: duyệt và từ chối trong ParticipantDetailSheet.
      final cho3 = idOf('${single.tag} Cho 3');
      final cho4 = idOf('${single.tag} Cho 4');
      await openDetail(tester, cho3);
      await press(tester, 'participant-detail-approve');
      await expectGone(
        tester,
        'participant-detail-profile',
        step: 'sheet đóng sau khi duyệt',
      );
      await waitStatus(cho3, 'COMPLETE');
      await openDetail(tester, cho4);
      await press(tester, 'participant-detail-reject');
      await confirmDialog(tester, 'từ chối đăng ký trong sheet');
      await expectGone(
        tester,
        'participant-detail-profile',
        step: 'sheet đóng sau khi từ chối',
      );
      await waitStatus(cho4, 'REJECTED');

      // TC-16: chi tiết VĐV đã duyệt: check-in, đã đóng phí (tắt rồi bật), ghi chú, liên hệ.
      final vdv1 = idOf('${single.tag} VDV 1');
      await openDetail(tester, vdv1);
      await tapSwitch(tester, 'participant-detail-checkin');
      await waitParticipant(
        vdv1,
        (p) => p['isPresent'] == true,
        'VĐV 1 đã check-in',
      );
      // Giải dựng bằng API là giải miễn phí: Backend coi hồ sơ miễn phí luôn là đã đóng phí
      // (spec organizer-registration-payment-state), nên bỏ đánh dấu không đổi `isPaid`.
      // BUG-SP-02 (sản phẩm): participant_detail_sheet.dart `showFee` phụ thuộc `_paid`, nên sau khi
      // bỏ đánh dấu ở hồ sơ miễn phí thì hàng phí biến mất và không bật lại được. Test chỉ kiểm
      // công tắc gọi được, hộp xác nhận hiện, Backend vẫn `isPaid` true và giữ check-in.
      await tapSwitch(tester, 'participant-detail-fee-paid');
      await confirmDialog(tester, 'bỏ đã đóng phí');
      await waitParticipant(
        vdv1,
        (p) => p['isPaid'] == true && p['isPresent'] == true,
        'VĐV 1 vẫn đã đóng phí (giải miễn phí) và giữ check-in',
      );
      await expectKey(
        tester,
        'participant-detail-checkin',
        step: 'sheet còn mở sau khi bỏ đánh dấu phí',
      );

      final note = '${single.tag} ghi chú BTC';
      await press(tester, 'participant-detail-note-row');
      await tester.enterText(
        find.byKey(const ValueKey('participant-detail-note')),
        note,
      );
      await tester.pump();
      await press(tester, 'participant-detail-note-save');
      await waitParticipant(
        vdv1,
        (p) => (p['customResponses'] as Map?)?['notes'] == note,
        'ghi chú BTC lưu trên Backend',
      );

      await press(tester, 'participant-contact-edit');
      await expectKey(
        tester,
        'participant-contact-name-1',
        step: 'ô sửa liên hệ VĐV 1',
      );
      await press(tester, 'participant-contact-cancel');
      await expectKey(
        tester,
        'participant-contact-edit',
        step: 'Hủy quay lại chế độ xem liên hệ',
      );
      await press(tester, 'participant-contact-edit');
      final renamed = '${single.tag} VDV 1 Sua';
      await tester.enterText(
        find.byKey(const ValueKey('participant-contact-name-1')),
        renamed,
      );
      await tester.enterText(
        find.byKey(const ValueKey('participant-contact-phone-1')),
        kPlayerPhone,
      );
      await tester.pump();
      await press(tester, 'participant-contact-save');
      await waitParticipant(
        vdv1,
        (p) => jsonEncode(p).contains(renamed),
        'tên liên hệ mới "$renamed" trên Backend',
      );
      _popRouteOf(tester, 'participant-detail-profile');
      await expectGone(
        tester,
        'participant-detail-profile',
        step: 'đóng sheet chi tiết',
      );
      debugPrint(
        'TC-QLGD-APP-16: participant-checkin-<id> trên hàng chỉ hiện khi giải ngoài giai đoạn đăng ký; '
        'giải dựng sẵn đang mở đăng ký nên check-in được bấm ở sheet chi tiết.',
      );

      // Menu dòng: Loại khỏi giải (VĐV 4) + xác nhận.
      final vdv4 = idOf('${single.tag} VDV 4');
      await press(tester, 'participant-row-menu-$vdv4');
      await press(tester, 'participant-kick-$vdv4');
      await confirmDialog(tester, 'loại khỏi giải');
      await waitStatus(vdv4, 'KICKED');
    },
    timeout: _testTimeout,
  );

  testWidgets(
    'TC-QLGD-APP-17: BTC ghép đôi thủ công trong giải đôi (chọn, xáo, gửi cặp)',
    (tester) async {
      final container = await signInAsOrganizer(tester);
      await openManageHub(tester, container, doubleId);
      await openHubTab(tester, 'VĐV');

      await press(tester, 'athletes-pairing');
      await expectKey(tester, 'pairing-tabs', step: 'sheet ghép đôi');
      final rows = _keyStartsWith('pairing-row-');
      await pumpUntilCondition(
        tester,
        () => rows.evaluate().length == 4,
        what: '4 VĐV lẻ chờ ghép trong sheet',
      );
      await press(tester, 'pairing-tab-auto');
      await press(tester, 'pairing-strategy-eloBalanced');
      await press(tester, 'pairing-tab-manual');
      await tester.enterText(
        find.byKey(const ValueKey('pairing-search')),
        doubleTag.toLowerCase(),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        rows,
        findsNWidgets(4),
        reason: 'Mọi VĐV lẻ đều chứa tiền tố giải trong tên',
      );
      await tapCentered(tester, rows.at(0));
      await tapCentered(tester, rows.at(1));
      await snap(tester, 'da-chon-2-vdv-ghep');
      await press(tester, 'pairing-shuffle');
      await press(tester, 'pairing-submit');
      await expectGone(
        tester,
        'pairing-tabs',
        step: 'sheet đóng sau khi gửi cặp',
      );
      await waitFor(
        tester,
        () => _fetchManage(single.token, doubleId),
        (list) => _countStatus(list, 'PENDING_PARTNER') == 2,
        what: 'còn 2 VĐV lẻ chờ đối tác sau khi ghép 1 cặp',
      );
    },
    timeout: _testTimeout,
  );

  testWidgets(
    'TC-QLGD-APP-18: BTC tự ghép (Hủy rồi xác nhận) và gỡ một VĐV khỏi cặp ở sheet đổi VĐV giữa các cặp',
    (tester) async {
      final container = await signInAsOrganizer(tester);
      await openManageHub(tester, container, doubleId);
      await openHubTab(tester, 'VĐV');

      await press(tester, 'athletes-auto-pair');
      await expectKey(tester, 'auto-pair-confirm', step: 'hộp Tự ghép');
      await press(tester, 'auto-pair-strategy-sameLevel');
      await press(tester, 'auto-pair-cancel');
      await expectGone(
        tester,
        'auto-pair-confirm',
        step: 'Hủy đóng hộp Tự ghép',
      );
      expect(
        _countStatus(await _fetchManage(single.token, doubleId), 'PENDING_PARTNER'),
        2,
        reason: 'Hủy không được ghép cặp nào',
      );
      await press(tester, 'athletes-auto-pair');
      await press(tester, 'auto-pair-confirm');
      await waitFor(
        tester,
        () => _fetchManage(single.token, doubleId),
        (list) => _countStatus(list, 'PENDING_PARTNER') == 0,
        what: 'không còn VĐV lẻ sau Tự ghép',
      );

      await press(tester, 'athletes-more');
      await press(tester, 'athletes-pair-move');
      await expectKey(
        tester,
        'pair-move-tray',
        step: 'sheet đổi VĐV giữa các cặp',
      );
      final menus = _keyStartsWith('pair-move-menu-');
      await pumpUntilFound(tester, menus, what: 'menu của thành viên cặp');
      await tapCentered(tester, menus);
      await pressMenuText(tester, 'Gỡ khỏi cặp');
      await confirmDialog(tester, 'gỡ khỏi cặp');
      await waitFor(
        tester,
        () => _fetchManage(single.token, doubleId),
        (list) => _countStatus(list, 'PENDING_PARTNER') >= 1,
        what: 'VĐV bị gỡ khỏi cặp quay lại hàng chờ đối tác',
      );
      _popRouteOf(tester, 'pair-move-tray');
      await expectGone(tester, 'pair-move-tray', step: 'đóng sheet đổi VĐV');
    },
    timeout: _testTimeout,
  );

  testWidgets(
    'TC-QLGD-APP-19: BTC dùng menu Khác: suất đặc cách, VĐV ảo (sinh và xóa), mở Nhập Excel',
    (tester) async {
      final container = await signInAsOrganizer(tester);
      await openManageHub(tester, container, doubleId);
      await openHubTab(tester, 'VĐV');

      // Suất đặc cách cho tài khoản PLAYER E2E.
      await press(tester, 'athletes-more');
      await expectKey(
        tester,
        'athletes-download-template',
        step: 'menu Khác có mục tải file mẫu',
      );
      debugPrint(
        'TC-QLGD-APP-19: không bấm athletes-download-template vì mở bảng chia sẻ hệ thống (không thao tác được trên emulator).',
      );
      await press(tester, 'athletes-wildcard');
      await expectKey(tester, 'wildcard-submit', step: 'sheet suất đặc cách');
      final wildName = '$doubleTag Wild';
      await tester.enterText(
        find.byKey(const ValueKey('wildcard-contact')),
        kPlayerEmail,
      );
      await tester.enterText(
        find.byKey(const ValueKey('wildcard-team-name')),
        wildName,
      );
      await tester.pump();
      await press(tester, 'wildcard-submit');
      await expectGone(
        tester,
        'wildcard-submit',
        step: 'sheet đóng sau khi gán suất',
      );
      await waitFor(
        tester,
        () => _fetchManage(single.token, doubleId),
        (list) => list.any((p) => jsonEncode(p).contains(wildName)),
        what: 'suất đặc cách "$wildName" trên Backend',
      );

      // VĐV ảo: sinh rồi xóa.
      final mockName = '$doubleTag Ao';
      await press(tester, 'athletes-more');
      await press(tester, 'athletes-mock-data');
      await expectKey(tester, 'mock-generate', step: 'sheet VĐV ảo');
      await press(tester, 'mock-pair-mode-individualWaiting');
      await press(tester, 'mock-pair-mode-auto');
      await tester.enterText(
        find.byKey(const ValueKey('mock-names')),
        '$mockName 1\n$mockName 2',
      );
      await tester.pump();
      await press(tester, 'mock-generate');
      await expectGone(
        tester,
        'mock-generate',
        step: 'sheet đóng sau khi sinh VĐV ảo',
      );
      await waitFor(
        tester,
        () => _fetchManage(single.token, doubleId),
        (list) => list.any((p) => jsonEncode(p).contains(mockName)),
        what: 'VĐV ảo "$mockName" trên Backend',
      );
      await press(tester, 'athletes-more');
      await press(tester, 'athletes-mock-data');
      await press(tester, 'mock-clear');
      await confirmDialog(tester, 'xóa VĐV ảo');
      await waitFor(
        tester,
        () => _fetchManage(single.token, doubleId),
        (list) => !list.any((p) => jsonEncode(p).contains(mockName)),
        what: 'VĐV ảo đã bị xóa',
      );
      _popRouteOf(tester, 'mock-generate');
      await expectGone(tester, 'mock-generate', step: 'đóng sheet VĐV ảo');

      // Nhập Excel: file picker không thao tác được trên emulator, chỉ kiểm sheet mở và đóng được.
      await press(tester, 'athletes-import-excel');
      await expectKey(tester, 'roster-import-sheet', step: 'sheet Nhập Excel');
      await expectKey(
        tester,
        'roster-import-pick-file',
        step: 'nút chọn file trong sheet Nhập Excel',
      );
      debugPrint(
        'TC-QLGD-APP-19: không bấm roster-import-pick-file vì mở trình chọn file hệ thống (không thao tác được trên emulator).',
      );
      _popRouteOf(tester, 'roster-import-sheet');
      await expectGone(
        tester,
        'roster-import-sheet',
        step: 'đóng sheet Nhập Excel',
      );
    },
    timeout: _testTimeout,
  );
}

const _testTimeout = Timeout(Duration(minutes: 10));

late IntegrationTestWidgetsFlutterBinding _binding;
WidgetTester? _convertedFor;
var _shotCount = 0;

/// Chụp một ảnh đánh số tăng dần; ảnh in ra log dạng base64 (xem support/shot.dart).
/// The surface must be converted once per test (each test has its own WidgetTester).
Future<void> snap(WidgetTester tester, String name) async {
  if (!identical(_convertedFor, tester)) {
    await _binding.convertFlutterSurfaceToImage();
    _convertedFor = tester;
  }
  await tester.pump();
  _shotCount++;
  await shot(_binding, 'qlgd-${_shotCount.toString().padLeft(3, '0')}-$name');
}

void clearSnackBars(WidgetTester tester) => ScaffoldMessenger.of(
  tester.element(find.byType(Scaffold).first),
).clearSnackBars();

/// Bấm widget theo key (xóa snackbar che nút trước) rồi chụp ảnh.
Future<void> press(WidgetTester tester, String key, {String? step}) async {
  clearSnackBars(tester);
  await tester.pump(const Duration(milliseconds: 100));
  await tapKey(tester, key, step: step);
  await snap(tester, key);
}

/// Bấm chữ hiện trên màn (nút có nhãn, chưa có key) rồi chụp ảnh.
Future<void> pressText(
  WidgetTester tester,
  String text, {
  bool last = false,
}) async {
  clearSnackBars(tester);
  final finder = find.text(text);
  await pumpUntilFound(tester, finder, what: 'chữ "$text"');
  await tapCentered(tester, last ? finder.last : finder);
  await tester.pump(const Duration(milliseconds: 300));
  await snap(tester, 'text-$text');
}

/// Chọn một mục chữ trong menu PopupMenuButton đang mở.
Future<void> pressMenuText(WidgetTester tester, String text) async {
  final item = find.descendant(
    of: find.byType(PopupMenuItem<String>),
    matching: find.text(text),
  );
  await pumpUntilFound(tester, item, what: 'mục menu "$text"');
  await tapCentered(tester, item);
  await tester.pump(const Duration(milliseconds: 300));
  await snap(tester, 'menu-$text');
}

/// Mở menu 3 chấm của hàng nội dung [divisionId] và chọn mục [text].
Future<void> pressMenuItem(
  WidgetTester tester,
  String divisionId,
  String text,
) async {
  clearSnackBars(tester);
  final menu = find.descendant(
    of: find.byKey(ValueKey('division-row-$divisionId')),
    matching: find.byType(PopupMenuButton<String>),
  );
  // Danh sách làm mới ngay sau khi lưu nên nút menu có thể biến mất giữa lúc tìm thấy và lúc bấm: thử lại.
  for (var attempt = 0; attempt < 4; attempt++) {
    await pumpUntilFound(
      tester,
      menu,
      what: 'menu 3 chấm của nội dung $divisionId',
    );
    try {
      await tapCentered(tester, menu);
    } on StateError {
      await tester.pump(const Duration(milliseconds: 500));
      continue;
    }
    await tester.pump(const Duration(milliseconds: 500));
    await pressMenuText(tester, text);
    return;
  }
  fail('Không bấm được menu 3 chấm của nội dung $divisionId sau 4 lần thử');
}

/// Bấm nút xác nhận (FilledButton) của hộp thoại đang mở.
Future<void> confirmDialog(WidgetTester tester, String step) async {
  final button = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(FilledButton),
  );
  await pumpUntilFound(tester, button, what: 'hộp xác nhận ($step)');
  // The dialog scales in; wait so the tap lands on the settled button.
  await tester.pump(const Duration(milliseconds: 500));
  await snap(tester, 'xac-nhan');
  await tester.tap(button.last);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Bấm công tắc LavishSwitch nằm trong hàng có key [rowKey].
Future<void> tapSwitch(WidgetTester tester, String rowKey) async {
  clearSnackBars(tester);
  final toggle = find.descendant(
    of: find.byKey(ValueKey(rowKey)),
    matching: find.byType(LavishSwitch),
  );
  await pumpUntilFound(tester, toggle, what: 'công tắc trong hàng "$rowKey"');
  await tapCentered(tester, toggle);
  await tester.pump(const Duration(milliseconds: 300));
  await snap(tester, rowKey);
}

Future<void> expectGone(
  WidgetTester tester,
  String key, {
  required String step,
}) => pumpUntilCondition(
  tester,
  () => find.byKey(ValueKey(key)).evaluate().isEmpty,
  what: '$step: widget key "$key" biến mất',
);

/// Đóng route trên cùng chứa widget [key] (như bấm Back) khi sheet không có nút đóng riêng.
void _popRouteOf(WidgetTester tester, String key) =>
    Navigator.of(tester.element(find.byKey(ValueKey(key)).first)).pop();

Finder _keyStartsWith(String prefix) => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> && key.value.startsWith(prefix);
}, description: 'key bắt đầu bằng "$prefix"');

Finder _rowOf(Map<String, dynamic> participant) =>
    find.byKey(ValueKey('athlete-team-row-${participant['id']}'));

Finder _addAthleteBox(String divisionId) => find.descendant(
  of: find.byKey(ValueKey('athlete-division-body-$divisionId')),
  matching: find.text('Thêm VĐV'),
);

/// Mở sheet chi tiết của VĐV bằng cách chạm hàng của họ.
Future<void> openDetail(WidgetTester tester, String participantId) async {
  clearSnackBars(tester);
  final row = find.byKey(ValueKey('athlete-team-row-$participantId'));
  await pumpUntilFound(tester, row, what: 'hàng VĐV $participantId');
  await tapCentered(
    tester,
    find.descendant(of: row, matching: find.byType(InkWell)).first,
  );
  await expectKey(
    tester,
    'participant-detail-profile',
    step: 'sheet chi tiết VĐV',
  );
  await snap(tester, 'chi-tiet-vdv');
}

Future<void> _fillGuest(
  WidgetTester tester, {
  required String name,
  required String email,
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('add-athlete-direct-name')),
    name,
  );
  await tester.enterText(
    find.byKey(const ValueKey('add-athlete-direct-email')),
    email,
  );
  await tester.enterText(
    find.byKey(const ValueKey('add-athlete-direct-phone')),
    kPlayerPhone,
  );
  await tester.enterText(
    find.byKey(const ValueKey('add-athlete-direct-notes')),
    'E2E ghi chú',
  );
  await tester.pump();
}

/// Gọi Backend tới khi [ok] đúng; đỏ kèm [what] nếu hết giờ.
Future<T> waitFor<T>(
  WidgetTester tester,
  Future<T> Function() fetch,
  bool Function(T value) ok, {
  required String what,
  Duration timeout = const Duration(seconds: 40),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (true) {
    final value = await fetch();
    if (ok(value)) return value;
    if (DateTime.now().isAfter(deadline)) {
      fail('Hết ${timeout.inSeconds}s mà Backend chưa có: $what; giá trị cuối: $value');
    }
    await tester.pump(const Duration(seconds: 1));
  }
}

// Backend helpers local to this journey (BackendApi has no organizer participant list).

final _http = Dio(
  BaseOptions(
    baseUrl: kE2eApiBaseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 60),
    contentType: Headers.jsonContentType,
    validateStatus: (_) => true,
  ),
);

Future<Object?> _call(
  String method,
  String path,
  String token, {
  Object? data,
}) async {
  final response = await _http.request<Object?>(
    path,
    data: data,
    options: Options(
      method: method,
      headers: {'Authorization': 'Bearer $token'},
    ),
  );
  final code = response.statusCode ?? 0;
  if (code < 200 || code >= 300) {
    throw StateError(
      '$method $path -> HTTP $code: ${jsonEncode(response.data)}',
    );
  }
  final body = response.data;
  return body is Map && body.containsKey('data') ? body['data'] : body;
}

/// Danh sách đầy đủ cho BTC (`GET /tournaments/:id/manage/participants`), cùng nguồn với màn VĐV.
Future<List<Map<String, dynamic>>> _fetchManage(
  String token,
  String tournamentId,
) async {
  final data = await _call(
    'GET',
    '/tournaments/$tournamentId/manage/participants',
    token,
  );
  if (data is! List) {
    throw StateError('manage/participants không trả danh sách: $data');
  }
  return data
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

Future<void> _importRaw(
  String token,
  String tournamentId,
  String divisionId,
  List<Map<String, Object>> participants,
) => _call(
  'POST',
  '/tournaments/$tournamentId/roster-import',
  token,
  data: {'divisionId': divisionId, 'participants': participants},
);

/// Một VĐV lẻ (chỉ VĐV 1): giải đơn chờ duyệt khi [autoApprove] false, nội dung đôi chờ đối tác.
Map<String, Object> _soloEntry(String name, {required bool autoApprove}) => {
  'teamName': name,
  'player1Name': name,
  'player1Email': '${name.toLowerCase().replaceAll(' ', '-')}@example.com',
  'source': 'MANUAL_EMAIL',
  'autoApprove': autoApprove,
};

Map<String, dynamic> _byMarker(
  List<Map<String, dynamic>> list,
  String marker,
) => list.firstWhere(
  (p) => jsonEncode(p).contains(marker),
  orElse: () => throw StateError('Backend không có VĐV chứa "$marker"'),
);

const _inactiveStatuses = {'REJECTED', 'KICKED', 'WITHDRAWN'};

int _activeCount(List<Map<String, dynamic>> list) =>
    list.where((p) => !_inactiveStatuses.contains(p['teamStatus'])).length;

int _countStatus(List<Map<String, dynamic>> list, String status) =>
    list.where((p) => p['teamStatus'] == status).length;
