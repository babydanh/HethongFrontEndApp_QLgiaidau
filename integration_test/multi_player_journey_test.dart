import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/actors.dart';
import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/social_journey.dart';

/// Chuỗi B (task 2.2): hành trình đầy đủ của VĐV với nhiều tài khoản (TC-MULTI-B-01..20).
/// Emulator Android + Backend thật. Vai chính `player` thao tác trên giao diện; BTC (`organizer`),
/// đồng đội (`member`) và `viewer` đi bằng API hoặc đổi tài khoản trong app.
///
/// Nhóm 01-13: luồng VĐV (đăng ký đơn, đôi, đội, mã mời, theo dõi, thanh toán, dashboard, hồ sơ,
/// mật khẩu, xếp hạng). Nhóm 14-20: phân quyền âm (VĐV không phải BTC của giải).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final api = BackendApi();
  late final Map<String, E2eActor> actors;
  late final String organizerToken;
  late final String tag;
  late final CreatedTournament singles; // T1: giải đơn, còn đúng 1 suất
  late final CreatedTournament doubles; // T2: giải đôi tự ghép
  late final _LiteInfo inviteTournament; // T3: mở bằng /join/:code
  late final _LiteInfo liteTournament; // T4: mở bằng /lite-join/:code
  late final _LiteInfo paidTournament; // T5: có lệ phí
  late final String singlesName;
  late final String paidName;
  String? doublesParticipantId;
  String? doublesInviteToken;

  E2eActor actor(String role) => actors[role]!;

  setUpAll(() async {
    await initializeAppForTests();
    actors = await createActors(
      api,
      chain: 'B',
      roles: ['organizer', 'player', 'member', 'viewer'],
    );
    organizerToken = actor('organizer').token;
    tag = 'E2EB${DateTime.now().millisecondsSinceEpoch % 100000000}';
    singlesName = '$tag Giải đơn';
    paidName = '$tag Giải lệ phí';

    singles = await api.createLiteTournament(
      token: organizerToken,
      name: singlesName,
      matchType: 'SINGLES',
      maxParticipants: 4,
    );
    await api.approveTournamentAsAdmin(singles.tournamentId);
    await api.importRoster(
      token: organizerToken,
      tournamentId: singles.tournamentId,
      divisionId: singles.divisionId,
      tag: tag,
      count: 3,
      singles: true,
    );

    doubles = await api.createLiteTournament(
      token: organizerToken,
      name: '$tag Giải đôi',
      matchType: 'DOUBLES',
      maxParticipants: 4,
      doublesPairingMode: 'SELF',
    );
    await api.approveTournamentAsAdmin(doubles.tournamentId);

    inviteTournament = await _createLite(
      api,
      organizerToken,
      '$tag Giải mã mời',
      maxParticipants: 8,
    );
    await api.approveTournamentAsAdmin(inviteTournament.tournamentId);

    liteTournament = await _createLite(
      api,
      organizerToken,
      '$tag Giải lite',
      maxParticipants: 8,
    );
    await api.approveTournamentAsAdmin(liteTournament.tournamentId);

    paidTournament = await _createLite(
      api,
      organizerToken,
      paidName,
      maxParticipants: 8,
      entryFee: 50000,
    );
    await api.approveTournamentAsAdmin(paidTournament.tournamentId);
  });

  /// Đưa `player` vào giải T1 qua API nếu ca 01 chưa đăng ký (để các ca sau không phụ thuộc ca 01).
  Future<Map<String, dynamic>> ensurePlayerRegisteredInSingles() async {
    final token = await api.login(actor('player').email, kE2ePassword);
    var mine = await api.myRegistration(
      token: token,
      tournamentId: singles.tournamentId,
      divisionId: singles.divisionId,
    );
    if (mine['registered'] != true) {
      final status = await _registerViaApi(
        token,
        singles,
        '$tag ${actor('player').role}',
      );
      expect(status, inInclusiveRange(200, 299), reason: 'Đăng ký đơn qua API');
      mine = await api.myRegistration(
        token: token,
        tournamentId: singles.tournamentId,
        divisionId: singles.divisionId,
      );
    }
    expect(mine['registered'], isTrue, reason: 'Player phải có đơn ở giải đơn');
    return Map<String, dynamic>.from(mine['participant'] as Map);
  }

  // ---------------------------------------------------------------- Luồng VĐV

  testWidgets(
    'TC-MULTI-B-01 VĐV đăng ký đơn trên app, đơn ở trạng thái chờ BTC duyệt',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-01');
      final container = await _signIn(tester, actor('player'));
      await snap.snap('da-dang-nhap');

      container.read(routerProvider).go('/intro/${singles.tournamentId}');
      final registerButton = find.widgetWithText(FilledButton, 'Đăng ký');
      await pumpUntil(tester, registerButton);
      await snap.snap('trang-giai-don');
      await tester.tap(registerButton.first);
      await tester.pump();

      final submit = anyTextStartingWith([
        'Gửi yêu cầu tham gia',
        'Xác nhận đăng ký',
      ]);
      await pumpUntil(tester, submit);
      await _tickRankingConsent(tester);
      await snap.snap('form-dang-ky-don');
      await tapCentered(tester, submit);
      await tester.pump();
      await pumpUntil(
        tester,
        anyTextOf([
          'Chờ BTC duyệt',
          'Đang chờ Ban tổ chức duyệt',
          'Bạn đã đăng ký giải đấu này',
          'Đã đăng ký, chưa thanh toán',
        ]),
      );
      await snap.snap('sau-khi-gui-don');

      final token = await api.login(actor('player').email, kE2ePassword);
      final mine = await api.myRegistration(
        token: token,
        tournamentId: singles.tournamentId,
        divisionId: singles.divisionId,
      );
      expect(mine['registered'], isTrue, reason: 'Backend phải có đơn của VĐV');
      final participant = Map<String, dynamic>.from(mine['participant'] as Map);
      expect(participant['teamStatus'], 'PENDING_APPROVAL');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-02 BTC duyệt đơn bằng API, VĐV mở lại trang đăng ký không còn trạng thái chờ duyệt',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-02');
      final participant = await ensurePlayerRegisteredInSingles();
      if (participant['teamStatus'] == 'PENDING_APPROVAL') {
        await api.approveParticipant(
          token: organizerToken,
          tournamentId: singles.tournamentId,
          participantId: participant['id'] as String,
        );
      }

      final container = await _signIn(tester, actor('player'));
      container.read(routerProvider).go('/register/${singles.tournamentId}');
      await pumpUntil(
        tester,
        anyTextOf([
          'Bạn đã đăng ký giải đấu này',
          'Đã đăng ký, chưa thanh toán',
          'Đã đăng ký và thanh toán',
        ]),
      );
      expect(find.text('Đang chờ Ban tổ chức duyệt'), findsNothing);
      await snap.snap('da-duoc-duyet');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-03 VĐV đăng ký đôi tự ghép, mời đồng đội bằng email, đơn chờ đồng đội',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-03');
      final player = actor('player');
      final partner = actor('member');
      final teamName = '$tag Đội A';

      final container = await _signIn(tester, player);
      container.read(routerProvider).go('/intro/${doubles.tournamentId}');
      final registerButton = find.widgetWithText(FilledButton, 'Đăng ký');
      await pumpUntil(tester, registerButton);
      await snap.snap('trang-giai-doi');
      await tester.tap(registerButton.first);
      await tester.pump();

      final submit = anyTextStartingWith([
        'Gửi yêu cầu tham gia',
        'Xác nhận đăng ký',
      ]);
      await pumpUntil(tester, submit);
      await _tickRankingConsent(tester);
      await tapCentered(tester, submit);
      await tester.pump();

      await pumpUntil(tester, find.text('Tiếp theo'));
      await tester.enterText(
        find.widgetWithText(TextField, 'Tên đội'),
        teamName,
      );
      await tester.pump();
      await tapCentered(tester, find.text('Mời sau'));
      await tester.pump();
      final partnerField = find.widgetWithText(
        TextField,
        'Nhập email hoặc SĐT đồng đội',
      );
      await pumpUntil(tester, partnerField);
      await tester.enterText(partnerField, partner.email);
      await tester.pump();
      await pumpUntil(tester, find.text(partner.fullName));
      await snap.snap('tim-thay-dong-doi');
      await tapCentered(tester, find.text(partner.fullName));
      await tester.pump();
      await tapCentered(tester, find.text('Tiếp theo'));
      await tester.pump();
      await pumpUntil(tester, find.text('Sao chép link mời'));
      await snap.snap('buoc-moi-dong-doi');

      final token = await api.login(player.email, kE2ePassword);
      final mine = await api.myRegistration(
        token: token,
        tournamentId: doubles.tournamentId,
        divisionId: doubles.divisionId,
      );
      expect(mine['registered'], isTrue, reason: 'VĐV phải có đơn đôi');
      final participant = Map<String, dynamic>.from(mine['participant'] as Map);
      expect(participant['teamStatus'], 'PENDING_PARTNER');
      expect(participant['partnerUserId'], partner.userId);
      expect(participant['teamName'], teamName);
      final inviteToken = participant['teamInviteToken'] as String? ?? '';
      expect(inviteToken, isNotEmpty, reason: 'Đơn đôi phải có mã mời đội');
      doublesParticipantId = participant['id'] as String;
      doublesInviteToken = inviteToken;
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-04 đồng đội mở /join-team bằng mã mời và vào đội thành công',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-04');
      final pid = doublesParticipantId;
      final inviteToken = doublesInviteToken;
      expect(
        pid != null && inviteToken != null,
        isTrue,
        reason: 'Cần ca TC-MULTI-B-03 tạo đơn đôi trước',
      );
      final partner = actor('member');

      final container = await _signIn(tester, partner);
      final uri = Uri(
        path: '/join-team',
        queryParameters: {
          'tournamentId': doubles.tournamentId,
          'pid': pid,
          'token': inviteToken,
        },
      );
      container.read(routerProvider).go(uri.toString());
      await pumpUntil(tester, find.text('Xác nhận tham gia'));
      await snap.snap('man-tham-gia-doi');
      await tapCentered(tester, find.text('Xác nhận tham gia'));
      await tester.pump();
      await pumpUntil(tester, find.text('Tham gia đội thành công!'));
      await snap.snap('da-vao-doi');

      final token = await api.login(partner.email, kE2ePassword);
      final mine = await api.myRegistration(
        token: token,
        tournamentId: doubles.tournamentId,
        divisionId: doubles.divisionId,
      );
      expect(mine['registered'], isTrue, reason: 'Đồng đội phải thấy đơn đôi');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-05 mã mời /join/:code đưa VĐV tới màn đăng ký đúng giải, mã sai báo không tìm thấy',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-05');
      final code = inviteTournament.inviteCode;
      final container = await _signIn(tester, actor('member'));
      final router = container.read(routerProvider);

      router.go('/join/$code');
      await pumpUntilCondition(
        tester,
        () =>
            currentPath(tester) == '/register/${inviteTournament.tournamentId}',
        what: 'mã mời chuyển sang /register/${inviteTournament.tournamentId}',
      );
      await pumpUntil(
        tester,
        anyTextStartingWith(['Gửi yêu cầu tham gia', 'Xác nhận đăng ký']),
      );
      expect(find.text('Không tìm thấy giải'), findsNothing);
      await snap.snap('dang-ky-tu-ma-moi');

      router.go('/home');
      await socialWait(tester, const Duration(seconds: 1));
      router.go('/join/KHONGTONTAI99');
      await pumpUntil(tester, find.text('Không tìm thấy giải'));
      await snap.snap('ma-moi-sai');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-06 mã /lite-join/:code cho VĐV vào giải, mở lại báo đã tham gia',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-06');
      final code = liteTournament.inviteCode;
      final container = await _signIn(tester, actor('player'));
      final router = container.read(routerProvider);

      router.go('/lite-join/$code');
      final joinButton = find.widgetWithText(ElevatedButton, 'Tham gia giải');
      await pumpUntil(tester, joinButton);
      await snap.snap('man-lite-join');
      await tester.tap(joinButton.first);
      await tester.pump();
      await pumpUntilCondition(
        tester,
        () => currentPath(tester) == '/intro/${liteTournament.tournamentId}',
        what:
            'sau khi vào giải chuyển tới /intro/${liteTournament.tournamentId}',
      );
      await snap.snap('da-vao-giai-lite');

      router.go('/lite-join/$code');
      await pumpUntil(tester, find.text('Bạn đã tham gia giải này'));
      await snap.snap('bao-da-tham-gia');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-07 màn đăng ký đội /register/:id/team mở được cho VĐV đã đăng nhập',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-07');
      final container = await _signIn(tester, actor('player'));
      container
          .read(routerProvider)
          .go('/register/${singles.tournamentId}/team?teamSize=7');
      await pumpUntil(tester, find.text('Đăng ký đội bóng'));
      await socialWait(tester, const Duration(seconds: 3));
      expect(currentPath(tester), '/register/${singles.tournamentId}/team');
      expect(find.text('Đăng ký đội bóng'), findsOneWidget);
      await snap.snap('man-dang-ky-doi');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-08 VĐV theo dõi giải bằng nút đánh dấu, mở lại vẫn thấy đang theo dõi',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-08');
      final container = await _signIn(tester, actor('player'));
      final router = container.read(routerProvider);
      final route = '/intro/${inviteTournament.tournamentId}';

      router.go(route);
      final notFollowing = find.byIcon(Icons.bookmark_border_rounded);
      await pumpUntil(tester, notFollowing);
      await snap.snap('chua-theo-doi');
      await tester.tap(notFollowing.first);
      await tester.pump();
      await pumpUntil(tester, find.byIcon(Icons.bookmark_rounded));
      await snap.snap('da-theo-doi');

      router.go('/home');
      await socialWait(tester, const Duration(seconds: 2));
      router.go(route);
      await pumpUntil(tester, find.byIcon(Icons.bookmark_rounded));
      expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
      await snap.snap('mo-lai-van-theo-doi');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-09 màn thanh toán lệ phí hiện đúng giải có phí (tới màn cổng, không bấm trả)',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-09');
      final playerToken = await api.login(actor('player').email, kE2ePassword);
      final status = await _registerViaApi(
        playerToken,
        paidTournament,
        '$tag Đơn trả phí',
      );
      expect(status, inInclusiveRange(200, 299), reason: 'Đăng ký giải có phí');
      final mine = await api.myRegistration(
        token: playerToken,
        tournamentId: paidTournament.tournamentId,
        divisionId: paidTournament.divisionId,
      );
      final participantId =
          Map<String, dynamic>.from(mine['participant'] as Map)['id'] as String;

      final container = await _signIn(tester, actor('player'));
      final query = Uri(
        path: '/payment/checkout',
        queryParameters: {
          'tournamentId': paidTournament.tournamentId,
          'participantId': participantId,
          'divisionId': paidTournament.divisionId,
          'amount': '50000',
          'tournamentName': paidName,
        },
      );
      container.read(routerProvider).go(query.toString());
      await pumpUntil(tester, find.text('Thanh toán lệ phí'));
      await snap.snap('man-thanh-toan');
      expect(find.text('MIỄN PHÍ'), findsNothing);
      expect(find.textContaining(paidName), findsWidgets);
      expect(
        anyTextStartingWith(['THANH TOÁN', 'ĐÃ THU', 'Thu trực tiếp']),
        findsWidgets,
        reason: 'Nút thanh toán (hoặc trạng thái thu trực tiếp) phải hiện',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-10 dashboard của VĐV liệt kê giải đã đăng ký, không gắn nhãn Chủ giải',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-10');
      await ensurePlayerRegisteredInSingles();
      final container = await _signIn(tester, actor('player'));
      container.read(routerProvider).go('/dashboard');
      await pumpUntil(tester, find.text('Tổng quan'));
      await snap.snap('dashboard-tong-quan');
      await tapText(tester, 'Quản lý');
      await pumpUntil(tester, find.text(singlesName));
      expect(find.text('Đã đăng ký'), findsWidgets);
      expect(
        find.text('Chủ giải'),
        findsNothing,
        reason: 'VĐV không phải chủ giải nào',
      );
      await snap.snap('dashboard-giai-cua-toi');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-11 sửa hồ sơ: đổi họ tên trên app, Backend trả họ tên mới',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-11');
      final viewer = actor('viewer');
      final newName = '$tag Tên mới';
      final container = await _signIn(tester, viewer);
      container.read(routerProvider).go('/profile/edit');
      await pumpUntilCondition(
        tester,
        () =>
            find.byType(TextField).evaluate().isNotEmpty &&
            tester
                    .widget<TextField>(find.byType(TextField).first)
                    .controller
                    ?.text ==
                viewer.fullName,
        what: 'ô họ tên điền sẵn "${viewer.fullName}"',
      );
      await snap.snap('man-sua-ho-so');
      await tester.enterText(find.byType(TextField).first, newName);
      await tester.pump();
      await tapText(tester, 'Lưu thay đổi');
      await pumpUntil(tester, find.text('Đã lưu thay đổi'));
      await snap.snap('da-luu-ho-so');

      final token = await api.login(viewer.email, kE2ePassword);
      final profile = await _getJson('/users/profile', token);
      expect(profile['fullName'], newName);
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-12 đổi mật khẩu trên app rồi đăng nhập lại bằng mật khẩu mới, mật khẩu cũ bị từ chối',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-12');
      final viewer = actor('viewer');
      const newPassword = 'Mk2NewE2E';
      var container = await _signIn(tester, viewer);
      container.read(routerProvider).go('/profile/change-password');
      await pumpUntil(tester, find.text('Mật khẩu hiện tại'));
      final fields = find.byType(TextField);
      await pumpUntil(tester, fields);
      expect(fields, findsNWidgets(3));
      await tester.enterText(fields.at(0), kE2ePassword);
      await tester.enterText(fields.at(1), newPassword);
      await tester.enterText(fields.at(2), newPassword);
      await tester.pump();
      await snap.snap('form-doi-mat-khau');
      // Tiêu đề và nút cùng nhãn "Đổi mật khẩu": nút nằm ở thanh dưới nên là phần tử cuối.
      await tester.tap(find.text('Đổi mật khẩu').last);
      await tester.pump();
      await pumpUntilCondition(
        tester,
        () => currentPath(tester) == '/profile',
        what: 'đổi mật khẩu xong thì về /profile',
      );
      await snap.snap('da-doi-mat-khau');

      final oldStatus = await api.statusOf(
        'POST',
        '/auth/mobile/login',
        data: {'email': viewer.email, 'password': kE2ePassword},
      );
      expect(
        oldStatus,
        isIn([400, 401, 403]),
        reason: 'Mật khẩu cũ phải bị từ chối',
      );
      await leaveSocialSession(tester, container);

      container = await signInWithEmail(
        tester,
        email: viewer.email,
        password: newPassword,
      );
      expect(container.read(authProvider).isAuthenticated, isTrue);
      await snap.snap('dang-nhap-mat-khau-moi');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-13 bảng xếp hạng công khai tải được và đổi được bộ lọc Đơn/Đôi',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-13');
      final container = await _signIn(tester, actor('player'));
      container.read(routerProvider).go('/rankings');
      await pumpUntil(tester, find.text('Đơn'));
      await pumpUntil(
        tester,
        anyTextOf(['NGƯỜI CHƠI', 'Chưa có dữ liệu xếp hạng']),
        timeout: const Duration(seconds: 45),
      );
      expect(find.text('Không thể tải thông tin xếp hạng'), findsNothing);
      await snap.snap('xep-hang-tat-ca');
      await tapCentered(tester, find.text('Đôi'));
      await pumpUntil(
        tester,
        anyTextOf(['NGƯỜI CHƠI', 'Chưa có dữ liệu xếp hạng']),
        timeout: const Duration(seconds: 45),
      );
      expect(find.text('Không thể tải thông tin xếp hạng'), findsNothing);
      await snap.snap('xep-hang-doi');
      await leaveSocialSession(tester, container);
    },
  );

  // ------------------------------------------------------- Phân quyền âm (VĐV)

  testWidgets(
    'TC-MULTI-B-14 phân quyền âm: VĐV mở /organizer/tournaments/:id/manage của giải người khác thì bị chặn',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-14');
      final container = await _signIn(tester, actor('player'));
      await snap.snap('vdv-da-dang-nhap');
      await _expectBlockedPatient(
        tester,
        container,
        '/organizer/tournaments/${singles.tournamentId}/manage',
      );
      await snap.snap('man-quan-ly-bi-chan');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-15 phân quyền âm: VĐV không thấy nút Quản lý ở trang giải, BTC thấy nút đó',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-15');
      final route = '/intro/${singles.tournamentId}';
      final manageButton = find.byIcon(Icons.settings_suggest_rounded);

      var container = await _signIn(tester, actor('player'));
      container.read(routerProvider).go(route);
      await pumpUntil(tester, find.byIcon(Icons.share_outlined));
      await socialWait(tester, const Duration(seconds: 4));
      expect(
        manageButton,
        findsNothing,
        reason: 'VĐV không được thấy nút Quản lý',
      );
      await snap.snap('vdv-khong-co-nut-quan-ly');
      await leaveSocialSession(tester, container);

      container = await _signIn(tester, actor('organizer'));
      container.read(routerProvider).go(route);
      await pumpUntil(
        tester,
        manageButton,
        timeout: const Duration(seconds: 45),
      );
      await snap.snap('btc-co-nut-quan-ly');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-16 phân quyền âm: VĐV mở /admin/tournament/:id thì bị đưa về trang chủ',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-16');
      final container = await _signIn(tester, actor('player'));
      await _expectBlockedPatient(
        tester,
        container,
        '/admin/tournament/${singles.tournamentId}',
      );
      await snap.snap('admin-bi-chan');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-17 phân quyền âm: VĐV mở màn vận hành /organizer/tournaments/:id/ops thì bị chặn',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-17');
      final container = await _signIn(tester, actor('player'));
      await _expectBlockedPatient(
        tester,
        container,
        '/organizer/tournaments/${singles.tournamentId}/ops',
      );
      await snap.snap('ops-bi-chan');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-B-18 phân quyền âm API: VĐV sửa, xoá, sinh bracket, duyệt VĐV, khai mạc giải của người khác đều bị 401/403',
    (tester) async {
      final token = await api.login(actor('player').email, kE2ePassword);
      final t = singles.tournamentId;
      final participants = await api.listParticipants(
        token: organizerToken,
        tournamentId: t,
        divisionId: singles.divisionId,
      );
      expect(participants, isNotEmpty);
      final participantId = participants.first['id'] as String;
      final calls = <String, Future<int>>{
        'PATCH /tournaments/:id': api.statusOf(
          'PATCH',
          '/tournaments/$t',
          token: token,
          data: {'name': '$tag bị sửa trái phép'},
        ),
        'DELETE /tournaments/:id': api.statusOf(
          'DELETE',
          '/tournaments/$t',
          token: token,
        ),
        'POST /tournaments/:id/generate-bracket': api.statusOf(
          'POST',
          '/tournaments/$t/generate-bracket',
          token: token,
          data: {'divisionId': singles.divisionId},
        ),
        'PATCH /tournaments/:id/participants/:pid': api.statusOf(
          'PATCH',
          '/tournaments/$t/participants/$participantId',
          token: token,
          data: {'status': 'COMPLETE'},
        ),
        'POST /tournaments/:id/start': api.statusOf(
          'POST',
          '/tournaments/$t/start',
          token: token,
        ),
      };
      for (final entry in calls.entries) {
        expect(
          await entry.value,
          isIn([401, 403]),
          reason: '${entry.key} bằng token VĐV phải bị từ chối',
        );
      }
      final after = await api.getTournament(
        token: organizerToken,
        tournamentId: t,
      );
      expect(after['name'], singlesName);
    },
  );

  testWidgets(
    'TC-MULTI-B-19 phân quyền âm API: VĐV gọi lệnh ADMIN bị 403, không có token thì bị 401',
    (tester) async {
      final token = await api.login(actor('player').email, kE2ePassword);
      final t = singles.tournamentId;
      expect(
        await api.statusOf(
          'POST',
          '/admin/tournaments/$t/approve',
          token: token,
        ),
        isIn([401, 403]),
        reason: 'VĐV không được duyệt giải của ADMIN',
      );
      expect(
        await api.statusOf('PATCH', '/tournaments/$t', data: {'name': 'x'}),
        isIn([401, 403]),
        reason: 'Không token không được sửa giải',
      );
      expect(
        await api.statusOf('GET', '/tournaments/$t/my-registration'),
        isIn([401, 403]),
        reason: 'Không token không xem được đơn của người khác',
      );
    },
  );

  testWidgets(
    'TC-MULTI-B-20 phân quyền âm: mã mời đội sai không cho vào đội, màn không báo thành công',
    (tester) async {
      final snap = SocialShooter(tester, binding, 'TC-MULTI-B-20');
      final pid = doublesParticipantId;
      expect(pid, isNotNull, reason: 'Cần ca TC-MULTI-B-03 tạo đơn đôi trước');
      final container = await _signIn(tester, actor('viewer'));
      final uri = Uri(
        path: '/join-team',
        queryParameters: {
          'tournamentId': doubles.tournamentId,
          'pid': pid,
          'token': 'ma-moi-sai-hoan-toan',
        },
      );
      container.read(routerProvider).go(uri.toString());
      await pumpUntil(tester, find.text('Xác nhận tham gia'));
      await tapCentered(tester, find.text('Xác nhận tham gia'));
      await tester.pump();
      await socialWait(tester, const Duration(seconds: 4));
      await pumpUntil(tester, find.text('Xác nhận tham gia'));
      expect(find.text('Tham gia đội thành công!'), findsNothing);
      await snap.snap('ma-moi-doi-sai');
      await leaveSocialSession(tester, container);
    },
  );
}

// ------------------------------------------------------------------ Helper

/// Đăng nhập rồi chờ app ổn định ở trang chủ: màn chuyển sau đăng nhập có thể đè lệnh `go` đến sớm
/// (lần chạy cloud 43557878374: mọi ca sau ca đầu vẫn kẹt ở /home).
Future<ProviderContainer> _signIn(WidgetTester tester, E2eActor actor) async {
  final container = await signInAs(tester, actor);
  container.read(routerProvider).go('/home');
  await socialWait(tester, const Duration(seconds: 3));
  return container;
}

/// Giải nhanh tạo bằng helper riêng (cần mã mời và lệ phí, `BackendApi.createLiteTournament` không có).
class _LiteInfo {
  const _LiteInfo({
    required this.tournamentId,
    required this.divisionId,
    required this.inviteCode,
  });

  final String tournamentId;
  final String divisionId;
  final String inviteCode;
}

final Dio _rawDio = Dio(
  BaseOptions(
    baseUrl: kE2eApiBaseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 60),
    contentType: Headers.jsonContentType,
    validateStatus: (_) => true,
  ),
);

Object? _payload(Object? body) =>
    body is Map && body['data'] != null ? body['data'] : body;

Future<Map<String, dynamic>> _getJson(String path, String token) async {
  final response = await _rawDio.get<Object?>(
    path,
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  final code = response.statusCode ?? 0;
  expect(code, inInclusiveRange(200, 299), reason: 'GET $path');
  final data = _payload(response.data);
  expect(data, isA<Map>(), reason: 'GET $path phải trả object');
  return Map<String, dynamic>.from(data as Map);
}

/// Tạo giải nhanh PUBLIC (đơn, loại trực tiếp) và lấy mã mời. Giống `BackendApi.createLiteTournament`, thêm `entryFee`.
Future<_LiteInfo> _createLite(
  BackendApi api,
  String token,
  String name, {
  required int maxParticipants,
  int? entryFee,
}) async {
  final response = await _rawDio.post<Object?>(
    '/tournaments/lite',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
    data: {
      'name': name,
      'sport': 'pickleball',
      'format': 'singles',
      'bracketType': 'single_elimination',
      'maxTeams': maxParticipants,
      'visibility': 'PUBLIC',
      'entryFee': ?entryFee,
      'divisions': [
        {
          'name': 'Nội dung chính',
          'matchType': 'SINGLES',
          'bracketType': 'SINGLE_ELIMINATION',
          'maxParticipants': maxParticipants,
        },
      ],
    },
  );
  final code = response.statusCode ?? 0;
  expect(code, inInclusiveRange(200, 299), reason: 'POST /tournaments/lite');
  final data = _payload(response.data);
  expect(data, isA<Map>(), reason: 'Tạo giải phải trả object');
  final map = Map<String, dynamic>.from(data as Map);
  final id = map['id'] as String;
  final divisionIds = map['divisionIds'] as List;
  var inviteCode = map['inviteCode']?.toString() ?? '';
  if (inviteCode.isEmpty) {
    final detail = await api.getTournament(token: token, tournamentId: id);
    inviteCode = detail['inviteCode']?.toString() ?? '';
  }
  expect(
    inviteCode,
    isNotEmpty,
    reason: 'Giải nhanh phải có inviteCode (tạo hoặc chi tiết giải)',
  );
  return _LiteInfo(
    tournamentId: id,
    divisionId: divisionIds.first as String,
    inviteCode: inviteCode,
  );
}

/// Đăng ký đơn qua `POST /tournaments/:id/register` (cùng body app gửi). Trả mã HTTP.
Future<int> _registerViaApi(
  String token,
  Object tournament,
  String teamName,
) async {
  final (id, divisionId) = switch (tournament) {
    CreatedTournament t => (t.tournamentId, t.divisionId),
    _LiteInfo t => (t.tournamentId, t.divisionId),
    _ => throw ArgumentError.value(tournament, 'tournament'),
  };
  final response = await _rawDio.post<Object?>(
    '/tournaments/$id/register',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
    data: {
      'teamName': teamName,
      'divisionId': divisionId,
      'rankingConsent': true,
    },
  );
  return response.statusCode ?? 0;
}

/// Tick ô đồng ý xếp hạng. Giải có xếp hạng bắt buộc đồng ý; Backend trả 400 nếu thiếu.
Future<void> _tickRankingConsent(WidgetTester tester) async {
  final tile = find.widgetWithText(
    CheckboxListTile,
    'Đồng ý hiển thị kết quả và điểm ELO trên bảng xếp hạng',
  );
  await pumpUntil(tester, tile);
  await tapCentered(tester, tile);
  await tester.pump();
  expect(
    tester.widget<CheckboxListTile>(tile).value,
    isTrue,
    reason: 'Ô đồng ý xếp hạng phải được tick trước khi gửi đăng ký',
  );
}

final Finder _blockedMessage = find.byWidgetPredicate(
  (w) =>
      w is Text &&
      RegExp(
        r'không có quyền|không đủ quyền|cần đăng nhập|vui lòng đăng nhập|đăng nhập để',
        caseSensitive: false,
      ).hasMatch(w.data ?? ''),
  description: 'Text báo thiếu quyền hoặc cần đăng nhập',
);

/// Giống `expectBlocked` nhưng chờ tối đa 20 giây cho màn tải xong (màn quản lý gọi API rồi mới biết bị 403).
/// Đạt khi route đã về `/login` hoặc `/home`, hoặc thấy chữ báo thiếu quyền.
Future<void> _expectBlockedPatient(
  WidgetTester tester,
  ProviderContainer container,
  String route,
) async {
  container.read(routerProvider).go(route);
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  bool blocked() {
    final path = currentPath(tester);
    return path == '/login' ||
        path == '/home' ||
        _blockedMessage.evaluate().isNotEmpty;
  }

  while (!blocked() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(
    blocked(),
    isTrue,
    reason:
        'Mở $route phải bị chặn (về /login, /home hoặc báo không có quyền) '
        'nhưng đang ở "${currentPath(tester)}" và không có chữ báo thiếu quyền',
  );
}
