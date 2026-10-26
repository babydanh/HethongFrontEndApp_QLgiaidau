import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/backend_api.dart';

/// Test API (không dựng UI) cho change quan-ly-giai-web-parity, chạy trên Backend thật:
/// task 2.1 hạng mục, 4.5 AI xếp lịch, 5.1 camera, 5.2 stream key.
///
/// Bảo mật: body của camera/stream key có thể chứa khoá luồng. Test không in, không đưa
/// body vào `reason`; chỉ khẳng định "có giá trị không rỗng" và "khoá đổi sau rotate".
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final api = BackendApi();
  final tag = 'e2e-${DateTime.now().millisecondsSinceEpoch}';
  late String organizerToken;
  late String playerToken;
  late CreatedTournament tournament;

  setUpAll(() async {
    organizerToken = await api.login(kOrganizerEmail, kE2ePassword);
    playerToken = await api.login(kPlayerEmail, kE2ePassword);
    tournament = await api.createLiteTournament(
      token: organizerToken,
      name: '$tag Giải quản lý API',
      matchType: 'SINGLES',
      maxParticipants: 8,
    );
  });

  Future<ApiResponse> call(
    String method,
    String path, {
    Object? data,
    String? token,
  }) => api.request(method, path, token: token ?? organizerToken, data: data);

  Map<String, dynamic> asMap(Object? data) =>
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

  String text(Object? value) => value is String ? value : '';

  /// Chỉ mã HTTP: body của route camera có thể chứa khoá.
  String status(String label, ApiResponse r) =>
      '$label -> HTTP ${r.statusCode}';

  /// Thêm `message` lỗi của Backend (chuỗi cố định, không chứa khoá) cho route hạng mục.
  String statusWithMessage(String label, ApiResponse r) {
    final message = asMap(r.data)['message'];
    return '${status(label, r)} ${message is String ? message : ''}';
  }

  String randomUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  group('2.1 hạng mục (create/update division)', () {
    Future<String> createDivision(String name) async {
      final r = await call(
        'POST',
        '/tournaments/${tournament.tournamentId}/divisions',
        data: {
          'name': name,
          'matchType': 'SINGLES',
          'maxParticipants': 8,
          'bracketType': 'SINGLE_ELIMINATION',
          'entryFeeOverrideEnabled': false,
        },
      );
      expect(r.ok, isTrue, reason: statusWithMessage('create division', r));
      final id = asMap(r.data)['id'];
      expect(
        id is String && id.isNotEmpty,
        isTrue,
        reason: 'thiếu id hạng mục',
      );
      addTearDown(() async {
        final d = await call('DELETE', '/tournaments/divisions/$id');
        if (!d.ok) debugPrint(status('dọn division', d));
      });
      return id as String;
    }

    Future<Map<String, dynamic>> findDivision(String id) async {
      final divisions = await api.listDivisions(tournament.tournamentId);
      return divisions.firstWhere(
        (d) => d['id'] == id,
        orElse: () => <String, dynamic>{},
      );
    }

    test(
      'BTC tạo hạng mục mới và hạng mục hiện trong danh sách giải',
      () async {
        final name = '$tag Hạng mục tạo';
        final id = await createDivision(name);

        final found = await findDivision(id);
        expect(found['name'], name);
        expect(found['matchType'], 'SINGLES');
        expect(found['maxParticipants'], 8);
      },
    );

    test('tạo hạng mục với matchType sai bị từ chối 400', () async {
      final r = await call(
        'POST',
        '/tournaments/${tournament.tournamentId}/divisions',
        data: {'name': '$tag sai', 'matchType': 'KHONG_CO'},
      );
      expect(r.statusCode, 400, reason: status('matchType sai', r));
    });

    test(
      'BTC sửa hạng mục (PATCH divisions/:id) và giá trị mới được lưu',
      () async {
        final id = await createDivision('$tag Hạng mục sửa');
        final r = await call(
          'PATCH',
          '/tournaments/divisions/$id',
          data: {
            'name': '$tag Hạng mục đã sửa',
            'maxParticipants': 6,
            'minElo': 800,
            'maxElo': 2000,
            'prizeDescription': '$tag giải thưởng',
          },
        );
        expect(r.ok, isTrue, reason: statusWithMessage('update division', r));

        final found = await findDivision(id);
        expect(found['name'], '$tag Hạng mục đã sửa');
        expect(found['maxParticipants'], 6);
        expect(found['minElo'], 800);
        expect(found['maxElo'], 2000);
        expect(found['prizeDescription'], '$tag giải thưởng');
      },
    );

    test(
      'BTC sửa cấu hình hạng mục (PATCH .../config) và giá trị mới được lưu',
      () async {
        final id = await createDivision('$tag Hạng mục cấu hình');
        final r = await call(
          'PATCH',
          '/tournaments/${tournament.tournamentId}/divisions/$id/config',
          data: {'maxParticipants': 4, 'prizeDescription': '$tag cấu hình'},
        );
        expect(r.ok, isTrue, reason: statusWithMessage('config division', r));

        final found = await findDivision(id);
        expect(found['maxParticipants'], 4);
        expect(found['prizeDescription'], '$tag cấu hình');
      },
    );

    test('VĐV (PLAYER) không sửa được hạng mục: 403', () async {
      final id = await createDivision('$tag Hạng mục quyền');
      final r = await call(
        'PATCH',
        '/tournaments/divisions/$id',
        token: playerToken,
        data: {'name': '$tag chiếm quyền'},
      );
      expect(r.statusCode, 403, reason: status('player update', r));
    });
  });

  group('4.5 AI xếp lịch (schedule-preview)', () {
    test(
      'preview chỉ trả mã mà app xử lý được; 200 thì có intent và preview',
      () async {
        final r = await call(
          'POST',
          '/ai/tournaments/${tournament.tournamentId}/schedule-preview',
          data: {
            'command': 'Xếp vòng 1 từ 08:00 đến 12:00',
            'date': '2030-01-15',
            'courtIds': [randomUuidV4()],
            'gridIncrementMinutes': 15,
            'operatingWindow': {
              'start': '2030-01-15T08:00:00.000Z',
              'end': '2030-01-15T12:00:00.000Z',
            },
          },
        );
        // Chưa cấu hình AI: 503 (service). Giải chưa có trận / sân lạ: 400 hoặc 404.
        // Không được là 401/403/500: BTC có quyền và payload đúng DTO.
        expect(
          [200, 400, 404, 503],
          contains(r.statusCode),
          reason: statusWithMessage('schedule-preview', r),
        );
        if (r.statusCode != 200) return;
        final body = asMap(r.data);
        expect(body['intent'], isA<Map>());
        expect(body['preview'], isA<Map>());
      },
    );

    test(
      'payload thiếu courtIds bị từ chối 400 (DTO), không phải 5xx',
      () async {
        final r = await call(
          'POST',
          '/ai/tournaments/${tournament.tournamentId}/schedule-preview',
          data: {'command': 'Xếp lịch', 'date': '2030-01-15', 'courtIds': []},
        );
        expect(r.statusCode, 400, reason: status('thiếu courtIds', r));
      },
    );
  });

  group('5.1 camera (CRUD)', () {
    Future<String> createCamera({
      required String mode,
      Map<String, Object?> extra = const {},
    }) async {
      final r = await call(
        'POST',
        '/livestream/tournaments/${tournament.tournamentId}/cameras',
        data: {
          'name': '$tag-cam-${mode.toLowerCase()}',
          'mode': mode,
          'protocol': 'RTMP',
          ...extra,
        },
      );
      expect(r.ok, isTrue, reason: status('create camera $mode', r));
      final body = asMap(r.data);
      final id = body['id'];
      expect(id is String && id.isNotEmpty, isTrue, reason: 'thiếu id camera');
      expect(body['mode'], mode);
      addTearDown(() async {
        final d = await call('DELETE', '/livestream/cameras/$id');
        if (!d.ok) debugPrint(status('dọn camera', d));
      });
      return id as String;
    }

    Future<List<Map<String, dynamic>>> listCameras() async {
      final r = await call(
        'GET',
        '/livestream/tournaments/${tournament.tournamentId}/cameras',
      );
      expect(r.ok, isTrue, reason: status('list cameras', r));
      final data = r.data;
      return data is List
          ? data.whereType<Map>().map(Map<String, dynamic>.from).toList()
          : <Map<String, dynamic>>[];
    }

    test(
      'BTC tạo camera PUSH và camera hiện trong danh sách, chưa gán sân',
      () async {
        final id = await createCamera(mode: 'PUSH');

        final found = (await listCameras()).where((c) => c['id'] == id);
        expect(found, hasLength(1));
        expect(found.first['mode'], 'PUSH');
        expect(found.first['courtId'], isNull);
        expect(text(found.first['name']), startsWith(tag));
      },
    );

    test('BTC tạo camera PULL với URL phát https giả', () async {
      final id = await createCamera(
        mode: 'PULL',
        extra: {'playbackUrl': 'https://fake.invalid/live/$tag.m3u8'},
      );

      final found = (await listCameras()).firstWhere((c) => c['id'] == id);
      expect(text(found['playbackUrl']), isNotEmpty);
    });

    test('camera PULL không có nguồn bị từ chối 400', () async {
      final r = await call(
        'POST',
        '/livestream/tournaments/${tournament.tournamentId}/cameras',
        data: {'name': '$tag-cam-thieu', 'mode': 'PULL', 'protocol': 'RTMP'},
      );
      expect(r.statusCode, 400, reason: status('PULL thiếu nguồn', r));
    });

    test('gán sân: bỏ gán (null) OK, sân lạ 404, thiếu courtId 400', () async {
      final id = await createCamera(mode: 'PUSH');

      final clear = await call(
        'PATCH',
        '/livestream/cameras/$id/court',
        data: {'courtId': null},
      );
      expect(clear.ok, isTrue, reason: status('bỏ gán sân', clear));
      expect(asMap(clear.data)['courtId'], isNull);

      final unknown = await call(
        'PATCH',
        '/livestream/cameras/$id/court',
        data: {'courtId': randomUuidV4()},
      );
      expect(unknown.statusCode, 404, reason: status('sân lạ', unknown));

      final missing = await call(
        'PATCH',
        '/livestream/cameras/$id/court',
        data: <String, Object?>{},
      );
      expect(missing.statusCode, 400, reason: status('thiếu courtId', missing));
    });

    test('BTC xoá camera và camera biến mất khỏi danh sách', () async {
      final id = await createCamera(mode: 'PUSH');

      final r = await call('DELETE', '/livestream/cameras/$id');
      expect(r.ok, isTrue, reason: status('delete camera', r));
      expect((await listCameras()).any((c) => c['id'] == id), isFalse);
    });

    test('VĐV (PLAYER) không xem được danh sách camera: 403', () async {
      final r = await call(
        'GET',
        '/livestream/tournaments/${tournament.tournamentId}/cameras',
        token: playerToken,
      );
      expect(r.statusCode, 403, reason: status('player list cameras', r));
    });
  });

  group('5.2 stream key (aqp-stream-key)', () {
    Future<String> createPushCamera() async {
      final r = await call(
        'POST',
        '/livestream/tournaments/${tournament.tournamentId}/cameras',
        data: {'name': '$tag-cam-key', 'mode': 'PUSH', 'protocol': 'RTMP'},
      );
      expect(r.ok, isTrue, reason: status('create camera', r));
      final id = asMap(r.data)['id'] as String;
      addTearDown(() async {
        final d = await call('DELETE', '/livestream/cameras/$id');
        if (!d.ok) debugPrint(status('dọn camera', d));
      });
      return id;
    }

    String keyRoute(String id) => '/livestream/cameras/$id/aqp-stream-key';

    // Chỉ để so sánh nội bộ, không bao giờ đưa vào reason hay in.
    String keyOf(ApiResponse r) {
      final rtmp = asMap(asMap(r.data)['rtmp']);
      return '${text(rtmp['server'])}|${text(rtmp['streamKey'])}';
    }

    test(
      'camera PUSH mới chưa có khoá: GET trả streamKeyId null và không có rtmp',
      () async {
        final id = await createPushCamera();

        final r = await call('GET', keyRoute(id));
        expect(r.ok, isTrue, reason: status('get key', r));
        final body = asMap(r.data);
        expect(body['streamKeyId'], isNull);
        expect(body['rtmp'], isNull);
      },
    );

    test('cấp khoá rồi rotate: khoá có giá trị và khác khoá trước', () async {
      final id = await createPushCamera();

      final issued = await call(
        'POST',
        keyRoute(id),
        data: <String, Object?>{},
      );
      // 503 = máy chủ media AQP chưa cấu hình trên môi trường test (Backend ném
      // ServiceUnavailable, app hiện lỗi). Không thể kiểm khoá thật khi đó.
      expect(
        [200, 201, 503],
        contains(issued.statusCode),
        reason: status('issue key', issued),
      );
      if (!issued.ok) {
        debugPrint(
          'AQP chưa cấu hình (HTTP ${issued.statusCode}): bỏ qua rotate.',
        );
        return;
      }
      final issuedBody = asMap(issued.data);
      final rtmp = asMap(issuedBody['rtmp']);
      expect(
        text(issuedBody['streamKeyId']),
        isNotEmpty,
        reason: 'thiếu streamKeyId',
      );
      expect(text(rtmp['server']), isNotEmpty, reason: 'thiếu rtmp.server');
      expect(
        text(rtmp['streamKey']),
        isNotEmpty,
        reason: 'thiếu rtmp.streamKey',
      );
      expect(
        text(issuedBody['qrPayloadString']),
        isNotEmpty,
        reason: 'thiếu qrPayloadString',
      );

      final rotated = await call(
        'POST',
        '${keyRoute(id)}/rotate',
        data: <String, Object?>{},
      );
      expect(rotated.statusCode, 200, reason: status('rotate key', rotated));
      expect(
        keyOf(rotated) != keyOf(issued),
        isTrue,
        reason: 'khoá sau rotate phải khác khoá trước',
      );
    });

    test('camera PULL không có stream key để cấp: 400', () async {
      final created = await call(
        'POST',
        '/livestream/tournaments/${tournament.tournamentId}/cameras',
        data: {
          'name': '$tag-cam-pull-key',
          'mode': 'PULL',
          'protocol': 'RTMP',
          'playbackUrl': 'https://fake.invalid/live/$tag-key.m3u8',
        },
      );
      expect(created.ok, isTrue, reason: status('create PULL', created));
      final id = asMap(created.data)['id'] as String;
      addTearDown(() => call('DELETE', '/livestream/cameras/$id'));

      final r = await call('POST', keyRoute(id), data: <String, Object?>{});
      expect(r.statusCode, 400, reason: status('PULL issue key', r));
    });

    test('không có token thì không đọc được khoá: 401', () async {
      final id = await createPushCamera();

      final r = await api.request('GET', keyRoute(id));
      expect(r.statusCode, 401, reason: status('GET key không token', r));
    });
  });
}
