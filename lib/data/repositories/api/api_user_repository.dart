import 'dart:ui';

import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/user_repository.dart';
import 'package:dio/dio.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class ApiUserRepository implements IUserRepository {
  static const _log = AppLogger('ApiUserRepository');
  final DioClient _dioClient;

  ApiUserRepository(this._dioClient);

  AppLocalizations get _l10n =>
      lookupAppLocalizations(PlatformDispatcher.instance.locale);

  @override
  Future<UserProfile> getProfile() async {
    _log.info('Lấy thông tin người dùng qua API');
    try {
      final response = await _dioClient.dio.get('/users/profile');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = response.data;
        if (raw is Map) {
          final data = raw['data'] is Map ? raw['data'] as Map : raw;
          return UserProfile.fromJson(Map<String, dynamic>.from(data));
        }
      }

      throw Exception(_l10n.userProfileLoadFailed);
    } catch (e, stack) {
      _log.error('Lỗi lấy thông tin người dùng', e, stack);
      if (e is DioException) {
        throw Exception(
          _parseNestJsError(
            e.response?.data,
            e.message ?? _l10n.networkConnectionFailed,
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    _log.info('Cập nhật thông tin người dùng qua API');
    try {
      final response = await _dioClient.dio.patch('/users/profile', data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = response.data;
        if (raw is Map) {
          final result = raw['data'] is Map ? raw['data'] as Map : raw;
          return UserProfile.fromJson(Map<String, dynamic>.from(result));
        }
      }

      throw Exception(_l10n.userProfileUpdateFailed);
    } catch (e, stack) {
      _log.error('Lỗi cập nhật thông tin người dùng', e, stack);
      if (e is DioException) {
        throw Exception(
          _parseNestJsError(
            e.response?.data,
            e.message ?? _l10n.networkConnectionFailed,
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Future<UserProfile> uploadAvatar(List<int> bytes, String fileName) async {
    _log.info('Tải lên ảnh đại diện qua API');
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dioClient.dio.post(
        '/users/profile/avatar',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = response.data;
        if (raw is Map) {
          final result = raw['data'] is Map ? raw['data'] as Map : raw;
          return UserProfile.fromJson(Map<String, dynamic>.from(result));
        }
      }

      throw Exception(_l10n.userAvatarUploadFailed);
    } catch (e, stack) {
      _log.error('Lỗi tải lên ảnh đại diện', e, stack);
      if (e is DioException) {
        throw Exception(
          _parseNestJsError(
            e.response?.data,
            e.message ?? _l10n.networkConnectionFailed,
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Future<UserProfile> uploadCover(List<int> bytes, String fileName) async {
    _log.info('Tải lên ảnh bìa qua API');
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dioClient.dio.post(
        '/users/profile/cover',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = response.data;
        if (raw is Map) {
          final result = raw['data'] is Map ? raw['data'] as Map : raw;
          return UserProfile.fromJson(Map<String, dynamic>.from(result));
        }
      }

      throw Exception(_l10n.userCoverUploadFailed);
    } catch (e, stack) {
      _log.error('Lỗi tải lên ảnh bìa', e, stack);
      if (e is DioException) {
        throw Exception(
          _parseNestJsError(
            e.response?.data,
            e.message ?? _l10n.networkConnectionFailed,
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Future<UserPublicProfile> getPublicProfile(String userId) async {
    _log.info('Lấy hồ sơ công khai: userId=$userId');
    try {
      final response = await _dioClient.dio.get('/users/$userId/public');
      if (response.statusCode == 200) {
        final raw = response.data;
        if (raw is Map) {
          final data = raw['data'] is Map ? raw['data'] as Map : raw;
          return UserPublicProfile.fromJson(Map<String, dynamic>.from(data));
        }
      }
      throw Exception(_l10n.userPublicProfileLoadFailed);
    } catch (e, stack) {
      _log.error('Lỗi tải hồ sơ công khai', e, stack);
      if (e is DioException) {
        throw Exception(
          _parseNestJsError(
            e.response?.data,
            e.message ?? _l10n.networkConnectionFailed,
          ),
        );
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
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _log.success('Đổi mật khẩu thành công');
        return;
      }

      throw Exception(_l10n.userPasswordChangeFailed);
    } catch (e, stack) {
      _log.error('Lỗi đổi mật khẩu', e, stack);
      if (e is DioException) {
        throw Exception(
          _parseNestJsError(
            e.response?.data,
            e.message ?? _l10n.networkConnectionFailed,
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<UserSearchResult>> searchUsers(String query) async {
    _log.info('Tìm kiếm người dùng: $query');
    try {
      final response = await _dioClient.dio.get(
        '/users/search',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200) {
        final raw = response.data;
        final list = raw is Map
            ? (raw['data'] as List<dynamic>? ?? [])
            : (raw is List ? raw : []);
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => UserSearchResult.fromJson(e))
            .toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Lỗi tìm kiếm người dùng', e, stack);
      return [];
    }
  }

  @override
  Future<void> deleteAccount(String password) async {
    _log.info('Xóa tài khoản qua API');
    try {
      final response = await _dioClient.dio.post(
        '/users/delete-account',
        data: {'password': password},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _log.success('Đã xóa tài khoản');
        return;
      }
      throw Exception(_l10n.userAccountDeleteFailed);
    } catch (e, stack) {
      _log.error('Lỗi xóa tài khoản', e, stack);
      if (e is DioException) {
        throw Exception(
          _parseNestJsError(
            e.response?.data,
            e.message ?? _l10n.networkConnectionFailed,
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> createChangeRequest({
    required String requestType,
    required String newValue,
  }) async {
    _log.info('Gửi yêu cầu thay đổi ($requestType) qua API');
    try {
      final response = await _dioClient.dio.post(
        '/users/change-requests',
        data: {'requestType': requestType, 'newValue': newValue},
      );
      if (response.statusCode == 200 || response.statusCode == 201) return;
      throw Exception(_l10n.userChangeRequestFailed);
    } catch (e, stack) {
      _log.error('Lỗi gửi yêu cầu thay đổi', e, stack);
      if (e is DioException) {
        throw Exception(
          _parseNestJsError(
            e.response?.data,
            e.message ?? _l10n.networkConnectionFailed,
          ),
        );
      }
      rethrow;
    }
  }

  String _parseNestJsError(dynamic responseData, String fallback) {
    if (responseData == null) {
      return fallback;
    }
    if (responseData is! Map) {
      if (responseData is String && responseData.isNotEmpty) {
        return responseData;
      }
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
