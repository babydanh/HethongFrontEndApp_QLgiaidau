import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';
import 'support/backend_api.dart';

/// Task 4.3: BTC tạo giải nhanh trên app, thêm VĐV khách ở trang quản lý,
/// tạo nhánh trên app rồi thấy nhánh. ADMIN duyệt giải và import 3 VĐV qua API
/// (app không có bước ADMIN duyệt; import là dữ liệu nền). Backend thật.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeAppForTests);

  testWidgets(
    'BTC tạo giải nhanh, thêm VĐV khách, tạo nhánh và nhánh hiện trên app',
    (tester) async {
      final api = BackendApi();
      final tag = 'E2E${DateTime.now().millisecondsSinceEpoch}';
      final tournamentName = '$tag Giải nhanh BTC';
      final guestName = '$tag Khách BTC';

      final container = await pumpApp(tester);
      await ensureSignedOut(tester, container);
      container.read(routerProvider).go('/login');
      await loginWithForm(
        tester,
        email: kOrganizerEmail,
        password: kE2ePassword,
      );
      await pumpUntilCondition(
        tester,
        () => container.read(authProvider).isAuthenticated,
        what: 'BTC $kOrganizerEmail đã đăng nhập',
      );
      final organizerToken = await api.login(kOrganizerEmail, kE2ePassword);

      // 1. Tạo giải nhanh trên app: tên, thời gian bắt đầu (mặc định của picker), một nội dung đơn.
      container.read(routerProvider).go('/tournaments/create');
      await pumpUntilFound(
        tester,
        find.byType(TextFormField),
        what: 'form Tạo giải nhanh (ô tên giải)',
      );
      await tester.enterText(find.byType(TextFormField).first, tournamentName);
      await tester.pump();

      await scrollToText(tester, 'Thêm nội dung');
      await tester.tap(find.text('Thêm nội dung').first);
      await pumpUntilCondition(
        tester,
        () => find.text('Thêm nội dung').evaluate().length >= 2,
        what: 'bottom sheet thêm nội dung',
      );
      await tester.tap(find.text('Thêm nội dung').last);
      await tester.pump(const Duration(seconds: 1));

      await scrollToText(tester, 'Thời gian bắt đầu *');
      await tester.tap(find.text('Thời gian bắt đầu *'));
      await pumpUntilFound(tester, find.text('OK'), what: 'hộp chọn ngày (OK)');
      await tester.tap(find.text('OK').first);
      await tester.pump(const Duration(seconds: 1));
      await pumpUntilFound(tester, find.text('OK'), what: 'hộp chọn giờ (OK)');
      await tester.tap(find.text('OK').first);
      await tester.pump(const Duration(seconds: 1));

      // Nút gửi nằm ở thanh dưới (bottomNavigationBar, create_public_quick_tournament_screen.dart:1037-1070),
      // nhãn thật là 'Tạo giải đấu' (không phải l10n quickCreateSubmit), luôn hiển thị nên không cần cuộn.
      await pumpUntilFound(
        tester,
        find.widgetWithText(FilledButton, 'Tạo giải đấu'),
        what: 'nút Tạo giải đấu ở thanh dưới',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Tạo giải đấu'));
      await tester.pump();

      // Sau khi tạo, app mở trang quản lý giải (hub, /lite-manage/:id); chờ KPI "Vận động viên" trên hub.
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('tournament-overview-athletes-edit')),
        timeout: const Duration(seconds: 60),
        what: 'trang quản lý giải vừa tạo (hub, KPI Vận động viên)',
      );
      final location = container
          .read(routerProvider)
          .routerDelegate
          .currentConfiguration
          .uri
          .toString();
      final tournamentId = RegExp(
        r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
      ).firstMatch(location)?.group(0);
      expect(
        tournamentId,
        isNotNull,
        reason: 'Không đọc được id giải từ đường dẫn: $location',
      );
      final id = tournamentId!;

      // Nút thêm VĐV ('organizer-ops-add-athlete') chỉ có ở màn điều hành, không có trên hub.
      // Mở màn điều hành bằng router như các bước sau của test.
      final opsAddButton = find.byKey(
        const ValueKey('organizer-ops-add-athlete'),
      );
      container.read(routerProvider).go('/organizer/tournaments/$id/ops');
      // Màn điều hành mở ở tab Trận đấu (_selectedTab = 1). Nút thêm VĐV chỉ được dựng ở tab
      // "Danh sách tham gia" (organizer_ops_screen.dart: _selectedTab == 3), nên phải bấm tab trước.
      final rosterTab = find.widgetWithText(ChoiceChip, 'Danh sách tham gia');
      await pumpUntilFound(
        tester,
        rosterTab,
        timeout: const Duration(seconds: 60),
        what: 'nhãn tab Danh sách tham gia trên màn điều hành',
      );
      await tapCentered(tester, rosterTab);
      await pumpUntilFound(
        tester,
        opsAddButton,
        timeout: const Duration(seconds: 60),
        what: 'nút thêm VĐV (tab Danh sách tham gia)',
      );

      // ADMIN duyệt giải và import 3 VĐV (API). Thông tin này là dữ liệu nền.
      await api.approveTournamentAsAdmin(id);
      final divisions = await api.listDivisions(id);
      expect(
        divisions,
        isNotEmpty,
        reason: 'Giải nhanh phải có nội dung thi đấu',
      );
      final divisionId = divisions.first['id'] as String;
      await api.importRoster(
        token: organizerToken,
        tournamentId: id,
        divisionId: divisionId,
        tag: tag,
        count: 3,
        singles: true,
      );

      // 2. Thêm VĐV khách ở trang quản lý (tab Nhập tên).
      await tester.tap(opsAddButton);
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('add-athlete-sheet')),
        what: 'sheet thêm VĐV',
      );
      await tester.tap(find.text('Nhập tên').first);
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('add-athlete-direct-name')),
        what: 'ô tên VĐV khách',
      );
      await tester.enterText(
        find.byKey(const ValueKey('add-athlete-direct-name')),
        guestName,
      );
      await tester.enterText(
        find.byKey(const ValueKey('add-athlete-direct-email')),
        '$tag-guest@example.com',
      );
      await tester.tap(find.byKey(const ValueKey('add-athlete-direct-submit')));
      await tester.pump();

      var participants = <Map<String, dynamic>>[];
      for (
        var attempt = 0;
        attempt < 20 && participants.length < 4;
        attempt++
      ) {
        await tester.pump(const Duration(seconds: 1));
        participants = await api.listParticipants(
          token: organizerToken,
          tournamentId: id,
          divisionId: divisionId,
        );
      }
      expect(
        participants,
        hasLength(4),
        reason: 'Sau khi thêm khách phải có 3 VĐV import và 1 khách',
      );

      // 3. Tạo nhánh trên app: Bốc thăm tự động, rồi Lưu & Bắt đầu giải.
      container
          .read(routerProvider)
          .go('/organizer/tournaments/$id/manage/draw');
      await pumpUntilFound(
        tester,
        find.text('Bốc thăm tự động'),
        what: 'màn bốc thăm (Bốc thăm tự động)',
      );
      await tester.tap(find.text('Bốc thăm tự động').first);
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.text('Lưu & Bắt đầu giải'),
        what: 'nút Lưu & Bắt đầu giải sau khi bốc thăm',
      );
      await tester.tap(find.text('Lưu & Bắt đầu giải').first);
      await tester.pump();

      var matches = <Map<String, dynamic>>[];
      for (var attempt = 0; attempt < 30 && matches.isEmpty; attempt++) {
        await tester.pump(const Duration(seconds: 1));
        matches = await api.listMatches(
          token: organizerToken,
          tournamentId: id,
          divisionId: divisionId,
        );
      }
      expect(
        matches,
        isNotEmpty,
        reason: 'Sau Lưu & Bắt đầu giải phải có trận trên Backend',
      );

      // 4. Nhánh hiện trên app: tên VĐV import có trên màn nhánh.
      container.read(routerProvider).go('/tournament/$id/bracket');
      await pumpUntilFound(
        tester,
        find.textContaining(tag),
        timeout: const Duration(seconds: 60),
        what: 'tên VĐV của giải trên màn nhánh',
      );
    },
  );
}
