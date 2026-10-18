import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
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

      // 1. Danh sách → chi tiết
      final tournamentsTab = find.byKey(const ValueKey('tournaments'));
      await pumpUntilFound(
        tester,
        tournamentsTab,
        what: 'tab Giải đấu trên trang chủ',
      );
      await tester.tap(tournamentsTab.first);
      await tester.pump();
      await scrollToText(tester, tournamentName);
      await tester.tap(find.text(tournamentName).first);
      await pumpUntilFound(
        tester,
        find.text('Đăng ký ngay'),
        what: 'nút Đăng ký ngay trên trang chi tiết giải (đăng ký đang mở)',
      );

      // 2. Đăng ký đơn trên app
      await tester.tap(find.text('Đăng ký ngay').first);
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
}
