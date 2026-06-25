import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/saved_tournament.dart';

class SavedTournamentsNotifier extends AsyncNotifier<List<SavedTournament>> {

  @override
  Future<List<SavedTournament>> build() async {
    return ref.watch(localSessionRepositoryProvider).getSavedTournaments();
  }

  Future<void> saveTournament(String id, String tokenCode, String role) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(localSessionRepositoryProvider);
      await repo.saveTournament(SavedTournament(
        id: id,
        role: role,
        tokenCode: tokenCode,
      ));
      return repo.getSavedTournaments();
    });
  }

  Future<void> removeTournament(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(localSessionRepositoryProvider);
      await repo.removeTournament(id);
      return repo.getSavedTournaments();
    });
  }
}

final savedTournamentsProvider = AsyncNotifierProvider<SavedTournamentsNotifier, List<SavedTournament>>(
  SavedTournamentsNotifier.new,
);
