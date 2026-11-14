import 'dart:convert';

import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/actors.dart';
import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/organizer_journey.dart';
import 'support/social_journey.dart';

/// TC-MULTI-F-01..15: chuỗi giải, màn vận hành `/ops` và giải Lite, nhiều tài khoản (App + Backend thật).
/// Vai chính thao tác trên giao diện; vai phụ (VĐV, đồng BTC, người nhận lời mời) hành động qua API
/// hoặc đăng nhập riêng ở điểm giao.
///
/// Lời mời nhân sự CHUỖI giải: lib/ không có màn hay route nào (không có `invitations` trong lib/features/series),
/// nên F-05/F-06 gọi route đoán của BackendApi và chỉ khẳng định mã HTTP. 404 thì đó là phát hiện, không đoán tiếp.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final api = BackendApi();
  final raw = _RawApi();

  late Map<String, E2eActor> actors;
  late String tag;
  late _LiteSeed opsT; // đơn, 4 VĐV: màn /ops
  late _LiteSeed joinT; // đơn, trống: VĐV vào bằng mã
  late _LiteSeed pairT; // đôi, 4 VĐV lẻ chờ ghép: ghép cặp
  late String organizerId;

  E2eActor actor(String role) => actors[role]!;
  String orgToken() => actor('organizer').token;

  setUpAll(() async {
    await initializeAppForTests();
    actors = await createActors(
      api,
      chain: 'F',
      roles: ['organizer', 'player', 'referee', 'coOrganizer', 'viewer'],
    );
    tag = 'E2E${DateTime.now().millisecondsSinceEpoch % 100000000}F';
    organizerId = '${(await SocialApi().profile(orgToken()))['id']}';
    opsT = await _seedLite(api, orgToken(), '$tag Ops', 'SINGLES', roster: 4);
    joinT = await _seedLite(api, orgToken(), '$tag Vao', 'SINGLES');
    pairT = await _seedLite(api, orgToken(), '$tag Doi', 'DOUBLES');
    await _importSolo(raw, orgToken(), pairT, '$tag Le', 4);
  });

  // ───────────────────────── Chuỗi giải (UI của BTC) ─────────────────────────

  testWidgets(
    'TC-MULTI-F-01 BTC tạo chuỗi giải trên form, danh sách và Backend có chuỗi đúng tên',
    (tester) async {
      _tolerateProductLayoutErrors();
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-F-01');
      final name = '$tag Chuoi tao UI';
      final container = await signInAs(tester, actor('organizer'));

      container.read(routerProvider).go('/organizer/series');
      await tapKey(tester, 'series-add', step: 'nút + của Chuỗi giải của tôi');
      await pumpUntil(tester, find.byKey(const ValueKey('series-form-name')));
      await shooter.snap('form-tao-chuoi');
      await tester.enterText(_seriesNameField(), name);
      await tester.pump();
      await tapKey(tester, 'series-form-submit');

      await pumpUntil(
        tester,
        find.text(name),
        timeout: const Duration(seconds: 45),
      );
      await shooter.snap('danh-sach-co-chuoi-moi');
      final mine = await _mySeries(raw, orgToken(), organizerId);
      expect(
        mine.any((s) => s['name'] == name),
        isTrue,
        reason: 'GET /series?organizerId phải có chuỗi "$name"',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-F-02 BTC sửa tên chuỗi giải, danh sách và Backend đổi theo',
    (tester) async {
      _tolerateProductLayoutErrors();
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-F-02');
      final oldName = '$tag Chuoi cu';
      final newName = '$tag Chuoi moi';
      final id = await api.createSeries(token: orgToken(), name: oldName);
      final container = await signInAs(tester, actor('organizer'));

      container.read(routerProvider).go('/organizer/series');
      await pumpUntil(
        tester,
        find.text(oldName),
        timeout: const Duration(seconds: 45),
      );
      await tapKey(tester, 'series-edit-$id');
      await pumpUntil(tester, find.byKey(const ValueKey('series-form-name')));
      await shooter.snap('form-sua-chuoi');
      await tester.enterText(_seriesNameField(), newName);
      await tester.pump();
      await tapKey(tester, 'series-form-submit');

      await pumpUntil(
        tester,
        find.text(newName),
        timeout: const Duration(seconds: 45),
      );
      expect(
        find.text(oldName),
        findsNothing,
        reason: 'Tên cũ không còn trong danh sách sau khi sửa',
      );
      await shooter.snap('danh-sach-ten-moi');
      final detail = await raw.get('/series/$id', token: orgToken());
      expect(detail.statusCode, 200, reason: 'GET /series/$id');
      expect(
        jsonEncode(detail.data),
        contains(newName),
        reason: 'Backend phải trả tên mới',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-F-03 BTC xóa chuỗi giải: hộp xác nhận, dòng biến mất, Backend không còn chuỗi',
    (tester) async {
      _tolerateProductLayoutErrors();
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-F-03');
      final name = '$tag Chuoi xoa';
      final id = await api.createSeries(token: orgToken(), name: name);
      final container = await signInAs(tester, actor('organizer'));

      container.read(routerProvider).go('/organizer/series');
      await pumpUntil(
        tester,
        find.text(name),
        timeout: const Duration(seconds: 45),
      );
      await tapKey(tester, 'series-delete-$id');
      await pumpUntil(
        tester,
        find.byKey(const ValueKey('series-delete-confirm')),
      );
      await shooter.snap('hop-xac-nhan-xoa');
      await tapKey(tester, 'series-delete-confirm');

      await pumpUntilCondition(
        tester,
        () => find.text(name).evaluate().isEmpty,
        what: 'chuỗi "$name" biến mất khỏi danh sách sau khi xóa',
        timeout: const Duration(seconds: 45),
      );
      await shooter.snap('da-xoa');
      final mine = await _mySeries(raw, orgToken(), organizerId);
      expect(
        mine.any((s) => s['id'] == id),
        isFalse,
        reason: 'Backend không còn chuỗi $id trong danh sách của BTC',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-F-04 BTC mở Quản lý vòng của chuỗi từ danh sách: thấy chuỗi chưa có vòng và nút Thêm vòng',
    (tester) async {
      _tolerateProductLayoutErrors();
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-F-04');
      final name = '$tag Chuoi vong';
      final id = await api.createSeries(token: orgToken(), name: name);
      final container = await signInAs(tester, actor('organizer'));

      container.read(routerProvider).go('/organizer/series');
      await pumpUntil(
        tester,
        find.text(name),
        timeout: const Duration(seconds: 45),
      );
      await tapKey(tester, 'series-row-$id');
      await pumpUntil(
        tester,
        find.text('Chuỗi chưa có vòng nào.'),
        timeout: const Duration(seconds: 45),
      );
      await expectKey(tester, 'series-legs-add', step: 'nút Thêm vòng');
      expect(currentPath(tester), '/organizer/series/$id/manage');
      await shooter.snap('quan-ly-vong-trong');
      await leaveSocialSession(tester, container);
    },
  );

  // ─────────────── Mời nhân sự chuỗi (route đoán, không có UI trong app) ───────────────

  String? invitationId;

  testWidgets(
    'TC-MULTI-F-05 BTC mời nhân sự chuỗi giải theo email: Backend nhận lời mời',
    (tester) async {
      final seriesId = await api.createSeries(
        token: orgToken(),
        name: '$tag Chuoi nhan su',
      );
      final res = await raw.send(
        'POST',
        '/organizer/series/$seriesId/invitations',
        token: orgToken(),
        data: {'email': actor('referee').email},
      );
      expect(
        res.statusCode,
        inInclusiveRange(200, 299),
        reason:
            'POST /organizer/series/:id/invitations [ĐOÁN] trả ${res.statusCode}: ${_snip(res.data)}',
      );
      invitationId = _idOf(res.data);
      expect(
        invitationId,
        isNotNull,
        reason: 'Lời mời phải có id: ${_snip(res.data)}',
      );
    },
  );

  testWidgets(
    'TC-MULTI-F-06 người nhận lời mời chuỗi chấp nhận qua API, người ngoài không chấp nhận được',
    (tester) async {
      final id = invitationId;
      expect(id, isNotNull, reason: 'Cần F-05 tạo được lời mời trước');
      final outsider = await raw.send(
        'POST',
        '/organizer/series/invitations/$id/accept',
        token: actor('viewer').token,
      );
      expect(
        outsider.statusCode,
        isNot(inInclusiveRange(200, 299)),
        reason:
            'Người không được mời không được chấp nhận lời mời (trả ${outsider.statusCode})',
      );
      final accepted = await raw.send(
        'POST',
        '/organizer/series/invitations/$id/accept',
        token: actor('referee').token,
      );
      expect(
        accepted.statusCode,
        inInclusiveRange(200, 299),
        reason:
            'Người được mời chấp nhận trả ${accepted.statusCode}: ${_snip(accepted.data)}',
      );
    },
  );

  // ───────────────────────── Màn vận hành /ops ─────────────────────────

  testWidgets(
    'TC-MULTI-F-07 BTC mở /ops của giải: thấy danh sách VĐV đã nhập và nút Thêm VĐV',
    (tester) async {
      _tolerateProductLayoutErrors();
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-F-07');
      final container = await signInAs(tester, actor('organizer'));

      await _openOpsRoster(tester, container, opsT.id);
      await shooter.snap('ops-danh-sach-tham-gia');
      for (var i = 1; i <= 4; i++) {
        expect(
          find.textContaining('${opsT.tag} VDV $i'),
          findsWidgets,
          reason: 'Danh sách phải có VĐV $i',
        );
      }
      expect(
        find.byKey(const ValueKey('organizer-ops-add-athlete')),
        findsOneWidget,
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-F-08 VĐV mới nhập qua API hiện trong /ops sau khi BTC bấm Làm mới',
    (tester) async {
      _tolerateProductLayoutErrors();
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-F-08');
      final container = await signInAs(tester, actor('organizer'));
      await _openOpsRoster(tester, container, opsT.id);
      final newTag = '${opsT.tag}N';
      expect(
        find.textContaining('$newTag VDV 1'),
        findsNothing,
        reason: 'Trước khi nhập chưa có VĐV mới',
      );

      await api.importRoster(
        token: orgToken(),
        tournamentId: opsT.id,
        divisionId: opsT.divisionId,
        tag: newTag,
        count: 1,
        singles: true,
      );
      await tapFinder(
        tester,
        find.byTooltip('Làm mới'),
        what: 'nút Làm mới của /ops',
      );
      await pumpUntil(
        tester,
        find.textContaining('$newTag VDV 1'),
        timeout: const Duration(seconds: 45),
      );
      await shooter.snap('ops-thay-vdv-moi');
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-F-09 đồng BTC được BTC thêm vào giải thấy đủ nút quản lý ở /ops',
    (tester) async {
      _tolerateProductLayoutErrors();
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-F-09');
      await api.addStaff(
        token: orgToken(),
        tournamentId: opsT.id,
        email: actor('coOrganizer').email,
        role: 'CO_ORGANIZER',
      );
      final container = await signInAs(tester, actor('coOrganizer'));

      await _openOpsRoster(tester, container, opsT.id);
      await shooter.snap('dong-btc-thay-ops');
      expect(
        find.byKey(const ValueKey('organizer-ops-add-athlete')),
        findsOneWidget,
      );
      await leaveSocialSession(tester, container);
    },
  );

  // ───────────────────────── Phân quyền âm ─────────────────────────

  testWidgets(
    'TC-MULTI-F-10 [phân quyền âm] VĐV mở /ops của giải người khác: không có nút Thêm VĐV',
    (tester) async {
      _tolerateProductLayoutErrors();
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-F-10');
      final container = await signInAs(tester, actor('player'));

      container
          .read(routerProvider)
          .go('/organizer/tournaments/${opsT.id}/ops');
      final tab = find.widgetWithText(ChoiceChip, 'Danh sách tham gia');
      await pumpUntil(tester, tab, timeout: const Duration(seconds: 45));
      await tapCentered(tester, tab);
      await socialWait(tester, const Duration(seconds: 5));
      await shooter.snap('vdv-o-ops-roster');
      expect(
        find.byKey(const ValueKey('organizer-ops-add-athlete')),
        findsNothing,
        reason: 'VĐV không phải BTC không được thấy nút Thêm VĐV',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-F-11 [phân quyền âm] người dùng thường không thấy nút quản lý chuỗi ở /series, BTC thấy',
    (tester) async {
      _tolerateProductLayoutErrors();
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-F-11');
      const tooltip = 'Quản lý chuỗi giải của tôi';

      var container = await signInAs(tester, actor('organizer'));
      container.read(routerProvider).go('/series');
      await pumpUntil(
        tester,
        find.byTooltip(tooltip),
        timeout: const Duration(seconds: 45),
      );
      await shooter.snap('btc-thay-nut-quan-ly-chuoi');
      await leaveSocialSession(tester, container);

      container = await signInAs(tester, actor('viewer'));
      container.read(routerProvider).go('/series');
      await pumpUntil(
        tester,
        find.text('Chuỗi giải đấu'),
        timeout: const Duration(seconds: 30),
      );
      await socialWait(tester, const Duration(seconds: 4));
      await shooter.snap('nguoi-thuong-khong-co-nut');
      expect(
        find.byTooltip(tooltip),
        findsNothing,
        reason: 'Người dùng không phải BTC không được thấy nút quản lý chuỗi',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-F-12 [phân quyền âm] khách chưa đăng nhập mở /organizer/series và /ops bị chặn',
    (tester) async {
      _tolerateProductLayoutErrors();
      final container = await pumpApp(tester);
      await ensureSignedOut(tester, container);
      await socialWait(tester, const Duration(seconds: 2));

      await expectBlocked(tester, '/organizer/series');
      await expectBlocked(tester, '/organizer/tournaments/${opsT.id}/ops');
      expect(
        find.byKey(const ValueKey('organizer-ops-add-athlete')),
        findsNothing,
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-F-13 [phân quyền âm] người khác sửa hoặc xóa chuỗi của BTC qua API bị từ chối',
    (tester) async {
      final name = '$tag Chuoi quyen';
      final id = await api.createSeries(token: orgToken(), name: name);
      for (final role in ['player', 'viewer', 'referee']) {
        final token = actor(role).token;
        final patch = await raw.send(
          'PATCH',
          '/organizer/series/$id',
          token: token,
          data: {'name': 'bi sua'},
        );
        expect(
          patch.statusCode,
          inInclusiveRange(400, 499),
          reason: '$role PATCH chuỗi của BTC trả ${patch.statusCode}',
        );
        final delete = await raw.send(
          'DELETE',
          '/organizer/series/$id',
          token: token,
        );
        expect(
          delete.statusCode,
          inInclusiveRange(400, 499),
          reason: '$role DELETE chuỗi của BTC trả ${delete.statusCode}',
        );
      }
      final anon = await raw.send('DELETE', '/organizer/series/$id');
      expect(anon.statusCode, 401, reason: 'Không có token thì phải 401');
      final stillThere = await raw.get('/series/$id', token: orgToken());
      expect(
        jsonEncode(stillThere.data),
        contains(name),
        reason: 'Chuỗi vẫn nguyên tên sau các lần bị từ chối',
      );
    },
  );

  // ───────────────────────── Lite ─────────────────────────

  testWidgets(
    'TC-MULTI-F-14 VĐV vào giải Lite bằng mã mời: bấm Tham gia giải, về trang giải, Backend có VĐV',
    (tester) async {
      _tolerateProductLayoutErrors();
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-F-14');
      final player = actor('player');
      final code =
          '${(await api.getTournament(token: orgToken(), tournamentId: joinT.id))['inviteCode'] ?? ''}';
      expect(
        code,
        isNotEmpty,
        reason: 'Giải Lite phải có inviteCode (GET /tournaments/:id)',
      );
      final container = await signInAs(tester, player);

      container.read(routerProvider).go('/lite-join/$code');
      final joinButton = find.widgetWithText(ElevatedButton, 'Tham gia giải');
      await pumpUntil(tester, joinButton, timeout: const Duration(seconds: 45));
      await shooter.snap('man-tham-gia-bang-ma');
      await tester.tap(joinButton);
      await tester.pump();
      await pumpUntilCondition(
        tester,
        () => currentPath(tester).startsWith('/intro/'),
        what: 'về trang giải /intro/:id sau khi tham gia',
        timeout: const Duration(seconds: 45),
      );
      await shooter.snap('da-tham-gia');

      final list = await api.listParticipants(
        token: orgToken(),
        tournamentId: joinT.id,
        divisionId: joinT.divisionId,
      );
      expect(
        jsonEncode(list),
        contains(player.fullName),
        reason: 'Danh sách VĐV của giải phải có "${player.fullName}"',
      );
      await leaveSocialSession(tester, container);
    },
  );

  testWidgets(
    'TC-MULTI-F-15 BTC ghép cặp ngẫu nhiên 4 VĐV lẻ ở giải đôi Lite rồi mở màn quản lý Lite',
    (tester) async {
      _tolerateProductLayoutErrors();
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-F-15');
      final container = await signInAs(tester, actor('organizer'));

      container.read(routerProvider).go('/lite-pairing/${pairT.id}');
      await pumpUntil(
        tester,
        find.text('Chờ ghép cặp (4)'),
        timeout: const Duration(seconds: 45),
      );
      await shooter.snap('4-vdv-cho-ghep');
      await tapText(tester, 'Ngẫu nhiên');
      await pumpUntil(tester, find.text('Xác nhận ghép cặp'));
      await tapText(tester, 'Xác nhận');
      await pumpUntil(
        tester,
        find.text('Đã ghép cặp (2)'),
        timeout: const Duration(seconds: 45),
      );
      await shooter.snap('da-ghep-2-cap');
      expect(
        find.text('Tạo bracket'),
        findsWidgets,
        reason: 'Sau khi ghép đủ cặp phải có nút Tạo bracket',
      );

      container.read(routerProvider).go('/lite-manage/${pairT.id}?workspace=1');
      await pumpUntil(
        tester,
        find.text('Thông tin giải đấu'),
        timeout: const Duration(seconds: 45),
      );
      expect(find.text('Người tham gia'), findsWidgets);
      await shooter.snap('quan-ly-lite');
      await leaveSocialSession(tester, container);
    },
  );
}

// ───────────────────────── Helper riêng của file ─────────────────────────

class _LiteSeed {
  const _LiteSeed({
    required this.id,
    required this.divisionId,
    required this.tag,
  });

  final String id;
  final String divisionId;
  final String tag;
}

/// Giải Lite đã ADMIN duyệt; [roster] VĐV đơn đã duyệt (bỏ qua nếu 0).
Future<_LiteSeed> _seedLite(
  BackendApi api,
  String token,
  String name,
  String matchType, {
  int roster = 0,
}) async {
  final created = await api.createLiteTournament(
    token: token,
    name: name,
    matchType: matchType,
    maxParticipants: 16,
  );
  await api.approveTournamentAsAdmin(created.tournamentId);
  final tag = name.replaceAll(' ', '');
  if (roster > 0) {
    await api.importRoster(
      token: token,
      tournamentId: created.tournamentId,
      divisionId: created.divisionId,
      tag: tag,
      count: roster,
      singles: true,
    );
  }
  return _LiteSeed(
    id: created.tournamentId,
    divisionId: created.divisionId,
    tag: tag,
  );
}

/// [count] VĐV lẻ (chỉ VĐV 1) vào giải đôi: Backend để PENDING_PARTNER, chờ BTC ghép cặp.
Future<void> _importSolo(
  _RawApi raw,
  String token,
  _LiteSeed seed,
  String tag,
  int count,
) async {
  final res = await raw.send(
    'POST',
    '/tournaments/${seed.id}/roster-import',
    token: token,
    data: {
      'divisionId': seed.divisionId,
      'participants': [
        for (var i = 1; i <= count; i++)
          {
            'teamName': '$tag $i',
            'player1Name': '$tag $i',
            'player1Email':
                '${tag.toLowerCase().replaceAll(' ', '-')}-$i@example.com',
            'source': 'MANUAL_EMAIL',
            'autoApprove': true,
          },
      ],
    },
  );
  final code = res.statusCode ?? 0;
  if (code < 200 || code > 299) {
    throw StateError('roster-import VĐV lẻ trả $code: ${_snip(res.data)}');
  }
}

/// Mở `/ops` rồi sang tab "Danh sách tham gia" và chờ nút Thêm VĐV (vai quản lý) hiện.
Future<void> _openOpsRoster(
  WidgetTester tester,
  ProviderContainer container,
  String tournamentId,
) async {
  container.read(routerProvider).go('/organizer/tournaments/$tournamentId/ops');
  final tab = find.widgetWithText(ChoiceChip, 'Danh sách tham gia');
  await pumpUntil(tester, tab, timeout: const Duration(seconds: 45));
  await tapCentered(tester, tab);
  await pumpUntil(
    tester,
    find.byKey(const ValueKey('organizer-ops-add-athlete')),
    timeout: const Duration(seconds: 45),
  );
}

Finder _seriesNameField() => find.descendant(
  of: find.byKey(const ValueKey('series-form-name')),
  matching: find.byType(EditableText),
);

/// Chuỗi của BTC (`GET /series?organizerId=`), giống `ApiSeriesManagementRepository.listMine`.
Future<List<Map<String, dynamic>>> _mySeries(
  _RawApi raw,
  String token,
  String organizerId,
) async {
  final res = await raw.get(
    '/series',
    token: token,
    query: {'organizerId': organizerId, 'limit': 50},
  );
  expect(res.statusCode, 200, reason: 'GET /series');
  final body = res.data;
  final data = body is Map ? body['data'] : body;
  if (data is! List) return const [];
  return data
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

String? _idOf(Object? body) {
  final data = body is Map && body.containsKey('data') ? body['data'] : body;
  final id = data is Map ? data['id'] : null;
  return id is String && id.isNotEmpty ? id : null;
}

String _snip(Object? value) {
  final text = value is String ? value : jsonEncode(value);
  return text.length > 300 ? text.substring(0, 300) : text;
}

/// Gọi Backend không ném lỗi theo mã HTTP, để ca phân quyền khẳng định đúng mã trả về.
class _RawApi {
  _RawApi()
    : _dio = Dio(
        BaseOptions(
          baseUrl: kE2eApiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          contentType: Headers.jsonContentType,
          validateStatus: (_) => true,
        ),
      );

  final Dio _dio;

  Map<String, String>? _auth(String? token) =>
      token == null ? null : {'Authorization': 'Bearer $token'};

  Future<Response<Object?>> send(
    String method,
    String path, {
    String? token,
    Object? data,
  }) => _dio.request<Object?>(
    path,
    data: data,
    options: Options(method: method, headers: _auth(token)),
  );

  Future<Response<Object?>> get(
    String path, {
    String? token,
    Map<String, dynamic>? query,
  }) => _dio.request<Object?>(
    path,
    queryParameters: query,
    options: Options(method: 'GET', headers: _auth(token)),
  );
}

/// Lỗi layout đã biết của app (BUG-SP-01: RenderFlex tràn vài px, BUG-SP-04: cảnh báo ListTile) ghi vào log
/// rồi bỏ qua; mọi lỗi framework khác vẫn làm ca đỏ.
void _tolerateProductLayoutErrors() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.toString();
    if (text.contains('A RenderFlex overflowed by') ||
        text.contains(
          'ListTile background color or ink splashes may be invisible',
        )) {
      debugPrint(
        '[BUG-SP-01] bỏ qua lỗi layout đã biết: ${details.exceptionAsString().split('\n').first}',
      );
      return;
    }
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
}
