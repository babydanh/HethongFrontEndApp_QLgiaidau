import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_session_repository.dart';
import 'package:dio/dio.dart';

class SocialApiException implements Exception {
  final int? statusCode;
  final String? code;
  final String message;
  final dynamic details;

  SocialApiException({
    this.statusCode,
    this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => message;

  factory SocialApiException.fromDioException(DioException error) {
    final response = error.response;
    if (response?.data is Map) {
      final data = response!.data as Map;
      final code = data['code']?.toString();
      final serverMsg = data['message']?.toString();
      final statusCode = response.statusCode;

      String message;
      switch (code) {
        case 'SESSION_CLOSED':
          message = 'Kèo đã kết thúc hoặc bị hủy';
          break;
        case 'MAX_SLOTS_BELOW_CURRENT':
          message = 'Số slot tối đa không được nhỏ hơn số lượng đã tham gia';
          break;
        case 'CLUB_ONLY_REQUIRES_COMMUNITY':
          message = 'Kèo nội bộ phải gắn Club';
          break;
        case 'CANNOT_REMOVE_HOST':
          message = 'Không thể xóa người tổ chức';
          break;
        case 'INVALID_DATE':
        case 'INVALID_START_AT':
          message = 'Ngày hoặc giờ bắt đầu không hợp lệ';
          break;
        case 'FORBIDDEN_NOT_MANAGER':
          message = 'Chỉ quản trị viên mới có quyền này';
          break;
        case 'NOT_CLUB_MEMBER':
          message = 'Bạn chưa là thành viên Club này';
          break;
        case 'SESSION_NOT_FOUND':
          message = 'Không tìm thấy buổi Social';
          break;
        case 'COMMUNITY_NOT_FOUND':
          message = 'Không tìm thấy thông tin Câu lạc bộ';
          break;
        case 'USER_NOT_FOUND':
        case 'PARTICIPANT_NOT_FOUND':
          message = 'Không tìm thấy người tham gia';
          break;
        case 'CATEGORY_NOT_FOUND':
          message = 'Môn thể thao không hỗ trợ';
          break;
        case 'SESSION_FULL':
          message = 'Kèo đã đủ người';
          break;
        case 'ALREADY_JOINED':
          message = 'Bạn đã tham gia kèo này';
          break;
        default:
          if (statusCode == 401) {
            message = 'Phiên đăng nhập đã hết hạn, vui lòng thử lại';
          } else if (serverMsg != null && serverMsg.isNotEmpty) {
            message = serverMsg;
          } else {
            message = 'Đã có lỗi xảy ra, vui lòng thử lại sau';
          }
      }

      return SocialApiException(
        statusCode: statusCode,
        code: code,
        message: message,
        details: data['details'],
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return SocialApiException(
        message: 'Lỗi kết nối mạng, vui lòng kiểm tra đường truyền',
      );
    }

    return SocialApiException(
      statusCode: error.response?.statusCode,
      message: error.message ?? 'Đã có lỗi xảy ra',
    );
  }
}

class ApiSocialSessionRepository implements ISocialSessionRepository {
  static const _log = AppLogger('ApiSocialSessionRepository');
  final DioClient _dioClient;

  ApiSocialSessionRepository(this._dioClient);

  @override
  Future<SocialSessionListResponse> listByDate({
    required String date,
    String? sport,
    String? communityId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'date': date,
        'page': page,
        'limit': limit,
        if (sport != null && sport.isNotEmpty && sport.toLowerCase() != 'all')
          'sport': sport,
        if (communityId != null && communityId.isNotEmpty)
          'communityId': communityId,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
      };

      final response = await _dioClient.dio.get(
        '/social-sessions',
        queryParameters: queryParams,
        options: Options(extra: {'noCache': true}),
      );

      final body = _asMap(response.data);
      final rawData = body['data'];
      final rawMeta = body['meta'];

      Map<String, dynamic> combined = {};
      if (rawData is Map) {
        combined = _asMap(rawData);
        if (rawMeta is Map && !combined.containsKey('meta')) {
          combined['meta'] = rawMeta;
        }
      } else if (rawData is List) {
        combined = {
          'items': rawData,
          if (rawMeta is Map) 'meta': rawMeta,
        };
      } else {
        combined = body;
      }

      return SocialSessionListResponse.fromJson(combined);
    } on DioException catch (error, stack) {
      _log.error('listByDate error for date: $date', error, stack);
      throw SocialApiException.fromDioException(error);
    } catch (error, stack) {
      _log.error('listByDate unexpected error', error, stack);
      rethrow;
    }
  }

  @override
  Future<SocialSessionModel> getDetail(String sessionId) async {
    try {
      final response = await _dioClient.dio.get(
        '/social-sessions/$sessionId',
        options: Options(extra: {'noCache': true}),
      );
      final body = _asMap(response.data);
      final rawData = body['data'];
      final dataMap = rawData is Map ? _asMap(rawData) : body;
      return SocialSessionModel.fromJson(dataMap);
    } on DioException catch (error, stack) {
      _log.error('getDetail error for session: $sessionId', error, stack);
      throw SocialApiException.fromDioException(error);
    } catch (error, stack) {
      _log.error('getDetail unexpected error', error, stack);
      rethrow;
    }
  }

  @override
  Future<SocialSessionModel> create(CreateSocialSessionRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        '/social-sessions',
        data: request.toJson(),
      );
      final body = _asMap(response.data);
      final rawData = body['data'];
      final dataMap = rawData is Map ? _asMap(rawData) : body;
      return SocialSessionModel.fromJson(dataMap);
    } on DioException catch (error, stack) {
      _log.error('create session error', error, stack);
      throw SocialApiException.fromDioException(error);
    } catch (error, stack) {
      _log.error('create session unexpected error', error, stack);
      rethrow;
    }
  }

  @override
  Future<SocialSessionModel> update(
    String sessionId,
    Map<String, dynamic> fields,
  ) async {
    try {
      final response = await _dioClient.dio.patch(
        '/social-sessions/$sessionId',
        data: fields,
      );
      final body = _asMap(response.data);
      final rawData = body['data'];
      final dataMap = rawData is Map ? _asMap(rawData) : body;
      return SocialSessionModel.fromJson(dataMap);
    } on DioException catch (error, stack) {
      _log.error('update session error for: $sessionId', error, stack);
      throw SocialApiException.fromDioException(error);
    } catch (error, stack) {
      _log.error('update session unexpected error', error, stack);
      rethrow;
    }
  }

  @override
  Future<void> cancel(String sessionId) async {
    try {
      await _dioClient.dio.delete('/social-sessions/$sessionId');
    } on DioException catch (error, stack) {
      _log.error('cancel session error for: $sessionId', error, stack);
      throw SocialApiException.fromDioException(error);
    } catch (error, stack) {
      _log.error('cancel session unexpected error', error, stack);
      rethrow;
    }
  }

  @override
  Future<JoinSessionResponse> join(
    String sessionId, {
    int ticketCount = 1,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/social-sessions/$sessionId/join',
        data: {'ticketCount': ticketCount},
      );
      final body = _asMap(response.data);
      final rawData = body['data'];
      final dataMap = rawData is Map ? _asMap(rawData) : body;
      return JoinSessionResponse.fromJson(dataMap);
    } on DioException catch (error, stack) {
      _log.error('join session error for: $sessionId', error, stack);
      throw SocialApiException.fromDioException(error);
    } catch (error, stack) {
      _log.error('join session unexpected error', error, stack);
      rethrow;
    }
  }

  @override
  Future<void> addParticipant(
    String sessionId, {
    required String userId,
    int ticketCount = 1,
  }) async {
    try {
      await _dioClient.dio.post(
        '/social-sessions/$sessionId/participants',
        data: {
          'userId': userId,
          'ticketCount': ticketCount,
        },
      );
    } on DioException catch (error, stack) {
      _log.error('addParticipant error for: $sessionId', error, stack);
      throw SocialApiException.fromDioException(error);
    } catch (error, stack) {
      _log.error('addParticipant unexpected error', error, stack);
      rethrow;
    }
  }

  @override
  Future<void> removeParticipant(String sessionId, String userId) async {
    try {
      await _dioClient.dio.delete(
        '/social-sessions/$sessionId/participants/$userId',
      );
    } on DioException catch (error, stack) {
      _log.error(
        'removeParticipant error for session: $sessionId, user: $userId',
        error,
        stack,
      );
      throw SocialApiException.fromDioException(error);
    } catch (error, stack) {
      _log.error('removeParticipant unexpected error', error, stack);
      rethrow;
    }
  }

  @override
  Future<void> updatePaymentStatus(
    String sessionId,
    String userId, {
    required String paymentStatus,
  }) async {
    try {
      await _dioClient.dio.patch(
        '/social-sessions/$sessionId/participants/$userId/payment',
        data: {'paymentStatus': paymentStatus},
      );
    } on DioException catch (error, stack) {
      _log.error(
        'updatePaymentStatus error for session: $sessionId, user: $userId',
        error,
        stack,
      );
      throw SocialApiException.fromDioException(error);
    } catch (error, stack) {
      _log.error('updatePaymentStatus unexpected error', error, stack);
      rethrow;
    }
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }
}
