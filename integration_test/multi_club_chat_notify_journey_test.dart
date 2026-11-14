import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/actors.dart';
import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/social_journey.dart';

/// Chuỗi C (task 2.3): CLB, chat, thông báo, nhiều tài khoản (TC-MULTI-C-01..20).
/// Một emulator, Backend thật. Vai chính thao tác trên giao diện; vai phụ gọi API; ở điểm giao thì
/// đổi tài khoản bằng `signInAs`. Các ca dùng chung một CLB và chạy theo thứ tự trong file.
///
/// Vai: clubOwner (chủ CLB), member (xin vào, được duyệt), player (được mời, nhận lời),
/// referee (được mời, từ chối; sau đó xin vào rồi bị từ chối), viewer (người ngoài CLB).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final api = BackendApi();
  late Map<String, E2eActor> actors;
  late String clubId;
  late String clubName;

  E2eActor actor(String role) => actors[role]!;

  setUpAll(() async {
    await initializeAppForTests();
    actors = await createActors(
      api,
      chain: 'multic',
      roles: ['clubOwner', 'member', 'player', 'referee', 'viewer'],
    );
    clubName = socialTag('MultiC CLB');
    clubId = await api.createCommunity(
      token: actor('clubOwner').token,
      name: clubName,
    );
    // CLB mới ở trạng thái PENDING cho tới khi ADMIN duyệt.
    await api.approveCommunityAsAdmin(clubId);
  });

  SocialShooter shooterOf(WidgetTester tester, String code) =>
      SocialShooter(tester, binding, 'TC-MULTI-C-$code');

  testWidgets(
    'TC-MULTI-C-01 chủ CLB mở CLB đã duyệt: thấy nút Quản lý CLB, không có nút Tham gia',
    (tester) async {
      final shooter = shooterOf(tester, '01');
      final container = await signInAs(tester, actor('clubOwner'));
      await _openRoute(tester, container, '/club/$clubId');
      await pumpUntil(tester, find.text('Quản lý CLB'));
      await shooter.snap('chu-clb-mo-clb');
      expect(find.text('Quản lý CLB'), findsOneWidget);
      expect(
        find.text('Tham gia'),
        findsNothing,
        reason: 'chủ CLB đã là thành viên',
      );
      expect(
        find.byTooltip('Cài đặt'),
        findsOneWidget,
        reason: 'chủ CLB có nút Cài đặt trên thanh trên',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-02 thành viên xin vào CLB cần duyệt: báo đã gửi yêu cầu, nút chuyển thành Chờ phê duyệt',
    (tester) async {
      final shooter = shooterOf(tester, '02');
      final container = await signInAs(tester, actor('member'));
      await _openRoute(tester, container, '/club/$clubId');
      await pumpUntil(tester, find.text('Tham gia'));
      await shooter.snap('truoc-khi-xin-vao');
      await tapText(tester, 'Tham gia');
      await pumpUntil(
        tester,
        find.text(
          'Đã gửi yêu cầu tham gia. Vui lòng chờ Ban chủ nhiệm xét duyệt!',
        ),
        timeout: const Duration(seconds: 30),
      );
      await pumpUntil(tester, find.text('Chờ phê duyệt'));
      await shooter.snap('da-gui-yeu-cau');
      expect(find.text('Quản lý CLB'), findsNothing);
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-03 chủ CLB duyệt yêu cầu trên màn Điều phối: thấy đơn của thành viên và báo đã chấp nhận',
    (tester) async {
      final shooter = shooterOf(tester, '03');
      final container = await signInAs(tester, actor('clubOwner'));
      await _openRoute(tester, container, '/club/$clubId/manage', extra: true);
      await pumpUntil(tester, find.text('Điều phối Câu Lạc Bộ'));
      await pumpUntil(
        tester,
        find.text(actor('member').fullName),
        timeout: const Duration(seconds: 45),
      );
      expect(find.text('Đơn xin gia nhập (1)'), findsOneWidget);
      await shooter.snap('don-xin-gia-nhap');
      await tapText(tester, 'Duyệt');
      await pumpUntil(
        tester,
        find.text('Đã chấp nhận thành viên!'),
        timeout: const Duration(seconds: 30),
      );
      await shooter.snap('da-duyet');
      expect(
        find.text('Đơn xin gia nhập (1)'),
        findsNothing,
        reason: 'đơn đã duyệt không còn trong danh sách chờ',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-04 thành viên được duyệt nhận thông báo CLB chưa đọc trên màn Thông báo',
    (tester) async {
      final shooter = shooterOf(tester, '04');
      final approved = await _waitNotification(
        tester,
        api,
        actor('member').token,
        (n) => '${n['type']}'.toUpperCase().contains('JOIN_APPROVED'),
        what: 'thông báo được duyệt vào CLB của thành viên',
      );
      expect(
        approved['isRead'],
        isNot(true),
        reason: 'thông báo mới phải chưa đọc',
      );
      final container = await signInAs(tester, actor('member'));
      await _openRoute(tester, container, '/notifications');
      await pumpUntil(tester, find.text('${approved['title']}'));
      await shooter.snap('thong-bao-duoc-duyet');
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').startsWith('Chưa đọc ('),
        ),
        findsOneWidget,
        reason: 'chip Chưa đọc phải kèm số thông báo chưa đọc',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-05 phân quyền âm: thành viên thường không thấy nút Quản lý CLB và Cài đặt, có nút chat CLB',
    (tester) async {
      final shooter = shooterOf(tester, '05');
      final container = await signInAs(tester, actor('member'));
      await _openRoute(tester, container, '/club/$clubId');
      await pumpUntil(tester, find.text('Đã tham gia'));
      await shooter.snap('thanh-vien-thuong');
      expect(
        find.text('Quản lý CLB'),
        findsNothing,
        reason: 'chỉ chủ và quản trị CLB thấy nút Quản lý',
      );
      expect(
        find.byTooltip('Cài đặt'),
        findsNothing,
        reason: 'chỉ chủ và quản trị CLB thấy nút Cài đặt',
      );
      expect(
        find.byIcon(Icons.chat_bubble_outline),
        findsWidgets,
        reason: 'thành viên đã vào có nút chat CLB',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-06 chủ mời thành viên: người được mời nhận thông báo mời, bấm Chấp nhận thì thành viên CLB',
    (tester) async {
      final shooter = shooterOf(tester, '06');
      await api.inviteCommunityMember(
        token: actor('clubOwner').token,
        communityId: clubId,
        userId: actor('player').userId,
      );
      final invite = await _waitNotification(
        tester,
        api,
        actor('player').token,
        (n) => '${n['type']}'.toUpperCase().contains('INVITE'),
        what: 'thông báo lời mời CLB của người được mời',
      );
      final container = await signInAs(tester, actor('player'));
      await _openRoute(tester, container, '/notifications');
      await pumpUntil(tester, find.text('${invite['title']}'));
      await pumpUntil(tester, find.text('Chấp nhận'));
      expect(find.text('Từ chối'), findsOneWidget);
      await shooter.snap('thong-bao-loi-moi');
      await tapText(tester, 'Chấp nhận');
      await pumpUntil(
        tester,
        find.text('Đã chấp nhận lời mời!'),
        timeout: const Duration(seconds: 30),
      );
      await pumpUntil(tester, find.text('Đã phản hồi lời mời'));
      await shooter.snap('da-chap-nhan');
      await _openRoute(tester, container, '/club/$clubId');
      await pumpUntil(tester, find.text('Đã tham gia'));
      expect(
        find.text('Quản lý CLB'),
        findsNothing,
        reason: 'người được mời vào với vai thành viên thường',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-07 màn Lời mời CLB: người được mời thấy lời mời, bấm Từ chối thì báo đã từ chối',
    (tester) async {
      final shooter = shooterOf(tester, '07');
      await api.inviteCommunityMember(
        token: actor('clubOwner').token,
        communityId: clubId,
        userId: actor('referee').userId,
      );
      final container = await signInAs(tester, actor('referee'));
      await _openRoute(tester, container, '/club-invites');
      await pumpUntil(tester, find.text('Lời mời CLB'));
      await pumpUntil(
        tester,
        find.textContaining('Được mời bởi'),
        timeout: const Duration(seconds: 45),
      );
      expect(find.text(clubName), findsWidgets);
      await shooter.snap('man-loi-moi-clb');
      await tapText(tester, 'Từ chối');
      await pumpUntil(
        tester,
        find.text('Đã từ chối lời mời.'),
        timeout: const Duration(seconds: 30),
      );
      await shooter.snap('da-tu-choi-loi-moi');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-08 chat CLB: chủ gửi tin trên giao diện, thành viên mở chat CLB thấy tin đó',
    (tester) async {
      final shooter = shooterOf(tester, '08');
      final roomId = await _clubRoomId(
        tester,
        api,
        actor('clubOwner').token,
        clubId,
      );
      final message = socialTag('Chu-gui-');
      var container = await signInAs(tester, actor('clubOwner'));
      await _openChat(tester, container, roomId, clubName, clubId);
      await shooter.snap('chu-mo-chat-clb');
      await _sendChat(tester, message);
      await shooter.snap('chu-da-gui');

      container = await signInAs(tester, actor('member'));
      await _openChat(tester, container, roomId, clubName, clubId);
      await pumpUntil(
        tester,
        find.text(message),
        timeout: const Duration(seconds: 45),
      );
      await shooter.snap('thanh-vien-thay-tin-chu');
      expect(find.text(message), findsWidgets);
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-09 chat CLB hai chiều: thành viên gửi tin trả lời, chủ CLB mở chat thấy tin đó',
    (tester) async {
      final shooter = shooterOf(tester, '09');
      final roomId = await _clubRoomId(
        tester,
        api,
        actor('member').token,
        clubId,
      );
      final reply = socialTag('Thanh-vien-tra-loi-');
      var container = await signInAs(tester, actor('member'));
      await _openChat(tester, container, roomId, clubName, clubId);
      await _sendChat(tester, reply);
      await shooter.snap('thanh-vien-da-gui');

      container = await signInAs(tester, actor('clubOwner'));
      await _openChat(tester, container, roomId, clubName, clubId);
      await pumpUntil(
        tester,
        find.text(reply),
        timeout: const Duration(seconds: 45),
      );
      await shooter.snap('chu-thay-tin-tra-loi');
      expect(find.text(reply), findsWidgets);
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-10 danh sách chat: phòng CLB hiện tên CLB kèm nhãn CLB và tin mới nhất',
    (tester) async {
      final shooter = shooterOf(tester, '10');
      final room = await _clubRoomId(
        tester,
        api,
        actor('clubOwner').token,
        clubId,
      );
      expect(room, isNotEmpty);
      final container = await signInAs(tester, actor('clubOwner'));
      await _openRoute(tester, container, '/chat');
      await pumpUntil(
        tester,
        find.text(clubName),
        timeout: const Duration(seconds: 45),
      );
      await shooter.snap('danh-sach-chat');
      expect(find.text('CLB'), findsWidgets, reason: 'phòng CLB có nhãn CLB');
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').startsWith('Thanh-vien-tra-loi-'),
        ),
        findsWidgets,
        reason: 'dòng phụ của phòng CLB là tin mới nhất (tin trả lời của thành viên)',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-11 chat 1-1: thành viên nhắn chủ CLB qua API, chủ thấy trong danh sách chat, mở ra trả lời',
    (tester) async {
      final shooter = shooterOf(tester, '11');
      final member = actor('member');
      final owner = actor('clubOwner');
      final roomId = await api.createDirectRoom(
        token: member.token,
        otherUserId: owner.userId,
      );
      final hello = socialTag('Xin-chao-');
      await api.sendChatMessage(
        token: member.token,
        roomId: roomId,
        text: hello,
      );

      final container = await signInAs(tester, owner);
      await _openRoute(tester, container, '/chat');
      await pumpUntil(
        tester,
        find.text(member.fullName),
        timeout: const Duration(seconds: 45),
      );
      await pumpUntil(tester, find.text(hello));
      await shooter.snap('chu-thay-phong-1-1');
      await tester.tap(find.text(member.fullName).first);
      await tester.pump();
      await pumpUntil(
        tester,
        find.byType(TextField),
        timeout: const Duration(seconds: 30),
      );
      final answer = socialTag('Chao-lai-');
      await _sendChat(tester, answer);
      await shooter.snap('chu-da-tra-loi-1-1');
      final lastMessage = await _waitRoomLastMessage(
        tester,
        api,
        member.token,
        roomId,
        answer,
      );
      expect(
        lastMessage,
        answer,
        reason: 'thành viên phải nhận tin trả lời của chủ trong phòng 1-1',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-12 bấm một thông báo chưa đọc thì thông báo đó thành đã đọc ở Backend',
    (tester) async {
      final shooter = shooterOf(tester, '12');
      final target = await _waitNotification(
        tester,
        api,
        actor('member').token,
        (n) => '${n['type']}'.toUpperCase().contains('JOIN_APPROVED'),
        what: 'thông báo được duyệt của thành viên',
      );
      expect(
        target['isRead'],
        isNot(true),
        reason: 'tiền đề: chưa ai đọc thông báo này',
      );
      final container = await signInAs(tester, actor('member'));
      await _openRoute(tester, container, '/notifications');
      await pumpUntil(tester, find.text('${target['title']}'));
      await shooter.snap('truoc-khi-bam');
      await tester.tap(find.text('${target['title']}').first);
      await tester.pump();
      final read = await _waitNotification(
        tester,
        api,
        actor('member').token,
        (n) => n['id'] == target['id'] && n['isRead'] == true,
        what: 'thông báo được duyệt chuyển sang đã đọc',
      );
      expect(read['isRead'], isTrue);
      await shooter.snap('sau-khi-bam');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-13 Đọc tất cả: bấm nút thì mọi thông báo thành đã đọc và nút biến mất',
    (tester) async {
      final shooter = shooterOf(tester, '13');
      // Lời mời từ CLB thứ hai tạo thêm một thông báo chưa đọc cho thành viên.
      final secondClub = await api.createCommunity(
        token: actor('clubOwner').token,
        name: socialTag('MultiC CLB hai'),
      );
      await api.approveCommunityAsAdmin(secondClub);
      await api.inviteCommunityMember(
        token: actor('clubOwner').token,
        communityId: secondClub,
        userId: actor('member').userId,
      );
      await _waitNotification(
        tester,
        api,
        actor('member').token,
        (n) => n['isRead'] != true,
        what: 'một thông báo chưa đọc của thành viên',
      );
      final container = await signInAs(tester, actor('member'));
      await _openRoute(tester, container, '/notifications');
      await pumpUntil(tester, find.byTooltip('Đọc tất cả'));
      await shooter.snap('truoc-doc-tat-ca');
      await tester.tap(find.byTooltip('Đọc tất cả'));
      await tester.pump();
      await _waitUntilTrue(
        tester,
        () async =>
            (await api.listNotifications(token: actor('member').token))
                .every((n) => n['isRead'] == true),
        what: 'mọi thông báo của thành viên đã đọc ở Backend',
      );
      await socialWait(tester, const Duration(seconds: 2));
      expect(
        find.byTooltip('Đọc tất cả'),
        findsNothing,
        reason: 'hết thông báo chưa đọc thì ẩn nút Đọc tất cả',
      );
      await shooter.snap('sau-doc-tat-ca');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-14 bộ lọc Chưa đọc: sau Đọc tất cả báo đã đọc hết, bấm Xem tất cả thì thấy lại danh sách',
    (tester) async {
      final shooter = shooterOf(tester, '14');
      final container = await signInAs(tester, actor('member'));
      await _openRoute(tester, container, '/notifications');
      final chip = find.byWidgetPredicate(
        (w) => w is Text && (w.data ?? '').startsWith('Chưa đọc'),
      );
      await pumpUntil(tester, chip);
      await tester.tap(chip.first);
      await tester.pump();
      await pumpUntil(tester, find.text('Bạn đã đọc hết tất cả thông báo!'));
      await shooter.snap('loc-chua-doc-rong');
      await tapText(tester, 'Xem tất cả thông báo');
      await pumpUntil(
        tester,
        find.text('Hôm nay'),
        timeout: const Duration(seconds: 30),
      );
      expect(find.text('Bạn đã đọc hết tất cả thông báo!'), findsNothing);
      await shooter.snap('xem-tat-ca');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-15 thẻ lọc thông báo: Đội nhóm có thông báo CLB, Giải đấu không có',
    (tester) async {
      final shooter = shooterOf(tester, '15');
      final approved = await _waitNotification(
        tester,
        api,
        actor('member').token,
        (n) => '${n['type']}'.toUpperCase().contains('JOIN_APPROVED'),
        what: 'thông báo được duyệt của thành viên',
      );
      final title = '${approved['title']}';
      final container = await signInAs(tester, actor('member'));
      await _openRoute(tester, container, '/notifications');
      await pumpUntil(tester, find.text(title));
      await tapText(tester, 'Giải đấu');
      await socialWait(tester, const Duration(seconds: 1));
      expect(
        find.text(title),
        findsNothing,
        reason: 'thông báo CLB không thuộc thẻ Giải đấu',
      );
      await shooter.snap('the-giai-dau');
      await tapText(tester, 'Đội nhóm');
      await pumpUntil(tester, find.text(title));
      await shooter.snap('the-doi-nhom');
      expect(find.text(title), findsWidgets);
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-16 phân quyền âm qua API: thành viên thường không duyệt đơn, không mời, người ngoài không nhắn vào chat CLB',
    (tester) async {
      final roomId = await _clubRoomId(
        tester,
        api,
        actor('clubOwner').token,
        clubId,
      );
      final memberToken = actor('member').token;
      final reviewCode = await api.statusOf(
        'PATCH',
        '/communities/$clubId/join-requests/${actor('viewer').userId}',
        token: memberToken,
        data: {'action': 'APPROVE'},
      );
      expect(
        reviewCode,
        anyOf(401, 403),
        reason: 'thành viên thường duyệt đơn phải bị từ chối, nhận $reviewCode',
      );
      final inviteCode = await api.statusOf(
        'POST',
        '/communities/$clubId/invite',
        token: memberToken,
        data: {'userId': actor('viewer').userId, 'role': 'MEMBER'},
      );
      expect(
        inviteCode,
        anyOf(401, 403),
        reason:
            'thành viên thường mời người khác phải bị từ chối, nhận $inviteCode',
      );
      final outsiderSend = await api.statusOf(
        'POST',
        '/chat/messages',
        token: actor('viewer').token,
        data: {'roomId': roomId, 'messageText': 'người ngoài thử nhắn'},
      );
      expect(
        outsiderSend,
        allOf(greaterThanOrEqualTo(400), lessThan(500)),
        reason:
            'người ngoài CLB nhắn vào chat CLB phải bị từ chối, nhận $outsiderSend',
      );
    },
  );

  testWidgets(
    'TC-MULTI-C-17 phân quyền âm trên giao diện: thành viên thường mở thẳng /club/:id/manage phải bị chặn',
    (tester) async {
      final shooter = shooterOf(tester, '17');
      final container = await signInAs(tester, actor('member'));
      await expectBlocked(tester, '/club/$clubId/manage');
      await shooter.snap('thanh-vien-mo-manage');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-18 phân quyền âm: người ngoài CLB thấy nút Tham gia, không thấy Quản lý CLB, Đã tham gia, chat CLB',
    (tester) async {
      final shooter = shooterOf(tester, '18');
      final container = await signInAs(tester, actor('viewer'));
      await _openRoute(tester, container, '/club/$clubId');
      await pumpUntil(tester, find.text('Tham gia'));
      await shooter.snap('nguoi-ngoai-xem-clb');
      expect(find.text('Quản lý CLB'), findsNothing);
      expect(find.text('Đã tham gia'), findsNothing);
      expect(find.byTooltip('Cài đặt'), findsNothing);
      expect(
        find.byIcon(Icons.chat_bubble_outline),
        findsNothing,
        reason: 'chỉ thành viên đã vào mới có nút chat CLB',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-C-19 chủ CLB từ chối đơn xin vào: người xin nhận thông báo bị từ chối',
    (tester) async {
      final shooter = shooterOf(tester, '19');
      final referee = actor('referee');
      await api.joinCommunity(token: referee.token, communityId: clubId);
      final container = await signInAs(tester, actor('clubOwner'));
      await _openRoute(tester, container, '/club/$clubId/manage', extra: true);
      await pumpUntil(
        tester,
        find.text(referee.fullName),
        timeout: const Duration(seconds: 45),
      );
      await shooter.snap('don-cua-nguoi-xin');
      await tapText(tester, 'Từ chối');
      await pumpUntil(
        tester,
        find.text('Đã từ chối đơn gia nhập.'),
        timeout: const Duration(seconds: 30),
      );
      await shooter.snap('da-tu-choi-don');
      await leaveSocialSession(tester, container);
      final rejected = await _waitNotification(
        tester,
        api,
        referee.token,
        (n) => '${n['type']}'.toUpperCase().contains('JOIN_REJECTED'),
        what: 'thông báo bị từ chối vào CLB của người xin',
      );
      expect('${rejected['type']}'.toUpperCase(), contains('REJECTED'));
    },
  );

  // BUG-CHAT-01: nếu đỏ vì lỗi sản phẩm thì thêm
  // skip: 'BUG-CHAT-01: ChatDetailScreen gọi setState sau dispose khi socket đóng'.
  testWidgets(
    'TC-MULTI-C-20 thoát màn chat khi socket đóng: không ném lỗi setState sau dispose (BUG-CHAT-01)',
    (tester) async {
      final shooter = shooterOf(tester, '20');
      final roomId = await _clubRoomId(
        tester,
        api,
        actor('member').token,
        clubId,
      );
      final container = await signInAs(tester, actor('member'));
      await _openChat(tester, container, roomId, clubName, clubId);
      await shooter.snap('dang-trong-chat');
      // Rời màn chat: socket đóng và gọi onConnection(false) sau khi State đã dispose.
      container.read(routerProvider).go('/home');
      await socialWait(tester, const Duration(seconds: 4));
      final error = tester.takeException();
      drainKnownProductErrors(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      drainKnownProductErrors(tester);
      container.dispose();
      expect(
        error,
        isNull,
        reason: 'thoát màn chat không được ném lỗi: $error',
      );
    },
  );
}

/// Về trang chủ rồi đẩy [route] lên trên (nút back có trang bên dưới để pop), chờ route đổi.
Future<void> _openRoute(
  WidgetTester tester,
  ProviderContainer container,
  String route, {
  Object? extra,
}) async {
  final router = container.read(routerProvider);
  router.go('/home');
  await socialWait(tester, const Duration(seconds: 1));
  router.push(route, extra: extra);
  await pumpUntilCondition(
    tester,
    () => currentPath(tester) == Uri.parse(route).path,
    what: 'route $route',
    timeout: const Duration(seconds: 30),
  );
}

/// Mở chat phòng [roomId] như khi bấm nút chat CLB (`/chat/:id?...&type=CLUB`), chờ ô nhập hiện ra.
Future<void> _openChat(
  WidgetTester tester,
  ProviderContainer container,
  String roomId,
  String clubName,
  String clubId,
) async {
  final router = container.read(routerProvider);
  router.go('/home');
  await socialWait(tester, const Duration(seconds: 1));
  final name = Uri.encodeComponent(clubName);
  router.push('/chat/$roomId?name=$name&type=CLUB&communityId=$clubId');
  await pumpUntil(
    tester,
    find.byType(TextField),
    timeout: const Duration(seconds: 45),
  );
  await socialWait(tester, const Duration(seconds: 2));
}

/// Gõ [text] vào ô nhập của chat đang mở, bấm Gửi, chờ tin hiện trong khung chat.
Future<void> _sendChat(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).first, text);
  await tester.pump();
  await tapFinder(tester, find.byIcon(Icons.send_rounded), what: 'nút Gửi');
  await pumpUntil(
    tester,
    find.text(text),
    timeout: const Duration(seconds: 30),
  );
}

/// Chờ [probe] đúng, thăm dò Backend mỗi giây (không dùng Future.delayed cố định).
Future<void> _waitUntilTrue(
  WidgetTester tester,
  Future<bool> Function() probe, {
  required String what,
  Duration timeout = const Duration(seconds: 45),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await probe()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Hết ${timeout.inSeconds}s mà chưa thấy: $what');
    }
    await socialWait(tester);
  }
}

/// Chờ một thông báo thoả [test] trong `GET /notifications` của [token], trả thông báo đó.
Future<Map<String, dynamic>> _waitNotification(
  WidgetTester tester,
  BackendApi api,
  String token,
  bool Function(Map<String, dynamic> notification) test, {
  required String what,
}) async {
  Map<String, dynamic>? found;
  await _waitUntilTrue(tester, () async {
    final list = await api.listNotifications(token: token);
    final hits = list.where(test);
    found = hits.isEmpty ? null : hits.first;
    return found != null;
  }, what: what);
  return found!;
}

/// Id phòng chat CLB của [communityId], thăm dò `GET /chat/rooms` tới khi có.
Future<String> _clubRoomId(
  WidgetTester tester,
  BackendApi api,
  String token,
  String communityId,
) async {
  String? roomId;
  await _waitUntilTrue(tester, () async {
    final rooms = await api.listChatRooms(token: token);
    final hits = rooms.where((r) => '${r['communityId']}' == communityId);
    roomId = hits.isEmpty ? null : '${hits.first['id']}';
    return roomId != null;
  }, what: 'phòng chat của CLB $communityId trong GET /chat/rooms');
  return roomId!;
}

/// Chờ tin mới nhất của phòng [roomId] (theo `GET /chat/rooms` của [token]) đúng bằng [expected].
Future<String> _waitRoomLastMessage(
  WidgetTester tester,
  BackendApi api,
  String token,
  String roomId,
  String expected,
) async {
  var last = '';
  await _waitUntilTrue(tester, () async {
    final rooms = await api.listChatRooms(token: token);
    final room = rooms.where((r) => '${r['id']}' == roomId);
    final message = room.isEmpty ? null : room.first['lastMessage'];
    last = message is Map
        ? '${message['messageText'] ?? message['content'] ?? ''}'
        : '';
    return last == expected;
  }, what: 'tin mới nhất của phòng $roomId là "$expected"');
  return last;
}
