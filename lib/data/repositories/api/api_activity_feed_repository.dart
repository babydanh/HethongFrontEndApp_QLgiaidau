import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/repositories/activity_feed_repository.dart';
import 'package:app_quanly_giaidau/features/social/models/activity_feed_item.dart';
import 'package:dio/dio.dart';

class ApiActivityFeedRepository implements IActivityFeedRepository {
  final DioClient _dioClient;

  ApiActivityFeedRepository(this._dioClient);

  @override
  Future<ActivityFeedPage> getClubActivityFeed({
    required String date,
    String? type,
    String? region,
    String? cursor,
    int limit = 50,
  }) async {
    final response = await _dioClient.dio.get(
      '/communities/activity-feed',
      queryParameters: {
        'date': date,
        'limit': limit,
        if (type != null && type.isNotEmpty) 'type': type,
        if (region != null && region.isNotEmpty) 'region': region,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
      options: Options(extra: {'noCache': true}),
    );
    final body = _asMap(response.data);
    final data = _asMap(body['data']);
    final raw = data['items'] is List ? data['items'] as List : const [];
    return ActivityFeedPage(
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(ActivityFeedItem.fromClubJson)
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false),
      nextCursor: _safeCursor(_asMap(body['meta'])['nextCursor']),
      hasMore: _asMap(body['meta'])['hasMore'] == true,
    );
  }

  @override
  Future<ActivityFeedPage> getPersonalPickups({
    required String date,
    String? categoryId,
    String? region,
    String? cursor,
    int limit = 50,
  }) async {
    final response = await _dioClient.dio.get(
      '/social/pickups',
      queryParameters: {
        'date': date,
        'limit': limit,
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        if (region != null && region.isNotEmpty) 'region': region,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
      options: Options(extra: {'noCache': true}),
    );
    final body = _asMap(response.data);
    final rawData = body['data'];
    final raw = rawData is List
        ? rawData
        : _asMap(rawData)['items'] is List
        ? _asMap(rawData)['items'] as List
        : const [];
    return ActivityFeedPage(
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(ActivityFeedItem.fromPersonalJson)
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false),
      nextCursor: _safeCursor(_asMap(body['meta'])['nextCursor']),
      hasMore: _asMap(body['meta'])['hasMore'] == true,
    );
  }

  @override
  Future<void> createPersonalPickup({
    required String categoryId,
    required String title,
    required String description,
    required String playDate,
    required String startTime,
    required String endTime,
    required String location,
    int? feePerSlot,
    required int maxSlots,
  }) async {
    await _dioClient.dio.post(
      '/social/pickups',
      data: {
        'categoryId': categoryId,
        'title': title,
        if (description.trim().isNotEmpty) 'description': description.trim(),
        'playDate': playDate,
        'startTime': startTime,
        'endTime': endTime,
        'location': location,
        ...?(feePerSlot == null ? null : {'feePerSlot': feePerSlot}),
        'maxSlots': maxSlots,
        'levelRequirement': 'Mọi trình độ',
        'genderRequirement': 'ANY',
      },
      options: Options(
        headers: {
          'Idempotency-Key': 'pickup-${DateTime.now().microsecondsSinceEpoch}',
        },
      ),
    );
  }

  @override
  Future<void> joinPersonalPickup(String id) async {
    await _dioClient.dio.post('/social/pickups/$id/participants/self');
  }

  @override
  Future<void> leavePersonalPickup(String id) async {
    await _dioClient.dio.delete('/social/pickups/$id/participants/self');
  }

  @override
  Future<void> joinClubSession(String sessionId) async {
    await _dioClient.dio.post(
      '/club-match-sessions/$sessionId/participants/self',
    );
  }

  @override
  Future<void> leaveClubSession(String sessionId) async {
    await _dioClient.dio.post(
      '/club-match-sessions/$sessionId/participants/self/withdraw',
    );
  }
}

Map<String, dynamic> _asMap(Object? value) => value is Map
    ? value.map((key, item) => MapEntry(key.toString(), item))
    : const <String, dynamic>{};

String? _safeCursor(Object? value) {
  final cursor = value?.toString().trim();
  return cursor == null || cursor.isEmpty ? null : cursor;
}
