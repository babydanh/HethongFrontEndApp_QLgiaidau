import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/services/token_manager.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/team_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/local_session_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_tournament_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_team_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/local/shared_prefs_local_session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// ─── Core Network Providers ───

final tokenManagerProvider = Provider<TokenManager>((ref) {
  return TokenManager();
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(tokenManager: ref.watch(tokenManagerProvider));
});

// ─── Repository Providers ───

final tournamentRepositoryProvider = Provider<ITournamentRepository>((ref) {
  return ApiTournamentRepository(ref.watch(dioClientProvider));
});

final teamRepositoryProvider = Provider<ITeamRepository>((ref) {
  return ApiTeamRepository(ref.watch(dioClientProvider));
});

final matchRepositoryProvider = Provider<IMatchRepository>((ref) {
  return ApiMatchRepository(ref.watch(dioClientProvider));
});

final localSessionRepositoryProvider = Provider<ILocalSessionRepository>((ref) {
  return SharedPrefsLocalSessionRepository();
});

// ─── Tournament Providers ───

/// Stream tất cả giải đấu
final tournamentsProvider = StreamProvider<List<Tournament>>((ref) {
  return ref.watch(tournamentRepositoryProvider).watchAll();
});

/// Danh sách "Những giải đấu của bạn"
final myTournamentsProvider = Provider<AsyncValue<List<Tournament>>>((ref) {
  final allTournamentsAsync = ref.watch(tournamentsProvider);

  if (allTournamentsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }
  
  if (allTournamentsAsync.hasError) {
    return AsyncValue.error(allTournamentsAsync.error!, allTournamentsAsync.stackTrace!);
  }

  final allTournaments = allTournamentsAsync.value ?? [];
  return AsyncValue.data(allTournaments);
});

/// Stream 1 giải đấu theo ID
final tournamentProvider =
    StreamProvider.family<Tournament?, String>((ref, id) {
  return ref.watch(tournamentRepositoryProvider).watch(id);
});

final presenceCountProvider = StreamProvider.family<int, ({String tournamentId, String role})>((ref, params) {
  // Thay thế presence realtime của Firestore
  return Stream.value(1);
});

// ─── Team Providers ───

/// Stream danh sách đội theo giải đấu
final teamsProvider =
    StreamProvider.family<List<Team>, String>((ref, tournamentId) {
  return ref.watch(teamRepositoryProvider).watchByTournament(tournamentId);
});

// ─── Match Providers ───

/// Stream tất cả trận đấu trong giải (cho bracket view)
final matchesProvider =
    StreamProvider.family<List<MatchModel>, String>((ref, tournamentId) {
  return ref.watch(matchRepositoryProvider).watchByTournament(tournamentId);
});

/// Stream trận đang live (cho viewer)
final liveMatchesProvider =
    StreamProvider.family<List<MatchModel>, String>((ref, tournamentId) {
  return ref.watch(matchRepositoryProvider).watchLive(tournamentId);
});

/// Stream 1 trận cụ thể
final singleMatchProvider =
    StreamProvider.family<MatchModel?, ({String tournamentId, String matchId})>(
        (ref, params) {
  return ref
      .watch(matchRepositoryProvider)
      .watchMatch(params.tournamentId, params.matchId);
});
