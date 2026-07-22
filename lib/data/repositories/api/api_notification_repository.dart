import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';

class ApiNotificationRepository {
  static const _log = AppLogger('ApiNotificationRepo');
  final DioClient _dioClient;

  ApiNotificationRepository(this._dioClient);

  /// GET /notifications?page=&limit=
  Future<List<AppNotification>> getMyNotifications({int page = 1, int limit = 20}) async {
    _log.info('Lấy danh sách thông báo: page=$page, limit=$limit');
    try {
      final response = await _dioClient.dio.get(
        '/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        return data.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Lỗi lấy danh sách thông báo', e, stack);
      rethrow;
    }
  }

  /// GET /notifications/unread-count
  Future<int> getUnreadCount() async {
    _log.info('Lấy số thông báo chưa đọc');
    try {
      final response = await _dioClient.dio.get('/notifications/unread-count');
      if (response.statusCode == 200) {
        return response.data['count'] ?? response.data['data']?['count'] ?? 0;
      }
      return 0;
    } catch (e, stack) {
      _log.error('Lỗi lấy unread count', e, stack);
      rethrow;
    }
  }

  /// PATCH /notifications/:id/read
  Future<void> markAsRead(String id) async {
    _log.info('Đánh dấu đã đọc: $id');
    try {
      await _dioClient.dio.patch('/notifications/$id/read');
    } catch (e, stack) {
      _log.error('Lỗi đánh dấu đã đọc', e, stack);
      rethrow;
    }
  }

  /// PATCH /notifications/read-all
  Future<void> markAllAsRead() async {
    _log.info('Đánh dấu tất cả đã đọc');
    try {
      await _dioClient.dio.patch('/notifications/read-all');
    } catch (e, stack) {
      _log.error('Lỗi đánh dấu tất cả đã đọc', e, stack);
      rethrow;
    }
  }
}
