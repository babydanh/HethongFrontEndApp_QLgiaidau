import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/social_journey.dart';

/// Journey Social 3/3: trò chuyện, thanh toán, sửa, huỷ, quyền người ngoài (TC-SOCIAL-APP-13..18).
/// Emulator Android + Backend thật. Host = `admin1`, người chơi = `user8`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeAppForTests);

  testWidgets(
    'TC-SOCIAL-APP-13 trò chuyện: host gửi tin chữ thấy ngay, người tham gia mở tab thấy tin đó',
    (tester) async {
      final api = SocialApi();
      final tag = socialTag('SH13');
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-13');
      final hostToken = await api.login(kOrganizerEmail);
      final playerToken = await api.login(kPlayerEmail);
      final session = await api.createSession(token: hostToken, title: '$tag Trò chuyện');
      await api.addUser(hostToken, session.id, '${(await api.profile(playerToken))['id']}');
      final message = '$tag xin chào cả nhà';

      var container = await signInWithEmail(tester, email: kOrganizerEmail);
      await openSession(tester, container, session);
      await openSocialTab(tester, 'Trò chuyện');
      final input = find.byType(TextField);
      await pumpUntilFound(
        tester,
        input,
        what: 'ô nhập tin nhắn của tab Trò chuyện (buổi đang mở)',
        timeout: const Duration(seconds: 30),
      );
      await shooter.snap('tab-tro-chuyen-host');
      await tester.enterText(input.first, message);
      await tester.pump();
      await tapFinder(tester, find.byIcon(Icons.send_rounded), what: 'nút Gửi');
      await pumpUntilFound(
        tester,
        find.text(message),
        what: 'tin vừa gửi hiện trong khung chat',
        timeout: const Duration(seconds: 30),
      );
      await shooter.snap('host-da-gui-tin');

      // Người tham gia mở buổi, vào tab Trò chuyện và thấy tin của host.
      container = await signInWithEmail(tester, email: kPlayerEmail);
      await openSession(tester, container, session);
      await openSocialTab(tester, 'Trò chuyện');
      await pumpUntilFound(
        tester,
        find.text(message),
        what: 'tin của host hiện ở máy người tham gia',
        timeout: const Duration(seconds: 30),
      );
      await shooter.snap('nguoi-choi-thay-tin');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-SOCIAL-APP-14 host sửa tên buổi rồi huỷ buổi: sau huỷ không còn Sửa/Huỷ và tab Trò chuyện chỉ đọc',
    (tester) async {
      final api = SocialApi();
      final tag = socialTag('SH14');
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-14');
      final hostToken = await api.login(kOrganizerEmail);
      final session = await api.createSession(token: hostToken, title: '$tag Sửa rồi huỷ');
      final newTitle = '$tag Đã đổi tên';

      final container = await signInWithEmail(tester, email: kOrganizerEmail);
      await openSession(tester, container, session);

      // Sửa: menu ⋮ -> Chỉnh sửa kèo -> đổi tên -> Cập nhật kèo.
      await tapFinder(tester, find.byIcon(Icons.more_vert_rounded), what: 'nút ⋮ trên thanh trên');
      await pumpUntilFound(tester, find.text('Hủy kèo'), what: 'menu ⋮ của host (Hủy kèo)');
      await shooter.snap('menu-host');
      expect(find.text('Chỉnh sửa kèo'), findsOneWidget);
      await tester.tap(find.text('Chỉnh sửa kèo'));
      await tester.pump();
      await pumpUntilFound(tester, find.text('Cập nhật kèo'), what: 'form Cập nhật kèo');
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, newTitle);
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Cập nhật kèo'));
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.text(newTitle.toUpperCase()),
        what: 'tên mới trên chi tiết buổi sau khi sửa',
        timeout: const Duration(seconds: 30),
      );
      await shooter.snap('da-sua-ten');
      expect((await api.getSession(hostToken, session.id))['title'], newTitle);

      // Huỷ: menu ⋮ -> Hủy kèo -> xác nhận. App thoát khỏi buổi và báo thành công.
      await tapFinder(tester, find.byIcon(Icons.more_vert_rounded), what: 'nút ⋮ (lần 2)');
      await tapText(tester, 'Hủy kèo');
      await pumpUntilFound(tester, find.text('Xác nhận hủy kèo'), what: 'hộp thoại xác nhận huỷ');
      await shooter.snap('hop-thoai-huy');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Hủy kèo'));
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.text('Đã hủy buổi Social thành công!'),
        what: 'thông báo huỷ buổi thành công',
        timeout: const Duration(seconds: 30),
      );
      final cancelled = await api.getSession(hostToken, session.id);
      expect('${cancelled['status']}'.toUpperCase(), 'CANCELLED');

      // Mở lại buổi đã huỷ: menu không còn Sửa/Huỷ, tab Trò chuyện không có ô nhập.
      await openSession(tester, container, SeededSession(id: session.id, title: newTitle, raw: cancelled));
      await shooter.snap('buoi-da-huy');
      await tapFinder(tester, find.byIcon(Icons.more_vert_rounded), what: 'nút ⋮ của buổi đã huỷ');
      await pumpUntilFound(tester, find.text('Lặp lại kèo'), what: 'menu ⋮ của buổi đã huỷ');
      expect(find.text('Chỉnh sửa kèo'), findsNothing, reason: 'chỉ OPEN/FULL mới sửa được');
      expect(find.text('Hủy kèo'), findsNothing, reason: 'buổi đã huỷ không huỷ lần nữa');
      await tester.tapAt(const Offset(20, 60));
      await socialWait(tester);
      await openSocialTab(tester, 'Trò chuyện');
      await socialWait(tester, const Duration(seconds: 2));
      expect(find.byType(TextField), findsNothing, reason: 'buổi đã đóng: tab Trò chuyện chỉ đọc, không có ô nhập');
      await shooter.snap('tro-chuyen-chi-doc');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-SOCIAL-APP-15 tab Thanh toán của host: tổng quan, đánh dấu ĐÃ THU và Backend ghi nhận',
    (tester) async {
      final api = SocialApi();
      final tag = socialTag('SH15');
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-15');
      final hostToken = await api.login(kOrganizerEmail);
      final session = await api.createSession(
        token: hostToken,
        title: '$tag Thu phí',
        feePerSlot: 50000,
      );
      final account = await api.registerUser(tag: tag, label: 'Dong Tien');
      await api.addUser(hostToken, session.id, account.id);

      final container = await signInWithEmail(tester, email: kOrganizerEmail);
      await openSession(tester, container, session);
      await openSocialTab(tester, 'Thanh toán');
      await pumpUntilFound(tester, find.text('TỔNG QUAN TÀI CHÍNH'), what: 'tổng quan tài chính');
      expect(find.text('DANH SÁCH THANH TOÁN'), findsOneWidget);
      await shooter.snap('tab-thanh-toan');
      await pumpUntilFound(tester, find.text('CHƯA THU'), what: 'chip CHƯA THU của người tham gia');
      final before = find.text('CHƯA THU').evaluate().length;
      await tester.tap(find.text('CHƯA THU').first);
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.text('ĐÃ THU'),
        what: 'chip chuyển sang ĐÃ THU sau khi bấm',
        timeout: const Duration(seconds: 30),
      );
      expect(find.text('CHƯA THU').evaluate().length, before - 1);
      await shooter.snap('da-thu-mot-nguoi');

      final people = await api.participants(hostToken, session.id);
      expect(
        people.any((p) => '${p['paymentStatus'] ?? p['payment_status'] ?? ''}'.toUpperCase() == 'PAID'),
        isTrue,
        reason: 'Backend phải có một người PAID: $people',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-SOCIAL-APP-16 người ngoài không thấy nút của host; menu ⋮ chỉ có báo cáo; "Quyết định sau" không gạch chân',
    (tester) async {
      final api = SocialApi();
      final tag = socialTag('SH16');
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-16');
      final hostToken = await api.login(kOrganizerEmail);
      final session = await api.createSession(
        token: hostToken,
        title: '$tag Quyền người ngoài',
        feePerSlot: 50000,
      );

      final container = await signInWithEmail(tester, email: kPlayerEmail);
      await openSession(tester, container, session);
      await shooter.snap('nguoi-ngoai-chi-tiet');
      expect(find.text('Thanh toán'), findsNothing, reason: 'tab Thanh toán chỉ dành cho host');
      expect(find.text('Tìm thêm người chơi'), findsNothing);
      expect(
        textWidget(tester, 'Quyết định sau').style?.decoration,
        isNot(TextDecoration.underline),
        reason: 'người chơi thường: "Quyết định sau" không có gạch chân vì không bấm được',
      );
      await tester.tap(find.text('Quyết định sau').first);
      await socialWait(tester);
      expect(find.text('Cập nhật kèo'), findsNothing, reason: 'người chơi bấm không mở form sửa');

      await openSocialTab(tester, 'Người tham gia');
      expect(find.text('Thêm người'), findsNothing, reason: 'người chơi không có nút Thêm người');
      await openSocialTab(tester, 'Chi tiết');

      await tapFinder(tester, find.byIcon(Icons.more_vert_rounded), what: 'nút ⋮ của người ngoài');
      await pumpUntilFound(tester, find.text('Báo cáo buổi Social này'), what: 'mục báo cáo trong menu ⋮');
      expect(find.text('Chỉnh sửa kèo'), findsNothing);
      expect(find.text('Hủy kèo'), findsNothing);
      await shooter.snap('menu-nguoi-ngoai');
      await tester.tap(find.text('Báo cáo buổi Social này'));
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.text('Cảm ơn bạn đã gửi báo cáo.'),
        what: 'thông báo sau khi báo cáo',
      );
      await shooter.snap('da-bao-cao');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-SOCIAL-APP-17 gửi ảnh và dán ảnh trong tab Trò chuyện (SKIP: cần hộp chọn ảnh hệ thống của Android)',
    (tester) async {},
    skip: true,
  );

  testWidgets(
    'TC-SOCIAL-APP-18 chia sẻ buổi qua nút chia sẻ (SKIP: share_plus mở hộp chia sẻ hệ thống, ngoài tầm điều khiển của integration_test)',
    (tester) async {},
    skip: true,
  );
}
