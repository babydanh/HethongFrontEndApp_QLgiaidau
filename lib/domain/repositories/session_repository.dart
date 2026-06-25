abstract class ISessionRepository {
  Future<String?> getSavedInviteToken();

  Future<void> saveInviteToken(String tokenCode);

  Future<void> clearInviteToken();

  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> clearAuthTokens();
}
