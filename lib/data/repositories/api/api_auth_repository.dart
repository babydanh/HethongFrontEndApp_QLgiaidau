import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/entities/auth_session.dart';
import 'package:app_quanly_giaidau/domain/repositories/auth_repository.dart';
import 'package:dio/dio.dart';

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
      if (e is DioException) {
        throw Exception(_parseNestJsError(
          e.response?.data,
          e.message ?? 'Lỗi kết nối đến máy chủ',
        ));
      }
      rethrow;
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
      if (e is DioException) {
        throw Exception(_parseNestJsError(
          e.response?.data,
          e.message ?? 'Lỗi kết nối đến máy chủ',
        ));
      }
      rethrow;
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
      if (e is DioException) {
        throw Exception(_parseNestJsError(
          e.response?.data,
          e.message ?? 'Lỗi kết nối đến máy chủ',
        ));
      }
      rethrow;
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

  String _parseNestJsError(dynamic responseData, String fallback) {
    if (responseData == null) {
      return fallback;
    }
    final rawMessage = responseData['message'];
    String msg;
    if (rawMessage is List && rawMessage.isNotEmpty) {
      msg = rawMessage.first.toString();
    } else if (rawMessage is String) {
      msg = rawMessage;
    } else {
      return fallback;
    }

    const viMap = {
      'Email already exists':
          'Email này đã được đăng ký. Vui lòng dùng email khác hoặc đăng nhập.',
      'email should not be empty': 'Vui lòng nhập địa chỉ email.',
      'email must be an email': 'Địa chỉ email không hợp lệ.',
      'password must be longer than or equal to 6 characters':
          'Mật khẩu phải có ít nhất 6 ký tự.',
      'password should not be empty': 'Vui lòng nhập mật khẩu.',
      'fullName should not be empty': 'Vui lòng nhập họ và tên.',
      'Invalid credentials': 'Email hoặc mật khẩu không đúng.',
      'Tài khoản này được đăng ký qua Google. Vui lòng đăng nhập bằng Google.':
          'Tài khoản này đã đăng ký qua Google. Vui lòng đăng nhập bằng Google.',
    };

    return viMap[msg] ?? msg;
  }
}
