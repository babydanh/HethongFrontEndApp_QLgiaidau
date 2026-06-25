import 'package:app_quanly_giaidau/domain/repositories/session_repository.dart';

class ClearSessionUseCase {
  final ISessionRepository _sessionRepository;

  ClearSessionUseCase(this._sessionRepository);

  Future<void> call() async {
    await _sessionRepository.clearInviteToken();
    await _sessionRepository.clearAuthTokens();
  }
}
