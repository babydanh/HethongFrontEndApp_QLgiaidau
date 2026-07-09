import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tournamentsProvider = StreamProvider<List<Tournament>>((ref) {
  return ref.watch(tournamentRepositoryProvider).watchAll().map((list) {
    return list.where((t) => t.status != 'PENDING_DELETE' && t.status != 'pending_delete').toList();
  });
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

final tournamentDivisionsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tournamentId) async {
  final dio = ref.watch(dioClientProvider).dio;
  final response = await dio.get('/tournaments/$tournamentId/divisions');
  if (response.statusCode == 200) {
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return [];
});

final matchesWithDivisionProvider = StreamProvider.family<List<MatchModel>, ({String tournamentId, String? divisionId})>((ref, params) {
  return ref.watch(matchRepositoryProvider).watchByTournament(params.tournamentId, divisionId: params.divisionId);
});

final liveMatchesProvider =
    StreamProvider.family<List<MatchModel>, String>((ref, tournamentId) {
  return ref.watch(matchRepositoryProvider).watchLive(tournamentId);
});

final bracketMatchesProvider =
    StreamProvider.family<List<MatchModel>, String>((ref, tournamentId) {
  return ref.watch(tournamentRepositoryProvider).watchBracketMatches(tournamentId);
});

final singleMatchProvider = StreamProvider.autoDispose.family<
    MatchModel?,
    ({String tournamentId, String matchId})>((ref, params) {
  return ref
      .watch(matchRepositoryProvider)
      .watchMatch(params.tournamentId, params.matchId);
});

final viewerCountProvider = StreamProvider.autoDispose.family<int, String>((ref, matchId) {
  final socketService = ref.watch(matchSocketServiceProvider);
  socketService.connect(matchId);

  ref.onDispose(() {
    socketService.leave(matchId);
  });

  return socketService.onViewerCount
      .where((data) => data['matchId'] == matchId)
      .map((data) => data['viewerCount'] as int? ?? 0);
});

