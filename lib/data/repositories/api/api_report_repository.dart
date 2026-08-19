import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/entities/violation_report.dart';
import 'package:app_quanly_giaidau/domain/repositories/report_repository.dart';
import 'package:dio/dio.dart';

class ApiReportRepository implements IReportRepository {
  static const _log = AppLogger('ApiReportRepository');
  final DioClient _dioClient;

  ApiReportRepository(this._dioClient);

  @override
  Future<ViolationReportPage> getMine({
    String? cursor,
    int limit = 10,
  }) async {
    _log.info('Lấy báo cáo của người dùng: cursor=${cursor != null}, limit=$limit');
    try {
      final response = await _dioClient.dio.get(
        '/users/reports/me',
        queryParameters: {
          'limit': limit,
          ...?(cursor == null ? null : <String, dynamic>{'cursor': cursor}),
        },
        options: Options(extra: {'noCache': true}),
      );

      final raw = response.data;
      if (response.statusCode != 200 || raw is! Map) {
        throw Exception('Không thể tải lịch sử báo cáo');
      }

      final data = raw['data'];
      final list = data is List
          ? data
          : data is Map && data['data'] is List
              ? data['data'] as List
              : const <dynamic>[];
      final meta = raw['meta'] is Map
          ? Map<String, dynamic>.from(raw['meta'] as Map)
          : data is Map && data['meta'] is Map
              ? Map<String, dynamic>.from(data['meta'] as Map)
              : const <String, dynamic>{};
      final items = list
          .whereType<Map>()
          .map((item) => ViolationReport.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);

      return ViolationReportPage(
        items: items,
        nextCursor: meta['nextCursor']?.toString(),
        totalPages: int.tryParse(meta['totalPages']?.toString() ?? '') ?? 1,
      );
    } catch (error, stack) {
      _log.error('Lỗi lấy lịch sử báo cáo', error, stack);
      if (error is DioException) {
        throw Exception(_parseNestJsError(
          error.response?.data,
          error.message ?? 'Lỗi kết nối đến máy chủ',
        ));
      }
      rethrow;
    }
  }

  String _parseNestJsError(dynamic responseData, String fallback) {
    if (responseData is! Map) return fallback;
    final message = responseData['message'];
    if (message is String && message.isNotEmpty) return message;
    if (message is List && message.isNotEmpty) return message.first.toString();
    return fallback;
  }
}
