import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/entities/roster_layout.dart';
import 'package:app_quanly_giaidau/domain/repositories/roster_layout_repository.dart';
import 'package:dio/dio.dart';

class ApiRosterLayoutRepository implements RosterLayoutRepository {
  ApiRosterLayoutRepository(this._dioClient);

  final DioClient _dioClient;
  Dio get _dio => _dioClient.dio;

  @override
  Future<RosterLayoutResponse> analyzeRosterLayout(
    String tournamentId, {
    required List<Map<String, dynamic>> sheets,
    String locale = 'vi',
    bool retryEmptyLayout = false,
  }) async {
    final response = await _dio.post(
      '/ai/tournaments/$tournamentId/roster-layout',
      data: {'sheets': sheets, 'locale': locale},
      // Lần hỏi lại gửi lý do trên query string để log server đếm được; Backend cũ bỏ qua.
      queryParameters: retryEmptyLayout
          ? const {'retryReason': 'EMPTY_LAYOUT'}
          : null,
    );
    final body = response.data;
    final data = body is Map<String, dynamic> ? body['data'] : null;
    if (data is! Map) {
      throw const FormatException('Expected an object in API response data.');
    }
    return RosterLayoutResponse.fromJson(Map<String, dynamic>.from(data));
  }
}
