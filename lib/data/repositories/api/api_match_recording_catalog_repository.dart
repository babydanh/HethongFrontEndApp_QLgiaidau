import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:dio/dio.dart';

class ApiMatchRecordingCatalogRepository
    implements IMatchRecordingCatalogRepository {
  ApiMatchRecordingCatalogRepository(this._dioClient);

  final DioClient _dioClient;
  Dio get _dio => _dioClient.dio;

  Object? _data(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return body['data'];
    }
    throw const FormatException('Expected API response data envelope.');
  }

  Map<String, Object?> _map(Response<dynamic> response) {
    final value = _data(response);
    if (value is Map<String, Object?>) return value;
    throw const FormatException('Expected an object in API response data.');
  }

  @override
  Future<MatchStreamControlStateModel> getMatchControlState(
    String matchId,
  ) async {
    final response = await _dio.get(
      '/livestream/matches/$matchId/control-state',
      options: Options(extra: const <String, Object?>{'noCache': true}),
    );
    final state = MatchStreamControlStateModel.fromJson(_map(response));
    if (state.matchId != matchId) {
      throw const FormatException('Invalid match control-state response.');
    }
    return state;
  }

  @override
  Future<MatchRecordingDaysModel> listRecordingDays(String matchId) async {
    final response = await _dio.get(
      '/livestream/matches/$matchId/recording-days',
      options: Options(extra: const <String, Object?>{'noCache': true}),
    );
    return MatchRecordingDaysModel.fromJson(_data(response));
  }

  @override
  Future<List<MatchRecordingFileModel>> listRecordings(
    String matchId, {
    required String period,
  }) async {
    final response = await _dio.get(
      '/livestream/matches/$matchId/recordings',
      queryParameters: <String, Object?>{'period': period},
      options: Options(extra: const <String, Object?>{'noCache': true}),
    );
    return MatchRecordingFileModel.listFromJson(_data(response));
  }
}
