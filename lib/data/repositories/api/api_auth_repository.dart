import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/auth_session.dart';
import 'package:app_quanly_giaidau/domain/repositories/auth_repository.dart';

class ApiAuthRepository implements IAuthRepository {
  static const _log = AppLogger('ApiAuthRepository');
  final DioClient _dioClient;

  ApiAuthRepository(this._dioClient);

  @override
  Future<AuthSession> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _log.info('Đăng nhập bằng email qua Mobile API');
    try {
      final response = await _dioClient.dio.post(
        '/auth/mobile/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _mapAuthSession(response.data);
      }

      throw Exception('Không tìm thấy thông tin xác thực trong phản hồi');
    } catch (e, stack) {
      _log.error('Lỗi đăng nhập email', e, stack);
      throw Exception(ErrorParser.parse(e, 'Lỗi kết nối đến máy chủ'));
    }
  }

  @override
  Future<AuthSession> registerWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _log.info('Đăng ký bằng email qua Mobile API');
    try {
      final response = await _dioClient.dio.post(
        '/auth/mobile/register',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return await loginWithEmailPassword(
          email: email,
          password: password,
        );
      }

      throw Exception('Đăng ký không thành công. Vui lòng thử lại.');
    } catch (e, stack) {
      _log.error('Lỗi đăng ký email', e, stack);
      throw Exception(ErrorParser.parse(e, 'Lỗi kết nối đến máy chủ'));
    }
  }

  @override
  Future<AuthSession> loginWithGoogle(String idToken) async {
    _log.info('Đăng nhập bằng Google qua Mobile API');
    try {
      final response = await _dioClient.dio.post(
        '/auth/mobile/google',
        data: {
          'idToken': idToken,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _mapAuthSession(response.data);
      }

      throw Exception('Không tìm thấy thông tin xác thực Google');
    } catch (e, stack) {
      _log.error('Lỗi đăng nhập Google', e, stack);
      throw Exception(ErrorParser.parse(e, 'Lỗi kết nối đến máy chủ'));
    }
  }

  @override
  Future<void> requestEmailVerification() async {
    _log.info('Gửi yêu cầu xác minh email qua Mobile API');
    try {
      await _dioClient.dio.post('/auth/verify-email/request');
    } catch (e, stack) {
      _log.error('Lỗi gửi yêu cầu xác minh email', e, stack);
      throw Exception(ErrorParser.parse(e, 'Lỗi kết nối đến máy chủ'));
    }
  }

  @override
  Future<void> confirmEmailVerification({
    required String token,
  }) async {
    _log.info('Xác minh email qua Mobile API');
    try {
      await _dioClient.dio.post(
        '/auth/verify-email/confirm',
        data: {'token': token},
      );
    } catch (e, stack) {
      _log.error('Lỗi xác minh email', e, stack);
      throw Exception(ErrorParser.parse(e, 'Lỗi kết nối đến máy chủ'));
    }
  }

  AuthSession _mapAuthSession(dynamic rawData) {
    final data = rawData as Map<String, dynamic>;
    final innerData =
        data['data'] as Map<String, dynamic>? ?? data;
    final accessToken = innerData['accessToken'] as String?;
    final refreshToken = innerData['refreshToken'] as String?;
    final userMap = innerData['user'] as Map<String, dynamic>?;
    final userRolesList = userMap?['roles'] as List<dynamic>? ?? [];

    if (accessToken == null || refreshToken == null) {
      throw Exception('Không tìm thấy thông tin xác thực trong phản hồi');
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      roles: userRolesList.map((role) => role.toString()).toList(),
    );
  }

}
