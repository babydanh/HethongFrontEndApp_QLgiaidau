import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_chat_moderation.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_chat_room.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_chat_repository.dart';
import 'package:dio/dio.dart';

class ApiTournamentChatRepository implements ITournamentChatRepository {
  static const _log = AppLogger('ApiTournamentChatRepository');
  final DioClient _dioClient;

  ApiTournamentChatRepository(this._dioClient);

  @override
  Future<TournamentChatRoom> getChatRoom(String tournamentId) async {
    final response = await _dioClient.dio.get(
      '/tournaments/$tournamentId/chat-room',
      options: Options(extra: {'noCache': true}),
    );
    final raw = response.data;
    final data = raw is Map ? (raw['data'] ?? raw) : null;
    if (data is! Map) {
      throw const FormatException('Invalid chat-room response');
    }
    return TournamentChatRoom.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> kickUser(String roomId, String userId) async {
    _log.info('Kick user $userId from room $roomId');
    await _dioClient.dio.post(
      '/chat/rooms/$roomId/kicks',
      data: {'userId': userId},
    );
  }

  @override
  Future<void> unkickUser(String roomId, String userId) async {
    await _dioClient.dio.delete('/chat/rooms/$roomId/kicks/$userId');
  }

  @override
  Future<List<ChatRoomKick>> listKicks(String roomId) async {
    final response = await _dioClient.dio.get(
      '/chat/rooms/$roomId/kicks',
      options: Options(extra: {'noCache': true}),
    );
    final data = _unwrap(response.data);
    final rows = data is List ? data : const [];
    return rows
        .whereType<Map>()
        .map((r) => ChatRoomKick.fromJson(Map<String, dynamic>.from(r)))
        .toList(growable: false);
  }

  @override
  Future<ChatRoomMemberPage> listParticipants(
    String roomId, {
    int limit = 50,
    String? cursor,
  }) async {
    final response = await _dioClient.dio.get(
      '/chat/rooms/$roomId/participants',
      queryParameters: {'limit': limit, 'cursor': ?cursor},
      options: Options(extra: {'noCache': true}),
    );
    final data = _unwrap(response.data);
    final rows = data is Map && data['items'] is List
        ? data['items'] as List
        : const [];
    return ChatRoomMemberPage(
      items: rows
          .whereType<Map>()
          .map((r) => ChatRoomMember.fromJson(Map<String, dynamic>.from(r)))
          .toList(growable: false),
      nextCursor: data is Map ? data['nextCursor']?.toString() : null,
    );
  }

  @override
  Future<void> muteUser(String roomId, String userId, int minutes) async {
    _log.info('Mute user $userId in room $roomId for $minutes min');
    await _dioClient.dio.post(
      '/chat/rooms/$roomId/mutes',
      data: {'userId': userId, 'minutes': minutes},
    );
  }

  @override
  Future<void> unmuteUser(String roomId, String userId) async {
    await _dioClient.dio.delete('/chat/rooms/$roomId/mutes/$userId');
  }

  @override
  Future<void> updateSettings(
    String roomId, {
    int? slowModeSeconds,
    bool? locked,
  }) async {
    await _dioClient.dio.patch(
      '/chat/rooms/$roomId/settings',
      data: {'slowModeSeconds': ?slowModeSeconds, 'locked': ?locked},
    );
  }

  /// `{statusCode, message, data}` envelope or a bare body.
  static Object? _unwrap(Object? raw) =>
      raw is Map && raw.containsKey('data') ? raw['data'] : raw;
}
