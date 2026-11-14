import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/actors.dart';
import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/social_journey.dart';

/// Chuỗi H: ma trận vai x endpoint nhạy cảm, gọi thẳng Backend bằng token từng vai
/// (TC-MULTI-H-01..16), cộng nhóm giao diện "phân quyền âm" (TC-MULTI-H-17..19).
///
/// Chỉ GHI lên dữ liệu do chính chuỗi tạo (giải, CLB, phòng chat, tài khoản tiền tố E2E...-h);
/// dữ liệu dùng chung của tài khoản CI không bị sửa hay xoá. Ô "chặn" kỳ vọng 401/403; ô "qua"
/// kỳ vọng không bị 401/403/5xx (strict: đúng 2xx). Ô lệch thì ca đó đỏ: thêm `skip: 'BUG-PERM-xx'`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeAppForTests);

  group('Ma trận quyền qua API', () {
    testWidgets(
      'TC-MULTI-H-01 sửa giải: chỉ BTC và đồng BTC, người ngoài bị chặn',
      (tester) async {
        final fx = await _fixture();
        final path = '/tournaments/${fx.tid}';
        await _runMatrix(fx, 'H-01', [
          for (final r in _outsiders)
            _Cell(
              r,
              Want.deny,
              'PATCH',
              path,
              data: {'name': '${fx.tag} bị sửa trái phép'},
            ),
          _Cell(
            'organizer',
            Want.pass,
            'PATCH',
            path,
            data: {'name': '${fx.tag} Giải ma trận'},
          ),
          _Cell(
            'coOrganizer',
            Want.pass,
            'PATCH',
            path,
            data: {'name': '${fx.tag} Giải ma trận'},
          ),
        ]);
      },
    );

    testWidgets(
      'TC-MULTI-H-02 duyệt VĐV: người ngoài bị chặn, BTC và đồng BTC duyệt được',
      (tester) async {
        final fx = await _fixture();
        final path = '/tournaments/${fx.tid}/participants/${fx.participantId}';
        await _runMatrix(fx, 'H-02', [
          for (final r in _outsiders)
            _Cell(r, Want.deny, 'PATCH', path, data: {'status': 'REJECTED'}),
          _Cell(
            'organizer',
            Want.pass,
            'PATCH',
            path,
            data: {'status': 'COMPLETE'},
          ),
          _Cell(
            'coOrganizer',
            Want.pass,
            'PATCH',
            path,
            data: {'status': 'COMPLETE'},
          ),
        ]);
      },
    );

    testWidgets(
      'TC-MULTI-H-03 sinh bracket: người ngoài và trọng tài bị chặn (BTC đã sinh ở bước dựng)',
      (tester) async {
        final fx = await _fixture();
        final path = '/tournaments/${fx.tid}/generate-bracket';
        await _runMatrix(fx, 'H-03', [
          for (final r in _outsiders)
            _Cell(r, Want.deny, 'POST', path, data: {'divisionId': fx.did}),
        ]);
      },
    );

    testWidgets(
      'TC-MULTI-H-04 bắt đầu trận: người ngoài bị chặn, trọng tài và BTC bắt đầu được',
      (tester) async {
        final fx = await _fixture();
        final body = {'status': 'ONGOING'};
        await _runMatrix(fx, 'H-04', [
          for (final r in _outsiders.where((r) => r != 'referee'))
            _Cell(
              r,
              Want.deny,
              'PATCH',
              '/matches/${fx.match1}/status',
              data: body,
            ),
          _Cell(
            'referee',
            Want.pass,
            'PATCH',
            '/matches/${fx.match1}/status',
            data: body,
            strict: true,
          ),
          _Cell(
            'organizer',
            Want.pass,
            'PATCH',
            '/matches/${fx.match2}/status',
            data: body,
            strict: true,
          ),
        ]);
      },
    );

    testWidgets(
      'TC-MULTI-H-05 chấm điểm: người ngoài bị chặn, trọng tài và BTC chấm được',
      (tester) async {
        final fx = await _fixture();
        await _runMatrix(fx, 'H-05', [
          for (final r in _outsiders.where((r) => r != 'referee'))
            _Cell(
              r,
              Want.deny,
              'PATCH',
              '/matches/${fx.match1}/score',
              data: fx.scorePayload(1),
            ),
          _Cell(
            'referee',
            Want.pass,
            'PATCH',
            '/matches/${fx.match1}/score',
            data: fx.scorePayload(1),
            strict: true,
          ),
          _Cell(
            'organizer',
            Want.pass,
            'PATCH',
            '/matches/${fx.match2}/score',
            data: fx.scorePayload(2),
            strict: true,
          ),
        ]);
      },
    );

    testWidgets('TC-MULTI-H-06 mời trọng tài: chỉ BTC và đồng BTC', (
      tester,
    ) async {
      final fx = await _fixture();
      final path = '/tournaments/${fx.tid}/referees';
      final body = {'email': fx.actor('member').email};
      await _runMatrix(fx, 'H-06', [
        for (final r in _outsiders)
          _Cell(r, Want.deny, 'POST', path, data: body),
        _Cell('organizer', Want.pass, 'POST', path, data: body),
      ]);
    });

    testWidgets('TC-MULTI-H-07 thêm đồng BTC/nhân sự: người ngoài bị chặn', (
      tester,
    ) async {
      final fx = await _fixture();
      final path = '/tournaments/${fx.tid}/staff';
      final denyBody = {
        'email': fx.actor('clubOwner').email,
        'role': 'CO_ORGANIZER',
      };
      await _runMatrix(fx, 'H-07', [
        for (final r in _outsiders)
          _Cell(r, Want.deny, 'POST', path, data: denyBody),
        _Cell(
          'organizer',
          Want.pass,
          'POST',
          path,
          data: {'email': fx.actor('member').email, 'role': 'CO_ORGANIZER'},
        ),
      ]);
    });

    testWidgets(
      'TC-MULTI-H-08 ADMIN duyệt giải: BTC và mọi vai khác bị chặn, chỉ ADMIN qua',
      (tester) async {
        final fx = await _fixture();
        final path = '/admin/tournaments/${fx.tid2}/approve';
        await _runMatrix(fx, 'H-08', [
          for (final r in ['organizer', ..._outsiders])
            _Cell(r, Want.deny, 'POST', path),
          _Cell('admin', Want.pass, 'POST', path, strict: true),
        ]);
      },
    );

    testWidgets(
      'TC-MULTI-H-09 xoá giải: người ngoài bị chặn, BTC xoá được giải của mình',
      (tester) async {
        final fx = await _fixture();
        final path = '/tournaments/${fx.tid2}';
        await _runMatrix(fx, 'H-09', [
          for (final r in _outsiders) _Cell(r, Want.deny, 'DELETE', path),
          _Cell('organizer', Want.pass, 'DELETE', path),
        ]);
      },
    );

    testWidgets(
      'TC-MULTI-H-10 ADMIN duyệt CLB: chủ CLB, thành viên, BTC bị chặn, chỉ ADMIN qua',
      (tester) async {
        final fx = await _fixture();
        final path = '/communities/${fx.communityId}/review';
        final body = {'status': 'ACTIVE'};
        await _runMatrix(fx, 'H-10', [
          for (final r in [
            'clubOwner',
            'member',
            'player',
            'viewer',
            'organizer',
            'guest',
          ])
            _Cell(r, Want.deny, 'PATCH', path, data: body),
          _Cell('admin', Want.pass, 'PATCH', path, data: body, strict: true),
        ]);
      },
    );

    testWidgets(
      'TC-MULTI-H-11 duyệt yêu cầu vào CLB: thành viên không tự duyệt, chỉ chủ CLB duyệt',
      (tester) async {
        final fx = await _fixture();
        await fx.api.joinCommunity(
          token: fx.token('member'),
          communityId: fx.communityId,
        );
        final path =
            '/communities/${fx.communityId}/join-requests/${fx.actor('member').userId}';
        final body = {'action': 'APPROVE'};
        await _runMatrix(fx, 'H-11', [
          for (final r in ['member', 'player', 'viewer', 'referee', 'guest'])
            _Cell(r, Want.deny, 'PATCH', path, data: body),
          _Cell(
            'clubOwner',
            Want.pass,
            'PATCH',
            path,
            data: body,
            strict: true,
          ),
        ]);
      },
    );

    testWidgets(
      'TC-MULTI-H-12 mời thành viên CLB: thành viên thường bị chặn, chủ CLB mời được',
      (tester) async {
        final fx = await _fixture();
        final path = '/communities/${fx.communityId}/invite';
        final body = {'userId': fx.actor('viewer').userId, 'role': 'MEMBER'};
        await _runMatrix(fx, 'H-12', [
          for (final r in ['member', 'player', 'viewer', 'guest'])
            _Cell(r, Want.deny, 'POST', path, data: body),
          _Cell('clubOwner', Want.pass, 'POST', path, data: body),
        ]);
      },
    );

    testWidgets(
      'TC-MULTI-H-13 chat: người ngoài phòng không gửi được; không thu hồi tin của người khác',
      (tester) async {
        final fx = await _fixture();
        final send = {
          'roomId': fx.roomId,
          'messageText': '${fx.tag} tin ngoài phòng',
        };
        final revoke = '/chat/messages/${fx.messageId}/revoke';
        await _runMatrix(fx, 'H-13', [
          for (final r in ['viewer', 'clubOwner', 'guest'])
            _Cell(r, Want.deny, 'POST', '/chat/messages', data: send),
          _Cell(
            'member',
            Want.pass,
            'POST',
            '/chat/messages',
            data: {
              'roomId': fx.roomId,
              'messageText': '${fx.tag} tin của member',
            },
          ),
          for (final r in ['viewer', 'clubOwner', 'member', 'guest'])
            _Cell(r, Want.deny, 'POST', revoke),
          _Cell('player', Want.pass, 'POST', revoke),
        ]);
      },
    );

    testWidgets(
      'TC-MULTI-H-14 sửa hồ sơ người khác: mọi lệnh bị từ chối, người dùng tự sửa được hồ sơ mình',
      (tester) async {
        final fx = await _fixture();
        final victim = '/users/${fx.actor('viewer').userId}';
        await _runMatrix(fx, 'H-14', [
          for (final r in ['player', 'clubOwner', 'organizer', 'guest'])
            _Cell(
              r,
              Want.reject,
              'PATCH',
              victim,
              data: {'fullName': '${fx.tag} bị đổi tên'},
            ),
          _Cell(
            'guest',
            Want.deny,
            'PATCH',
            '/users/profile',
            data: {'fullName': 'Khách'},
          ),
          _Cell(
            'guest',
            Want.deny,
            'PATCH',
            '/users/change-password',
            data: {'oldPassword': 'a', 'newPassword': 'b'},
          ),
          _Cell(
            'viewer',
            Want.pass,
            'PATCH',
            '/users/profile',
            data: {'fullName': fx.actor('viewer').fullName},
            strict: true,
          ),
        ]);
      },
    );

    testWidgets(
      'TC-MULTI-H-15 khách chưa đăng nhập: mọi lệnh ghi nhạy cảm trả 401/403',
      (tester) async {
        final fx = await _fixture();
        await _runMatrix(fx, 'H-15', [
          _Cell(
            'guest',
            Want.deny,
            'POST',
            '/tournaments/lite',
            data: {'name': '${fx.tag} khách tạo giải'},
          ),
          _Cell('guest', Want.deny, 'DELETE', '/tournaments/${fx.tid}'),
          _Cell('guest', Want.deny, 'POST', '/tournaments/${fx.tid}/start'),
          _Cell('guest', Want.deny, 'POST', '/tournaments/${fx.tid}/complete'),
          _Cell(
            'guest',
            Want.deny,
            'POST',
            '/communities',
            data: {'name': '${fx.tag} CLB khách'},
          ),
          _Cell(
            'guest',
            Want.deny,
            'POST',
            '/chat/rooms',
            data: {
              'type': 'DIRECT',
              'memberIds': [fx.actor('viewer').userId],
            },
          ),
          _Cell('guest', Want.deny, 'GET', '/notifications'),
          _Cell('guest', Want.deny, 'POST', '/tournaments/${fx.tid}/follow'),
        ]);
      },
    );

    testWidgets(
      'TC-MULTI-H-16 BTC khai mạc giải: người ngoài bị chặn, BTC qua',
      (tester) async {
        final fx = await _fixture();
        await _runMatrix(fx, 'H-16', [
          for (final r in _outsiders) ...[
            _Cell(r, Want.deny, 'POST', '/tournaments/${fx.tid}/start'),
            _Cell(r, Want.deny, 'POST', '/tournaments/${fx.tid}/complete'),
          ],
          _Cell('organizer', Want.pass, 'POST', '/tournaments/${fx.tid}/start'),
        ]);
      },
    );
  });

  group('Phân quyền âm trên giao diện', () {
    testWidgets(
      'TC-MULTI-H-17 VĐV mở màn vận hành giải của BTC: bị chặn hoặc báo không có quyền',
      (tester) async {
        final fx = await _fixture();
        final shooter = SocialShooter(tester, binding, 'TC-MULTI-H-17');
        await signInAs(tester, fx.actor('player'));
        await shooter.snap('vdv-da-dang-nhap');
        await expectBlocked(tester, '/organizer/tournaments/${fx.tid}/ops');
        await shooter.snap('man-ops-bi-chan');
      },
    );

    testWidgets('TC-MULTI-H-18 VĐV mở /admin: không ở lại màn quản trị', (
      tester,
    ) async {
      final fx = await _fixture();
      final shooter = SocialShooter(tester, binding, 'TC-MULTI-H-18');
      final container = await signInAs(tester, fx.actor('player'));
      container.read(routerProvider).go('/admin');
      await socialWait(tester, const Duration(seconds: 3));
      final path = currentPath(tester);
      await shooter.snap('sau-khi-mo-admin');
      expect(
        path.startsWith('/admin'),
        isFalse,
        reason: 'VĐV mở /admin phải bị đưa đi nơi khác nhưng đang ở "$path"',
      );
    });

    testWidgets(
      'TC-MULTI-H-19 người dùng thường mở màn vận hành giải: bị chặn',
      (tester) async {
        final fx = await _fixture();
        final shooter = SocialShooter(tester, binding, 'TC-MULTI-H-19');
        await signInAs(tester, fx.actor('viewer'));
        await expectBlocked(tester, '/organizer/tournaments/${fx.tid}/ops');
        await shooter.snap('man-ops-bi-chan');
      },
    );
  });
}

// ---------------------------------------------------------------------------------------------
// Ma trận
// ---------------------------------------------------------------------------------------------

/// Vai không có quyền quản lý giải: dùng cho mọi ô "chặn" của giải.
const List<String> _outsiders = [
  'player',
  'viewer',
  'referee',
  'clubOwner',
  'member',
  'guest',
];

/// deny: kỳ vọng 401/403. pass: kỳ vọng không bị chặn quyền (không 401/403, không 5xx).
/// reject: kỳ vọng mọi mã 4xx (route có thể không tồn tại, miễn là không ghi được).
enum Want { deny, pass, reject }

class _Cell {
  const _Cell(
    this.role,
    this.want,
    this.method,
    this.path, {
    this.data,
    this.strict = false,
  });

  final String role;
  final Want want;
  final String method;
  final String path;
  final Object? data;

  /// Với ô pass: đòi đúng 2xx thay vì chỉ "không bị chặn quyền".
  final bool strict;

  bool accepts(int code) {
    final blocked = code == 401 || code == 403;
    return switch (want) {
      Want.deny => blocked,
      Want.reject => code >= 400 && code < 500,
      Want.pass =>
        strict ? code >= 200 && code < 300 : !blocked && code > 0 && code < 500,
    };
  }

  String get label => '${role.padRight(11)} $method $path';
}

/// Chạy mọi ô theo thứ tự (ô chặn trước, ô ghi sau), in bảng kết quả, gom ô lệch vào một lần expect.
Future<void> _runMatrix(_Fixture fx, String name, List<_Cell> cells) async {
  final mismatches = <String>[];
  for (final cell in cells) {
    final code = await fx.api.statusOf(
      cell.method,
      cell.path,
      token: cell.role == 'guest' ? null : fx.token(cell.role),
      data: cell.data,
    );
    final ok = cell.accepts(code);
    final line =
        '[MATRIX $name] ${ok ? 'OK  ' : 'LỆCH'} ${cell.label} -> HTTP $code '
        '(kỳ vọng ${cell.want.name}${cell.strict ? ' 2xx' : ''})';
    debugPrintSynchronously(line);
    if (!ok) mismatches.add(line);
  }
  expect(
    mismatches,
    isEmpty,
    reason: 'Ô lệch kỳ vọng phân quyền:\n${mismatches.join('\n')}',
  );
}

// ---------------------------------------------------------------------------------------------
// Dữ liệu dựng một lần cho cả file (toàn bộ do chuỗi H tạo)
// ---------------------------------------------------------------------------------------------

class _Fixture {
  _Fixture({
    required this.api,
    required this.actors,
    required this.tag,
    required this.tid,
    required this.did,
    required this.tid2,
    required this.participantId,
    required this.match1,
    required this.match2,
    required this.participants,
    required this.communityId,
    required this.roomId,
    required this.messageId,
  });

  final BackendApi api;
  final Map<String, E2eActor> actors;
  final String tag;
  final String tid;
  final String did;
  final String tid2;
  final String participantId;
  final String match1;
  final String match2;

  /// [trận 1 bên 1, trận 1 bên 2, trận 2 bên 1, trận 2 bên 2].
  final List<String> participants;
  final String communityId;
  final String roomId;
  final String messageId;

  E2eActor actor(String role) => actors[role]!;
  String token(String role) => actors[role]!.token;

  /// Điểm 2-0 cho bên 1 của trận [match] (1 hoặc 2), cùng dạng với `BackendApi.scoreMatch`.
  Map<String, Object> scorePayload(int match) {
    final winnerId = participants[(match - 1) * 2];
    const set = {'team1Score': 11, 'team2Score': 5, 'isFinished': true};
    return {
      'p1SetsWon': 2,
      'p2SetsWon': 0,
      'winnerId': winnerId,
      'scoreDetails': {
        'sets': [set, set],
      },
    };
  }
}

Future<_Fixture>? _cached;
Future<_Fixture> _fixture() => _cached ??= _buildFixture();

Future<_Fixture> _buildFixture() async {
  final api = BackendApi();
  final actors = await createActors(
    api,
    chain: 'h',
    roles: const [
      'organizer',
      'admin',
      'player',
      'referee',
      'coOrganizer',
      'viewer',
      'clubOwner',
      'member',
    ],
  );
  final tag = 'E2E${DateTime.now().millisecondsSinceEpoch}-h';
  final btc = actors['organizer']!.token;

  // Giải 1: BTC tạo, ADMIN duyệt, 4 VĐV, bracket, một trọng tài đã nhận lời, một đồng BTC.
  final t = await api.createLiteTournament(
    token: btc,
    name: '$tag Giải ma trận',
    matchType: 'SINGLES',
    maxParticipants: 8,
  );
  await api.approveTournamentAsAdmin(t.tournamentId);
  await api.importRoster(
    token: btc,
    tournamentId: t.tournamentId,
    divisionId: t.divisionId,
    tag: tag,
    count: 4,
    singles: true,
  );
  final roster = await api.listParticipants(
    token: btc,
    tournamentId: t.tournamentId,
    divisionId: t.divisionId,
  );
  await api.generateBracket(
    token: btc,
    tournamentId: t.tournamentId,
    divisionId: t.divisionId,
  );
  final round1 =
      (await api.listMatches(
            token: btc,
            tournamentId: t.tournamentId,
            divisionId: t.divisionId,
          ))
          .where(
            (m) => m['participant1Id'] != null && m['participant2Id'] != null,
          )
          .toList();
  if (round1.length < 2) {
    fail('Bracket 4 VĐV phải có 2 trận vòng 1, nhưng chỉ có ${round1.length}');
  }
  await api.addReferee(
    token: btc,
    tournamentId: t.tournamentId,
    email: actors['referee']!.email,
  );
  final invites = await api.listReferees(
    token: btc,
    tournamentId: t.tournamentId,
  );
  await api.respondReferee(
    token: actors['referee']!.token,
    tournamentId: t.tournamentId,
    refereeId: invites.first['id'] as String,
    accept: true,
  );
  await api.addStaff(
    token: btc,
    tournamentId: t.tournamentId,
    email: actors['coOrganizer']!.email,
    role: 'CO_ORGANIZER',
  );

  // Giải 2: chưa duyệt, dùng cho ô ADMIN duyệt và ô xoá giải.
  final t2 = await api.createLiteTournament(
    token: btc,
    name: '$tag Giải chờ duyệt',
    matchType: 'SINGLES',
    maxParticipants: 8,
  );

  // CLB do chủ CLB tạo, đang chờ ADMIN duyệt (ô H-10).
  final communityId = await api.createCommunity(
    token: actors['clubOwner']!.token,
    name: '$tag CLB',
  );

  // Phòng chat 1-1 player <-> member và một tin của player.
  final roomId = await api.createDirectRoom(
    token: actors['player']!.token,
    otherUserId: actors['member']!.userId,
  );
  final messageId = await api.sendChatMessage(
    token: actors['player']!.token,
    roomId: roomId,
    text: '$tag tin của player',
  );

  return _Fixture(
    api: api,
    actors: actors,
    tag: tag,
    tid: t.tournamentId,
    did: t.divisionId,
    tid2: t2.tournamentId,
    participantId: roster.first['id'] as String,
    match1: round1[0]['id'] as String,
    match2: round1[1]['id'] as String,
    participants: [
      round1[0]['participant1Id'] as String,
      round1[0]['participant2Id'] as String,
      round1[1]['participant1Id'] as String,
      round1[1]['participant2Id'] as String,
    ],
    communityId: communityId,
    roomId: roomId,
    messageId: messageId,
  );
}
