import 'package:app_quanly_giaidau/domain/entities/auth_session.dart';
import 'package:app_quanly_giaidau/domain/repositories/auth_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/session_repository.dart';

class LoginWithEmailUseCase {
  final IAuthRepository _authRepository;
  final ISessionRepository _sessionRepository;

  LoginWithEmailUseCase(this._authRepository, this._sessionRepository);

  Future<AuthSession> call({
    required String email,
    required String password,
  }) async {
    final session = await _authRepository.loginWithEmailPassword(
      email: email,
      password: password,
    );
    await _sessionRepository.saveAuthTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }
}
