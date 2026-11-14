import 'package:app_quanly_giaidau/features/home/widgets/explore_new_tournaments.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/social_journey.dart';

/// Journey Social 1/3: tạo buổi giao lưu và thấy nó ở danh sách Khám phá (TC-SOCIAL-APP-01..04).
/// Emulator Android + Backend thật. Host là BTC `admin1`; dữ liệu dựng bằng API khi app không có màn đó.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeAppForTests);

  testWidgets(
    'TC-SOCIAL-APP-01 host tạo buổi qua form: đôi, 4 người, phí 50.000, địa điểm "Quyết định sau"',
    (tester) async {
      final api = SocialApi();
      final tag = socialTag('SC1');
      final title = '$tag Giao lưu đôi';
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-01');

      await signInWithEmail(tester, email: kOrganizerEmail);
      await openCreateSocialForm(tester);
      await shooter.snap('form-tao-keo-trong');

      // Môn: form tự chọn môn đầu tiên đang bật; thể thức "Đánh đôi" bấm tay.
      await tapText(tester, 'Đánh đôi');

      // Địa điểm: chọn "Quyết định sau" trong luồng chọn địa điểm.
      await tapText(tester, 'Chọn địa điểm');
      await tapText(tester, 'Quyết định sau');
      await socialWait(tester);
      expect(
        find.text('Quyết định sau'),
        findsWidgets,
        reason: 'hàng địa điểm phải hiện "Quyết định sau" sau khi chọn',
      );

      // Số người: mặc định 6, bấm trừ hai lần còn 4.
      await tapFinder(tester, find.byIcon(Icons.remove), what: 'nút trừ số người chơi');
      await tapFinder(tester, find.byIcon(Icons.remove), what: 'nút trừ số người chơi (lần 2)');
      expect(find.text('4'), findsWidgets, reason: 'số người chơi phải về 4');

      // Phí: mở hộp thoại, nhập 50000, xác nhận.
      await tapText(tester, 'Không có');
      final feeField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await pumpUntilFound(tester, feeField, what: 'ô nhập phí trong hộp thoại');
      await tester.enterText(feeField, '50000');
      await tester.pump();
      await tapText(tester, 'Xác nhận');
      await pumpUntilFound(
        tester,
        find.textContaining('50.000'),
        what: 'dòng phí hiện 50.000 sau khi xác nhận',
      );

      // Tên kèo và ghi chú (địa điểm hoãn nên không có ô tên sân, địa chỉ sân).
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2), reason: 'địa điểm hoãn: chỉ còn ô tên kèo và ghi chú');
      await tester.enterText(fields.at(0), title);
      await tester.enterText(fields.at(1), 'Mang vợt và nước uống');
      await tester.pump();
      await shooter.snap('form-da-dien');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Tạo kèo'));
      await tester.pump();

      // Tạo xong form đóng và báo thành công. (App hiện KHÔNG mở chi tiết buổi: xem Bug sản phẩm trong báo cáo.)
      await pumpUntilFound(
        tester,
        find.text('Tạo Social "$title" thành công!'),
        what: 'thông báo tạo buổi thành công',
        timeout: const Duration(seconds: 60),
      );
      await shooter.snap('tao-thanh-cong');
      // Buổi mới hiện ở Khám phá đúng ngày đã chọn; bấm thẻ để mở chi tiết với quyền host.
      await openSessionFromExplore(tester, title);
      await shooter.snap('chi-tiet-sau-tao');
      expect(find.text('Thanh toán'), findsOneWidget, reason: 'buổi có phí thì host có tab Thanh toán');
      expect(find.text('Quyết định sau'), findsWidgets);
      expect(find.text('Đánh đôi'), findsWidgets);
      // Dòng giá là RichText (TextSpan), phải bật findRichText.
      expect(find.textContaining('50.000', findRichText: true), findsWidgets);
      expect(find.text('Mang vợt và nước uống'), findsOneWidget);

      // Backend phải lưu đúng những gì form gửi.
      final hostToken = await api.login(kOrganizerEmail);
      final sessionId = await api.idByTitle(hostToken, title);
      expect(sessionId, isNotNull, reason: 'Backend phải có buổi "$title"');
      final saved = await api.getSession(hostToken, sessionId!);
      expect(saved['title'], title);
      expect(saved['playFormat'], 'Đánh đôi');
      expect(saved['maxSlots'], 4);
      expect(saved['feePerSlot'], 50000);
      expect('${saved['status']}'.toUpperCase(), 'OPEN');
      expect(saved['venueName'], 'Quyết định sau');
    },
  );

  testWidgets(
    'TC-SOCIAL-APP-02 form tạo buổi báo lỗi bắt buộc khi chưa chọn địa điểm, không tạo buổi',
    (tester) async {
      final api = SocialApi();
      final tag = socialTag('SC2');
      final title = '$tag Thiếu địa điểm';
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-02');

      await signInWithEmail(tester, email: kOrganizerEmail);
      await openCreateSocialForm(tester);
      final fields = find.byType(TextFormField);
      await pumpUntilFound(tester, fields, what: 'ô tên kèo');
      await tester.enterText(fields.first, title);
      await tester.pump();

      // Chưa chọn địa điểm: bấm Tạo kèo phải báo lỗi và ở lại form.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Tạo kèo'));
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.textContaining('Vui lòng chọn địa điểm'),
        what: 'thông báo bắt buộc chọn địa điểm',
      );
      await shooter.snap('bao-loi-thieu-dia-diem');
      expect(
        find.text('Tạo Social "$title" thành công!'),
        findsNothing,
        reason: 'form lỗi thì không được báo tạo thành công',
      );
      expect(find.widgetWithText(ElevatedButton, 'Tạo kèo'), findsOneWidget);

      // Chọn "Quyết định sau" thì gửi được.
      await tapText(tester, 'Chọn địa điểm');
      await tapText(tester, 'Quyết định sau');
      await socialWait(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Tạo kèo'));
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.text('Tạo Social "$title" thành công!'),
        what: 'thông báo tạo buổi thành công sau khi sửa lỗi và gửi lại',
        timeout: const Duration(seconds: 60),
      );
      await shooter.snap('tao-duoc-sau-khi-sua');

      final hostToken = await api.login(kOrganizerEmail);
      expect(
        await api.countByTitle(hostToken, title),
        1,
        reason: 'đúng một buổi "$title" trên Backend (lần gửi lỗi không tạo gì)',
      );
    },
  );

  testWidgets(
    'TC-SOCIAL-APP-03 form tạo buổi chọn sân đã lưu bằng tìm kiếm, có ô tên sân và địa chỉ sân để sửa',
    (tester) async {
      final api = SocialApi();
      final tag = socialTag('SC3');
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-03');

      // Dựng một sân có ghim bằng API (buổi khác của host) để tìm lại trong thư viện sân.
      final hostToken = await api.login(kOrganizerEmail);
      final seed = await api.createSession(
        token: hostToken,
        title: '$tag Buổi dựng sân',
        deferred: false,
      );
      final venueName = '${seed.raw['venueName'] ?? 'Sân E2E ${seed.title}'}';

      await signInWithEmail(tester, email: kOrganizerEmail);
      await openCreateSocialForm(tester);
      await tapText(tester, 'Chọn địa điểm');
      final search = find.widgetWithText(TextField, 'Tìm theo tên hoặc địa chỉ');
      await pumpUntilFound(tester, search, what: 'ô tìm địa điểm');
      await tester.enterText(search, tag);
      await tester.pump();
      await pumpUntilFound(
        tester,
        find.text(venueName),
        what: 'kết quả tìm "$venueName" trong thư viện sân',
        timeout: const Duration(seconds: 30),
      );
      await shooter.snap('ket-qua-tim-san');
      await tester.tap(find.text(venueName).first);
      await tester.pump();

      await pumpUntilFound(
        tester,
        find.widgetWithText(TextFormField, 'Địa chỉ sân'),
        what: 'ô Địa chỉ sân sau khi chọn sân',
      );
      await shooter.snap('da-chon-san');
      expect(find.widgetWithText(TextFormField, 'Tên sân'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-SOCIAL-APP-04 Khám phá: buổi mới tạo hiện đúng một lần, giải mới chỉ có MỘT mốc thời gian',
    (tester) async {
      final api = SocialApi();
      final backend = BackendApi();
      final tag = socialTag('SC4');
      final sessionTitle = '$tag Buổi khám phá';
      final tournamentName = '$tag Giải khám phá';
      final shooter = SocialShooter(tester, binding, 'TC-SOCIAL-APP-04');

      final hostToken = await api.login(kOrganizerEmail);
      final startAt = DateTime.now().add(const Duration(hours: 1));
      await api.createSession(token: hostToken, title: sessionTitle, startAt: startAt);
      final tournament = await backend.createLiteTournament(
        token: hostToken,
        name: tournamentName,
        matchType: 'SINGLES',
        maxParticipants: 8,
      );
      await backend.approveTournamentAsAdmin(tournament.tournamentId);

      final container = await signInWithEmail(tester, email: kPlayerEmail);
      final navExplore = find.descendant(
        of: find.byType(FloatingBottomNav),
        matching: find.text('Khám phá'),
      );
      await tapFinder(tester, navExplore, what: 'nhãn Khám phá trên thanh điều hướng');
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('explore_social')),
        what: 'danh sách Khám phá (explore_social)',
      );

      // Buổi: hiện ở ngày bắt đầu (cuộn tới thẻ vì danh sách dựng lười).
      final sessionDay = DateUtils.dateOnly(startAt.toLocal());
      container.read(socialFilterProvider.notifier).setSelectedDate(sessionDay);
      await socialWait(tester, const Duration(seconds: 3));
      await scrollToText(tester, sessionTitle);
      await shooter.snap('the-buoi');

      // Giải mở đăng ký: đếm số mốc theo luật của danh sách Khám phá trên dữ liệu Backend thật.
      await pumpUntilCondition(
        tester,
        () => container.read(tournamentsProvider).value != null,
        what: 'danh sách giải từ Backend',
      );
      final all = container.read(tournamentsProvider).value!;
      final today = DateUtils.dateOnly(DateTime.now());
      final milestones = <DateTime>[
        for (var offset = 0; offset <= 14; offset++)
          for (final entry in newTournamentEntriesForDay(
            all,
            today.add(Duration(days: offset)),
            DateTime.now(),
          ))
            if (entry.tournament.name == tournamentName) today.add(Duration(days: offset)),
      ];
      expect(
        milestones,
        hasLength(1),
        reason: 'giải "$tournamentName" đang mở đăng ký chỉ có MỘT mốc trong 15 ngày tới, đang có $milestones',
      );
      container.read(socialFilterProvider.notifier).setSelectedDate(milestones.single);
      await socialWait(tester, const Duration(seconds: 3));
      await scrollToText(tester, tournamentName);
      await shooter.snap('the-giai');
    },
  );
}
