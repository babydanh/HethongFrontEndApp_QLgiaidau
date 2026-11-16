import 'package:app_quanly_giaidau/domain/entities/tournament_chat_room.dart';

abstract class ITournamentChatRepository {
  /// GET /tournaments/:id/chat-room (needs login). Answers 200 with
  /// `available: false` for a kicked or purged room.
  Future<TournamentChatRoom> getChatRoom(String tournamentId);

  /// POST /chat/rooms/:roomId/kicks. Organizer only.
  Future<void> kickUser(String roomId, String userId);

  /// DELETE /chat/rooms/:roomId/kicks/:userId. Organizer only.
  Future<void> unkickUser(String roomId, String userId);
}
