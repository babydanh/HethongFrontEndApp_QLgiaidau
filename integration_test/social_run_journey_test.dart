import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/features/match/widgets/official_score_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/social_journey.dart';

/// Journey Social 2/3: chi tiết buổi, người tham gia, quyền, trận đấu (TC-SOCIAL-APP-05..13).
/// Emulator Android + Backend thật. Host = `admin1`, người chơi = `user8`; người phụ tạo bằng API.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeAppForTests);

  testWidgets(
    'TC-SOCIAL-APP-05 tab Chi tiết của host: "Quyết định sau" có gạch chân mở form sửa, sheet Tìm người và Liên hệ',
    (tester) async {
      final api = SocialApi();
      final tag = socialTag('SR5');
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-05');
      final hostToken = await api.login(kOrganizerEmail);
      final session = await api.createSession(token: hostToken, title: '$tag Chi tiết host');

      final container = await signInWithEmail(tester, email: kOrganizerEmail);
      await openSession(tester, container, session);
      await shooter.snap('chi-tiet-host');

      // Host thấy 4 tab (không có Thanh toán vì buổi miễn phí) và nút Tìm thêm người chơi.
      for (final label in ['Chi tiết', 'Người tham gia', 'Trận đấu', 'Trò chuyện']) {
        expect(find.text(label), findsOneWidget, reason: 'host phải thấy tab "$label"');
      }
      expect(find.text('Thanh toán'), findsNothing);
      expect(find.text('Chỉ đường'), findsNothing, reason: 'chưa có toạ độ thì không có Chỉ đường');
      expect(
        textWidget(tester, 'Quyết định sau').style?.decoration,
        TextDecoration.underline,
        reason: 'host: "Quyết định sau" phải có gạch chân vì bấm được',
      );

      // Sheet "Tìm thêm người chơi" có nút sao chép tin nhắn mời.
      await tapText(tester, 'Tìm thêm người chơi');
      await pumpUntilFound(tester, find.text('Sao chép tin nhắn'), what: 'sheet Tìm thêm người chơi');
      await shooter.snap('sheet-tim-nguoi-choi');
      await tester.tapAt(const Offset(20, 60));
      await socialWait(tester);
      expect(find.text('Sao chép tin nhắn'), findsNothing, reason: 'sheet phải đóng khi bấm ra ngoài');

      // Sheet "Liên hệ BTC".
      await tapText(tester, 'Liên hệ BTC');
      await pumpUntilFound(tester, find.textContaining('Liên hệ Host:'), what: 'sheet Liên hệ Host');
      await shooter.snap('sheet-lien-he');
      await tester.tapAt(const Offset(20, 60));
      await socialWait(tester);

      // Bấm "Quyết định sau" mở form sửa địa điểm (TC-SOCIAL-PLACE-TAP-01 ở mức app thật).
      await tester.tap(find.text('Quyết định sau').first);
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.text('Cập nhật kèo'),
        what: 'form Cập nhật kèo sau khi host bấm "Quyết định sau"',
      );
      await shooter.snap('form-sua-dia-diem');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-SOCIAL-APP-06 Chỉ đường chỉ hiện khi buổi có toạ độ',
    (tester) async {
      final api = SocialApi();
      final tag = socialTag('SR6');
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-06');
      final hostToken = await api.login(kOrganizerEmail);
      final pinned = await api.createSession(
        token: hostToken,
        title: '$tag Có toạ độ',
        deferred: false,
      );
      final deferred = await api.createSession(token: hostToken, title: '$tag Chưa có sân');

      final container = await signInWithEmail(tester, email: kPlayerEmail);
      await openSession(tester, container, pinned);
      expect(find.text('Chỉ đường'), findsOneWidget, reason: 'buổi có toạ độ phải có nút Chỉ đường');
      await shooter.snap('co-chi-duong');

      await openSession(tester, container, deferred);
      expect(find.text('Chỉ đường'), findsNothing, reason: 'buổi "Quyết định sau" không có Chỉ đường');
      await shooter.snap('khong-chi-duong');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-SOCIAL-APP-07 người chơi xin tham gia, rút yêu cầu, xin lại; host duyệt; người chơi thành "Đã tham gia"',
    (tester) async {
      final api = SocialApi();
      final tag = socialTag('SR7');
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-07');
      final hostToken = await api.login(kOrganizerEmail);
      final playerToken = await api.login(kPlayerEmail);
      final session = await api.createSession(token: hostToken, title: '$tag Xin tham gia');

      var container = await signInWithEmail(tester, email: kPlayerEmail);
      await openSession(tester, container, session);
      expect(find.text('Thanh toán'), findsNothing, reason: 'người chơi không có tab Thanh toán');
      expect(find.text('Tìm thêm người chơi'), findsNothing, reason: 'người chơi không có nút của host');
      await shooter.snap('nguoi-choi-truoc-khi-xin');

      Future<void> sendRequest() async {
        await tapText(tester, 'Yêu cầu tham gia');
        await tapText(tester, 'Gửi yêu cầu tham gia');
        await pumpUntilFound(
          tester,
          find.text('Chờ duyệt'),
          what: 'nút "Chờ duyệt" sau khi gửi yêu cầu',
          timeout: const Duration(seconds: 30),
        );
        // Chờ sheet gửi yêu cầu đóng hẳn: bấm khi sheet còn đang đóng sẽ trúng lớp nền của nó.
        // Thông báo "Đã gửi yêu cầu..." nổi che thanh nút phía dưới: chờ nó tắt rồi mới bấm tiếp.
        await socialWait(tester, const Duration(seconds: 7));
        drainKnownProductErrors(tester);
      }

      await sendRequest();
      await shooter.snap('cho-duyet');

      // Rút yêu cầu: hộp thoại xác nhận rồi quay về "Yêu cầu tham gia".
      await tapFinder(
        tester,
        find.widgetWithText(ElevatedButton, 'Chờ duyệt'),
        what: 'nút Chờ duyệt (rút yêu cầu)',
      );
      await pumpUntilFound(tester, find.text('Hủy yêu cầu tham gia?'), what: 'hộp thoại hủy yêu cầu');
      await tapText(tester, 'Xác nhận');
      await pumpUntilFound(
        tester,
        find.text('Yêu cầu tham gia'),
        what: 'nút "Yêu cầu tham gia" sau khi rút yêu cầu',
        timeout: const Duration(seconds: 30),
      );
      await shooter.snap('da-rut-yeu-cau');

      await sendRequest();

      // Host duyệt trên tab Người tham gia.
      container = await signInWithEmail(tester, email: kOrganizerEmail);
      await openSession(tester, container, session);
      await openSocialTab(tester, 'Người tham gia');
      await pumpUntilFound(tester, find.textContaining('ĐÃ YÊU CẦU • 1'), what: 'mục ĐÃ YÊU CẦU • 1');
      await shooter.snap('host-thay-yeu-cau');
      await tapFinder(tester, find.byTooltip('Cho phép tham gia'), what: 'nút duyệt yêu cầu');
      await pumpUntilFound(
        tester,
        find.textContaining('XÁC NHẬN THAM GIA • 2/'),
        what: 'số người xác nhận tăng lên 2 sau khi duyệt',
        timeout: const Duration(seconds: 30),
      );
      await shooter.snap('host-da-duyet');

      final people = await api.participants(hostToken, session.id);
      final playerId = '${(await api.profile(playerToken))['id']}';
      expect(
        people.any((p) => '${p['userId']}' == playerId && '${p['status']}'.toUpperCase() == 'JOINED'),
        isTrue,
        reason: 'Backend phải ghi người chơi JOINED sau khi host duyệt: $people',
      );

      // Người chơi mở lại thấy "Đã tham gia".
      container = await signInWithEmail(tester, email: kPlayerEmail);
      await openSession(tester, container, session);
      await pumpUntilFound(tester, find.text('Đã tham gia'), what: 'nút "Đã tham gia" của người chơi');
      await shooter.snap('nguoi-choi-da-tham-gia');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-SOCIAL-APP-08 host thêm khách và tài khoản, rồi xoá người trên tab Người tham gia',
    (tester) async {
      final api = SocialApi();
      final tag = socialTag('SR8');
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-08');
      final hostToken = await api.login(kOrganizerEmail);
      final session = await api.createSession(token: hostToken, title: '$tag Thêm xoá người');
      final account = await api.registerUser(tag: tag, label: 'Tai Khoan');
      final guestName = '$tag Khach';

      final container = await signInWithEmail(tester, email: kOrganizerEmail);
      await openSession(tester, container, session);
      await openSocialTab(tester, 'Người tham gia');
      await pumpUntilFound(tester, find.textContaining('XÁC NHẬN THAM GIA • 1/6'), what: 'chỉ có host: 1/6');
      await shooter.snap('chi-co-host');

      // Thêm khách (người ngoài chưa có tài khoản).
      await tapText(tester, 'Thêm người');
      await pumpUntilFound(tester, find.text('Thêm người tham gia'), what: 'sheet Thêm người tham gia');
      await tapText(tester, 'Người ngoài');
      final guestField = find.widgetWithText(TextField, 'Tên người chơi');
      await pumpUntilFound(tester, guestField, what: 'ô Tên người chơi');
      await tester.enterText(guestField, guestName);
      await tester.pump();
      await tapText(tester, 'Thêm người ngoài');
      await pumpUntilFound(
        tester,
        find.textContaining('XÁC NHẬN THAM GIA • 2/6'),
        what: 'đã thêm khách: 2/6',
        timeout: const Duration(seconds: 30),
      );
      expect(find.text(guestName), findsOneWidget);
      await shooter.snap('da-them-khach');

      // Thêm tài khoản có sẵn bằng tìm kiếm toàn hệ thống.
      await tapText(tester, 'Thêm người');
      await pumpUntilFound(tester, find.text('Thêm người tham gia'), what: 'sheet Thêm người tham gia (lần 2)');
      final search = find.widgetWithText(TextField, 'Tìm theo tên hoặc email');
      await pumpUntilFound(tester, search, what: 'ô tìm người chơi');
      await tester.enterText(search, account.fullName);
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.text(account.fullName),
        what: 'kết quả tìm "${account.fullName}"',
        timeout: const Duration(seconds: 30),
      );
      await shooter.snap('ket-qua-tim-nguoi');
      await socialWait(tester);
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, account.fullName),
          matching: find.byType(Checkbox),
        ),
      );
      await tester.pump();
      await tapText(tester, 'Thêm vào buổi (1)');
      await pumpUntilFound(
        tester,
        find.textContaining('XÁC NHẬN THAM GIA • 3/6'),
        what: 'đã thêm tài khoản: 3/6',
        timeout: const Duration(seconds: 30),
      );
      await shooter.snap('da-them-tai-khoan');

      // Xoá khách: bấm vào ô người, xác nhận.
      await tester.tap(find.text(guestName).first);
      await tester.pump();
      await pumpUntilFound(tester, find.text('Xóa người tham gia?'), what: 'hộp thoại xoá người');
      await tapText(tester, 'Xóa');
      await pumpUntilFound(
        tester,
        find.textContaining('XÁC NHẬN THAM GIA • 2/6'),
        what: 'sau khi xoá khách: 2/6',
        timeout: const Duration(seconds: 30),
      );
      expect(find.text(guestName), findsNothing);
      await shooter.snap('da-xoa-khach');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-SOCIAL-APP-09 sức chứa đầy: Backend FULL, người chơi thấy "Đã đủ người" và không bấm được',
    (tester) async {
      final api = SocialApi();
      final tag = socialTag('SR9');
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-09');
      final hostToken = await api.login(kOrganizerEmail);
      final session = await api.createSession(
        token: hostToken,
        title: '$tag Đủ người',
        maxSlots: 2,
      );
      final account = await api.registerUser(tag: tag, label: 'Nguoi Cuoi');
      await api.addUser(hostToken, session.id, account.id);
      final full = await api.getSession(hostToken, session.id);
      expect('${full['status']}'.toUpperCase(), 'FULL', reason: 'đủ 2/2 người thì Backend đặt FULL');

      final container = await signInWithEmail(tester, email: kPlayerEmail);
      await openSession(tester, container, session);
      final fullButton = find.widgetWithText(ElevatedButton, 'Đã đủ người');
      await pumpUntilFound(tester, fullButton, what: 'nút "Đã đủ người"');
      expect(tester.widget<ElevatedButton>(fullButton).onPressed, isNull);
      await shooter.snap('nguoi-choi-thay-da-du');
      expect(find.text('Yêu cầu tham gia'), findsNothing);

      await openSocialTab(tester, 'Người tham gia');
      await pumpUntilFound(tester, find.textContaining('XÁC NHẬN THAM GIA • 2/2'), what: '2/2 trên tab Người tham gia');
      expect(find.text('Thêm người'), findsNothing, reason: 'người chơi không có nút Thêm người');
      await shooter.snap('tab-nguoi-tham-gia-2-2');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-SOCIAL-APP-10 thẻ avatar host không lặp ở hàng người tham gia (TC-GL-AVATAR-01)',
    (tester) async {
      final api = SocialApi();
      final tag = socialTag('SR10');
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-10');
      final hostToken = await api.login(kOrganizerEmail);
      final playerToken = await api.login(kPlayerEmail);
      final session = await api.createSession(token: hostToken, title: '$tag Avatar host');
      final hostName = '${(await api.profile(hostToken))['fullName']}';
      final player = await api.profile(playerToken);
      await api.addUser(hostToken, session.id, '${player['id']}');

      final container = await signInWithEmail(tester, email: kOrganizerEmail);
      await openSession(tester, container, session);
      await shooter.snap('chi-tiet-co-nguoi-tham-gia');
      expect(find.text('Host'), findsWidgets);
      expect(countText(initialsOf(hostName)), 1, reason: 'avatar chữ của host chỉ ở thẻ host');
      expect(
        countText(initialsOf('${player['fullName']}')),
        1,
        reason: 'người chơi có đúng một avatar ở hàng người tham gia',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-SOCIAL-APP-11 host tạo trận Đôi mặc định, chạm thẻ mở bảng nhập điểm và bảng điểm, nhập 11-5 ra người thắng',
    (tester) async {
      final api = SocialApi();
      final tag = socialTag('SR11');
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-11');
      final hostToken = await api.login(kOrganizerEmail);
      final session = await api.createSession(token: hostToken, title: '$tag Trận đôi');
      final hostName = '${(await api.profile(hostToken))['fullName']}';
      final others = [
        for (final label in ['Mot', 'Hai', 'Ba']) await api.registerUser(tag: tag, label: label),
      ];
      for (final user in others) {
        await api.addUser(hostToken, session.id, user.id);
      }

      final container = await signInWithEmail(tester, email: kOrganizerEmail);
      await openSession(tester, container, session);
      await openSocialTab(tester, 'Trận đấu');
      await pumpUntilFound(
        tester,
        find.text('Chưa có trận đấu nào trong buổi này.'),
        what: 'trạng thái chưa có trận',
      );
      await shooter.snap('chua-co-tran');

      await tapText(tester, 'Tạo trận đấu');
      final dialog = find.byType(Dialog);
      await pumpUntilFound(tester, dialog, what: 'hộp thoại Tạo trận đấu');
      final matchType = find.descendant(of: dialog, matching: find.byType(SegmentedButton<String>));
      expect(
        tester.widget<SegmentedButton<String>>(matchType).selected,
        {'DOUBLES'},
        reason: 'thể thức mặc định là Đôi',
      );
      expect(
        find.descendant(of: dialog, matching: find.text('Bracket')),
        findsOneWidget,
        reason: 'host buổi cá nhân có thể thức Bracket',
      );
      for (final name in [hostName, ...others.map((u) => u.fullName)]) {
        final row = find.descendant(of: dialog, matching: find.text(name));
        await pumpUntilFound(tester, row, what: 'dòng thành viên "$name" trong hộp thoại Tạo trận đấu');
        await tester.tap(row.first);
        await tester.pump();
      }
      await shooter.snap('da-chon-hai-doi');
      await tester.tap(
        find.descendant(of: dialog, matching: find.widgetWithText(FilledButton, 'Tạo trận đấu')),
      );
      await tester.pump();

      // Tạo xong, hộp thoại Nhập kết quả mở ngay; đóng lại để trận ở trạng thái "Chưa bắt đầu".
      await pumpUntilFound(tester, find.text('Nhập kết quả'), what: 'hộp thoại Nhập kết quả sau khi tạo trận');
      await shooter.snap('hop-thoai-nhap-ket-qua');
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.byIcon(Icons.close_rounded)).first);
      await socialWait(tester);
      await pumpUntilFound(tester, find.text('Chưa bắt đầu'), what: 'thẻ trận Chưa bắt đầu');
      // Thẻ trận có nút Bấm điểm (social-nut-bam-diem), không có Nhập nhanh; chạm thẻ vẫn mở bảng nhập điểm.
      expect(find.text('Nhập nhanh'), findsNothing);
      expect(find.text('Bấm điểm'), findsOneWidget);
      await shooter.snap('the-tran-chua-bat-dau');

      // Chạm thẻ mở bảng Nhập kết quả, trong đó có nút Mở bảng điểm sang màn bấm điểm trực tiếp.
      await tester.tap(find.text(hostName).first);
      await tester.pump();
      await pumpUntilFound(tester, find.text('Nhập kết quả'), what: 'bảng Nhập kết quả khi chạm thẻ trận');
      await tapFinder(tester, find.text('Mở bảng điểm'), what: 'nút Mở bảng điểm trong bảng Nhập kết quả');
      await pumpUntilFound(tester, find.byType(OfficialScorePage), what: 'màn bấm điểm trực tiếp');
      await shooter.snap('man-bam-diem');
      container.read(routerProvider).pop();
      await socialWait(tester, const Duration(seconds: 2));

      // Chạm thẻ lần nữa: nhập 11 - 5, lưu, thẻ chuyển Đã hoàn thành và hiện tỉ số.
      await tester.tap(find.text(hostName).first);
      await tester.pump();
      await pumpUntilFound(tester, find.text('Nhập kết quả'), what: 'bảng Nhập kết quả (lần 2)');
      final scoreFields = find.descendant(of: find.byType(Dialog), matching: find.byType(TextField));
      await tester.enterText(scoreFields.at(0), '11');
      await tester.enterText(scoreFields.at(1), '5');
      await tester.pump();
      await shooter.snap('da-nhap-11-5');
      await tester.tap(find.text('Lưu kết quả thủ công').first);
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.text('Đã hoàn thành'),
        what: 'thẻ trận Đã hoàn thành sau khi lưu',
        timeout: const Duration(seconds: 30),
      );
      // Thẻ trận hiện số set thắng (1-0) chứ không phải điểm 11-5 (xem Ghi chú sản phẩm trong báo cáo).
      expect(find.text('1'), findsWidgets, reason: 'đội A thắng 1 set');
      expect(find.text('0'), findsWidgets, reason: 'đội B thắng 0 set');
      
      await shooter.snap('tran-da-hoan-thanh');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-SOCIAL-APP-12 host tạo Bracket từ người tham gia và thấy nút Xem bracket',
    (tester) async {
      final api = SocialApi();
      final tag = socialTag('SR12');
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-12');
      final hostToken = await api.login(kOrganizerEmail);
      final session = await api.createSession(token: hostToken, title: '$tag Bracket');
      for (final label in ['Mot', 'Hai', 'Ba']) {
        final user = await api.registerUser(tag: tag, label: label);
        await api.addUser(hostToken, session.id, user.id);
      }

      final container = await signInWithEmail(tester, email: kOrganizerEmail);
      await openSession(tester, container, session);
      await openSocialTab(tester, 'Trận đấu');
      await tapText(tester, 'Tạo trận đấu');
      await pumpUntilFound(tester, find.byType(Dialog), what: 'hộp thoại Tạo trận đấu');
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Bracket')));
      await tester.pump();
      await pumpUntilFound(tester, find.text('Loại trực tiếp'), what: 'biểu mẫu Bracket (chip Loại trực tiếp)');
      await shooter.snap('bieu-mau-bracket');
      await tester.tap(find.text('Tạo bracket'));
      await tester.pump();

      // App mở trang giải vừa tạo.
      await pumpUntilCondition(
        tester,
        // `uri` của cấu hình chỉ là trang nền (/home); trang vừa push nằm ở phần tử cuối.
        () => container
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .last
            .matchedLocation
            .startsWith('/tournaments/'),
        what: 'app mở trang giải của bracket',
        timeout: const Duration(seconds: 60),
      );
      await shooter.snap('trang-giai-bracket');
      final saved = await api.getSession(hostToken, session.id);
      expect('${saved['bracketTournamentId'] ?? ''}', isNotEmpty, reason: 'buổi phải gắn giải bracket: $saved');

      // Quay lại buổi: tab Trận đấu có nút Xem bracket.
      await openSession(tester, container, session);
      await openSocialTab(tester, 'Trận đấu');
      await pumpUntilFound(tester, find.text('Xem bracket'), what: 'nút Xem bracket');
      await shooter.snap('co-nut-xem-bracket');
      await leaveSocialSession(tester, container);
    },
  );
}
