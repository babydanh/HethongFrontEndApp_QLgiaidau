import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';

class TournamentActionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> deleteTournament(String tournamentId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(deleteTournamentUseCaseProvider).call(tournamentId);
    });
    return !state.hasError;
  }

  Future<bool> finalizeTournament(String tournamentId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(finalizeTournamentUseCaseProvider).call(tournamentId);
    });
    return !state.hasError;
  }
}

final tournamentActionProvider = AsyncNotifierProvider<TournamentActionNotifier, void>(
  TournamentActionNotifier.new,
);
