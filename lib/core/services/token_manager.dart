import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      if (role != null) {
        await prefs.setString(_roleKey, role);
      }
      _log.success('Tokens saved successfully (Web SharedPreferences)');
      return;
    }

    try {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      if (role != null) {
        await _secureStorage.write(key: _roleKey, value: role);
      }
      _log.success('Tokens saved successfully (SecureStorage)');
    } catch (e) {
      _log.warning('Failed to save via secure storage, falling back to SharedPreferences: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      if (role != null) {
        await prefs.setString(_roleKey, role);
      }
    }
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    }
    try {
      final token = await _secureStorage.read(key: _accessTokenKey);
      if (token != null) return token;
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } catch (e) {
      _log.warning('Failed to read access token from secure storage: $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    }
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    }
    try {
      final token = await _secureStorage.read(key: _refreshTokenKey);
      if (token != null) return token;
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      _log.warning('Failed to read refresh token from secure storage: $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    }
  }

  Future<String?> getRole() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_roleKey);
    }
    try {
      final role = await _secureStorage.read(key: _roleKey);
      if (role != null) return role;
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_roleKey);
    } catch (e) {
      _log.warning('Failed to read role from secure storage: $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_roleKey);
    }
  }

  Future<void> clearTokens() async {
    _log.info('Clearing secure tokens');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_roleKey);

    if (!kIsWeb) {
      try {
        await _secureStorage.delete(key: _accessTokenKey);
        await _secureStorage.delete(key: _refreshTokenKey);
        await _secureStorage.delete(key: _roleKey);
        _log.success('Tokens cleared');
      } catch (e, stack) {
        _log.error('Failed to clear secure storage tokens', e, stack);
      }
    } else {
      _log.success('Tokens cleared (Web SharedPreferences)');
    }
  }

  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
