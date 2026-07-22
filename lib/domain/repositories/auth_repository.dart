import 'package:app_quanly_giaidau/domain/entities/auth_session.dart';

abstract class IAuthRepository {
  Future<AuthSession> loginWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AuthSession> registerWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
  });

  Future<AuthSession> loginWithGoogle(String idToken);

  Future<AuthSession> loginWithFacebook(String accessToken);

  Future<void> requestEmailVerification();

  Future<void> confirmEmailVerification({
    required String token,
  });
}
