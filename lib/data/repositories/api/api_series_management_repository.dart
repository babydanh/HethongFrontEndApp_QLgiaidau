import 'dart:math';

import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/entities/managed_series.dart';
import 'package:app_quanly_giaidau/domain/repositories/series_management_repository.dart';
import 'package:dio/dio.dart';

class ApiSeriesManagementRepository implements SeriesManagementRepository {
  ApiSeriesManagementRepository(this._dioClient, {Random? random})
    : _random = random ?? Random();

  final DioClient _dioClient;
  final Random _random;
  Dio get _dio => _dioClient.dio;

  /// Backend caps a page at 50 (`QuerySeriesDto.limit`).
  static const _pageLimit = 50;

  Object? _data(Response<dynamic> response) {
    final body = response.data;
    return body is Map<String, dynamic> ? body['data'] : null;
  }

  Map<String, dynamic> _dataMap(Response<dynamic> response) {
    final data = _data(response);
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Expected an object in API response data.');
  }

  @override
  Future<List<ManagedSeries>> listMine(String organizerId) async {
    final response = await _dio.get(
      '/series',
      queryParameters: <String, dynamic>{
        'organizerId': organizerId,
        'limit': _pageLimit,
      },
    );
    final data = _data(response);
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ManagedSeries.fromJson)
        .toList(growable: false);
  }

  @override
  Future<ManagedSeries> getById(String id) async {
    final response = await _dio.get('/series/$id');
    final series = _dataMap(response)['series'];
    if (series is! Map<String, dynamic>) {
      throw const FormatException('Expected `series` in API response data.');
    }
    return ManagedSeries.fromJson(series);
  }

  @override
  Future<ManagedSeries> create(SeriesInput input) async {
    final response = await _dio.post(
      '/organizer/series',
      data: input.toCreateJson(_slugFor(input.name)),
    );
    return ManagedSeries.fromJson(_dataMap(response));
  }

  @override
  Future<ManagedSeries> update(String id, SeriesInput input) async {
    final response = await _dio.patch(
      '/organizer/series/$id',
      data: input.toUpdateJson(),
    );
    return ManagedSeries.fromJson(_dataMap(response));
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete('/organizer/series/$id');
  }

  /// Backend requires a unique `slug`; derive it from the name and add a short
  /// random suffix so two series with the same name do not collide.
  String _slugFor(String name) {
    final base = _slugBase(name);
    final suffix = List.generate(
      4,
      (_) => _slugAlphabet[_random.nextInt(_slugAlphabet.length)],
    ).join();
    return '${base.isEmpty ? 'series' : base}-$suffix';
  }
}

const _slugAlphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

const _diacritics = <String, String>{
  'àáạảãâầấậẩẫăằắặẳẵ': 'a',
  'èéẹẻẽêềếệểễ': 'e',
  'ìíịỉĩ': 'i',
  'òóọỏõôồốộổỗơờớợởỡ': 'o',
  'ùúụủũưừứựửữ': 'u',
  'ỳýỵỷỹ': 'y',
  'đ': 'd',
};

String _slugBase(String name) {
  final lower = name.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final mapped = _diacritics.entries
        .where((e) => e.key.contains(ch))
        .map((e) => e.value)
        .firstOrNull;
    buffer.write(mapped ?? ch);
  }
  return buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
