import 'package:app_quanly_giaidau/domain/entities/auth_session.dart';

abstract class IAuthRepository {
  /// [identifier] is an email or a phone number, sent as typed; the server
  /// normalizes it.
  Future<AuthSession> login({
    required String identifier,
    required String password,
  });

  /// At least one of [email] and [phone] must be non-blank.
  Future<AuthSession> register({
    String? email,
    String? phone,
    required String password,
    required String fullName,
  });

  Future<AuthSession> loginWithGoogle(String idToken);

  Future<AuthSession> loginWithApple({
    required String idToken,
    String? nonce,
    String? fullName,
  });

  Future<AuthSession> loginWithFacebook(String accessToken);

  Future<void> requestEmailVerification();

  Future<void> confirmEmailVerification({
    required String token,
  });

  Future<void> requestPhoneVerification({
    required String phoneNumber,
  });

  Future<void> confirmPhoneVerification({
    required String code,
  });

  /// Thu hồi refresh token phía server (POST /auth/logout).
  Future<void> logout({required String refreshToken});
}
