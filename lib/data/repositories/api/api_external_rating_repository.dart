import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/core/utils/dupr_limit.dart';
import 'package:app_quanly_giaidau/domain/repositories/external_rating_repository.dart';

class ApiExternalRatingRepository implements ExternalRatingRepository {
  ApiExternalRatingRepository(this._dioClient);

  static const _path = '/users/me/external-ratings';
  static const _provider = 'DUPR';

  final DioClient _dioClient;

  @override
  Future<double?> getMyDuprRating({
    required String categoryId,
    required String matchType,
  }) async {
    final response = await _dioClient.dio.get(
      _path,
      queryParameters: {
        'provider': _provider,
        'categoryId': categoryId,
        'matchType': matchType,
        'limit': 100,
      },
    );
    // Body is { statusCode, message, data: [rows], meta }.
    final raw = response.data;
    final rows = raw is Map ? raw['data'] : null;
    if (rows is! List) return null;
    return pickDuprFromRatings([
      for (final row in rows)
        if (row is Map) Map<String, dynamic>.from(row),
    ]);
  }

  @override
  Future<void> saveMyDuprRating({
    required String categoryId,
    required String matchType,
    required double value,
  }) async {
    await _dioClient.dio.put(
      _path,
      data: {
        'categoryId': categoryId,
        'matchType': matchType,
        'provider': _provider,
        'value': value,
        'isPublic': true,
      },
    );
  }
}
