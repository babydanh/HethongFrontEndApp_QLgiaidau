import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';

class TournamentActionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> deleteTournament(String tournamentId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 1. Delete associated tokens from root collection
      await ref.read(tokenRepositoryProvider).deleteTokensByTournament(tournamentId);
      // 2. Delete the tournament (which deletes subcollections: teams, matches, standings)
      await ref.read(tournamentRepositoryProvider).delete(tournamentId);
    });
    return !state.hasError;
  }

  Future<bool> finalizeTournament(String tournamentId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(tournamentRepositoryProvider).update(tournamentId, {
        'status': AppConstants.statusCompleted,
        'updatedAt': DateTime.now(),
      });
    });
    return !state.hasError;
  }
}

final tournamentActionProvider = AsyncNotifierProvider<TournamentActionNotifier, void>(
  TournamentActionNotifier.new,
);
