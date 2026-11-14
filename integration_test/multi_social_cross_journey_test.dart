import 'dart:convert';

import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/actors.dart';
import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/social_journey.dart';

/// Chuỗi D (TC-MULTI-D-01..12): Social chéo tài khoản. Emulator Android + Backend thật.
/// Host = `admin1` (vai organizer), người chơi và người ngoài = hai tài khoản mới tạo riêng cho chuỗi.
/// Hành động của host làm qua API hoặc giao diện; người nhận kiểm trên giao diện của chính họ.
///
/// Ca đánh dấu `skip: true` có mã `BUG-...` trong tên: đỏ vì sản phẩm, giữ nguyên `expect`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final backend = BackendApi();
  final api = SocialApi(backend: backend);
  late E2eActor host;
  late E2eActor player;
  late E2eActor outsider;

  setUpAll(() async {
    await initializeAppForTests();
    final actors = await createActors(
      backend,
      chain: 'D',
      roles: const ['organizer', 'player', 'member'],
    );
    host = actors['organizer']!;
    player = actors['player']!;
    outsider = actors['member']!;
  });

  /// Buổi do host tạo, có phí, đã thêm [player] bằng API.
  Future<SeededSession> sessionWithPlayer(String tag, String name) async {
    final session = await api.createSession(
      token: host.token,
      title: '$tag $name',
      feePerSlot: 50000,
    );
    await api.addUser(host.token, session.id, player.userId);
    return session;
  }

  /// Thông báo ở cả hai scope Backend tách ra (app đọc cả hai).
  Future<List<Map<String, dynamic>>> allNotifications(String token) async => [
    for (final scope in const ['player', 'management'])
      ...await backend.listNotifications(token: token, scope: scope),
  ];

  /// Chờ tới khi Backend có thông báo nhắc tới buổi (id hoặc tiêu đề) cho [token]; null khi hết giờ.
  Future<Map<String, dynamic>?> sessionNotification(
    WidgetTester tester,
    String token,
    SeededSession session,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 45));
    while (DateTime.now().isBefore(deadline)) {
      final items = await allNotifications(token);
      for (final n in items) {
        final raw = jsonEncode(n);
        if (raw.contains(session.id) || raw.contains(session.title)) return n;
      }
      await socialWait(tester);
    }
    return null;
  }

  /// Host đánh dấu ĐÃ THU cho [userId] bằng API (cùng endpoint tab Thanh toán gọi).
  Future<int> markPaid(String sessionId, String userId) => backend.statusOf(
    'PATCH',
    '/social-sessions/$sessionId/participants/$userId/payment',
    token: host.token,
    data: {'paymentStatus': 'PAID'},
  );

  /// Trạng thái thanh toán của [userId] theo chi tiết buổi mà [token] nhìn thấy.
  Future<String> paymentOf(
    String token,
    String sessionId,
    String userId,
  ) async {
    final people = await api.participants(token, sessionId);
    final mine = people.where((p) => '${p['userId']}' == userId).toList();
    expect(mine, isNotEmpty, reason: 'chi tiết buổi phải có $userId: $people');
    return '${mine.first['paymentStatus'] ?? mine.first['payment_status'] ?? ''}'
        .toUpperCase();
  }

  /// Chạm chip trạng thái [chipLabel] ở dòng thanh toán của người tên [rowName] (chip gần chữ tên nhất).
  Future<void> tapChipOfRow(
    WidgetTester tester,
    String chipLabel,
    String rowName,
  ) async {
    final chips = find.text(chipLabel);
    final names = find.text(rowName);
    await pumpUntilFound(tester, names, what: 'dòng thanh toán của "$rowName"');
    await pumpUntilFound(tester, chips, what: 'chip "$chipLabel"');
    var bestIndex = 0;
    var bestDistance = double.infinity;
    final nameCenter = tester.getCenter(names.first);
    for (var i = 0; i < chips.evaluate().length; i++) {
      final distance = (tester.getCenter(chips.at(i)) - nameCenter).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    final target = chips.at(bestIndex);
    await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
    await tester.pump();
    await tester.tap(target);
    await tester.pump();
  }

  group('Host thêm tài khoản: người đó nhận thông báo và thấy kèo', () {
    testWidgets(
      'TC-MULTI-D-01 host thêm tài khoản bằng API: Backend ghi người chơi JOINED, host và người chơi cùng thấy',
      (tester) async {
        final tag = socialTag('MD1');
        final session = await sessionWithPlayer(tag, 'Host thêm người');

        for (final token in [host.token, player.token]) {
          final people = await api.participants(token, session.id);
          expect(
            people.any(
              (p) =>
                  '${p['userId']}' == player.userId &&
                  '${p['status']}'.toUpperCase() == 'JOINED',
            ),
            isTrue,
            reason:
                'mọi tài khoản trong buổi phải thấy người chơi JOINED: $people',
          );
        }
      },
    );

    testWidgets(
      'TC-MULTI-D-02 người chơi được thêm nhận thông báo nhắc tới kèo (Backend)',
      (tester) async {
        final tag = socialTag('MD2');
        final session = await sessionWithPlayer(tag, 'Thông báo API');

        final notification = await sessionNotification(
          tester,
          player.token,
          session,
        );
        expect(
          notification,
          isNotNull,
          reason:
              'host thêm người chơi vào buổi ${session.id} mà sau 45 giây người chơi vẫn không có thông báo nào nhắc tới buổi; '
              'thông báo hiện có: ${(await allNotifications(player.token)).map((n) => "${n['type']}:${n['title']}").toList()}',
        );
        expect(
          '${notification!['title'] ?? ''}'.isNotEmpty,
          isTrue,
          reason:
              'thông báo phải có tiêu đề để hiện trong /notifications: $notification',
        );
      },
    );

    testWidgets(
      'TC-MULTI-D-03 người chơi mở /notifications thấy thông báo về kèo đã được thêm',
      (tester) async {
        final tag = socialTag('MD3');
        final shooter = SocialShooter(tester, binding, 'TC-MULTI-D-03');
        final session = await sessionWithPlayer(tag, 'Thông báo UI');
        final notification = await sessionNotification(
          tester,
          player.token,
          session,
        );
        expect(
          notification,
          isNotNull,
          reason: 'Backend chưa có thông báo cho buổi ${session.id}',
        );
        final title = '${notification!['title']}';

        final container = await signInAs(tester, player);
        container.read(routerProvider).go('/notifications');
        await pumpUntil(
          tester,
          find.text(title),
          timeout: const Duration(seconds: 45),
        );
        await shooter.snap('thong-bao-cua-nguoi-choi');
        expect(find.text(title), findsWidgets);
        await leaveSocialSession(tester, container);
      },
    );

    testWidgets(
      'TC-MULTI-D-04 người chơi mở kèo: thấy "Đã tham gia", không có tab Thanh toán và nút của host',
      (tester) async {
        final tag = socialTag('MD4');
        final shooter = SocialShooter(tester, binding, 'TC-MULTI-D-04');
        final session = await sessionWithPlayer(tag, 'Người chơi thấy kèo');

        final container = await signInAs(tester, player);
        await openSession(tester, container, session);
        await pumpUntil(tester, find.text('Đã tham gia'));
        await shooter.snap('nguoi-choi-da-tham-gia');
        expect(find.text(session.title.toUpperCase()), findsWidgets);
        expect(
          find.text('Thanh toán'),
          findsNothing,
          reason: 'tab Thanh toán chỉ dành cho host',
        );
        expect(find.text('Tìm thêm người chơi'), findsNothing);
        expect(find.text('Yêu cầu tham gia'), findsNothing);
        await leaveSocialSession(tester, container);
      },
    );

    testWidgets(
      'TC-MULTI-D-05 host mở tab Người tham gia thấy tên tài khoản vừa thêm',
      (tester) async {
        final tag = socialTag('MD5');
        final shooter = SocialShooter(tester, binding, 'TC-MULTI-D-05');
        final session = await sessionWithPlayer(tag, 'Host thấy người');

        final container = await signInAs(tester, host);
        await openSession(tester, container, session);
        await openSocialTab(tester, 'Người tham gia');
        await pumpUntil(tester, find.text(player.fullName));
        await shooter.snap('host-thay-nguoi-choi');
        expect(find.textContaining('XÁC NHẬN THAM GIA • 2/'), findsOneWidget);
        await leaveSocialSession(tester, container);
      },
    );
  });

  group('Thanh toán: host đánh dấu ĐÃ THU, người chơi thấy', () {
    testWidgets(
      'TC-MULTI-D-06 host đánh dấu ĐÃ THU trên tab Thanh toán đúng dòng người chơi, Backend ghi PAID',
      (tester) async {
        final tag = socialTag('MD6');
        final shooter = SocialShooter(tester, binding, 'TC-MULTI-D-06');
        final session = await sessionWithPlayer(tag, 'Host đánh dấu thu');

        final container = await signInAs(tester, host);
        await openSession(tester, container, session);
        await openSocialTab(tester, 'Thanh toán');
        await pumpUntil(tester, find.text('TỔNG QUAN TÀI CHÍNH'));
        await shooter.snap('tab-thanh-toan-truoc-khi-thu');
        await tapChipOfRow(tester, 'CHƯA THU', player.fullName);
        await pumpUntil(
          tester,
          find.text('ĐÃ THU'),
          timeout: const Duration(seconds: 30),
        );
        await shooter.snap('da-thu-nguoi-choi');
        expect(
          await paymentOf(host.token, session.id, player.userId),
          'PAID',
          reason: 'Backend phải ghi PAID cho đúng người chơi vừa bấm',
        );
        await leaveSocialSession(tester, container);
      },
    );

    testWidgets(
      'TC-MULTI-D-07 sau khi host thu tiền, chi tiết buổi dưới tài khoản người chơi có paymentStatus PAID',
      (tester) async {
        final tag = socialTag('MD7');
        final session = await sessionWithPlayer(tag, 'Người chơi thấy PAID');
        expect(
          await paymentOf(player.token, session.id, player.userId),
          isNot('PAID'),
        );

        final status = await markPaid(session.id, player.userId);
        expect(
          status,
          inInclusiveRange(200, 299),
          reason: 'host đánh dấu thu phải 2xx',
        );
        expect(
          await paymentOf(player.token, session.id, player.userId),
          'PAID',
          reason: 'người chơi phải thấy mình đã thanh toán qua chi tiết buổi',
        );
      },
    );

    testWidgets(
      'TC-MULTI-D-08 BUG-SOCIAL-D-01 người chơi thấy trạng thái thanh toán của mình trên màn kèo',
      (tester) async {
        final tag = socialTag('MD8');
        final shooter = SocialShooter(tester, binding, 'TC-MULTI-D-08');
        final session = await sessionWithPlayer(tag, 'Người chơi xem thu');
        expect(
          await markPaid(session.id, player.userId),
          inInclusiveRange(200, 299),
        );

        final container = await signInAs(tester, player);
        await openSession(tester, container, session);
        await openSocialTab(tester, 'Người tham gia');
        await shooter.snap('nguoi-choi-sau-khi-da-thu');
        expect(
          find.textContaining(
            RegExp('ĐÃ THU|Đã thu|Đã thanh toán|ĐÃ THANH TOÁN'),
          ),
          findsWidgets,
          reason: 'màn kèo của người chơi phải cho biết mình đã thanh toán',
        );
        await leaveSocialSession(tester, container);
      },
      // lib/features/social: chỉ social_payment_tab.dart (tab của host) hiện trạng thái thanh toán;
      // tab Chi tiết và Người tham gia của người chơi không có chữ nào về thanh toán.
      skip: true,
    );
  });

  group('Báo cáo kèo và phân quyền âm', () {
    testWidgets(
      'TC-MULTI-D-09 người chơi báo cáo kèo: menu ⋮ chỉ có báo cáo, bấm báo cáo hiện lời cảm ơn',
      (tester) async {
        final tag = socialTag('MD9');
        final shooter = SocialShooter(tester, binding, 'TC-MULTI-D-09');
        final session = await sessionWithPlayer(tag, 'Người chơi báo cáo');

        final container = await signInAs(tester, player);
        await openSession(tester, container, session);
        await tapFinder(
          tester,
          find.byIcon(Icons.more_vert_rounded),
          what: 'nút ⋮ của người chơi',
        );
        await pumpUntil(tester, find.text('Báo cáo buổi Social này'));
        expect(find.text('Chỉnh sửa kèo'), findsNothing);
        expect(find.text('Hủy kèo'), findsNothing);
        await shooter.snap('menu-bao-cao');
        await tester.tap(find.text('Báo cáo buổi Social này'));
        await tester.pump();
        await pumpUntil(tester, find.text('Cảm ơn bạn đã gửi báo cáo.'));
        await shooter.snap('da-bao-cao');
        await leaveSocialSession(tester, container);
      },
    );

    testWidgets(
      'TC-MULTI-D-10 người ngoài không được thêm vào: thấy "Yêu cầu tham gia", không có thông báo kèo',
      (tester) async {
        final tag = socialTag('MD10');
        final shooter = SocialShooter(tester, binding, 'TC-MULTI-D-10');
        final session = await sessionWithPlayer(tag, 'Người ngoài');
        // Người chơi đã nhận thông báo thì Backend đã gửi xong; lúc đó người ngoài phải chưa có gì.
        expect(
          await sessionNotification(tester, player.token, session),
          isNotNull,
        );
        final leaked = await allNotifications(outsider.token);
        expect(
          leaked.any((n) {
            final raw = jsonEncode(n);
            return raw.contains(session.id) || raw.contains(session.title);
          }),
          isFalse,
          reason:
              'người ngoài không được nhận thông báo của buổi họ không tham gia',
        );

        final container = await signInAs(tester, outsider);
        await openSession(tester, container, session);
        await pumpUntil(tester, find.text('Yêu cầu tham gia'));
        await shooter.snap('nguoi-ngoai-chua-tham-gia');
        expect(find.text('Đã tham gia'), findsNothing);
        expect(find.text('Thanh toán'), findsNothing);
        await leaveSocialSession(tester, container);
      },
    );

    testWidgets(
      'TC-MULTI-D-11 phân quyền âm qua API: người chơi không sửa thu tiền, thêm người, huỷ buổi của host',
      (tester) async {
        final tag = socialTag('MD11');
        final session = await sessionWithPlayer(tag, 'Quyền API');
        final base = '/social-sessions/${session.id}';

        final pay = await backend.statusOf(
          'PATCH',
          '$base/participants/${player.userId}/payment',
          token: player.token,
          data: {'paymentStatus': 'PAID'},
        );
        final add = await backend.statusOf(
          'POST',
          '$base/participants',
          token: player.token,
          data: {'userId': outsider.userId, 'ticketCount': 1},
        );
        final cancel = await backend.statusOf(
          'PATCH',
          '$base/cancel',
          token: player.token,
        );

        expect(
          pay,
          anyOf(401, 403),
          reason: 'người chơi tự đánh dấu ĐÃ THU nhận HTTP $pay',
        );
        expect(
          add,
          anyOf(401, 403),
          reason: 'người chơi thêm người nhận HTTP $add',
        );
        expect(
          cancel,
          anyOf(401, 403),
          reason: 'người chơi huỷ buổi của host nhận HTTP $cancel',
        );
        final after = await api.getSession(host.token, session.id);
        expect(
          '${after['status']}'.toUpperCase(),
          'OPEN',
          reason: 'buổi phải còn mở',
        );
        expect(
          await paymentOf(host.token, session.id, player.userId),
          isNot('PAID'),
          reason: 'trạng thái thanh toán không được đổi bởi người chơi',
        );
      },
    );

    testWidgets(
      'TC-MULTI-D-12 người chơi trên giao diện không thấy nút của host ở tab Người tham gia',
      (tester) async {
        final tag = socialTag('MD12');
        final shooter = SocialShooter(tester, binding, 'TC-MULTI-D-12');
        final session = await sessionWithPlayer(tag, 'Quyền giao diện');

        final container = await signInAs(tester, player);
        await openSession(tester, container, session);
        await openSocialTab(tester, 'Người tham gia');
        await pumpUntil(tester, find.textContaining('XÁC NHẬN THAM GIA • 2/'));
        await shooter.snap('nguoi-choi-tab-nguoi-tham-gia');
        expect(
          find.text('Thêm người'),
          findsNothing,
          reason: 'nút Thêm người chỉ dành cho host',
        );
        expect(
          find.byIcon(Icons.close_rounded),
          findsNothing,
          reason: 'người chơi không xoá được ai',
        );
        expect(find.text('Thanh toán'), findsNothing);
        await leaveSocialSession(tester, container);
      },
    );
  });
}
