import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_recording_catalog_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TC-CAM-SYNC-01..06: model + repository của điều khiển phát camera theo trận.
const _matchId = 'match-1';
const _tournamentId = 'tour-1';

class _NoTokenManager extends TokenManager {
  @override
  Future<String?> getAccessToken() async => 'tok';
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? data, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(<String, Object?>{'data': data}),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

ApiMatchRecordingCatalogRepository _repo(_Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiMatchRecordingCatalogRepository(
    DioClient(tokenManager: _NoTokenManager(), dio: dio),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://api.example.test/api/v1',
    );
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('TC-CAM-SYNC-01 control-state đọc streamStatus, ENDED về IDLE, lạ là null',
      () async {
    final bodies = <Map<String, Object?>>[
      {'matchId': _matchId, 'hasCamera': true, 'streamStatus': 'LIVE'},
      {'matchId': _matchId, 'hasCamera': true, 'streamStatus': 'ENDED'},
      {'matchId': _matchId, 'hasCamera': true, 'streamStatus': 'WHAT'},
      {'matchId': _matchId, 'hasCamera': false, 'streamStatus': null},
    ];
    var index = 0;
    final repo = _repo(_Adapter((_) => _json(bodies[index++])));

    final live = await repo.getMatchControlState(_matchId);
    final ended = await repo.getMatchControlState(_matchId);
    final unknown = await repo.getMatchControlState(_matchId);
    final noCamera = await repo.getMatchControlState(_matchId);

    expect(live.streamStatus, MatchStreamStatus.live);
    expect(live.canToggleStream, isTrue);
    expect(ended.streamStatus, MatchStreamStatus.idle);
    expect(unknown.streamStatus, isNull);
    expect(unknown.canToggleStream, isFalse, reason: 'không đoán nút Bắt đầu');
    expect(noCamera.canToggleStream, isFalse);
  });

  test('TC-CAM-SYNC-02 start gọi POST /start và đọc publish + recordingStatus',
      () async {
    final adapter = _Adapter(
      (_) => _json({
        'livestream': {'streamStatus': 'LIVE'},
        'publish': {'url': 'rtmp://x/y', 'protocol': 'RTMP'},
        'playbackUrl': 'https://p/x.m3u8',
        'recordingStatus': 'PENDING',
      }),
    );

    final result = await _repo(adapter).startMatchStream(_matchId);

    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.path, '/livestream/matches/$_matchId/start');
    expect(result.streamStatus, MatchStreamStatus.live);
    expect(result.publishUrl, 'rtmp://x/y');
    expect(result.recordingStatus, MatchRecordingStatus.pending);
  });

  test('TC-CAM-SYNC-03 start kiểu PULL: publish null, trạng thái thiếu', () async {
    final repo = _repo(
      _Adapter(
        (_) => _json({
          'livestream': null,
          'publish': null,
          'playbackUrl': 'https://p/x.m3u8',
        }),
      ),
    );

    final result = await repo.startMatchStream(_matchId);

    expect(result.publishUrl, isNull);
    expect(result.streamStatus, isNull);
    expect(result.recordingStatus, isNull);
  });

  test('TC-CAM-SYNC-04 stop gọi POST /stop và đọc trạng thái phẳng', () async {
    final adapter = _Adapter(
      (_) => _json({'streamStatus': 'IDLE', 'recordingStatus': 'STOPPED'}),
    );

    final result = await _repo(adapter).stopMatchStream(_matchId);

    expect(adapter.requests.single.path, '/livestream/matches/$_matchId/stop');
    expect(result.streamStatus, MatchStreamStatus.idle);
    expect(result.recordingStatus, MatchRecordingStatus.stopped);
  });

  test('TC-CAM-SYNC-05 danh sách trận-livestream bỏ dòng hỏng, hasRecording chỉ true khi đúng boolean',
      () async {
    final adapter = _Adapter(
      (_) => _json([
        {'matchId': 'a', 'cameraId': 'c1', 'streamStatus': 'LIVE', 'hasRecording': true},
        {'matchId': 'b', 'cameraId': null, 'streamStatus': 'ENDED', 'hasRecording': 'true'},
        {'cameraId': 'c3'},
        'rác',
        {'matchId': 'd', 'streamStatus': 'ZZZ'},
      ]),
    );

    final rows = await _repo(adapter).listTournamentMatchLivestreams(_tournamentId);

    expect(adapter.requests.single.path, '/livestream/tournaments/$_tournamentId/matches');
    expect(rows.map((r) => r.matchId), <String>['a', 'b', 'd']);
    expect(rows[0].streamStatus, MatchStreamStatus.live);
    expect(rows[0].hasCamera, isTrue);
    expect(rows[0].hasRecording, isTrue);
    expect(rows[1].streamStatus, MatchStreamStatus.idle);
    expect(rows[1].hasRecording, isFalse);
    expect(rows[1].hasCamera, isFalse);
    expect(rows[2].streamStatus, isNull);
  });

  test('TC-CAM-SYNC-06 tải video đầy đủ gọi download kèm period + token và ghi file', () async {
    final adapter = _Adapter(
      (_) => ResponseBody.fromBytes(
        <int>[1, 2, 3, 4],
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['video/mp4'],
        },
      ),
    );
    final dir = await Directory.systemTemp.createTemp('cam_sync');
    addTearDown(() => dir.delete(recursive: true));
    final savePath = '${dir.path}/full.mp4';

    await _repo(adapter).downloadFullRecording(
      _matchId,
      period: '2026-10-09',
      savePath: savePath,
    );

    final request = adapter.requests.single;
    expect(request.path, '/livestream/matches/$_matchId/recordings/download');
    expect(request.queryParameters['period'], '2026-10-09');
    expect(request.headers['Authorization'], 'Bearer tok');
    expect(await File(savePath).readAsBytes(), <int>[1, 2, 3, 4]);
  });
}
