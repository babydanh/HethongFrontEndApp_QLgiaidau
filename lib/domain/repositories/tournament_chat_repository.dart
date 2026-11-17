import 'package:app_quanly_giaidau/domain/entities/tournament_chat_moderation.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_chat_room.dart';

abstract class ITournamentChatRepository {
  /// GET /tournaments/:id/chat-room (needs login). Answers 200 with
  /// `available: false` for a kicked or purged room.
  Future<TournamentChatRoom> getChatRoom(String tournamentId);

  /// POST /chat/rooms/:roomId/kicks. Moderators only.
  Future<void> kickUser(String roomId, String userId);

  /// DELETE /chat/rooms/:roomId/kicks/:userId. Moderators only.
  Future<void> unkickUser(String roomId, String userId);

  /// GET /chat/rooms/:roomId/kicks. Moderators only.
  Future<List<ChatRoomKick>> listKicks(String roomId);

  /// GET /chat/rooms/:roomId/participants. Moderators only.
  Future<ChatRoomMemberPage> listParticipants(
    String roomId, {
    int limit = 50,
    String? cursor,
  });

  /// POST /chat/rooms/:roomId/mutes; [minutes] is one of [kChatMuteMinutes].
  Future<void> muteUser(String roomId, String userId, int minutes);

  /// DELETE /chat/rooms/:roomId/mutes/:userId.
  Future<void> unmuteUser(String roomId, String userId);

  /// PATCH /chat/rooms/:roomId/settings; only the given fields change.
  Future<void> updateSettings(
    String roomId, {
    int? slowModeSeconds,
    bool? locked,
  });
}
