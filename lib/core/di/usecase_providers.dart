import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/usecases/auth/clear_session_use_case.dart';
import 'package:app_quanly_giaidau/domain/usecases/auth/login_with_email_use_case.dart';
import 'package:app_quanly_giaidau/domain/usecases/auth/login_with_google_use_case.dart';
import 'package:app_quanly_giaidau/domain/usecases/auth/register_with_email_use_case.dart';
import 'package:app_quanly_giaidau/domain/usecases/auth/restore_saved_invite_token_use_case.dart';
import 'package:app_quanly_giaidau/domain/usecases/auth/save_invite_token_use_case.dart';
import 'package:app_quanly_giaidau/domain/usecases/auth/validate_invite_token_use_case.dart';
import 'package:app_quanly_giaidau/domain/usecases/tournament/create_tournament_use_case.dart';
import 'package:app_quanly_giaidau/domain/usecases/tournament/delete_tournament_use_case.dart';
import 'package:app_quanly_giaidau/domain/usecases/tournament/finalize_tournament_use_case.dart';
import 'package:app_quanly_giaidau/domain/usecases/tournament/publish_tournament_draw_use_case.dart';
import 'package:app_quanly_giaidau/domain/usecases/tournament/reset_tournament_draw_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final restoreSavedInviteTokenUseCaseProvider =
    Provider<RestoreSavedInviteTokenUseCase>((ref) {
  return RestoreSavedInviteTokenUseCase(ref.watch(sessionRepositoryProvider));
});

final saveInviteTokenUseCaseProvider = Provider<SaveInviteTokenUseCase>((ref) {
  return SaveInviteTokenUseCase(ref.watch(sessionRepositoryProvider));
});

final clearSessionUseCaseProvider = Provider<ClearSessionUseCase>((ref) {
  return ClearSessionUseCase(ref.watch(sessionRepositoryProvider));
});

final loginWithEmailUseCaseProvider = Provider<LoginWithEmailUseCase>((ref) {
  return LoginWithEmailUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionRepositoryProvider),
  );
});

final loginWithGoogleUseCaseProvider = Provider<LoginWithGoogleUseCase>((ref) {
  return LoginWithGoogleUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionRepositoryProvider),
  );
});

final registerWithEmailUseCaseProvider =
    Provider<RegisterWithEmailUseCase>((ref) {
  return RegisterWithEmailUseCase(
    ref.watch(authRepositoryProvider),
    ref.watch(sessionRepositoryProvider),
  );
});

final validateInviteTokenUseCaseProvider =
    Provider<ValidateInviteTokenUseCase>((ref) {
  return ValidateInviteTokenUseCase(ref.watch(tokenRepositoryProvider));
});

final createTournamentUseCaseProvider =
    Provider<CreateTournamentUseCase>((ref) {
  return CreateTournamentUseCase(ref.watch(tournamentRepositoryProvider));
});

final deleteTournamentUseCaseProvider =
    Provider<DeleteTournamentUseCase>((ref) {
  return DeleteTournamentUseCase(
    ref.watch(tournamentRepositoryProvider),
    ref.watch(tokenRepositoryProvider),
  );
});

final finalizeTournamentUseCaseProvider =
    Provider<FinalizeTournamentUseCase>((ref) {
  return FinalizeTournamentUseCase(ref.watch(tournamentRepositoryProvider));
});

final publishTournamentDrawUseCaseProvider =
    Provider<PublishTournamentDrawUseCase>((ref) {
  return PublishTournamentDrawUseCase(
    ref.watch(matchRepositoryProvider),
    ref.watch(tournamentRepositoryProvider),
  );
});

final resetTournamentDrawUseCaseProvider =
    Provider<ResetTournamentDrawUseCase>((ref) {
  return ResetTournamentDrawUseCase(
    ref.watch(matchRepositoryProvider),
    ref.watch(tournamentRepositoryProvider),
  );
});
