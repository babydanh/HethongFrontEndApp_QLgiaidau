import 'package:app_quanly_giaidau/core/services/token_manager.dart';
import 'package:app_quanly_giaidau/domain/repositories/session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSessionRepository implements ISessionRepository {
  static const _inviteTokenKey = 'saved_token';
  final TokenManager _tokenManager;

  AppSessionRepository(this._tokenManager);

  @override
  Future<String?> getSavedInviteToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_inviteTokenKey);
  }

  @override
  Future<void> saveInviteToken(String tokenCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_inviteTokenKey, tokenCode);
  }

  @override
  Future<void> clearInviteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_inviteTokenKey);
  }

  @override
  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    return _tokenManager.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> clearAuthTokens() {
    return _tokenManager.clearTokens();
  }
}
