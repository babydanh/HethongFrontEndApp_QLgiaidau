import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/repositories/series_legs_repository.dart';
import 'package:dio/dio.dart';

class ApiSeriesLegsRepository implements SeriesLegsRepository {
  ApiSeriesLegsRepository(this._dioClient);

  final DioClient _dioClient;
  Dio get _dio => _dioClient.dio;

  String _legsPath(String seriesId) => '/organizer/series/$seriesId/legs';

  List<Map<String, dynamic>> _dataList(Response<dynamic> response) {
    final body = response.data;
    final data = body is Map<String, dynamic> ? body['data'] : body;
    if (data is! List) {
      throw const FormatException('Expected a list in API response data.');
    }
    return data.whereType<Map<String, dynamic>>().toList();
  }

  @override
  Future<List<SeriesLegRecord>> getLegs(String seriesId) async {
    final response = await _dio.get('/series/$seriesId/legs');
    return _dataList(response).map(SeriesLegRecord.fromJson).toList();
  }

  @override
  Future<List<SeriesLegEvent>> getLegEvents(
    String seriesId,
    String legId,
  ) async {
    final response = await _dio.get('/series/$seriesId/legs/$legId/events');
    return _dataList(response).map(SeriesLegEvent.fromJson).toList();
  }

  @override
  Future<void> createLeg(String seriesId, SeriesLegInput input) async {
    await _dio.post(_legsPath(seriesId), data: input.toCreateJson());
  }

  @override
  Future<void> updateLeg(
    String seriesId,
    String legId,
    SeriesLegInput input,
  ) async {
    await _dio.patch(
      '${_legsPath(seriesId)}/$legId',
      data: input.toUpdateJson(),
    );
  }

  @override
  Future<void> deleteLeg(String seriesId, String legId) async {
    await _dio.delete('${_legsPath(seriesId)}/$legId');
  }

  @override
  Future<void> linkTournament(
    String seriesId,
    String legId,
    SeriesLinkInput input,
  ) async {
    await _dio.post(
      '${_legsPath(seriesId)}/$legId/events',
      data: input.toJson(),
    );
  }

  @override
  Future<void> unlinkTournament(
    String seriesId,
    String legId,
    String eventId,
  ) async {
    await _dio.delete('${_legsPath(seriesId)}/$legId/events/$eventId');
  }
}
