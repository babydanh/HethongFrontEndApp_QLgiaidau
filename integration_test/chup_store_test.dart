import 'dart:ui' as ui;

import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/organizer_journey.dart';
import 'support/shot.dart';
import 'support/social_journey.dart';

/// Store screenshots (App Store / Google Play): pickleball scoring desk and a
/// social session, filled with readable fake names. Emulator + real Backend.
/// Not a regression test: a missing step logs `CHUP-LOI` and the run goes on.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final api = BackendApi();
  final stamp = DateTime.now().millisecondsSinceEpoch;

  setUpAll(initializeAppForTests);

  Future<void> step(String what, Future<void> Function() run) async {
    try {
      await run();
    } catch (error) {
      debugPrintSynchronously('CHUP-LOI $what: $error');
    }
  }

  testWidgets('chụp màn bấm điểm pickleball đôi', (tester) async {
    final token = await api.login(kOrganizerEmail, kE2ePassword);
    final created = await api.createLiteTournament(
      token: token,
      name: 'Pickleball Mở Rộng Sài Gòn 2026',
      matchType: 'DOUBLES',
      maxParticipants: 8,
    );
    await api.approveTournamentAsAdmin(created.tournamentId);
    await _importTeams(token, created.tournamentId, created.divisionId, stamp);
    await api.generateBracket(
      token: token,
      tournamentId: created.tournamentId,
      divisionId: created.divisionId,
    );
    await step(
      'khai mạc',
      () =>
          api.startTournament(token: token, tournamentId: created.tournamentId),
    );
    final matches = await api.listMatches(
      token: token,
      tournamentId: created.tournamentId,
      divisionId: created.divisionId,
    );
    final match = matches.firstWhere(
      (m) => m['participant1Id'] != null && m['participant2Id'] != null,
    );
    final matchId = match['id'] as String;
    await api.startMatch(token: token, matchId: matchId);

    final shooter = _StoreShooter(tester, 'store-pb');
    final container = await signInAsOrganizer(tester);
    container
        .read(routerProvider)
        .go(
          '/organizer/tournaments/${created.tournamentId}/ops/match/$matchId',
        );
    await socialWait(tester, const Duration(seconds: 6));
    await shooter.snap('xem-tran');
    await step('mở bảng điểm', () async {
      await tapFinder(tester, find.byTooltip('MỞ BẢNG'), what: 'nút MỞ BẢNG');
      await socialWait(tester, const Duration(seconds: 3));
      await shooter.snap('ban-diem-dau');
    });

    // Rally a few points: "+" of the serving team scores, of the receiver is a side-out.
    for (final team in [1, 1, 2, 2, 1, 1, 1, 2, 1, 1]) {
      await step('cộng điểm đội $team', () async {
        final plus = find.byTooltip('Cộng điểm đội $team');
        if (plus.evaluate().isEmpty) {
          throw StateError('không thấy nút + đội $team');
        }
        await tester.tap(plus.first);
        await socialWait(tester, const Duration(milliseconds: 900));
      });
    }
    await socialWait(tester, const Duration(seconds: 2));
    await shooter.snap('ban-diem-giua-van');
  });

  testWidgets('chụp buổi giao lưu social', (tester) async {
    final shooter = _StoreShooter(tester, 'store-social');
    final social = SocialApi();
    final hostEmail = 'store$stamp-host@example.com';
    await api.registerAccount(
      email: hostEmail,
      password: kE2ePassword,
      fullName: 'Nguyễn Hoàng Long',
    );
    final hostToken = await social.login(hostEmail);
    final session = await social.createSession(
      token: hostToken,
      title: 'Giao lưu Pickleball tối thứ Bảy',
      maxSlots: 8,
      startAt: DateTime.now().add(const Duration(days: 1)),
      description:
          'Đánh đôi xoay vòng, mọi trình độ. Mang theo vợt, sân có sẵn bóng.',
    );
    const guests = [
      'Trần Minh Anh',
      'Lê Hoàng Nam',
      'Phạm Thu Hà',
      'Võ Đức Huy',
      'Ngô Bảo Ngọc',
    ];
    final guestTokens = <String>[];
    for (var i = 0; i < guests.length; i++) {
      await step('khách ${guests[i]}', () async {
        final email = 'store$stamp-g$i@example.com';
        final id = await api.registerAccount(
          email: email,
          password: kE2ePassword,
          fullName: guests[i],
        );
        await social.addUser(hostToken, session.id, id);
        guestTokens.add(await social.login(email));
      });
    }
    const chat = [
      'Tối nay mấy giờ có mặt vậy mọi người?',
      'Mình tới lúc 18h45 nhé',
      'Ok, gặp ở sân số 2!',
    ];
    for (var i = 0; i < chat.length && i < guestTokens.length; i++) {
      await step(
        'tin nhắn $i',
        () => social.sendMessage(guestTokens[i], session.id, chat[i]),
      );
    }

    await step(
      'host nhắn',
      () => social.sendMessage(
        hostToken,
        session.id,
        'Sân đã đặt xong, 19h bắt đầu nha!',
      ),
    );

    final container = await signInAs(tester, email: hostEmail);
    await openSession(tester, container, session);
    await socialWait(tester, const Duration(seconds: 3));
    await shooter.snap('chi-tiet');
    for (final tab in ['Người tham gia', 'Trận đấu', 'Trò chuyện']) {
      await step('tab $tab', () async {
        await openSocialTab(tester, tab);
        await socialWait(tester, const Duration(seconds: 2));
        await shooter.snap('tab-${tab.toLowerCase().replaceAll(' ', '-')}');
      });
    }
    await step('khám phá', () async {
      container.read(routerProvider).go('/home');
      await socialWait(tester, const Duration(seconds: 2));
      final navExplore = find.descendant(
        of: find.byType(FloatingBottomNav),
        matching: find.text('Khám phá'),
      );
      await tapFinder(tester, navExplore, what: 'Khám phá');
      await socialWait(tester, const Duration(seconds: 4));
      await shooter.snap('kham-pha');
    });
  });
}

/// Four doubles teams with readable fake names (emails are fake `@example.com`).
Future<void> _importTeams(
  String token,
  String tournamentId,
  String divisionId,
  int stamp,
) async {
  const teams = [
    ('Sài Gòn Smash', 'Nguyễn Văn Khoa', 'Trần Quốc Bảo'),
    ('Dink Masters', 'Lê Minh Tâm', 'Phạm Gia Huy'),
    ('Kitchen Kings', 'Hoàng Anh Tuấn', 'Đỗ Thành Long'),
    ('Quận 7 Pickle', 'Bùi Đức Thịnh', 'Vũ Hải Đăng'),
  ];
  final dio = Dio(
    BaseOptions(
      baseUrl: kE2eApiBaseUrl,
      contentType: Headers.jsonContentType,
      headers: {'Authorization': 'Bearer $token'},
    ),
  );
  await dio.post<Object?>(
    '/tournaments/$tournamentId/roster-import',
    data: {
      'divisionId': divisionId,
      'participants': [
        for (var i = 0; i < teams.length; i++)
          {
            'teamName': teams[i].$1,
            'player1Name': teams[i].$2,
            'player1Email': 'store$stamp-t${i}a@example.com',
            'player2Name': teams[i].$3,
            'player2Email': 'store$stamp-t${i}b@example.com',
            'source': 'MANUAL_EMAIL',
            'autoApprove': true,
            'isPaid': true,
          },
      ],
    },
  );
}

/// iPhone 6.9" store size (1320 x 2868 at 3x = 440 x 956 logical).
const _storeSize = Size(1320, 2868);

/// Renders the whole view (routes, sheets, overlays) off-screen at the store size,
/// independent of the small CI emulator surface, and prints it like `shot()`.
class _StoreShooter {
  _StoreShooter(this.tester, this.prefix) {
    tester.view.physicalSize = _storeSize;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  final WidgetTester tester;
  final String prefix;
  int _count = 0;

  Future<void> snap(String name) async {
    await tester.pump();
    final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
    final image = await layer.toImage(Offset.zero & _storeSize);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final bytes = data!.buffer.asUint8List();
    _count++;
    final shotName = '$prefix-${_count.toString().padLeft(2, '0')}-$name';
    debugPrintSynchronously('[[SHOT-BEGIN $shotName ${bytes.length}]]');
    final chunks = chunkBase64(bytes, size: 4000);
    for (var i = 0; i < chunks.length; i++) {
      debugPrintSynchronously('[[SHOT $shotName $i]] ${chunks[i]}');
    }
    debugPrintSynchronously('[[SHOT-END $shotName]]');
  }
}
