import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tournamentsProvider = StreamProvider<List<Tournament>>((ref) {
  return ref.watch(tournamentRepositoryProvider).watchAll();
});

final myTournamentsProvider = Provider<AsyncValue<List<Tournament>>>((ref) {
  final allTournamentsAsync = ref.watch(tournamentsProvider);

  if (allTournamentsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (allTournamentsAsync.hasError) {
    return AsyncValue.error(
      allTournamentsAsync.error!,
      allTournamentsAsync.stackTrace!,
    );
  }

  final allTournaments = allTournamentsAsync.value ?? [];
  return AsyncValue.data(allTournaments);
});

final tournamentProvider = StreamProvider.family<Tournament?, String>((ref, id) {
  return ref.watch(tournamentRepositoryProvider).watch(id);
});

final presenceCountProvider =
    StreamProvider.family<int, ({String tournamentId, String role})>(
  (ref, params) {
    return Stream.value(0);
  },
);

final teamsProvider =
    StreamProvider.family<List<Team>, String>((ref, tournamentId) {
  return ref.watch(teamRepositoryProvider).watchByTournament(tournamentId);
});

final matchesProvider =
    StreamProvider.family<List<MatchModel>, String>((ref, tournamentId) {
  return ref.watch(matchRepositoryProvider).watchByTournament(tournamentId);
});

final liveMatchesProvider =
    StreamProvider.family<List<MatchModel>, String>((ref, tournamentId) {
  return ref.watch(matchRepositoryProvider).watchLive(tournamentId);
});

final singleMatchProvider = StreamProvider.family<
    MatchModel?,
    ({String tournamentId, String matchId})>((ref, params) {
  return ref
      .watch(matchRepositoryProvider)
      .watchMatch(params.tournamentId, params.matchId);
});
