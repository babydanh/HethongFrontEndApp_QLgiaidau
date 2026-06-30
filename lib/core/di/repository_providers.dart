import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_auth_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_ranking_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_team_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_token_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_tournament_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_user_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/local/app_session_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/local/shared_prefs_local_session_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/auth_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/local_session_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/ranking_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/session_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/team_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/token_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tournamentRepositoryProvider = Provider<ITournamentRepository>((ref) {
  return ApiTournamentRepository(ref.watch(dioClientProvider));
});

final teamRepositoryProvider = Provider<ITeamRepository>((ref) {
  return ApiTeamRepository(ref.watch(dioClientProvider));
});

final matchRepositoryProvider = Provider<IMatchRepository>((ref) {
  return ApiMatchRepository(ref.watch(dioClientProvider));
});

final tokenRepositoryProvider = Provider<ITokenRepository>((ref) {
  return ApiTokenRepository(ref.watch(dioClientProvider));
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return ApiAuthRepository(ref.watch(dioClientProvider));
});

final localSessionRepositoryProvider = Provider<ILocalSessionRepository>((ref) {
  return SharedPrefsLocalSessionRepository();
});

final rankingRepositoryProvider = Provider<IRankingRepository>((ref) {
  return ApiRankingRepository(ref.watch(dioClientProvider));
});

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  return ApiUserRepository(ref.watch(dioClientProvider));
});

final sessionRepositoryProvider = Provider<ISessionRepository>((ref) {
  return AppSessionRepository(ref.watch(tokenManagerProvider));
});
