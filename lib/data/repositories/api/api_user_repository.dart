import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/user_repository.dart';
import 'package:dio/dio.dart';

class ApiUserRepository implements IUserRepository {
  static const _log = AppLogger('ApiUserRepository');
  final DioClient _dioClient;

  ApiUserRepository(this._dioClient);

  @override
  Future<UserProfile> getProfile() async {
    _log.info('Lấy thông tin người dùng qua API');
    try {
      final response = await _dioClient.dio.get('/users/profile');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] as Map<String, dynamic>? ?? response.data;
        return UserProfile.fromJson(data);
      }

      throw Exception('Không thể lấy thông tin người dùng');
    } catch (e, stack) {
      _log.error('Lỗi lấy thông tin người dùng', e, stack);
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
  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    _log.info('Cập nhật thông tin người dùng qua API');
    try {
      final response = await _dioClient.dio.patch(
        '/users/profile',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = response.data['data'] as Map<String, dynamic>? ?? response.data;
        return UserProfile.fromJson(result);
      }

      throw Exception('Cập nhật thông tin thất bại');
    } catch (e, stack) {
      _log.error('Lỗi cập nhật thông tin người dùng', e, stack);
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
  Future<UserProfile> uploadAvatar(String filePath) async {
    _log.info('Tải lên ảnh đại diện qua API');
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      final response = await _dioClient.dio.post(
        '/users/profile/avatar',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = response.data['data'] as Map<String, dynamic>? ?? response.data;
        return UserProfile.fromJson(result);
      }

      throw Exception('Tải ảnh đại diện thất bại');
    } catch (e, stack) {
      _log.error('Lỗi tải lên ảnh đại diện', e, stack);
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
  Future<UserProfile> uploadCover(String filePath) async {
    _log.info('Tải lên ảnh bìa qua API');
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      final response = await _dioClient.dio.post(
        '/users/profile/cover',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = response.data['data'] as Map<String, dynamic>? ?? response.data;
        return UserProfile.fromJson(result);
      }

      throw Exception('Tải ảnh bìa thất bại');
    } catch (e, stack) {
      _log.error('Lỗi tải lên ảnh bìa', e, stack);
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
  Future<void> changePassword(String oldPassword, String newPassword) async {
    _log.info('Đổi mật khẩu qua API');
    try {
      final response = await _dioClient.dio.patch(
        '/users/change-password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _log.success('Đổi mật khẩu thành công');
        return;
      }

      throw Exception('Đổi mật khẩu thất bại');
    } catch (e, stack) {
      _log.error('Lỗi đổi mật khẩu', e, stack);
      if (e is DioException) {
        throw Exception(_parseNestJsError(
          e.response?.data,
          e.message ?? 'Lỗi kết nối đến máy chủ',
        ));
      }
      rethrow;
    }
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
