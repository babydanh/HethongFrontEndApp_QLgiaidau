import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/club_match_session_model.dart';
import 'package:dio/dio.dart';

class ApiClubMatchSessionRepository {
  final DioClient _client;
  ApiClubMatchSessionRepository(this._client);

  dynamic _payload(dynamic raw) => raw is Map && raw.containsKey('data')
      ? raw['data']
      : raw;

  Future<List<ClubMatchSessionModel>> list(String communityId) async {
    final response = await _client.dio.get(
      '/club-match-sessions',
      queryParameters: {'communityId': communityId, 'limit': 50},
    );
    final payload = _payload(response.data);
    final rows = payload is Map ? payload['data'] : payload;
    return (rows as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((row) => ClubMatchSessionModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<ClubMatchSessionModel> create({
    required String communityId,
    String? name,
    String? description,
    required String registrationMode,
    required bool isRanked,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final response = await _client.dio.post('/club-match-sessions', data: {
      'communityId': communityId,
      if (name?.trim().isNotEmpty == true) 'name': name!.trim(),
      if (description?.trim().isNotEmpty == true)
        'description': description!.trim(),
      'registrationMode': registrationMode,
      'isRanked': isRanked,
      if (startAt != null) 'startAt': startAt.toIso8601String(),
      if (endAt != null) 'endAt': endAt.toIso8601String(),
    });
    return ClubMatchSessionModel.fromJson(
      Map<String, dynamic>.from(_payload(response.data) as Map),
    );
  }

  Future<List<ClubMatchParticipantModel>> participants(String sessionId) async {
    final response = await _client.dio.get('/club-match-sessions/$sessionId/participants', queryParameters: {'limit': 50});
    final payload = _payload(response.data);
    final rows = payload is Map ? payload['data'] : payload;
    return (rows as List<dynamic>? ?? const []).whereType<Map>().map((row) => ClubMatchParticipantModel.fromJson(Map<String, dynamic>.from(row))).toList();
  }

  Future<List<ClubSessionMatchModel>> matches(String sessionId) async {
    final response = await _client.dio.get('/club-match-sessions/$sessionId/matches', queryParameters: {'limit': 50});
    final payload = _payload(response.data);
    final rows = payload is Map ? payload['data'] : payload;
    return (rows as List<dynamic>? ?? const []).whereType<Map>().map((row) => ClubSessionMatchModel.fromJson(Map<String, dynamic>.from(row))).toList();
  }

  Future<void> selfJoin(String sessionId) =>
      _client.dio.post('/club-match-sessions/$sessionId/participants/self');

  Future<void> withdraw(String sessionId) =>
      _client.dio.post('/club-match-sessions/$sessionId/participants/self/withdraw');

  Future<void> transition(
    String sessionId,
    String action,
    int version,
  ) => _client.dio.post(
    '/club-match-sessions/$sessionId/transition',
    data: {'action': action, 'version': version},
  );

  Future<void> forceParticipants(String sessionId, List<String> userIds, String key) =>
      _client.dio.post('/club-match-sessions/$sessionId/participants/force', data: {'userIds': userIds}, options: _idempotency(key));

  Future<void> updatePreferences(
    String sessionId, {
    required List<String> preferredPartners,
    required List<String> preferredOpponents,
    required List<String> avoidedPlayers,
  }) => _client.dio.patch(
    '/club-match-sessions/$sessionId/preferences/me',
    data: {
      'preferredPartnerUserIds': preferredPartners,
      'preferredOpponentUserIds': preferredOpponents,
      'avoidUserIds': avoidedPlayers,
    },
  );

  Future<void> createMatch(String sessionId, List<String> sideA, List<String> sideB, String matchType, String key, {bool confirmWarnings = false}) =>
      _client.dio.post('/club-match-sessions/$sessionId/matches', data: {'sideAUserIds': sideA, 'sideBUserIds': sideB, 'matchType': matchType, 'confirmWarnings': confirmWarnings}, options: _idempotency(key));

  Future<void> updateScore(ClubSessionMatchModel match, int sideA, int sideB, {bool complete = false}) =>
      complete
          ? _client.dio.post('/club-match-sessions/matches/${match.id}/complete', data: {'p1SetsWon': sideA, 'p2SetsWon': sideB, 'expectedRevision': match.revision})
          : _client.dio.patch('/club-match-sessions/matches/${match.id}/score', data: {'p1SetsWon': sideA, 'p2SetsWon': sideB, 'expectedRevision': match.revision});

  Options _idempotency(String key) =>
      Options(headers: {'Idempotency-Key': key});
}
