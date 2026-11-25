import 'dart:ui';

import 'package:dio/dio.dart';

import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/auth_session.dart';
import 'package:app_quanly_giaidau/domain/repositories/auth_repository.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class ApiAuthRepository implements IAuthRepository {
  static const _log = AppLogger('ApiAuthRepository');
  final DioClient _dioClient;

  ApiAuthRepository(this._dioClient);

  AppLocalizations get _l10n =>
      lookupAppLocalizations(PlatformDispatcher.instance.locale);

  /// Backend đọc refresh token từ cookie `refreshToken` của `/auth/logout`.
  @override
  Future<void> logout({required String refreshToken}) async {
    await _dioClient.dio.post(
      '/auth/logout',
      options: Options(
        headers: {'Cookie': 'refreshToken=$refreshToken'},
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    _log.info('Đăng nhập bằng mật khẩu qua Mobile API');
    try {
      final response = await _dioClient.dio.post(
        '/auth/mobile/login',
        data: {'identifier': identifier, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _mapAuthSession(response.data);
      }

      throw Exception(_l10n.authCredentialsMissingResponse);
    } catch (e, stack) {
      _log.error('Lỗi đăng nhập bằng mật khẩu', e, stack);
      throw Exception(ErrorParser.parse(e, _l10n.networkConnectionFailed));
    }
  }

  @override
  Future<AuthSession> register({
    String? email,
    String? phone,
    required String password,
    required String fullName,
  }) async {
    _log.info('Đăng ký bằng mật khẩu qua Mobile API');
    final cleanEmail = _nonBlank(email);
    final cleanPhone = _nonBlank(phone);
    try {
      final response = await _dioClient.dio.post(
        '/auth/mobile/register',
        data: {
          'email': ?cleanEmail,
          'phone': ?cleanPhone,
          'password': password,
          'fullName': fullName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Sign in with the identifier the user typed.
        return await login(
          identifier: cleanEmail ?? cleanPhone ?? '',
          password: password,
        );
      }

      throw Exception(_l10n.authRegisterResponseInvalid);
    } catch (e, stack) {
      _log.error('Lỗi đăng ký bằng mật khẩu', e, stack);
      throw Exception(ErrorParser.parse(e, _l10n.networkConnectionFailed));
    }
  }

  @override
  Future<AuthSession> loginWithGoogle(String idToken) async {
    _log.info('Đăng nhập bằng Google qua Mobile API');
    try {
      final response = await _dioClient.dio.post(
        '/auth/mobile/google',
        data: {'idToken': idToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _mapAuthSession(response.data);
      }

      throw Exception(_l10n.authGoogleCredentialsMissing);
    } catch (e, stack) {
      _log.error('Lỗi đăng nhập Google', e, stack);
      throw Exception(ErrorParser.parse(e, _l10n.networkConnectionFailed));
    }
  }

  @override
  Future<AuthSession> loginWithApple({
    required String idToken,
    String? nonce,
    String? fullName,
  }) async {
    _log.info('Đăng nhập bằng Apple qua Mobile API');
    try {
      final response = await _dioClient.dio.post(
        '/auth/mobile/apple',
        data: {
          'idToken': idToken,
          if (nonce != null && nonce.isNotEmpty) 'nonce': nonce,
          if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _mapAuthSession(response.data);
      }

      throw Exception(_l10n.authAppleCredentialsMissing);
    } catch (e, stack) {
      _log.error('Lỗi đăng nhập Apple', e, stack);
      throw Exception(ErrorParser.parse(e, _l10n.networkConnectionFailed));
    }
  }

  @override
  Future<AuthSession> loginWithFacebook(String accessToken) async {
    _log.info('Đăng nhập bằng Facebook qua Mobile API');
    try {
      final response = await _dioClient.dio.post(
        '/auth/mobile/facebook',
        data: {'accessToken': accessToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _mapAuthSession(response.data);
      }

      throw Exception(_l10n.authFacebookCredentialsMissing);
    } catch (e, stack) {
      _log.error('Lỗi đăng nhập Facebook', e, stack);
      throw Exception(ErrorParser.parse(e, _l10n.networkConnectionFailed));
    }
  }

  @override
  Future<void> requestEmailVerification() async {
    _log.info('Gửi yêu cầu xác minh email qua Mobile API');
    try {
      await _dioClient.dio.post('/auth/verify-email/request');
    } catch (e, stack) {
      _log.error('Lỗi gửi yêu cầu xác minh email', e, stack);
      throw Exception(ErrorParser.parse(e, _l10n.networkConnectionFailed));
    }
  }

  @override
  Future<void> confirmEmailVerification({required String token}) async {
    _log.info('Xác minh email qua Mobile API');
    try {
      await _dioClient.dio.post(
        '/auth/verify-email/confirm',
        data: {'token': token},
      );
    } catch (e, stack) {
      _log.error('Lỗi xác minh email', e, stack);
      throw Exception(ErrorParser.parse(e, _l10n.networkConnectionFailed));
    }
  }

  @override
  Future<void> requestPhoneVerification({required String phoneNumber}) async {
    _log.info('Gửi yêu cầu xác minh số điện thoại qua Mobile API');
    try {
      await _dioClient.dio.post(
        '/auth/verify-phone/request',
        data: {'phoneNumber': phoneNumber},
      );
    } catch (e, stack) {
      _log.error('Lỗi gửi yêu cầu xác minh số điện thoại', e, stack);
      throw Exception(ErrorParser.parse(e, _l10n.networkConnectionFailed));
    }
  }

  @override
  Future<void> confirmPhoneVerification({required String code}) async {
    _log.info('Xác minh số điện thoại qua Mobile API');
    try {
      await _dioClient.dio.post(
        '/auth/verify-phone/confirm',
        data: {'code': code},
      );
    } catch (e, stack) {
      _log.error('Lỗi xác minh số điện thoại', e, stack);
      throw Exception(ErrorParser.parse(e, _l10n.networkConnectionFailed));
    }
  }

  static String? _nonBlank(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  AuthSession _mapAuthSession(dynamic rawData) {
    final data = rawData as Map<String, dynamic>;
    final innerData = data['data'] as Map<String, dynamic>? ?? data;
    final accessToken = innerData['accessToken'] as String?;
    final refreshToken = innerData['refreshToken'] as String?;
    final userMap = innerData['user'] as Map<String, dynamic>?;
    final userRolesList = userMap?['roles'] as List<dynamic>? ?? [];

    if (accessToken == null || refreshToken == null) {
      throw Exception(_l10n.authCredentialsMissingResponse);
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      roles: userRolesList.map((role) => role.toString()).toList(),
    );
  }
}
