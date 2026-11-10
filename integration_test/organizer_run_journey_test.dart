import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/features/match/widgets/official_score_modal.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lifecycle_end_sheet.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lifecycle_opening_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/organizer_journey.dart';
import 'support/shot.dart';

/// Task 2.2: organizer runs a tournament from the registration lifecycle to the
/// end: close/reopen registration, draw, bracket tab, opening, inline scores on
/// the results tab, live desk, end sheet and the public page. Real Backend.
/// Tests share one tournament (`run`) and must run in file order; `drawOnly`
/// is a second tournament for the manual draw.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final api = BackendApi();
  late SeededTournament run;
  late SeededTournament drawOnly;
  late String championName;

  setUpAll(() async {
    await initializeAppForTests();
    run = await seedTournament(api);
    drawOnly = await seedTournament(api);
  });

  Future<String> freshToken() => api.login(kOrganizerEmail, kE2ePassword);

  Future<String> status(String token, SeededTournament t) async {
    final data = await api.getTournament(
      token: token,
      tournamentId: t.tournamentId,
    );
    return StatusHelper.normalizeTournamentStatus(data['status'] as String?);
  }

  Future<void> pollStatus(
    WidgetTester tester,
    String token,
    SeededTournament t,
    String expected,
  ) => _pollBackend(
    tester,
    () => status(token, t),
    (value) => value == expected,
    what: 'trạng thái giải = $expected',
  );

  Future<List<Map<String, dynamic>>> liveMatches(
    String token,
    SeededTournament t,
  ) async {
    final all = await api.listMatches(
      token: token,
      tournamentId: t.tournamentId,
      divisionId: t.divisionId,
    );
    return all.where((m) => m['status'] != 'CANCELLED').toList();
  }

  Future<void> pollMatchCount(
    WidgetTester tester,
    String token,
    SeededTournament t, {
    required bool Function(int count) ok,
    required String what,
  }) => _pollBackend(
    tester,
    () async => (await liveMatches(token, t)).length,
    ok,
    what: what,
  );

  Future<Map<String, dynamic>> matchById(
    String token,
    SeededTournament t,
    String id,
  ) async => (await liveMatches(token, t)).firstWhere((m) => m['id'] == id);

  testWidgets(
    'TC-QLGD-APP-20..23: vòng đời đăng ký: mở, đóng, mở lại, đóng lại',
    (tester) async {
      final token = await freshToken();
      final container = await signInAsOrganizer(tester);
      final shots = _Shots(tester, binding, 'run-life');
      await openManageHub(tester, container, run.tournamentId);

      // TC-QLGD-APP-20: giải ADMIN đã duyệt phải ở trạng thái mở đăng ký.
      if (await status(token, run) == AppConstants.statusUpcoming) {
        await _tapButton(tester, 'Mở đăng ký ngay', step: 'TC-QLGD-APP-20');
        await _confirmDialog(tester, step: 'TC-QLGD-APP-20 mở đăng ký');
        await pollStatus(tester, token, run, AppConstants.statusRegistration);
      }
      expect(
        await status(token, run),
        AppConstants.statusRegistration,
        reason: 'Giải dựng bằng API + ADMIN duyệt phải đang mở đăng ký',
      );
      await expectKey(tester, 'lifecycle-step-current', step: 'TC-QLGD-APP-20');
      // "Công bố giải đấu" chỉ hiện ở nháp; giải dựng bằng API đã qua bước đó.
      expect(
        find.widgetWithText(LavishButton, 'Công bố giải đấu'),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('lifecycle-publish-blocked')),
        findsNothing,
      );
      debugPrint(
        'TC-QLGD-APP-20: không bấm "Công bố giải đấu" và lifecycle-publish-blocked: '
        'giải dựng bằng API không ở trạng thái nháp nên nút không hiện.',
      );
      await shots.snap('dang-mo-dang-ky');

      // TC-QLGD-APP-21: đóng đăng ký.
      await _tapButton(tester, 'Đóng đăng ký', step: 'TC-QLGD-APP-21');
      await _confirmDialog(tester, step: 'TC-QLGD-APP-21 đóng đăng ký');
      await pollStatus(
        tester,
        token,
        run,
        AppConstants.statusRegistrationClosed,
      );
      await pumpUntilFound(
        tester,
        find.widgetWithText(LavishButton, 'Khai mạc giải'),
        what: 'TC-QLGD-APP-21: nút Khai mạc giải sau khi đóng đăng ký',
      );
      expect(
        find.widgetWithText(LavishButton, 'Mở lại đăng ký'),
        findsOneWidget,
      );
      await shots.snap('da-dong-dang-ky');

      // TC-QLGD-APP-22: mở lại đăng ký.
      await _tapButton(tester, 'Mở lại đăng ký', step: 'TC-QLGD-APP-22');
      await _confirmDialog(tester, step: 'TC-QLGD-APP-22 mở lại đăng ký');
      await pollStatus(tester, token, run, AppConstants.statusRegistration);
      await pumpUntilFound(
        tester,
        find.widgetWithText(LavishButton, 'Đóng đăng ký'),
        what: 'TC-QLGD-APP-22: nút Đóng đăng ký sau khi mở lại',
      );
      await shots.snap('da-mo-lai-dang-ky');

      // TC-QLGD-APP-23: đóng lại để sang bốc thăm và khai mạc.
      await _tapButton(tester, 'Đóng đăng ký', step: 'TC-QLGD-APP-23');
      await _confirmDialog(tester, step: 'TC-QLGD-APP-23 đóng đăng ký');
      await pollStatus(
        tester,
        token,
        run,
        AppConstants.statusRegistrationClosed,
      );
      await shots.snap('dong-lai-dang-ky');
    },
  );

  testWidgets(
    'TC-QLGD-APP-24..26: bốc thăm từng đội, lưu sơ đồ và làm lại sơ đồ',
    (tester) async {
      final token = await freshToken();
      final container = await signInAsOrganizer(tester);
      final shots = _Shots(tester, binding, 'run-draw-manual');
      final drawRoute =
          '/organizer/tournaments/${drawOnly.tournamentId}/manage/draw';
      container.read(routerProvider).go(drawRoute);

      // TC-QLGD-APP-24: bốc thăm từng đội, lưu bị khóa tới khi lộ hết đội.
      await _tapText(tester, 'Bốc thăm từng đội', step: 'TC-QLGD-APP-24');
      await _expectText(tester, 'Còn 4 đội chưa bốc', step: 'TC-QLGD-APP-24');
      final save = find.widgetWithText(ElevatedButton, 'Lưu & Bắt đầu giải');
      await pumpUntilFound(
        tester,
        save,
        what: 'TC-QLGD-APP-24: nút Lưu & Bắt đầu giải',
      );
      expect(tester.widget<ElevatedButton>(save).onPressed, isNull);
      await shots.snap('bat-dau-boc-tung-doi');

      await _tapText(tester, 'Bốc 1 đội', step: 'TC-QLGD-APP-24');
      await _expectText(tester, 'Còn 3 đội chưa bốc', step: 'TC-QLGD-APP-24');
      expect(tester.widget<ElevatedButton>(save).onPressed, isNull);
      await shots.snap('boc-1-doi');

      await _tapText(tester, 'Hiện tất cả', step: 'TC-QLGD-APP-24');
      await pumpUntilCondition(
        tester,
        () => tester.widget<ElevatedButton>(save).onPressed != null,
        what: 'TC-QLGD-APP-24: nút Lưu & Bắt đầu giải bật sau Hiện tất cả',
      );
      await shots.snap('hien-tat-ca');

      _clearSnackBars(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tapCentered(tester, save);
      await pollMatchCount(
        tester,
        token,
        drawOnly,
        ok: (count) => count >= 3,
        what: 'TC-QLGD-APP-24: sơ đồ 4 VĐV có 3 trận sau Lưu & Bắt đầu giải',
      );
      await _expectText(
        tester,
        'Bốc thăm và lưu thành công',
        step: 'TC-QLGD-APP-24',
        contains: true,
      );
      expect(find.textContaining('Lỗi: '), findsNothing);
      await pumpUntilFound(
        tester,
        find.widgetWithText(Tab, 'Tổng quan'),
        what: 'TC-QLGD-APP-24: về trang quản lý sau khi lưu',
      );
      await shots.snap('da-luu-so-do');

      // TC-QLGD-APP-25: mở lại màn bốc thăm, sơ đồ đã có thì chỉ còn Làm lại sơ đồ.
      container.read(routerProvider).go(drawRoute);
      await _expectText(tester, 'Làm lại sơ đồ', step: 'TC-QLGD-APP-25');
      expect(find.text('Bốc thăm tự động'), findsNothing);
      await shots.snap('da-co-so-do');

      // TC-QLGD-APP-26: bấm Làm lại sơ đồ. App mobile chưa xóa được trận
      // (ApiMatchRepository.deleteAll ném UnimplementedError) nên chỉ kiểm màn không sập.
      await _tapText(tester, 'Làm lại sơ đồ', step: 'TC-QLGD-APP-26');
      await tester.pump(const Duration(seconds: 2));
      await _expectText(tester, 'Bốc thăm & Phân bảng', step: 'TC-QLGD-APP-26');
      final after = await liveMatches(token, drawOnly);
      debugPrint(
        'TC-QLGD-APP-26: sau Làm lại sơ đồ Backend còn ${after.length} trận '
        '(App mobile không có API xóa trận, nút báo lỗi).',
      );
      await shots.snap('sau-lam-lai');
    },
  );

  testWidgets(
    'TC-QLGD-APP-27..29: bốc thăm tự động, xóa và tạo lại bracket ở tab Bảng đấu',
    (tester) async {
      final token = await freshToken();
      final container = await signInAsOrganizer(tester);
      final shots = _Shots(tester, binding, 'run-bracket');
      container
          .read(routerProvider)
          .go('/organizer/tournaments/${run.tournamentId}/manage/draw');

      // TC-QLGD-APP-27: bốc thăm tự động rồi lưu.
      await _tapText(tester, 'Bốc thăm tự động', step: 'TC-QLGD-APP-27');
      final save = find.widgetWithText(ElevatedButton, 'Lưu & Bắt đầu giải');
      await pumpUntilFound(
        tester,
        save,
        what: 'TC-QLGD-APP-27: nút Lưu & Bắt đầu giải',
      );
      await shots.snap('xem-truoc-tu-dong');
      _clearSnackBars(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tapCentered(tester, save);
      await pollMatchCount(
        tester,
        token,
        run,
        ok: (count) => count >= 3,
        what: 'TC-QLGD-APP-27: sơ đồ 4 VĐV có 3 trận',
      );
      await pumpUntilFound(
        tester,
        find.widgetWithText(Tab, 'Bảng đấu'),
        what: 'TC-QLGD-APP-27: về trang quản lý sau khi lưu',
      );

      // TC-QLGD-APP-28: xóa bracket (hủy rồi xác nhận).
      await openHubTab(tester, 'Bảng đấu');
      await tapKey(tester, 'bracket-mgmt-delete', step: 'TC-QLGD-APP-28');
      await expectKey(
        tester,
        'bracket-mgmt-delete-confirm',
        step: 'TC-QLGD-APP-28',
      );
      await shots.snap('hop-thoai-xoa-bracket');
      await tapKey(tester, 'bracket-mgmt-delete-cancel', step: 'TC-QLGD-APP-28');
      await pumpUntilCondition(
        tester,
        () => find
            .byKey(const ValueKey('bracket-mgmt-delete-confirm'))
            .evaluate()
            .isEmpty,
        what: 'TC-QLGD-APP-28: hộp thoại xóa đóng sau Hủy',
      );
      expect((await liveMatches(token, run)).length, greaterThanOrEqualTo(3));

      await tapKey(tester, 'bracket-mgmt-delete', step: 'TC-QLGD-APP-28');
      await tapKey(
        tester,
        'bracket-mgmt-delete-confirm',
        step: 'TC-QLGD-APP-28',
      );
      await pollMatchCount(
        tester,
        token,
        run,
        ok: (count) => count == 0,
        what: 'TC-QLGD-APP-28: bracket đã xóa trên Backend',
      );
      await expectKey(tester, 'bracket-mgmt-create', step: 'TC-QLGD-APP-28');
      await shots.snap('da-xoa-bracket');

      // TC-QLGD-APP-29: tạo lại bracket từ tab Bảng đấu.
      _clearSnackBars(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tapKey(tester, 'bracket-mgmt-create', step: 'TC-QLGD-APP-29');
      await pollMatchCount(
        tester,
        token,
        run,
        ok: (count) => count >= 3,
        what: 'TC-QLGD-APP-29: bracket tạo lại có 3 trận',
      );
      await expectKey(tester, 'bracket-mgmt-delete', step: 'TC-QLGD-APP-29');
      await shots.snap('da-tao-lai-bracket');
    },
  );

  testWidgets('TC-QLGD-APP-30: khai mạc giải', (tester) async {
    final token = await freshToken();
    final container = await signInAsOrganizer(tester);
    final shots = _Shots(tester, binding, 'run-open');
    await openManageHub(tester, container, run.tournamentId);
    expect(await status(token, run), AppConstants.statusRegistrationClosed);

    // Sheet khai mạc chỉ hiện khi còn nội dung mở đăng ký; không thì hộp xác nhận kèm ô tick.
    final divisions = await api.listDivisions(run.tournamentId);
    final sheetExpected = divisions.any(
      (d) => divisionRegistrationOpen(d, AppConstants.statusRegistrationClosed),
    );
    await _tapButton(tester, 'Khai mạc giải', step: 'TC-QLGD-APP-30');
    if (sheetExpected) {
      await expectKey(
        tester,
        'lifecycle-opening-confirm',
        step: 'TC-QLGD-APP-30',
      );
      await shots.snap('sheet-khai-mac');
      final divisionKey = 'lifecycle-opening-division-${run.divisionId}';
      await tapKey(tester, divisionKey, step: 'TC-QLGD-APP-30 bỏ chọn nội dung');
      await tapKey(tester, divisionKey, step: 'TC-QLGD-APP-30 chọn lại nội dung');
      await tapKey(tester, 'lifecycle-opening-cancel', step: 'TC-QLGD-APP-30');
      await pumpUntilCondition(
        tester,
        () => find
            .byKey(const ValueKey('lifecycle-opening-confirm'))
            .evaluate()
            .isEmpty,
        what: 'TC-QLGD-APP-30: sheet khai mạc đóng sau Hủy',
      );
      expect(await status(token, run), AppConstants.statusRegistrationClosed);
      await _tapButton(tester, 'Khai mạc giải', step: 'TC-QLGD-APP-30');
      await tapKey(tester, 'lifecycle-opening-confirm', step: 'TC-QLGD-APP-30');
    } else {
      await pumpUntilFound(
        tester,
        find.byType(CheckboxListTile),
        what: 'TC-QLGD-APP-30: ô tick đóng đăng ký tất cả nội dung',
      );
      await shots.snap('hop-thoai-khai-mac');
      await tester.tap(find.byType(CheckboxListTile).last);
      await tester.pump(const Duration(milliseconds: 300));
      await _confirmDialog(tester, step: 'TC-QLGD-APP-30 xác nhận khai mạc');
    }
    await pollStatus(tester, token, run, AppConstants.statusInProgress);
    await pumpUntilFound(
      tester,
      find.widgetWithText(LavishButton, 'Kết thúc giải'),
      what: 'TC-QLGD-APP-30: nút Kết thúc giải sau khai mạc',
    );
    await shots.snap('da-khai-mac');
  });

  testWidgets(
    'TC-QLGD-APP-31..33: tab Kết quả: lọc, tìm, cuộn vòng và nhập điểm inline',
    (tester) async {
      final token = await freshToken();
      final container = await signInAsOrganizer(tester);
      final shots = _Shots(tester, binding, 'run-results');
      final before = await liveMatches(token, run);
      final playable = _playable(before);
      expect(playable, hasLength(2), reason: 'Bán kết phải có 2 trận đủ đối thủ');
      final m1 = playable[0]['id'] as String;
      final m2 = playable[1]['id'] as String;
      final row1 = find.byKey(ValueKey('results-row-$m1'));
      // BUG-SP-03 (sản phẩm): sheet nhập điểm ở tab Kết quả gửi PATCH /matches/:id/score cho trận
      // SCHEDULED và Backend trả 400 "Hãy bắt đầu trận trước"; sheet không tự bắt đầu trận.
      // Điều kiện đầu: bắt đầu trận 1 bằng API TRƯỚC khi App tải danh sách (revision mới, tránh 409).
      await api.startMatch(token: token, matchId: m1);
      await openManageHub(tester, container, run.tournamentId);
      await openHubTab(tester, 'Kết quả');

      // TC-QLGD-APP-31: các chip lọc và số đếm.
      await expectKey(tester, 'results-filter-all', step: 'TC-QLGD-APP-31');
      final unfinished = before
          .where((m) => m['isBye'] != true && m['status'] != 'COMPLETED')
          .length;
      await _expectCount(tester, 'unfinished', '$unfinished');
      await _expectCount(tester, 'finished', '0');
      for (final name in ['live', 'upcoming', 'finished', 'unfinished', 'all']) {
        await tapKey(tester, 'results-filter-$name', step: 'TC-QLGD-APP-31');
        await shots.snap('loc-$name');
        if (name == 'live') {
          await pumpUntilFound(
            tester,
            row1,
            what: 'TC-QLGD-APP-31: chip live thấy trận 1 đang đấu',
          );
        }
        if (name == 'finished') {
          await _expectText(
            tester,
            'Không có trận phù hợp',
            step: 'TC-QLGD-APP-31 chip $name',
          );
        }
      }
      await pumpUntilFound(
        tester,
        row1,
        what: 'TC-QLGD-APP-31: dòng trận 1 ở chip Tất cả',
      );

      // Tìm kiếm: không khớp thì rỗng, khớp theo tiền tố giải thì thấy lại trận.
      final search = find.byKey(const ValueKey('results-search'));
      await tester.enterText(search, 'zzz-khong-co-ai');
      await _expectText(
        tester,
        'Không có trận phù hợp',
        step: 'TC-QLGD-APP-31 tìm không khớp',
      );
      expect(row1, findsNothing);
      await shots.snap('tim-khong-khop');
      await tester.enterText(search, run.tag.toLowerCase());
      await pumpUntilFound(
        tester,
        row1,
        what: 'TC-QLGD-APP-31: tìm theo tiền tố giải thấy trận 1',
      );
      await tester.enterText(search, '');
      await pumpUntilFound(
        tester,
        row1,
        what: 'TC-QLGD-APP-31: xóa ô tìm vẫn thấy trận 1',
      );

      // Gập/mở hộp vòng và menu "Tới vòng".
      final toggle = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith(
              'results-box-toggle-',
            ),
        description: 'nút gập hộp vòng',
      );
      await pumpUntilFound(
        tester,
        toggle,
        what: 'TC-QLGD-APP-31: nút gập hộp vòng',
      );
      await tapCentered(tester, toggle);
      await pumpUntilCondition(
        tester,
        () => row1.evaluate().isEmpty,
        what: 'TC-QLGD-APP-31: hộp vòng gập thì mất dòng trận 1',
      );
      await tapCentered(tester, toggle);
      await pumpUntilFound(
        tester,
        row1,
        what: 'TC-QLGD-APP-31: mở lại hộp vòng',
      );
      await tapKey(tester, 'results-jump', step: 'TC-QLGD-APP-31');
      final jumpItem = find.byType(PopupMenuItem<String>);
      await pumpUntilFound(
        tester,
        jumpItem,
        what: 'TC-QLGD-APP-31: mục menu Tới vòng',
      );
      await shots.snap('menu-toi-vong');
      await tester.tap(jumpItem.first);
      await pumpUntilCondition(
        tester,
        () => jumpItem.evaluate().isEmpty,
        what: 'TC-QLGD-APP-31: menu Tới vòng đóng sau khi chọn',
      );
      await pumpUntilFound(
        tester,
        row1,
        what: 'TC-QLGD-APP-31: dòng trận 1 sau Tới vòng',
      );

      // TC-QLGD-APP-32: nhập điểm inline; hòa số set thì không lưu được.
      await tapKey(tester, 'results-score-$m1', step: 'TC-QLGD-APP-32');
      await expectKey(tester, 'results-score-sheet', step: 'TC-QLGD-APP-32');
      await shots.snap('sheet-nhap-diem');
      Future<void> enter(int side, int set, String value) => tester.enterText(
        find.byKey(ValueKey('results-score-input-$side-$set')),
        value,
      );
      await enter(1, 0, '11');
      await enter(2, 0, '5');
      await enter(1, 1, '5');
      await enter(2, 1, '11');
      await tester.pump(const Duration(milliseconds: 300));
      await expectKey(tester, 'results-score-tied', step: 'TC-QLGD-APP-32');
      final saveButton = find.byKey(const ValueKey('results-score-save'));
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
      await shots.snap('hoa-so-set');

      await tapKey(tester, 'results-score-add-set', step: 'TC-QLGD-APP-32');
      await expectKey(
        tester,
        'results-score-input-1-3',
        step: 'TC-QLGD-APP-32 thêm set',
      );
      await enter(1, 2, '11');
      await enter(2, 2, '9');
      await pumpUntilCondition(
        tester,
        () => find
            .byKey(const ValueKey('results-score-tied'))
            .evaluate()
            .isEmpty,
        what: 'TC-QLGD-APP-32: hết báo hòa sau set 3',
      );
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);

      // Chọn ngày giờ thi đấu: hai hộp chọn đều có nút OK.
      await tapKey(tester, 'results-score-played-pick', step: 'TC-QLGD-APP-32');
      await pumpUntilFound(
        tester,
        find.text('OK'),
        what: 'TC-QLGD-APP-32: hộp chọn ngày (OK)',
      );
      await tester.tap(find.text('OK').first);
      await tester.pump(const Duration(seconds: 1));
      await pumpUntilFound(
        tester,
        find.text('OK'),
        what: 'TC-QLGD-APP-32: hộp chọn giờ (OK)',
      );
      await tester.tap(find.text('OK').first);
      await tester.pump(const Duration(seconds: 1));
      await shots.snap('da-nhap-diem');

      await tapKey(tester, 'results-score-save', step: 'TC-QLGD-APP-32');
      await _pollBackend(
        tester,
        () => matchById(token, run, m1),
        (m) =>
            m['status'] == 'COMPLETED' &&
            m['winnerId'] == m['participant1Id'] &&
            m['p1SetsWon'] == 2 &&
            m['p2SetsWon'] == 1,
        what: 'TC-QLGD-APP-32: trận 1 COMPLETED, bên 1 thắng 2-1',
      );
      await pumpUntilCondition(
        tester,
        () => find
            .byKey(const ValueKey('results-score-sheet'))
            .evaluate()
            .isEmpty,
        what: 'TC-QLGD-APP-32: sheet nhập điểm đóng sau Lưu',
      );
      await _expectCount(tester, 'finished', '1');
      expect(find.byKey(ValueKey('results-score-$m1')), findsNothing);
      await shots.snap('da-luu-diem');

      // TC-QLGD-APP-33: nút "Mở bàn điểm" trong sheet đưa tới /live/:matchId.
      await tapKey(tester, 'results-score-$m2', step: 'TC-QLGD-APP-33');
      await expectKey(tester, 'results-score-sheet', step: 'TC-QLGD-APP-33');
      await tapKey(tester, 'results-score-live', step: 'TC-QLGD-APP-33');
      final router = container.read(routerProvider);
      await pumpUntilCondition(
        tester,
        () => router.routerDelegate.currentConfiguration.uri.path == '/live/$m2',
        what: 'TC-QLGD-APP-33: chuyển tới /live/$m2',
      );
      await tester.pump(const Duration(seconds: 2));
      await shots.snap('man-live-xem');
      router.pop();
      await expectKey(
        tester,
        'results-filter-all',
        step: 'TC-QLGD-APP-33 quay lại tab Kết quả',
      );
    },
  );

  testWidgets(
    'TC-QLGD-APP-34..35: bàn điểm live của BTC: bắt đầu trận và mở bảng điểm',
    (tester) async {
      final token = await freshToken();
      final container = await signInAsOrganizer(tester);
      final shots = _Shots(tester, binding, 'run-live');
      final m2 = _playable(await liveMatches(token, run)).single['id'] as String;
      container
          .read(routerProvider)
          .go('/organizer/tournaments/${run.tournamentId}/ops/match/$m2');

      // TC-QLGD-APP-34: trận đã xếp lịch, BTC bắt đầu trận.
      await _tapText(tester, 'BẮT ĐẦU TRẬN ĐẤU', step: 'TC-QLGD-APP-34');
      await _pollBackend(
        tester,
        () => matchById(token, run, m2),
        (m) => m['status'] == 'ONGOING',
        what: 'TC-QLGD-APP-34: trận 2 sang ONGOING',
      );

      // TC-QLGD-APP-35: bảng điểm chính thức. Giải lite tự mở bảng sau khi bắt đầu,
      // giải thường thì bấm "MỞ BẢNG".
      final scorePage = find.byType(OfficialScorePage);
      final openBoard = find.byTooltip('MỞ BẢNG');
      await pumpUntilCondition(
        tester,
        () => scorePage.evaluate().isNotEmpty || openBoard.evaluate().isNotEmpty,
        what: 'TC-QLGD-APP-35: bảng điểm tự mở hoặc nút MỞ BẢNG',
      );
      if (scorePage.evaluate().isEmpty) {
        await tapCentered(tester, openBoard);
      }
      await pumpUntilFound(
        tester,
        scorePage,
        what: 'TC-QLGD-APP-35: trang bảng điểm chính thức',
      );
      await _expectText(tester, 'Tính điểm', step: 'TC-QLGD-APP-35');
      await shots.snap('bang-diem-tinh-diem');
      await tapCentered(tester, find.text('Phạm lỗi').first);
      await tester.pump(const Duration(milliseconds: 500));
      await shots.snap('bang-diem-pham-loi');
      debugPrint(
        'TC-QLGD-APP-35: không chấm điểm bằng giao diện: bàn điểm pickleball dùng kéo-thả '
        'trên sân, và nút KẾT THÚC ở _buildLiveState không đạt được khi BTC có quyền chấm. '
        'Điểm các trận còn lại chấm bằng BackendApi.',
      );
      Navigator.of(tester.element(scorePage)).pop();
      await pumpUntilCondition(
        tester,
        () => scorePage.evaluate().isEmpty,
        what: 'TC-QLGD-APP-35: đóng trang bảng điểm',
      );

      // Menu "more" của người chấm.
      await tapKey(tester, 'live-more-menu', step: 'TC-QLGD-APP-35');
      await _expectText(tester, 'Chi tiết trận', step: 'TC-QLGD-APP-35 menu more');
      await shots.snap('menu-more');
      await tester.tapAt(const Offset(4, 4));
      await pumpUntilCondition(
        tester,
        () => find.text('Chi tiết trận').evaluate().isEmpty,
        what: 'TC-QLGD-APP-35: menu more đóng',
      );
    },
  );

  testWidgets(
    'TC-QLGD-APP-36..37: kết thúc giải: bị chặn khi còn trận LIVE, rồi xác nhận kết quả',
    (tester) async {
      final token = await freshToken();
      final container = await signInAsOrganizer(tester);
      final shots = _Shots(tester, binding, 'run-end');
      final live = (await liveMatches(token, run))
          .where((m) => m['status'] == 'ONGOING')
          .toList();
      expect(live, hasLength(1), reason: 'Còn đúng 1 trận ONGOING từ bàn điểm');
      await openManageHub(tester, container, run.tournamentId);

      // TC-QLGD-APP-36: còn trận LIVE thì nút xác nhận khóa và nêu lý do.
      await _openEndSheet(tester);
      await expectKey(
        tester,
        'lifecycle-end-blocked-reason',
        step: 'TC-QLGD-APP-36',
      );
      await expectKey(
        tester,
        'lifecycle-end-live-${live.single['id']}',
        step: 'TC-QLGD-APP-36',
      );
      final confirm = find.byKey(const ValueKey('lifecycle-end-confirm'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await shots.snap('ket-thuc-bi-chan');
      Navigator.of(tester.element(find.byType(LifecycleEndSheet))).pop();
      await pumpUntilCondition(
        tester,
        () => find.byType(LifecycleEndSheet).evaluate().isEmpty,
        what: 'TC-QLGD-APP-36: đóng sheet kết thúc giải',
      );

      // Nút "Kết thúc giải" ở thẻ vòng đời: hủy ở hộp xác nhận thì giải vẫn đang diễn ra.
      await _tapButton(tester, 'Kết thúc giải', step: 'TC-QLGD-APP-36');
      final cancel = find.widgetWithText(TextButton, 'Hủy');
      await pumpUntilFound(
        tester,
        cancel,
        what: 'TC-QLGD-APP-36: hộp xác nhận kết thúc (Hủy)',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(cancel.last);
      await tester.pump(const Duration(milliseconds: 500));
      expect(await status(token, run), AppConstants.statusInProgress);

      // Chấm nốt các trận bằng API (bàn điểm không thao tác được trên emulator).
      championName = await api.playOutSingleElimination(
        token: token,
        tournamentId: run.tournamentId,
        divisionId: run.divisionId,
      );

      // TC-QLGD-APP-37: hết trận thì sheet cho xác nhận; Backend không tự COMPLETED.
      expect(await status(token, run), AppConstants.statusInProgress);
      await _openEndSheet(tester);
      await _expectText(tester, 'Trận đã hoàn tất: 3/3', step: 'TC-QLGD-APP-37');
      await expectKey(tester, 'lifecycle-end-podium-1', step: 'TC-QLGD-APP-37');
      await pumpUntilCondition(
        tester,
        () => tester.widget<FilledButton>(confirm).onPressed != null,
        what: 'TC-QLGD-APP-37: nút xác nhận kết quả bật khi hết trận LIVE',
      );
      await shots.snap('ket-thuc-san-sang');
      await tapKey(tester, 'lifecycle-end-confirm', step: 'TC-QLGD-APP-37');
      await _confirmDialog(
        tester,
        label: 'Xác nhận kết quả',
        step: 'TC-QLGD-APP-37 xác nhận kết thúc giải',
      );
      await pollStatus(tester, token, run, AppConstants.statusCompleted);
      await _expectText(
        tester,
        'Giải đấu đã kết thúc thành công!',
        step: 'TC-QLGD-APP-37',
      );
      await pumpUntilCondition(
        tester,
        () => find
            .widgetWithText(LavishButton, 'Kết thúc giải')
            .evaluate()
            .isEmpty,
        what: 'TC-QLGD-APP-37: thẻ vòng đời hết nút Kết thúc giải',
      );
      // "Chốt lại kết quả" chỉ hiện khi sửa kết quả sau khi kết thúc.
      expect(
        find.byKey(const ValueKey('results-reconfirm-action')),
        findsNothing,
      );
      await shots.snap('da-ket-thuc');
    },
  );

  testWidgets(
    'TC-QLGD-APP-38..39: trang công khai thấy các tab và nhà vô địch',
    (tester) async {
      final container = await pumpApp(tester);
      await ensureSignedOut(tester, container);
      final shots = _Shots(tester, binding, 'run-public');
      container.read(routerProvider).go('/tournament/${run.tournamentId}');

      // TC-QLGD-APP-38: đủ các tab công khai.
      for (final label in [
        'Tổng quan',
        'Giới thiệu',
        'Danh sách đội',
        'Bảng đấu',
        'Lịch thi đấu',
      ]) {
        final tab = find.widgetWithText(Tab, label);
        await pumpUntilFound(
          tester,
          tab,
          what: 'TC-QLGD-APP-38: tab công khai "$label"',
        );
        await tapCentered(tester, tab);
        await tester.pump(const Duration(seconds: 1));
        await shots.snap('tab-${label.toLowerCase().replaceAll(' ', '-')}');
      }

      // TC-QLGD-APP-39: tab Kết quả có nhà vô địch trên bục.
      await pumpUntilFound(
        tester,
        find.text('Kết quả'),
        what: 'TC-QLGD-APP-39: tab Kết quả',
      );
      await tapCentered(tester, find.text('Kết quả').first);
      final podium = find.byKey(const ValueKey('results-podium-null'));
      await pumpUntilFound(tester, podium, what: 'TC-QLGD-APP-39: bục vinh danh');
      await pumpUntilFound(
        tester,
        find.descendant(of: podium, matching: find.text(championName)),
        what: 'TC-QLGD-APP-39: nhà vô địch $championName trên bục',
      );
      await shots.snap('nha-vo-dich');
    },
  );
}

/// Names the screenshots of one test: `prefix-NN-name`. The surface is converted once, lazily.
class _Shots {
  _Shots(this.tester, this.binding, this.prefix);

  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;
  final String prefix;
  bool _converted = false;
  int _count = 0;

  Future<void> snap(String name) async {
    if (!_converted) {
      await binding.convertFlutterSurfaceToImage();
      _converted = true;
    }
    await tester.pump();
    _count++;
    await shot(binding, '$prefix-${_count.toString().padLeft(2, '0')}-$name');
  }
}

/// Matches with both sides known that are not finished yet.
List<Map<String, dynamic>> _playable(List<Map<String, dynamic>> matches) =>
    matches
        .where(
          (m) =>
              m['isBye'] != true &&
              m['status'] != 'COMPLETED' &&
              m['participant1Id'] is String &&
              m['participant2Id'] is String,
        )
        .toList();

/// Polls the Backend (pumping frames between reads) until [ok]; fails after [timeout].
Future<void> _pollBackend<T>(
  WidgetTester tester,
  Future<T> Function() fetch,
  bool Function(T value) ok, {
  required String what,
  Duration timeout = const Duration(seconds: 45),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (true) {
    final value = await fetch();
    if (ok(value)) return;
    if (DateTime.now().isAfter(deadline)) {
      fail(
        'Hết ${timeout.inSeconds}s mà Backend chưa có: $what. Giá trị cuối: $value',
      );
    }
    await tester.pump(const Duration(seconds: 1));
  }
}

/// Snackbars can cover bottom buttons; clear the queue before tapping them.
void _clearSnackBars(WidgetTester tester) {
  ScaffoldMessenger.of(
    tester.element(find.byType(Scaffold).first),
  ).clearSnackBars();
}

/// Taps a lifecycle button (LavishButton) once it is enabled.
Future<void> _tapButton(
  WidgetTester tester,
  String label, {
  required String step,
}) async {
  final finder = find.widgetWithText(LavishButton, label);
  await pumpUntilFound(tester, finder, what: '$step: nút "$label"');
  await pumpUntilCondition(
    tester,
    () => tester.widget<LavishButton>(finder.first).onPressed != null,
    what: '$step: nút "$label" bật',
  );
  _clearSnackBars(tester);
  await tester.pump(const Duration(milliseconds: 400));
  await tapCentered(tester, finder);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Taps the first widget showing exactly [text].
Future<void> _tapText(
  WidgetTester tester,
  String text, {
  required String step,
}) async {
  final finder = find.text(text);
  await pumpUntilFound(tester, finder, what: '$step: nút "$text"');
  await tapCentered(tester, finder);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _expectText(
  WidgetTester tester,
  String text, {
  required String step,
  bool contains = false,
}) async {
  final finder = contains ? find.textContaining(text) : find.text(text);
  await pumpUntilFound(tester, finder, what: '$step: chữ "$text"');
  expect(finder, findsWidgets);
}

/// Taps the confirm button of the topmost dialog (a sheet below may have a button with the same label).
Future<void> _confirmDialog(
  WidgetTester tester, {
  String label = 'Xác nhận',
  required String step,
}) async {
  final finder = find.widgetWithText(FilledButton, label);
  await pumpUntilFound(
    tester,
    finder,
    what: '$step: nút "$label" của hộp xác nhận',
  );
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(finder.last);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Waits until the results chip counter `results-filter-count-<filter>` shows [expected].
Future<void> _expectCount(
  WidgetTester tester,
  String filter,
  String expected,
) async {
  final finder = find.byKey(ValueKey('results-filter-count-$filter'));
  await pumpUntilFound(tester, finder, what: 'số đếm chip lọc "$filter"');
  await pumpUntilCondition(
    tester,
    () => tester.widget<Text>(finder).data == expected,
    what: 'số đếm chip lọc "$filter" = $expected',
  );
}

/// Opens the hub overflow menu and the end-tournament sheet (LifecycleEndSheet).
Future<void> _openEndSheet(WidgetTester tester) async {
  final menu = find.byTooltip('HỆ THỐNG');
  await pumpUntilFound(tester, menu, what: 'menu HỆ THỐNG của trang quản lý');
  await tester.tap(menu.first);
  await tester.pump(const Duration(milliseconds: 400));
  final item = find.text('Kết thúc giải đấu');
  await pumpUntilFound(tester, item, what: 'mục "Kết thúc giải đấu" trong menu');
  // Chữ cùng tên còn nằm ở lộ trình trên trang: mục menu nằm trong lớp phủ nên là phần tử cuối.
  await tester.tap(item.last);
  await tester.pump(const Duration(milliseconds: 400));
  await pumpUntilFound(
    tester,
    find.byType(LifecycleEndSheet),
    what: 'sheet kết thúc giải',
  );
}
