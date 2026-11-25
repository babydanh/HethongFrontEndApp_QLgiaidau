import 'package:app_quanly_giaidau/domain/entities/auth_session.dart';
import 'package:app_quanly_giaidau/domain/repositories/auth_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/session_repository.dart';

class RegisterWithEmailUseCase {
  final IAuthRepository _authRepository;
  final ISessionRepository _sessionRepository;

  RegisterWithEmailUseCase(this._authRepository, this._sessionRepository);

  Future<AuthSession> call({
    String? email,
    String? phone,
    required String password,
    required String fullName,
  }) async {
    final session = await _authRepository.register(
      email: email,
      phone: phone,
      password: password,
      fullName: fullName,
    );
    await _sessionRepository.saveAuthTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }
}
