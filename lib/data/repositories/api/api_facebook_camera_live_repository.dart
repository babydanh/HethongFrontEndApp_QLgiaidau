import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/repositories/facebook_camera_live_repository.dart';
import 'package:dio/dio.dart';

class ApiFacebookCameraLiveRepository implements IFacebookCameraLiveRepository {
  ApiFacebookCameraLiveRepository(this._dioClient);

  final DioClient _dioClient;
  Dio get _dio => _dioClient.dio;

  Map<String, Object?> _map(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
    }
    throw const FormatException('Expected an object in API response data.');
  }

  @override
  Future<FacebookLiveConnection> getConnection(String tournamentId) async =>
      FacebookLiveConnection.fromJson(
        _map(
          await _dio.get(
            '/livestream/tournaments/$tournamentId/facebook-live/connection',
            options: Options(extra: const <String, Object?>{'noCache': true}),
          ),
        ),
      );

  @override
  Future<CreatedFacebookLive> createLive(String tournamentId) async =>
      CreatedFacebookLive.fromJson(
        _map(await _dio.post('/livestream/tournaments/$tournamentId/facebook-live')),
      );

  @override
  Future<Uri> getConnectUrl(String communityId) async {
    final raw = _map(
      await _dio.get(
        '/livestream/facebook/connect',
        queryParameters: {'communityId': communityId},
      ),
    )['authorizationUrl'];
    final uri = raw is String ? Uri.tryParse(raw) : null;
    if (uri == null || uri.scheme != 'https') {
      throw const FormatException('Invalid Facebook authorization URL.');
    }
    return uri;
  }
}
