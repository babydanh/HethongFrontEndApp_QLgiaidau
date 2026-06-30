import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';

class TokenManager {
  static const _log = AppLogger('TokenManager');
  final FlutterSecureStorage _secureStorage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _roleKey = 'user_role';

  TokenManager({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
  }) async {
    _log.info('Saving secure tokens');
    try {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      if (role != null) {
        await _secureStorage.write(key: _roleKey, value: role);
      }
      _log.success('Tokens saved successfully');
    } catch (e, stack) {
      _log.error('Failed to save tokens', e, stack);
      rethrow;
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (e, stack) {
      _log.error('Failed to read access token', e, stack);
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e, stack) {
      _log.error('Failed to read refresh token', e, stack);
      return null;
    }
  }

  Future<String?> getRole() async {
    try {
      return await _secureStorage.read(key: _roleKey);
    } catch (e, stack) {
      _log.error('Failed to read role', e, stack);
      return null;
    }
  }

  Future<void> clearTokens() async {
    _log.info('Clearing secure tokens');
    try {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _roleKey);
      _log.success('Tokens cleared');
    } catch (e, stack) {
      _log.error('Failed to clear tokens', e, stack);
    }
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
