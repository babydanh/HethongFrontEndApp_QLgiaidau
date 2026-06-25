import 'package:app_quanly_giaidau/domain/entities/auth_session.dart';
import 'package:app_quanly_giaidau/domain/repositories/auth_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/session_repository.dart';

class LoginWithGoogleUseCase {
  final IAuthRepository _authRepository;
  final ISessionRepository _sessionRepository;

  LoginWithGoogleUseCase(this._authRepository, this._sessionRepository);

  Future<AuthSession> call({
    required String idToken,
  }) async {
    final session = await _authRepository.loginWithGoogle(idToken);
    await _sessionRepository.saveAuthTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }
}
