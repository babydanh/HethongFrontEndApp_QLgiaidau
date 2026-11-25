import 'package:app_quanly_giaidau/domain/entities/auth_session.dart';
import 'package:app_quanly_giaidau/domain/repositories/auth_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/session_repository.dart';

class LoginWithEmailUseCase {
  final IAuthRepository _authRepository;
  final ISessionRepository _sessionRepository;

  LoginWithEmailUseCase(this._authRepository, this._sessionRepository);

  Future<AuthSession> call({
    required String identifier,
    required String password,
  }) async {
    final session = await _authRepository.login(
      identifier: identifier,
      password: password,
    );
    await _sessionRepository.saveAuthTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }
}
