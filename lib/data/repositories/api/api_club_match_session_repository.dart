import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:dio/dio.dart';

class ApiClubMatchSessionRepository {
  final DioClient _client;
  ApiClubMatchSessionRepository(this._client);

  dynamic _payload(dynamic raw) =>
      raw is Map && raw.containsKey('data') ? raw['data'] : raw;

  Future<List<Map<String, dynamic>>> _allCursorRows(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final rows = <Map<String, dynamic>>[];
    String? cursor;
    do {
      final response = await _client.dio.get(
        path,
        queryParameters: {
          ...?query,
          'limit': 50,
          // ignore: use_null_aware_elements
          if (cursor != null) 'cursor': cursor,
        },
      );
      final envelope = response.data;
      final pageRows = envelope is Map ? envelope['data'] : envelope;
      rows.addAll(
        (pageRows as List<dynamic>? ?? const []).whereType<Map>().map(
          (row) => Map<String, dynamic>.from(row),
        ),
      );
      final meta = envelope is Map ? envelope['meta'] : null;
      final hasMore = meta is Map && meta['hasMore'] == true;
      final next = meta is Map ? meta['nextCursor']?.toString() : null;
      cursor = hasMore && next != null && next.isNotEmpty && next != cursor
          ? next
          : null;
    } while (cursor != null);
    return rows;
  }

  Future<List<ClubMatchSessionModel>> list(String communityId) async {
    final rows = await _allCursorRows(
      '/club-match-sessions',
      query: {'communityId': communityId},
    );
    return rows.map(ClubMatchSessionModel.fromJson).toList();
  }

  Future<ClubMatchSessionModel> get(String sessionId) async {
    final response = await _client.dio.get('/club-match-sessions/$sessionId');
    return ClubMatchSessionModel.fromJson(
      Map<String, dynamic>.from(_payload(response.data) as Map),
    );
  }

  Future<ClubMatchSessionModel> create({
    required String communityId,
    String? name,
    String? description,
    required String registrationMode,
    required bool isRanked,
    int maxParticipants = 16,
    DateTime? startAt,
    DateTime? endAt,
    bool isRecurring = false,
    String recurringFrequency = 'WEEKLY',
    int recurringDayOfWeek = 6,
    List<int> recurringDaysOfWeek = const [6],
    String recurringTimeOfDay = '18:00',
    int recurringAdvanceDays = 3,
  }) async {
    final response = await _client.dio.post(
      '/club-match-sessions',
      data: {
        'communityId': communityId,
        if (name?.trim().isNotEmpty == true) 'name': name!.trim(),
        if (description?.trim().isNotEmpty == true)
          'description': description!.trim(),
        'registrationMode': registrationMode,
        'isRanked': isRanked,
        'maxParticipants': maxParticipants,
        if (startAt != null) 'startAt': startAt.toIso8601String(),
        if (endAt != null) 'endAt': endAt.toIso8601String(),
        'isRecurring': isRecurring,
        if (isRecurring) ...{
          'recurringFrequency': recurringFrequency,
          'recurringDayOfWeek': recurringDayOfWeek,
          'recurringDaysOfWeek': recurringDaysOfWeek,
          'recurringTimeOfDay': recurringTimeOfDay,
          'recurringAdvanceDays': recurringAdvanceDays,
        },
      },
    );
    return ClubMatchSessionModel.fromJson(
      Map<String, dynamic>.from(_payload(response.data) as Map),
    );
  }

  Future<List<ClubMatchParticipantModel>> participants(String sessionId) async {
    final rows = await _allCursorRows(
      '/club-match-sessions/$sessionId/participants',
    );
    return rows.map(ClubMatchParticipantModel.fromJson).toList();
  }

  Future<List<ClubSessionMatchModel>> matches(String sessionId) async {
    final rows = await _allCursorRows(
      '/club-match-sessions/$sessionId/matches',
    );
    return rows.map(ClubSessionMatchModel.fromJson).toList();
  }

  Future<void> selfJoin(String sessionId) =>
      _client.dio.post('/club-match-sessions/$sessionId/participants/self');

  Future<void> withdraw(String sessionId) => _client.dio.post(
    '/club-match-sessions/$sessionId/participants/self/withdraw',
  );

  Future<void> removeParticipant(
    String sessionId,
    String userId,
    int version,
  ) => _client.dio.patch(
    '/club-match-sessions/$sessionId/participants/$userId/remove',
    data: {'version': version},
  );

  Future<void> transition(String sessionId, String action, int version) =>
      _client.dio.post(
        '/club-match-sessions/$sessionId/transition',
        data: {'action': action, 'version': version},
      );

  Future<void> forceParticipants(
    String sessionId,
    List<String> userIds,
    String key,
  ) => _client.dio.post(
    '/club-match-sessions/$sessionId/participants/force',
    data: {'userIds': userIds},
    options: _idempotency(key),
  );

  Future<void> updatePreferences(
    String sessionId, {
    required List<String> preferredPartners,
    required List<String> preferredOpponents,
    required List<String> avoidedPlayers,
    required int version,
  }) => _client.dio.patch(
    '/club-match-sessions/$sessionId/preferences/me',
    data: {
      'preferredPartnerUserIds': preferredPartners,
      'preferredOpponentUserIds': preferredOpponents,
      'avoidUserIds': avoidedPlayers,
      'version': version,
    },
  );

  Future<void> createMatch(
    String sessionId,
    List<String> sideA,
    List<String> sideB,
    String matchType,
    String key, {
    bool confirmWarnings = false,
  }) => _client.dio.post(
    '/club-match-sessions/$sessionId/matches',
    data: {
      'sideAUserIds': sideA,
      'sideBUserIds': sideB,
      'matchType': matchType,
      'confirmWarnings': confirmWarnings,
    },
    options: _idempotency(key),
  );

  Future<void> updateScore(
    ClubSessionMatchModel match,
    int sideA,
    int sideB, {
    bool complete = false,
  }) => complete
      ? _client.dio.post(
          '/club-match-sessions/matches/${match.id}/complete',
          data: {
            'p1SetsWon': sideA,
            'p2SetsWon': sideB,
            'expectedRevision': match.revision,
            'scoreDetails': match.scoreDetails,
          },
        )
      : _client.dio.patch(
          '/club-match-sessions/matches/${match.id}/score',
          data: {
            'p1SetsWon': sideA,
            'p2SetsWon': sideB,
            'expectedRevision': match.revision,
            'scoreDetails': match.scoreDetails,
          },
        );

  Options _idempotency(String key) =>
      Options(headers: {'Idempotency-Key': key});
}
