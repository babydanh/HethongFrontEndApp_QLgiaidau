import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/home_projection.dart';
import 'package:dio/dio.dart';

class ApiHomeProjectionRepository {
  final DioClient _dioClient;

  ApiHomeProjectionRepository(this._dioClient);

  Future<HomeProjection> fetch({
    required String sport,
    required String matchStatus,
  }) async {
    if (matchStatus != 'ONGOING' && matchStatus != 'COMPLETED') {
      throw ArgumentError.value(
        matchStatus,
        'matchStatus',
        'Home only supports live and completed matches.',
      );
    }

    final response = await _dioClient.dio.get(
      '/tournaments/home',
      queryParameters: {
        if (sport != 'all') 'sport': sport,
        'matchStatus': matchStatus,
      },
      options: Options(extra: const {'trigger': 'home_projection'}),
    );
    if (response.statusCode != 200) {
      throw StateError('Home projection returned HTTP ${response.statusCode}.');
    }

    dynamic payload = response.data;
    for (var depth = 0; depth < 3; depth++) {
      if (payload is Map && payload['data'] != null) {
        payload = payload['data'];
      } else {
        break;
      }
    }
    if (payload is! Map) {
      throw const FormatException('Home projection response is invalid.');
    }
    return HomeProjection.fromJson(Map<String, dynamic>.from(payload));
  }
}
