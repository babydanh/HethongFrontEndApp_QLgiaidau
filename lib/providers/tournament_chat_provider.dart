import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_chat_room.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chat room status of a tournament for the signed-in viewer. Callers must not
/// watch it for guests (the endpoint needs login).
/// Refresh with `ref.invalidate(tournamentChatRoomProvider(tournamentId))`.
final tournamentChatRoomProvider = FutureProvider.autoDispose
    .family<TournamentChatRoom, String>(
      (ref, tournamentId) => ref
          .watch(tournamentChatRepositoryProvider)
          .getChatRoom(tournamentId),
    );
