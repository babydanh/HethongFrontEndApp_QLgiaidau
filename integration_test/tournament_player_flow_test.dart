import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';
import 'support/backend_api.dart';

/// Task 4.2 (phần đơn): VĐV đi từ danh sách tới chi tiết, đăng ký đơn trên app,
/// BTC duyệt bằng API, xem nhánh và lịch, thấy nhà vô địch. Backend thật.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeAppForTests);

  testWidgets(
    'VĐV đăng ký đơn, được duyệt, xem nhánh và lịch, thấy nhà vô địch',
    (tester) async {
      final api = BackendApi();
      final tag = 'E2E${DateTime.now().millisecondsSinceEpoch}';
      final tournamentName = '$tag Giải đơn';

      // Dựng dữ liệu bằng API: BTC tạo giải, ADMIN duyệt, thêm 3 VĐV để còn đúng 1 suất cho VĐV kiểm thử.
      final organizerToken = await api.login(kOrganizerEmail, kE2ePassword);
      final created = await api.createLiteTournament(
        token: organizerToken,
        name: tournamentName,
        matchType: 'SINGLES',
        maxParticipants: 4,
      );
      final tournamentId = created.tournamentId;
      final divisionId = created.divisionId;
      await api.approveTournamentAsAdmin(tournamentId);
      await api.importRoster(
        token: organizerToken,
        tournamentId: tournamentId,
        divisionId: divisionId,
        tag: tag,
        count: 3,
        singles: true,
      );

      final container = await pumpApp(tester);
      await ensureSignedOut(tester, container);
      container.read(routerProvider).go('/login');
      await loginWithForm(tester, email: kPlayerEmail, password: kE2ePassword);
      await pumpUntilCondition(
        tester,
        () => container.read(authProvider).isAuthenticated,
        what: 'VĐV $kPlayerEmail đã đăng nhập',
      );

      // 1. Danh sách → chi tiết. Trang chủ mở ở tab Khám phá; nội dung tab Giải đấu
      // (ValueKey('tournaments'), home_screen.dart:805-809) chỉ dựng sau khi bấm nhãn nav "Giải đấu".
      final navTournaments = find.descendant(
        of: find.byType(FloatingBottomNav),
        matching: find.text('Giải đấu'),
      );
      await pumpUntilFound(
        tester,
        navTournaments,
        what: 'nhãn Giải đấu trên thanh điều hướng',
      );
      await tester.tap(navTournaments.first);
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('tournaments')),
        what: 'tab Giải đấu trên trang chủ (sau khi bấm nhãn nav)',
      );
      await scrollToText(tester, tournamentName);
      await tapCentered(tester, find.text(tournamentName));
      await pumpUntilFound(
        tester,
        find.widgetWithText(FilledButton, 'Đăng ký'),
        what: 'nút Đăng ký trên thanh đăng ký trang chi tiết giải (đăng ký đang mở)',
      );

      // 2. Đăng ký đơn trên app
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng ký').first);
      await tester.pump();
      final submit = anyTextOf(['Gửi yêu cầu tham gia', 'Xác nhận đăng ký']);
      await pumpUntilFound(tester, submit, what: 'nút gửi đăng ký');
      await tester.tap(submit.first);
      await tester.pump();
      await pumpUntilFound(
        tester,
        anyTextOf([
          'Đang chờ Ban tổ chức duyệt',
          'Bạn đã đăng ký giải đấu này',
          'Đã đăng ký, chưa thanh toán',
        ]),
        what: 'trạng thái sau khi gửi đăng ký (chờ duyệt hoặc đã đăng ký)',
      );

      // 3. BTC duyệt đơn bằng API (app không có màn duyệt đơn cho BTC)
      final pending = (await api.listParticipants(
        token: organizerToken,
        tournamentId: tournamentId,
        divisionId: divisionId,
      )).where((p) => p['teamStatus'] == 'PENDING_APPROVAL').toList();
      expect(
        pending,
        hasLength(1),
        reason: 'Phải có đúng 1 đơn VĐV đang chờ duyệt',
      );
      await api.approveParticipant(
        token: organizerToken,
        tournamentId: tournamentId,
        participantId: pending.single['id'] as String,
      );

      // 4. VĐV mở lại trang đăng ký: không còn trạng thái chờ duyệt
      container.read(routerProvider).go('/register/$tournamentId');
      await pumpUntilFound(
        tester,
        anyTextOf([
          'Bạn đã đăng ký giải đấu này',
          'Đã đăng ký, chưa thanh toán',
          'Đã đăng ký và thanh toán',
        ]),
        what: 'trạng thái đã đăng ký sau khi BTC duyệt',
      );
      expect(find.text('Đang chờ Ban tổ chức duyệt'), findsNothing);

      // 5. BTC tạo nhánh bằng API (đủ 4 VĐV, đều đã duyệt)
      await api.generateBracket(
        token: organizerToken,
        tournamentId: tournamentId,
        divisionId: divisionId,
      );

      // 6. Xem nhánh và lịch trên app
      container.read(routerProvider).go('/intro/$tournamentId');
      await pumpUntilFound(
        tester,
        find.text('Bảng thi đấu'),
        what: 'tab Bảng thi đấu trên trang chi tiết',
      );
      await tester.tap(find.text('Bảng thi đấu').first);
      await pumpUntilFound(
        tester,
        find.textContaining('$tag VDV'),
        what: 'tên VĐV trong bảng thi đấu',
      );
      await tester.tap(find.text('Lịch thi đấu').first);
      await pumpUntilFound(
        tester,
        find.textContaining('$tag VDV'),
        what: 'trận có VĐV trong lịch thi đấu',
      );

      // 7. Chấm hết các trận bằng API. VĐV không có quyền chấm trong app; chấm trong app thuộc kịch bản BTC (4.3).
      final championName = await api.playOutSingleElimination(
        token: organizerToken,
        tournamentId: tournamentId,
        divisionId: divisionId,
      );

      // 8. Nhà vô địch hiển thị ở tab Kết quả
      container.read(routerProvider).go('/intro/$tournamentId');
      await pumpUntilFound(
        tester,
        find.text('Kết quả'),
        what: 'tab Kết quả sau khi giải có kết quả',
      );
      await tester.tap(find.text('Kết quả').first);
      await pumpUntilFound(
        tester,
        find.text(championName),
        what: 'tên nhà vô địch $championName ở tab Kết quả',
      );
    },
  );

  // Task 4.2 (phần đôi): VĐV đăng ký đôi ở chế độ tự ghép (SELF), mời đồng đội bằng email.
  // Ca này chỉ kiểm bước đăng ký và mời; đồng đội chưa chấp nhận nên đơn ở PENDING_PARTNER.
  testWidgets(
    'VĐV đăng ký đôi tự ghép, mời đồng đội bằng email và thấy trạng thái chờ đồng đội',
    (tester) async {
      final api = BackendApi();
      final tag = 'E2E${DateTime.now().millisecondsSinceEpoch}';
      final tournamentName = '$tag Giải đôi';
      final teamName = '$tag Đội A';
      final partnerName = '$tag Đồng đội';
      final partnerEmail = '${tag.toLowerCase()}-partner@example.com';

      // Dựng dữ liệu bằng API: BTC tạo giải đôi tự ghép, ADMIN duyệt, tạo tài khoản đồng đội mới.
      final organizerToken = await api.login(kOrganizerEmail, kE2ePassword);
      final created = await api.createLiteTournament(
        token: organizerToken,
        name: tournamentName,
        matchType: 'DOUBLES',
        maxParticipants: 4,
        doublesPairingMode: 'SELF',
      );
      final tournamentId = created.tournamentId;
      final divisionId = created.divisionId;
      await api.approveTournamentAsAdmin(tournamentId);
      final partnerId = await api.registerAccount(
        email: partnerEmail,
        password: kE2ePassword,
        fullName: partnerName,
      );

      final container = await pumpApp(tester);
      await ensureSignedOut(tester, container);
      container.read(routerProvider).go('/login');
      await loginWithForm(tester, email: kPlayerEmail, password: kE2ePassword);
      await pumpUntilCondition(
        tester,
        () => container.read(authProvider).isAuthenticated,
        what: 'VĐV $kPlayerEmail đã đăng nhập',
      );

      // 1. Danh sách → chi tiết → Đăng ký ngay (cùng đường với ca đăng ký đơn ở trên).
      final navTournaments = find.descendant(
        of: find.byType(FloatingBottomNav),
        matching: find.text('Giải đấu'),
      );
      await pumpUntilFound(
        tester,
        navTournaments,
        what: 'nhãn Giải đấu trên thanh điều hướng',
      );
      await tester.tap(navTournaments.first);
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('tournaments')),
        what: 'tab Giải đấu trên trang chủ (sau khi bấm nhãn nav)',
      );
      await scrollToText(tester, tournamentName);
      await tapCentered(tester, find.text(tournamentName));
      await pumpUntilFound(
        tester,
        find.text('Đăng ký ngay'),
        what: 'nút Đăng ký ngay trên trang chi tiết giải đôi',
      );

      // 2. Màn đăng ký chung chuyển sang luồng đôi (app_router /register/:id/doubles).
      await tester.tap(find.text('Đăng ký ngay').first);
      await tester.pump();
      final submit = anyTextOf(['Gửi yêu cầu tham gia', 'Xác nhận đăng ký']);
      await pumpUntilFound(
        tester,
        submit,
        what: 'nút gửi đăng ký nội dung đôi',
      );
      await tester.tap(submit.first);
      await tester.pump();

      // 3. Bước 1 "Đăng ký đôi": đặt tên đội, bỏ "Mời sau" để hiện ô tìm đồng đội.
      await pumpUntilFound(
        tester,
        find.text('Tiếp theo'),
        what: 'bước 1 đăng ký đôi (nút Tiếp theo)',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Tên đội'),
        teamName,
      );
      await tester.pump();
      await tester.tap(find.text('Mời sau').first);
      await tester.pump();
      final partnerField = find.widgetWithText(
        TextField,
        'Nhập email hoặc SĐT đồng đội',
      );
      await pumpUntilFound(
        tester,
        partnerField,
        what: 'ô nhập email hoặc SĐT đồng đội',
      );
      await tester.enterText(partnerField, partnerEmail);
      await tester.pump();
      // Tìm kiếm có debounce 500 ms; kết quả là ListTile có tên đồng đội.
      await pumpUntilFound(
        tester,
        find.text(partnerName),
        what: 'kết quả tìm đồng đội theo email vừa tạo',
      );
      await tester.tap(find.text(partnerName).first);
      await tester.pump();
      await tester.tap(find.text('Tiếp theo').first);
      await tester.pump();

      // 4. Bước 2 "Mời đồng đội": app hiện link mời và nút sao chép (sau khi POST /register thành công).
      await pumpUntilFound(
        tester,
        find.text('Sao chép link mời'),
        what: 'bước 2 mời đồng đội (nút sao chép link mời)',
      );
      expect(
        find.text('Chia sẻ mã mời hoặc link này cho đồng đội của bạn'),
        findsOneWidget,
        reason: 'Bước 2 phải hiện hướng dẫn chia sẻ mã mời',
      );

      // 5. Backend: đơn của VĐV đang chờ đồng đội, đúng đồng đội đã mời, có mã mời.
      final playerToken = await api.login(kPlayerEmail, kE2ePassword);
      final mine = await api.myRegistration(
        token: playerToken,
        tournamentId: tournamentId,
        divisionId: divisionId,
      );
      expect(mine['registered'], isTrue, reason: 'VĐV phải có đơn đăng ký đôi');
      final participant = Map<String, dynamic>.from(mine['participant'] as Map);
      expect(
        participant['teamStatus'],
        'PENDING_PARTNER',
        reason: 'Đơn đôi chờ đồng đội chấp nhận',
      );
      expect(
        participant['partnerUserId'],
        partnerId,
        reason: 'Đồng đội được mời phải là tài khoản vừa tạo',
      );
      expect(participant['teamName'], teamName);
      expect(
        participant['teamInviteToken'] as String? ?? '',
        isNotEmpty,
        reason: 'Đơn đôi chờ đồng đội phải có mã mời',
      );
    },
  );
}
