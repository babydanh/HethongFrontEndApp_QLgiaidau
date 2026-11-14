import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/features/admin/widgets/admin_list_skeleton.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'support/actors.dart';
import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/social_journey.dart';

/// Chuỗi E nhiều tài khoản: auth, admin và khách (TC-MULTI-E-01..20).
/// Emulator Android + Backend thật. Vai chính thao tác trên giao diện, vai phụ dựng dữ liệu qua API.
/// Không thanh toán cổng thật, không đăng nhập Google.
///
/// Lỗi sản phẩm đã xác định được đánh dấu `skip: 'BUG-...'`, giữ nguyên `expect` để gỡ skip khi sửa xong.
/// Đặt true để bỏ qua các ca đỏ vì lỗi sản phẩm đã xác nhận (BUG-...).
const bool _skipKnownBugs = true;

/// Ca 09, 10 đang chạy để lấy phản hồi của Backend cho POST /users/change-requests (xem `_sendGenderChangeRequest`).
const bool _skipChangeRequestCases = false;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeAppForTests);

  // ─── Auth: đăng ký, đăng nhập, quên mật khẩu ───

  testWidgets(
    'TC-MULTI-E-01 đăng ký tài khoản mới trên giao diện: vào được app, Backend đăng nhập được bằng tài khoản đó',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-01');
      final account = _newAccount('ME01');
      final container = await _guestApp(tester);
      await _openLogin(tester, container);
      await shooter.snap('man-dang-nhap');

      await _switchToRegister(tester);
      await shooter.snap('form-dang-ky');
      await _fillRegisterForm(tester, account);
      await shooter.snap('da-nhap-form');
      await _tapAuthSubmit(tester, 'Đăng ký');

      await pumpUntilCondition(
        tester,
        () => container.read(authProvider).isAuthenticated,
        timeout: const Duration(seconds: 45),
        what: 'đăng ký xong và đã đăng nhập ${account.email}',
      );
      expect(
        container.read(authProvider).role,
        UserRole.viewer,
        reason: 'Tài khoản mới đăng ký chưa có vai trò quản trị',
      );
      await _settleAfterLogin(tester);
      await shooter.snap('vao-trang-chu');
      expect(
        await _api.login(account.email, kE2ePassword),
        isNotEmpty,
        reason:
            'Tài khoản vừa đăng ký trên giao diện phải đăng nhập được qua Backend',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-E-02 form đăng ký báo lỗi từng ô: để trống, email sai, mật khẩu ngắn, vẫn chưa đăng nhập',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-02');
      final container = await _guestApp(tester);
      await _openLogin(tester, container);
      await _switchToRegister(tester);

      await _tapAuthSubmit(tester, 'Đăng ký');
      await pumpUntil(tester, find.text('Vui lòng nhập họ và tên'));
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
      await shooter.snap('de-trong');

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Nguoi Thu');
      await tester.enterText(fields.at(1), 'khong-phai-email');
      await tester.enterText(fields.at(2), '123');
      await tester.pump();
      await _tapAuthSubmit(tester, 'Đăng ký');
      await pumpUntil(tester, find.text('Địa chỉ email không hợp lệ'));
      expect(find.text('Mật khẩu tối thiểu 6 ký tự'), findsOneWidget);
      expect(find.text('Vui lòng nhập họ và tên'), findsNothing);
      await shooter.snap('email-sai-mat-khau-ngan');

      expect(container.read(authProvider).isAuthenticated, isFalse);
      expect(currentPath(tester), '/login');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-E-03 đăng ký trùng email và đăng nhập sai mật khẩu: hiện khung lỗi, không vào app',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-03');
      final viewer = (await _actors())['viewer']!;
      final container = await _guestApp(tester);
      await _openLogin(tester, container);

      // Đăng nhập sai mật khẩu.
      var fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), viewer.email);
      await tester.enterText(fields.at(1), 'sai-mat-khau-1');
      await tester.pump();
      await _tapAuthSubmit(tester, 'Đăng nhập');
      await _waitAuthResult(tester);
      expect(
        find.byIcon(Icons.error_outline_rounded),
        findsOneWidget,
        reason: 'Sai mật khẩu phải hiện khung lỗi',
      );
      expect(container.read(authProvider).isAuthenticated, isFalse);
      await shooter.snap('sai-mat-khau');

      // Đăng ký với email đã có tài khoản.
      await _switchToRegister(tester);
      fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(3));
      await tester.enterText(fields.at(0), 'Trung Email');
      await tester.enterText(fields.at(1), viewer.email);
      await tester.enterText(fields.at(2), kE2ePassword);
      await tester.pump();
      await _tapAuthSubmit(tester, 'Đăng ký');
      await _waitAuthResult(tester);
      expect(
        find.byIcon(Icons.error_outline_rounded),
        findsOneWidget,
        reason: 'Email đã có phải bị từ chối kèm khung lỗi',
      );
      expect(container.read(authProvider).isAuthenticated, isFalse);
      expect(currentPath(tester), '/login');
      await shooter.snap('trung-email');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-E-04 quên mật khẩu: kiểm email, gửi yêu cầu và thấy màn Đã gửi email khôi phục',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-04');
      final viewer = (await _actors())['viewer']!;
      final container = await _guestApp(tester);
      await _openLogin(tester, container);
      await tapText(tester, 'Quên mật khẩu?');
      await pumpUntil(tester, find.text('Đặt lại mật khẩu'));
      expect(_currentUri(tester).path, '/forgot-password');
      await shooter.snap('man-quen-mat-khau');

      await tapText(tester, 'Gửi Yêu Cầu Khôi Phục');
      await pumpUntil(tester, find.text('Vui lòng nhập địa chỉ email'));
      final email = find.byType(TextFormField);
      await tester.enterText(email.first, 'khong-phai-email');
      await tester.pump();
      await tapText(tester, 'Gửi Yêu Cầu Khôi Phục');
      await pumpUntil(tester, find.text('Email không hợp lệ'));
      await shooter.snap('email-sai');

      await tester.enterText(email.first, viewer.email);
      await tester.pump();
      await tapText(tester, 'Gửi Yêu Cầu Khôi Phục');
      await pumpUntil(
        tester,
        find.text('Đã Gửi Email Khôi Phục'),
        timeout: const Duration(seconds: 45),
      );
      expect(find.text('Trở về Đăng nhập'), findsOneWidget);
      await shooter.snap('da-gui-email');
      expect(container.read(authProvider).isAuthenticated, isFalse);
      await leaveSocialSession(tester, container);
    },
  );

  // ─── Admin ───

  testWidgets(
    'TC-MULTI-E-05 admin đăng nhập bằng form: vai trò admin, mở được 4 màn quản trị',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-05');
      final container = await _adminSession(tester);
      expect(container.read(authProvider).role, UserRole.admin);
      await shooter.snap('admin-trang-chu');

      const screens = {
        '/admin/clubs': 'Quản lý CLB',
        '/admin/change-requests': 'Yêu cầu thay đổi',
        '/admin/disputes': 'Khiếu nại',
        '/admin/verification': 'Xác thực',
      };
      for (final entry in screens.entries) {
        await _openRoute(tester, container, entry.key);
        await pumpUntil(tester, find.text(entry.value));
        expect(
          currentPath(tester),
          entry.key,
          reason: 'Admin phải ở lại ${entry.key}',
        );
        await _waitListLoaded(tester);
        await shooter.snap(entry.key.split('/').last);
      }
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-E-06 BUG-ADMIN-01 admin vào /admin ở lại một màn quản trị',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-06');
      final container = await _adminSession(tester);
      await _openRoute(tester, container, '/admin');
      await shooter.snap('sau-khi-vao-admin');
      expect(
        currentPath(tester),
        startsWith('/admin'),
        reason:
            'Admin vào /admin phải thấy màn quản trị, không bị chuyển về ${currentPath(tester)}',
      );
      await leaveSocialSession(tester, container);
    },
    skip:
        _skipKnownBugs, // BUG-ADMIN-01: /admin chuyển về /home, không có màn quản trị tổng (app_router.dart:241-246)
  );

  testWidgets(
    'TC-MULTI-E-07 BUG-ADMIN-03 admin thấy CLB mới trong Quản lý CLB, CLB đang hoạt động nên không có nút Duyệt',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-07');
      final owner = (await _actors())['clubOwner']!;
      final name = '${socialTag('ME07')} CLB duyet';
      final clubId = await _api.createCommunity(
        token: owner.token,
        name: name,
        joinMode: 'OPEN',
      );
      // Backend cho CLB tạo qua API hoạt động ngay (không qua PENDING), nên admin chỉ thấy Vô hiệu, không có Duyệt.
      expect(await _communityStatus(clubId, owner.token), 'ACTIVE');

      final container = await _adminSession(tester);
      await _openClubSearch(tester, container, name);
      await shooter.snap('clb-hoat-dong');
      expect(find.text('Duyệt'), findsNothing);
      expect(find.text('Vô hiệu'), findsOneWidget);
      await leaveSocialSession(tester, container);
    },
    skip:
        _skipKnownBugs, // BUG-ADMIN-03: GET /communities?limit=200 bị Backend 400 (tối đa 50), Quản lý CLB luôn báo lỗi tải
  );

  testWidgets(
    'TC-MULTI-E-08 BUG-ADMIN-03 admin vô hiệu CLB: bắt buộc nhập lý do, sau đó CLB bị từ chối',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-08');
      final owner = (await _actors())['clubOwner']!;
      final name = '${socialTag('ME08')} CLB tu choi';
      final clubId = await _api.createCommunity(
        token: owner.token,
        name: name,
        joinMode: 'OPEN',
      );

      final container = await _adminSession(tester);
      await _openClubSearch(tester, container, name);
      await _tapLabelBelow(tester, _textLike(name), 'Vô hiệu');
      await pumpUntil(tester, find.text('Vô hiệu hoá CLB'));
      await shooter.snap('hop-thoai-tu-choi');

      // Chưa nhập lý do thì Xác nhận không làm gì.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Xác nhận'));
      await socialWait(tester, const Duration(seconds: 1));
      expect(
        find.text('Vô hiệu hoá CLB'),
        findsOneWidget,
        reason: 'Thiếu lý do thì hộp thoại không được đóng',
      );
      expect(await _communityStatus(clubId, owner.token), 'ACTIVE');

      final reason = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(reason, 'E2E: hồ sơ CLB chưa đủ thông tin');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Xác nhận'));
      await pumpUntilCondition(
        tester,
        () => find.text('Vô hiệu hoá CLB').evaluate().isEmpty,
        what: 'hộp thoại vô hiệu đóng sau khi xác nhận',
      );
      await socialWait(tester, const Duration(seconds: 2));
      await shooter.snap('da-tu-choi');
      expect(await _communityStatus(clubId, owner.token), 'REJECTED');
      await leaveSocialSession(tester, container);
    },
    skip: _skipKnownBugs, // BUG-ADMIN-03
  );

  testWidgets(
    'TC-MULTI-E-09 BUG-ADMIN-04 admin duyệt yêu cầu thay đổi do VĐV gửi: thẻ chuyển sang Đã duyệt',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-09');
      final player = (await _actors())['player']!;
      await _sendGenderChangeRequest(player);

      final container = await _adminSession(tester);
      await _openChangeRequests(tester, container, player.fullName);
      await shooter.snap('yeu-cau-cho-xu-ly');
      await _tapLabelBelow(tester, _textLike(player.fullName), 'Duyệt');
      await pumpUntil(tester, find.text('Đã duyệt yêu cầu'));
      await shooter.snap('da-duyet');

      await tapText(tester, 'Đã duyệt');
      await _scrollToFinder(tester, _textLike(player.fullName));
      expect(
        _textLike(player.fullName),
        findsWidgets,
        reason: 'Yêu cầu đã duyệt phải nằm ở bộ lọc Đã duyệt',
      );
      await shooter.snap('loc-da-duyet');
      await leaveSocialSession(tester, container);
    },
    skip:
        _skipChangeRequestCases, // BUG-ADMIN-04: GET /admin/change-requests 404
  );

  testWidgets(
    'TC-MULTI-E-10 BUG-ADMIN-04 admin từ chối yêu cầu thay đổi: thẻ chuyển sang Từ chối',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-10');
      final referee = (await _actors())['referee']!;
      await _sendGenderChangeRequest(referee);

      final container = await _adminSession(tester);
      await _openChangeRequests(tester, container, referee.fullName);
      await _tapLabelBelow(tester, _textLike(referee.fullName), 'Từ chối');
      await pumpUntil(tester, find.text('Đã từ chối yêu cầu'));
      await shooter.snap('da-tu-choi');

      await tapText(tester, 'Từ chối');
      await _scrollToFinder(tester, _textLike(referee.fullName));
      expect(
        _textLike(referee.fullName),
        findsWidgets,
        reason: 'Yêu cầu bị từ chối phải nằm ở bộ lọc Từ chối',
      );
      await shooter.snap('loc-tu-choi');
      await leaveSocialSession(tester, container);
    },
    skip: _skipChangeRequestCases, // BUG-ADMIN-04
  );

  testWidgets(
    'TC-MULTI-E-11 BUG-ADMIN-04 admin mở màn khiếu nại: tải được danh sách và đổi được bộ lọc',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-11');
      final container = await _adminSession(tester);
      await _openRoute(tester, container, '/admin/disputes');
      await pumpUntil(tester, find.text('Khiếu nại'));
      await _waitListLoaded(tester);
      expect(
        find.byIcon(Icons.cloud_off_rounded),
        findsNothing,
        reason: 'Màn khiếu nại báo lỗi tải dữ liệu',
      );
      await shooter.snap('tat-ca');
      for (final filter in ['Đang mở', 'Đã giải quyết', 'Tất cả']) {
        await tapText(tester, filter);
        await socialWait(tester, const Duration(milliseconds: 800));
        expect(
          find.byIcon(Icons.cloud_off_rounded),
          findsNothing,
          reason: 'Lọc "$filter" bị lỗi',
        );
        await shooter.snap('loc-${filter.replaceAll(' ', '-').toLowerCase()}');
      }
      await leaveSocialSession(tester, container);
    },
    skip: _skipKnownBugs, // BUG-ADMIN-04: GET /admin/disputes 404
  );

  testWidgets(
    'TC-MULTI-E-12 BUG-ADMIN-04 admin mở màn xác minh: tải được danh sách, lọc theo loại và trạng thái',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-12');
      final container = await _adminSession(tester);
      await _openRoute(tester, container, '/admin/verification');
      await pumpUntil(tester, find.text('Xác thực'));
      await _waitListLoaded(tester);
      expect(
        find.byIcon(Icons.cloud_off_rounded),
        findsNothing,
        reason: 'Màn xác minh báo lỗi tải dữ liệu',
      );
      await shooter.snap('tat-ca');
      for (final filter in [
        'Người dùng',
        'CLB',
        'Giải đấu',
        'Chờ duyệt',
        'Đã xác thực',
        'Từ chối',
      ]) {
        await tapText(tester, filter);
        await socialWait(tester, const Duration(milliseconds: 800));
        expect(
          find.byIcon(Icons.cloud_off_rounded),
          findsNothing,
          reason: 'Lọc "$filter" bị lỗi',
        );
      }
      await shooter.snap('loc-cuoi');
      await leaveSocialSession(tester, container);
    },
    skip: _skipKnownBugs, // BUG-ADMIN-04: GET /admin/verification 404
  );

  group('phân quyền âm', () {
    testWidgets(
      'TC-MULTI-E-13 phân quyền âm: VĐV thường không vào được 4 màn quản trị admin',
      (tester) async {
        final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-13');
        final player = (await _actors())['player']!;
        final container = await signInAs(tester, player);
        await _settleAfterLogin(tester);
        expect(container.read(authProvider).role, isNot(UserRole.admin));
        for (final route in [
          '/admin/clubs',
          '/admin/change-requests',
          '/admin/disputes',
          '/admin/verification',
        ]) {
          await expectBlocked(tester, route);
          expect(
            find.text('Duyệt'),
            findsNothing,
            reason: 'VĐV không được thấy nút duyệt của admin ($route)',
          );
          await shooter.snap('chan-${route.split('/').last}');
        }
        await leaveSocialSession(tester, container);
      },
    );

    testWidgets(
      'TC-MULTI-E-18 phân quyền âm: khách không vào được /dashboard, /profile, /payments, /notifications, màn admin và BTC',
      (tester) async {
        final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-18');
        final container = await _guestApp(tester);
        for (final route in [
          '/dashboard',
          '/profile',
          '/payments',
          '/notifications',
          '/admin/clubs',
          '/referee',
          '/organizer/tournaments/khong-co/manage',
        ]) {
          await expectBlocked(tester, route);
          await shooter.snap('chan-${route.replaceAll('/', '-')}');
        }
        expect(container.read(authProvider).isAuthenticated, isFalse);
        await leaveSocialSession(tester, container);
      },
    );

    testWidgets(
      'TC-MULTI-E-19 BUG-GUEST-01 phân quyền âm: khách mở /chat, /club-create, /club-invites phải bị đưa về đăng nhập',
      (tester) async {
        final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-19');
        final container = await _guestApp(tester);
        for (final route in ['/chat', '/club-create', '/club-invites']) {
          await shooter.snap('truoc-${route.substring(1)}');
          await expectBlocked(tester, route);
        }
        await leaveSocialSession(tester, container);
      },
      skip:
          _skipKnownBugs, // BUG-GUEST-01: allowlist startsWith cho khách vào /chat, /club-create, /club-invites (app_router.dart:125-140)
    );
  });

  // ─── Khách ───

  testWidgets(
    'TC-MULTI-E-14 khách xem trang chủ: thấy lời mời đăng nhập, thanh điều hướng và mở được tab Xếp hạng',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-14');
      final container = await _guestApp(tester);
      await pumpUntil(
        tester,
        find.text('Đăng nhập để xem ELO & thống kê'),
        timeout: const Duration(seconds: 60),
      );
      expect(find.text('Trang chủ'), findsWidgets);
      expect(find.text('Xếp hạng'), findsWidgets);
      expect(container.read(authProvider).isAuthenticated, isFalse);
      await shooter.snap('trang-chu-khach');

      await tapText(tester, 'Xếp hạng');
      await socialWait(tester, const Duration(seconds: 3));
      expect(
        currentPath(tester),
        '/home',
        reason: 'Tab Xếp hạng nằm trong trang chủ, khách không bị đẩy đi',
      );
      await shooter.snap('xep-hang-khach');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-E-15 admin duyệt giải rồi khách mở được trang giới thiệu giải công khai',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-15');
      final shared = await _sharedTournament();
      expect(
        shared.statusBefore.toUpperCase(),
        contains('PENDING'),
        reason:
            'Giải BTC vừa tạo phải chờ admin duyệt, đang là ${shared.statusBefore}',
      );
      expect(
        shared.statusAfter.toUpperCase(),
        isNot(contains('PENDING')),
        reason:
            'Sau khi admin duyệt giải không còn chờ duyệt, đang là ${shared.statusAfter}',
      );

      final container = await _guestApp(tester);
      await _openRoute(tester, container, '/tournament/${shared.tournamentId}');
      await pumpUntil(
        tester,
        _textLike(shared.name),
        timeout: const Duration(seconds: 45),
      );
      expect(find.text('Giải đấu không tồn tại'), findsNothing);
      await shooter.snap('gioi-thieu-giai-khach');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-E-16 khách xem sơ đồ thi đấu của giải: thấy tên VĐV đã bốc thăm',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-16');
      final shared = await _sharedTournament();
      final container = await _guestApp(tester);
      await _openRoute(
        tester,
        container,
        '/tournament/${shared.tournamentId}/bracket',
      );
      await pumpUntil(
        tester,
        _textLike(shared.tag),
        timeout: const Duration(seconds: 45),
      );
      expect(find.text('Chưa có trận đấu nào'), findsNothing);
      expect(find.text('Giải đấu không tồn tại'), findsNothing);
      await shooter.snap('so-do-khach');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-E-17 khách xem trực tiếp: danh sách trận của giải và màn một trận đang diễn ra',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-17');
      final shared = await _sharedTournament();
      final container = await _guestApp(tester);

      await _openRoute(
        tester,
        container,
        '/live-matches/${shared.tournamentId}',
      );
      await pumpUntil(tester, find.text('Trận đấu trực tiếp'));
      await pumpUntil(
        tester,
        _textLike(shared.name),
        timeout: const Duration(seconds: 45),
      );
      expect(find.text('Giải đấu không tồn tại'), findsNothing);
      await shooter.snap('danh-sach-tran');

      await _openRoute(
        tester,
        container,
        '/live/${shared.matchId}?tournamentId=${shared.tournamentId}',
      );
      await pumpUntil(
        tester,
        _textLike(shared.tag),
        timeout: const Duration(seconds: 45),
      );
      expect(
        currentPath(tester),
        '/live/${shared.matchId}',
        reason: 'Khách xem trận công khai, không bị chuyển đi',
      );
      await shooter.snap('man-tran-khach');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-E-20 khách mở link mời giải rồi đăng ký tài khoản: sau đăng ký về đúng giải được mời',
    (tester) async {
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-E-20');
      final shared = await _sharedTournament();
      final detail = await _api.getTournament(
        token: shared.organizerToken,
        tournamentId: shared.tournamentId,
      );
      final code = '${detail['inviteCode'] ?? ''}';
      expect(
        code,
        isNotEmpty,
        reason: 'Backend không trả inviteCode cho giải ${shared.tournamentId}',
      );
      final account = _newAccount('ME20');

      final container = await _guestApp(tester);
      await _openRoute(tester, container, '/join/$code');
      await pumpUntilCondition(
        tester,
        () =>
            _currentUri(tester).path == '/login' ||
            find.text('Vui lòng đăng nhập để tham gia').evaluate().isNotEmpty,
        timeout: const Duration(seconds: 45),
        what:
            'link mời dẫn tới màn đăng nhập hoặc màn yêu cầu đăng nhập của giải',
      );
      await shooter.snap('sau-link-moi');
      if (_currentUri(tester).path != '/login') {
        await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
        await tester.pump();
      }
      await pumpUntil(tester, find.text('Địa chỉ Email'));
      final redirect = _currentUri(tester).queryParameters['redirect'] ?? '';
      expect(
        redirect.contains(code) || redirect.contains(shared.tournamentId),
        isTrue,
        reason:
            'Màn đăng nhập phải giữ đường dẫn quay lại giải được mời, đang là "$redirect"',
      );

      await tester.pump(const Duration(milliseconds: 1500));
      await _switchToRegister(tester);
      await _fillRegisterForm(tester, account);
      await _tapAuthSubmit(tester, 'Đăng ký');
      await pumpUntilCondition(
        tester,
        () => container.read(authProvider).isAuthenticated,
        timeout: const Duration(seconds: 45),
        what: 'đăng ký xong từ link mời',
      );
      await pumpUntilCondition(
        tester,
        () =>
            currentPath(tester) != '/login' &&
            currentPath(tester) != '/login-loading',
        timeout: const Duration(seconds: 45),
        what: 'rời màn đăng nhập sau khi đăng ký',
      );
      await socialWait(tester, const Duration(seconds: 2));
      final location = _currentUri(tester).toString();
      await shooter.snap('sau-dang-ky');
      expect(
        location.contains(code) || location.contains(shared.tournamentId),
        isTrue,
        reason: 'Sau đăng ký phải quay lại giải được mời, đang ở "$location"',
      );
      await leaveSocialSession(tester, container);
    },
  );
}

// ─────────────────────────── Dữ liệu dùng chung ───────────────────────────

final BackendApi _api = BackendApi();
Map<String, E2eActor>? _actorCache;
_SharedTournament? _sharedCache;

Future<Map<String, E2eActor>> _actors() async =>
    _actorCache ??= await createActors(
      _api,
      chain: 'multie',
      roles: const [
        'organizer',
        'admin',
        'player',
        'referee',
        'viewer',
        'clubOwner',
      ],
    );

/// Giải dùng chung cho ca khách (15, 16, 17, 20): BTC tạo, admin duyệt, 4 VĐV, bốc thăm, khai mạc, một trận đang diễn ra.
class _SharedTournament {
  const _SharedTournament({
    required this.organizerToken,
    required this.tournamentId,
    required this.name,
    required this.tag,
    required this.matchId,
    required this.statusBefore,
    required this.statusAfter,
  });

  final String organizerToken;
  final String tournamentId;
  final String name;
  final String tag;
  final String matchId;
  final String statusBefore;
  final String statusAfter;
}

Future<_SharedTournament> _sharedTournament() async =>
    _sharedCache ??= await _buildSharedTournament();

Future<_SharedTournament> _buildSharedTournament() async {
  final organizer = (await _actors())['organizer']!;
  final tag = socialTag('MEG');
  final name = '$tag Giải khách';
  final created = await _api.createLiteTournament(
    token: organizer.token,
    name: name,
    matchType: 'SINGLES',
    maxParticipants: 4,
  );
  final before = await _api.getTournament(
    token: organizer.token,
    tournamentId: created.tournamentId,
  );
  await _api.approveTournamentAsAdmin(created.tournamentId);
  final after = await _api.getTournament(
    token: organizer.token,
    tournamentId: created.tournamentId,
  );
  await _api.importRoster(
    token: organizer.token,
    tournamentId: created.tournamentId,
    divisionId: created.divisionId,
    tag: tag,
    count: 4,
    singles: true,
  );
  await _api.generateBracket(
    token: organizer.token,
    tournamentId: created.tournamentId,
    divisionId: created.divisionId,
  );
  await _api.startTournament(
    token: organizer.token,
    tournamentId: created.tournamentId,
  );
  final matches = await _api.listMatches(
    token: organizer.token,
    tournamentId: created.tournamentId,
    divisionId: created.divisionId,
  );
  final playable = matches.where(
    (m) =>
        m['participant1Id'] is String &&
        m['participant2Id'] is String &&
        m['status'] != 'COMPLETED',
  );
  if (playable.isEmpty) {
    throw StateError(
      'Giải ${created.tournamentId} không có trận nào đủ 2 đối thủ sau khi bốc thăm',
    );
  }
  final matchId = playable.first['id'] as String;
  await _api.startMatch(token: organizer.token, matchId: matchId);
  return _SharedTournament(
    organizerToken: organizer.token,
    tournamentId: created.tournamentId,
    name: name,
    tag: tag,
    matchId: matchId,
    statusBefore: '${before['status']}',
    statusAfter: '${after['status']}',
  );
}

class _NewAccount {
  const _NewAccount(this.fullName, this.email);

  final String fullName;
  final String email;
}

_NewAccount _newAccount(String prefix) {
  final tag = socialTag(prefix);
  return _NewAccount('E2E $tag Moi', 'e2e-$tag-moi@example.com'.toLowerCase());
}

/// Gửi yêu cầu đổi giới tính (giống hộp thoại trong Cài đặt) để admin có thẻ để duyệt.
Future<void> _sendGenderChangeRequest(E2eActor actor) async {
  final dio = Dio(
    BaseOptions(
      baseUrl: kE2eApiBaseUrl,
      validateStatus: (_) => true,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  final response = await dio.post<Object?>(
    '/users/change-requests',
    data: {'requestType': 'GENDER', 'newValue': 'Nữ'},
    options: Options(headers: {'Authorization': 'Bearer ${actor.token}'}),
  );
  final code = response.statusCode ?? 0;
  expect(
    code,
    inInclusiveRange(200, 299),
    reason: 'POST /users/change-requests trả HTTP $code: ${response.data}',
  );
}

/// Trạng thái CLB (viết hoa) theo `GET /communities/:id`.
Future<String> _communityStatus(String communityId, String token) async {
  final dio = Dio(
    BaseOptions(
      baseUrl: kE2eApiBaseUrl,
      validateStatus: (_) => true,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  final response = await dio.get<Object?>(
    '/communities/$communityId',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  expect(
    response.statusCode,
    inInclusiveRange(200, 299),
    reason: 'GET /communities/$communityId trả HTTP ${response.statusCode}',
  );
  final body = response.data;
  final data = body is Map && body.containsKey('data') ? body['data'] : body;
  return '${(data as Map)['status']}'.toUpperCase();
}

// ─────────────────────────── Phiên và điều hướng ───────────────────────────

/// Mở app ở trạng thái khách: đăng nhập tạm bằng tài khoản viewer rồi đăng xuất, để dùng bản dựng không GPS.
Future<ProviderContainer> _guestApp(WidgetTester tester) async {
  final bootstrap = (await _actors())['viewer']!;
  final container = await signInAs(tester, bootstrap);
  await ensureSignedOut(tester, container);
  container.read(routerProvider).go('/home');
  await socialWait(tester, const Duration(seconds: 2));
  expect(container.read(authProvider).isAuthenticated, isFalse);
  return container;
}

Future<ProviderContainer> _adminSession(WidgetTester tester) async {
  final admin = (await _actors())['admin']!;
  final container = await signInAs(tester, admin);
  await _settleAfterLogin(tester);
  return container;
}

/// Sau đăng nhập, màn chuyển tiếp hẹn giờ rồi `go('/home')` và ghi đè điều hướng của test; chờ nó xong.
Future<void> _settleAfterLogin(WidgetTester tester) => pumpUntilCondition(
  tester,
  () => currentPath(tester) == '/home',
  timeout: const Duration(seconds: 30),
  what: 'màn chuyển tiếp sau đăng nhập về /home',
);

Future<void> _openRoute(
  WidgetTester tester,
  ProviderContainer container,
  String route,
) async {
  container.read(routerProvider).go(route);
  await socialWait(tester, const Duration(seconds: 1));
}

/// Địa chỉ của màn trên cùng. Màn mở bằng `push` nằm trong `ImperativeRouteMatch`, còn `uri` của cả danh sách vẫn là màn bên dưới.
Uri _currentUri(WidgetTester tester) {
  final list = appContainer(
    tester,
  ).read(routerProvider).routerDelegate.currentConfiguration;
  final top = list.last;
  return top is ImperativeRouteMatch ? top.matches.uri : list.uri;
}

// ─────────────────────────── Form đăng nhập, đăng ký ───────────────────────────

Future<void> _openLogin(
  WidgetTester tester,
  ProviderContainer container,
) async {
  container.read(routerProvider).go('/login');
  await pumpUntil(tester, find.text('Địa chỉ Email'));
  // Form hiện bằng animation (fadeIn trễ 250ms, dài 400ms): chờ hết trước khi nhập hoặc bấm.
  await tester.pump(const Duration(milliseconds: 1500));
}

Future<void> _switchToRegister(WidgetTester tester) async {
  await tapText(tester, 'Đăng ký ngay');
  await pumpUntil(tester, find.text('Họ và tên'));
  await socialWait(tester, const Duration(milliseconds: 600));
}

Future<void> _fillRegisterForm(WidgetTester tester, _NewAccount account) async {
  final fields = find.byType(TextFormField);
  expect(
    fields,
    findsNWidgets(3),
    reason: 'Form đăng ký có 3 ô: họ tên, email, mật khẩu',
  );
  await tester.enterText(fields.at(0), account.fullName);
  await tester.enterText(fields.at(1), account.email);
  await tester.enterText(fields.at(2), kE2ePassword);
  await tester.pump();
}

/// Bấm nút gửi form (TextButton có nhãn [label]).
Future<void> _tapAuthSubmit(WidgetTester tester, String label) async {
  final button = find.widgetWithText(TextButton, label);
  await pumpUntil(tester, button);
  await tapCentered(tester, button);
}

/// Chờ nút gửi hiện lại sau lượt gọi Backend (trong lúc gọi nút thành vòng quay).
Future<void> _waitAuthResult(WidgetTester tester) async {
  await tester.pump();
  await pumpUntilCondition(
    tester,
    () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
    timeout: const Duration(seconds: 45),
    what: 'Backend trả lời lượt đăng nhập/đăng ký',
  );
  await tester.pump(const Duration(milliseconds: 500));
}

// ─────────────────────────── Màn admin ───────────────────────────

Future<void> _waitListLoaded(WidgetTester tester) => pumpUntilCondition(
  tester,
  () => find.byType(AdminListSkeleton).evaluate().isEmpty,
  timeout: const Duration(seconds: 45),
  what: 'danh sách admin tải xong (hết skeleton)',
);

/// Mở /admin/clubs và tìm CLB theo tên (danh sách có thể dài, tìm theo tên để thẻ nằm sát đầu).
Future<void> _openClubSearch(
  WidgetTester tester,
  ProviderContainer container,
  String name,
) async {
  await _openRoute(tester, container, '/admin/clubs');
  await pumpUntil(tester, find.text('Quản lý CLB'));
  await _waitListLoaded(tester);
  final search = find.byType(TextField);
  await pumpUntil(tester, search);
  await tester.enterText(search.first, name);
  await tester.pump();
  await pumpUntil(
    tester,
    _textLike(name),
    timeout: const Duration(seconds: 30),
  );
}

/// Mở /admin/change-requests, lọc Chờ xử lý và cuộn tới thẻ của [requesterName].
Future<void> _openChangeRequests(
  WidgetTester tester,
  ProviderContainer container,
  String requesterName,
) async {
  await _openRoute(tester, container, '/admin/change-requests');
  await pumpUntil(tester, find.text('Yêu cầu thay đổi'));
  await _waitListLoaded(tester);
  await tapText(tester, 'Chờ xử lý');
  await socialWait(tester, const Duration(milliseconds: 800));
  await _scrollToFinder(tester, _textLike(requesterName));
}

// ─────────────────────────── Tìm và chạm ───────────────────────────

/// Text chứa [part], không phân biệt hoa thường (tên có thể bị viết hoa hoặc cắt bởi giao diện).
Finder _textLike(String part) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? '').toLowerCase().contains(part.toLowerCase()),
  description: 'Text chứa "$part"',
);

/// Cuộn danh sách dọc tới khi thấy [target].
Future<void> _scrollToFinder(WidgetTester tester, Finder target) async {
  await pumpUntil(tester, target, timeout: const Duration(seconds: 30));
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: find
        .byWidgetPredicate(
          (w) =>
              w is Scrollable &&
              (w.axisDirection == AxisDirection.down ||
                  w.axisDirection == AxisDirection.up),
        )
        .first,
    maxScrolls: 40,
  );
  await tester.pump();
}

/// Chạm chữ [label] nằm ngay dưới [anchor] (nút của đúng thẻ chứa [anchor], không nhầm nút ở thẻ hoặc bộ lọc khác).
Future<void> _tapLabelBelow(
  WidgetTester tester,
  Finder anchor,
  String label,
) async {
  await pumpUntil(tester, anchor);
  await Scrollable.ensureVisible(tester.element(anchor.first), alignment: 0.3);
  await tester.pump(const Duration(milliseconds: 400));
  final anchorY = tester.getCenter(anchor.first).dy;
  final labels = find.text(label);
  int? best;
  var bestDistance = double.infinity;
  for (var i = 0; i < labels.evaluate().length; i++) {
    final distance = tester.getCenter(labels.at(i)).dy - anchorY;
    if (distance > 0 && distance < bestDistance) {
      best = i;
      bestDistance = distance;
    }
  }
  expect(
    best,
    isNotNull,
    reason:
        'Không thấy nút "$label" nằm dưới ${anchor.describeMatch(Plurality.one)}',
  );
  await tester.tap(labels.at(best!));
  await tester.pump();
}
