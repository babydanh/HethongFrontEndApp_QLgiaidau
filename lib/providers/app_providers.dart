import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/team_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/local_session_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/firebase/firebase_tournament_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/firebase/firebase_team_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/firebase/firebase_match_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/local/shared_prefs_local_session_repository.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/saved_tournaments_provider.dart';
import 'package:app_quanly_giaidau/core/services/presence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// ─── Repository Providers ───

final tournamentRepositoryProvider = Provider<ITournamentRepository>((ref) {
  return FirebaseTournamentRepository(ref.watch(firestoreProvider));
});

final teamRepositoryProvider = Provider<ITeamRepository>((ref) {
  return FirebaseTeamRepository(ref.watch(firestoreProvider));
});

final matchRepositoryProvider = Provider<IMatchRepository>((ref) {
  return FirebaseMatchRepository(ref.watch(firestoreProvider));
});

final localSessionRepositoryProvider = Provider<ILocalSessionRepository>((ref) {
  return SharedPrefsLocalSessionRepository();
});

// ─── Tournament Providers ───

/// Stream tất cả giải đấu (Admin)
final tournamentsProvider = StreamProvider<List<Tournament>>((ref) {
  // Bắt buộc watch authProvider để stream được gọi lại sau khi signInAnonymously thành công
  ref.watch(authProvider);
  return ref.watch(tournamentRepositoryProvider).watchAll();
});

/// Danh sách "Những giải đấu của bạn"
final myTournamentsProvider = Provider<AsyncValue<List<Tournament>>>((ref) {
  final allTournamentsAsync = ref.watch(tournamentsProvider);
  final savedTournamentsAsync = ref.watch(savedTournamentsProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final uid = auth.currentUser?.uid;

  if (allTournamentsAsync is AsyncLoading || savedTournamentsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }
  
  if (allTournamentsAsync.hasError) {
    return AsyncValue.error(allTournamentsAsync.error!, allTournamentsAsync.stackTrace!);
  }

  final allTournaments = allTournamentsAsync.value ?? [];
  final savedTournaments = savedTournamentsAsync.value ?? [];
  final savedIds = savedTournaments.map((e) => e.id).toSet();

  final myTournaments = allTournaments.where((t) {
    return (uid != null && t.creatorId == uid) || savedIds.contains(t.id);
  }).toList();

  return AsyncValue.data(myTournaments);
});

/// Stream 1 giải đấu theo ID
final tournamentProvider =
    StreamProvider.family<Tournament?, String>((ref, id) {
  return ref.watch(tournamentRepositoryProvider).watch(id);
});

final presenceCountProvider = StreamProvider.family<int, ({String tournamentId, String role})>((ref, params) {
  return ref.watch(presenceServiceProvider).watchOnlineCount(params.tournamentId, params.role);
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
