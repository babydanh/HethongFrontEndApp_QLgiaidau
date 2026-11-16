import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
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
}
