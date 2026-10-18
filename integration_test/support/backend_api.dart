import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Backend nhìn từ emulator Android: 10.0.2.2 là máy host (runner GitHub Actions).
const String kE2eApiBaseUrl = String.fromEnvironment(
  'E2E_API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api/v1',
);

/// Tài khoản seed trên CI (workflow test-app-e2e): admin1 = ORGANIZER,
/// user8 = PLAYER, vndcsport = ADMIN (chỉ có khi seed:data).
const String kOrganizerEmail = 'admin1@gmail.com';
const String kPlayerEmail = 'user8@gmail.com';
const String kE2ePassword = '123456';
const String kAdminEmail = 'vndcsport@gmail.com';
const String kAdminPassword = 'Admin@123';

/// SĐT đúng định dạng của UpdateUserDto (0 + đầu 3/5/7/8/9 + 8 chữ số). Tài khoản seed chưa có SĐT.
const String kPlayerPhone = '0912345678';

/// Lỗi gọi Backend: có mã HTTP và tối đa 300 ký tự đầu của body.
class BackendApiException implements Exception {
  BackendApiException({
    required this.method,
    required this.path,
    required this.statusCode,
    required this.bodySnippet,
  });

  final String method;
  final String path;
  final int? statusCode;
  final String bodySnippet;

  @override
  String toString() =>
      'BackendApi $method $path -> HTTP ${statusCode ?? 'không có mã'}: $bodySnippet';
}

class CreatedTournament {
  const CreatedTournament({
    required this.tournamentId,
    required this.divisionId,
  });

  final String tournamentId;
  final String divisionId;
}

/// Dựng dữ liệu và kiểm trạng thái qua Backend thật. Kịch bản UI vẫn đi qua màn hình app;
/// phần này chỉ làm những thao tác app không có (BTC duyệt đơn, ADMIN duyệt giải, chấm điểm).
class BackendApi {
  BackendApi({Dio? dio}) : _dio = dio ?? _defaultDio();

  static Dio _defaultDio() => Dio(
    BaseOptions(
      baseUrl: kE2eApiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      contentType: Headers.jsonContentType,
      validateStatus: (_) => true,
    ),
  );

  final Dio _dio;

  Future<String> login(String email, String password) async {
    const path = '/auth/mobile/login';
    final data = _unwrap(
      await _send('POST', path, data: {'email': email, 'password': password}),
    );
    final token = data is Map ? data['accessToken'] : null;
    if (token is! String || token.isEmpty) {
      throw _error('POST', path, 200, 'thiếu accessToken: ${_snippet(data)}');
    }
    return token;
  }

  /// Đăng ký tài khoản mới qua `POST /auth/mobile/register` (công khai, không cần xác thực email).
  /// Dùng làm đồng đội trong ca đăng ký đôi; dữ liệu do test tạo. Trả user id.
  Future<String> registerAccount({
    required String email,
    required String password,
    required String fullName,
  }) async {
    const path = '/auth/mobile/register';
    final body = await _send(
      'POST',
      path,
      data: {'email': email, 'password': password, 'fullName': fullName},
    );
    final map = _asMap(path, body);
    final id = map['id'];
    if (id is! String || id.isEmpty) {
      throw _error('POST', path, 201, 'thiếu id: ${_snippet(map)}');
    }
    return id;
  }

  /// Điền SĐT và giới tính của chính người gọi qua `PATCH /users/profile` (UpdateUserDto).
  /// Tài khoản seed đăng ký qua API chỉ có họ tên; thiếu SĐT thì app chặn đăng ký,
  /// thiếu giới tính thì banner "Hồ sơ chưa hoàn thiện" ẩn form gửi đăng ký.
  Future<void> completePlayerProfile({
    required String token,
    required String phoneNumber,
    required String gender,
  }) async {
    await _send(
      'PATCH',
      '/users/profile',
      token: token,
      data: {'phoneNumber': phoneNumber, 'gender': gender},
    );
  }

  /// Tạo giải nhanh PUBLIC (Backend đưa vào PENDING_APPROVAL, chờ ADMIN duyệt).
  /// [matchType]: SINGLES | DOUBLES | MIXED_DOUBLES. Nhánh loại trực tiếp.
  /// [doublesPairingMode]: ORGANIZER (mặc định) hoặc SELF; chỉ gửi khi không phải SINGLES.
  Future<CreatedTournament> createLiteTournament({
    required String token,
    required String name,
    required String matchType,
    required int maxParticipants,
    String doublesPairingMode = 'ORGANIZER',
  }) async {
    const path = '/tournaments/lite';
    final format = switch (matchType) {
      'SINGLES' => 'singles',
      'DOUBLES' => 'doubles',
      'MIXED_DOUBLES' => 'mixed_doubles',
      _ => throw ArgumentError.value(matchType, 'matchType'),
    };
    final body = await _send(
      'POST',
      path,
      token: token,
      data: {
        'name': name,
        'sport': 'pickleball',
        'format': format,
        // Top-level bracketType của DTO lite viết thường; divisions[].bracketType viết HOA.
        'bracketType': 'single_elimination',
        'maxTeams': maxParticipants,
        'visibility': 'PUBLIC',
        if (matchType != 'SINGLES') 'doublesPairingMode': doublesPairingMode,
        'divisions': [
          {
            'name': 'Nội dung chính',
            'matchType': matchType,
            'bracketType': 'SINGLE_ELIMINATION',
            'maxParticipants': maxParticipants,
          },
        ],
      },
    );
    final map = _asMap(path, body);
    final tournamentId = map['id'];
    final divisionIds = map['divisionIds'];
    if (tournamentId is! String ||
        divisionIds is! List ||
        divisionIds.isEmpty ||
        divisionIds.first is! String) {
      throw _error('POST', path, 200, 'thiếu id/divisionIds: ${_snippet(map)}');
    }
    return CreatedTournament(
      tournamentId: tournamentId,
      divisionId: divisionIds.first as String,
    );
  }

  /// ADMIN duyệt giải (PENDING_APPROVAL -> mở đăng ký). Đăng nhập bằng vndcsport của seed:data.
  Future<void> approveTournamentAsAdmin(String tournamentId) async {
    final adminToken = await login(kAdminEmail, kAdminPassword);
    await _send(
      'POST',
      '/admin/tournaments/$tournamentId/approve',
      token: adminToken,
    );
  }

  /// Thêm [count] VĐV/đội qua roster-import, tự duyệt và đánh dấu đã thu phí.
  /// Email `@example.com` là giả, giống helper Web đã chạy trên CI.
  Future<void> importRoster({
    required String token,
    required String tournamentId,
    required String divisionId,
    required String tag,
    required int count,
    required bool singles,
  }) async {
    final participants = <Map<String, Object>>[];
    for (var i = 1; i <= count; i++) {
      participants.add({
        'teamName': singles ? '$tag VDV $i' : '$tag Doi $i',
        'player1Name': '$tag P${i}A',
        'player1Email': '$tag-${i}a@example.com',
        'source': 'MANUAL_EMAIL',
        'autoApprove': true,
        'isPaid': true,
        if (!singles) 'player2Name': '$tag P${i}B',
        if (!singles) 'player2Email': '$tag-${i}b@example.com',
      });
    }
    await _send(
      'POST',
      '/tournaments/$tournamentId/roster-import',
      token: token,
      data: {'divisionId': divisionId, 'participants': participants},
    );
  }

  Future<List<Map<String, dynamic>>> listParticipants({
    required String token,
    required String tournamentId,
    required String divisionId,
  }) async {
    final path = '/tournaments/$tournamentId/participants';
    final body = await _send(
      'GET',
      path,
      token: token,
      query: {'divisionId': divisionId},
    );
    return _asList(path, body);
  }

  /// Đơn của chính người gọi (`GET /tournaments/:id/my-registration`): trả `partnerUserId`,
  /// `teamStatus`, `teamInviteToken`. Đồng đội chưa chấp nhận chưa có roster nên không thấy đơn này.
  Future<Map<String, dynamic>> myRegistration({
    required String token,
    required String tournamentId,
    required String divisionId,
  }) async {
    final path = '/tournaments/$tournamentId/my-registration';
    final body = await _send(
      'GET',
      path,
      token: token,
      query: {'divisionId': divisionId},
    );
    return _asMap(path, body);
  }

  /// Các nội dung thi đấu của giải (endpoint công khai, không cần token).
  Future<List<Map<String, dynamic>>> listDivisions(String tournamentId) async {
    final path = '/tournaments/$tournamentId/divisions';
    final body = await _send('GET', path);
    return _asList(path, body);
  }

  /// BTC duyệt một đơn đăng ký đang PENDING_APPROVAL (Backend chỉ nhận COMPLETE hoặc REJECTED).
  Future<void> approveParticipant({
    required String token,
    required String tournamentId,
    required String participantId,
  }) async {
    await _send(
      'PATCH',
      '/tournaments/$tournamentId/participants/$participantId',
      token: token,
      data: {'status': 'COMPLETE'},
    );
  }

  Future<void> generateBracket({
    required String token,
    required String tournamentId,
    required String divisionId,
  }) async {
    await _send(
      'POST',
      '/tournaments/$tournamentId/generate-bracket',
      token: token,
      data: {'divisionId': divisionId},
    );
  }

  Future<List<Map<String, dynamic>>> listMatches({
    required String token,
    required String tournamentId,
    required String divisionId,
  }) async {
    const path = '/matches';
    final body = await _send(
      'GET',
      path,
      token: token,
      query: {
        'tournamentId': tournamentId,
        'divisionId': divisionId,
        'limit': 500,
      },
    );
    return _asList(path, body);
  }

  /// Chấm hết nhánh loại trực tiếp: bên 1 thắng 2-0 (11-5, 11-5) mỗi trận.
  /// Trả tên đội vô địch (trận không có nextMatchId và COMPLETED).
  Future<String> playOutSingleElimination({
    required String token,
    required String tournamentId,
    required String divisionId,
  }) async {
    var matches = <Map<String, dynamic>>[];
    for (var step = 0; step < 20; step++) {
      matches = await listMatches(
        token: token,
        tournamentId: tournamentId,
        divisionId: divisionId,
      );
      final open = matches
          .where((m) => m['status'] != 'COMPLETED' && m['isBye'] != true)
          .toList();
      if (open.isEmpty) break;
      final playable = open
          .where(
            (m) =>
                m['participant1Id'] is String && m['participant2Id'] is String,
          )
          .toList();
      if (playable.isEmpty) {
        throw _error(
          'GET',
          '/matches',
          200,
          'còn ${open.length} trận chưa đủ 2 đối thủ: ${_snippet(open)}',
        );
      }
      for (final match in playable) {
        await _scorePlayerOneWins(token, match);
      }
    }
    final finals = matches
        .where((m) => m['status'] == 'COMPLETED' && m['nextMatchId'] == null)
        .toList();
    if (finals.length != 1 || finals.first['winnerId'] is! String) {
      throw _error(
        'GET',
        '/matches',
        200,
        'không xác định được trận kết: ${_snippet(finals)}',
      );
    }
    final winnerId = finals.first['winnerId'] as String;
    final participants = await listParticipants(
      token: token,
      tournamentId: tournamentId,
      divisionId: divisionId,
    );
    final winner = participants.where((p) => p['id'] == winnerId);
    if (winner.isEmpty) {
      throw _error(
        'GET',
        '/tournaments/$tournamentId/participants',
        200,
        'không có participant $winnerId',
      );
    }
    return winner.first['teamName'] as String;
  }

  Future<void> _scorePlayerOneWins(
    String token,
    Map<String, dynamic> match,
  ) async {
    final matchId = match['id'] as String;
    final p1 = match['participant1Id'] as String;
    if (match['status'] != 'ONGOING') {
      await _send(
        'PATCH',
        '/matches/$matchId/status',
        token: token,
        data: {'status': 'ONGOING'},
      );
    }
    final set = {'team1Score': 11, 'team2Score': 5, 'isFinished': true};
    await _send(
      'PATCH',
      '/matches/$matchId/score',
      token: token,
      data: {
        'p1SetsWon': 2,
        'p2SetsWon': 0,
        'winnerId': p1,
        'scoreDetails': {
          'sets': [set, set],
        },
      },
    );
  }

  Future<Object?> _send(
    String method,
    String path, {
    String? token,
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    final Response<Object?> response;
    try {
      response = await _dio.request<Object?>(
        path,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw _error(method, path, null, 'lỗi mạng: ${e.message}');
    }
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw _error(method, path, code, _snippet(response.data));
    }
    return response.data;
  }

  BackendApiException _error(
    String method,
    String path,
    int? statusCode,
    String detail,
  ) {
    final error = BackendApiException(
      method: method,
      path: path,
      statusCode: statusCode,
      bodySnippet: detail,
    );
    debugPrint(error.toString());
    return error;
  }

  static Object? _unwrap(Object? body) =>
      body is Map && body.containsKey('data') ? body['data'] : body;

  Map<String, dynamic> _asMap(String path, Object? body) {
    final data = _unwrap(body);
    if (data is! Map) {
      throw _error('GET', path, 200, 'không phải object: ${_snippet(body)}');
    }
    return Map<String, dynamic>.from(data);
  }

  List<Map<String, dynamic>> _asList(String path, Object? body) {
    final data = _unwrap(body);
    if (data is! List) {
      throw _error('GET', path, 200, 'không phải danh sách: ${_snippet(body)}');
    }
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static String _snippet(Object? value) {
    final text = value is String ? value : jsonEncode(value);
    return text.length > 300 ? text.substring(0, 300) : text;
  }
}
