import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/venue_suggestion.dart';
import 'package:app_quanly_giaidau/domain/repositories/venue_search_repository.dart';

class ApiVenueSearchRepository implements IVenueSearchRepository {
  final DioClient _dioClient;

  ApiVenueSearchRepository(this._dioClient);

  @override
  Future<List<VenueSuggestion>> search(String query, {int limit = 8}) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 2) return const <VenueSuggestion>[];

    final safeLimit = limit.clamp(1, 8).toInt();
    final response = await _dioClient.dio.get(
      '/venues',
      queryParameters: {
        'search': normalizedQuery,
        'page': 1,
        'limit': safeLimit,
      },
    );

    final body = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : const <String, dynamic>{};
    final rows = body['data'];
    if (rows is! List) {
      throw const FormatException('Expected a venue list in the API response.');
    }

    final venues = <VenueSuggestion>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final venue = VenueSuggestion.fromJson(Map<String, dynamic>.from(row));
      if (venue.isSelectable) venues.add(venue);
    }

    return venues.take(safeLimit).toList(growable: false);
  }

  @override
  Future<VenueDetails> getById(String venueId) async {
    final response = await _dioClient.dio.get('/venues/$venueId');
    final body = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : const <String, dynamic>{};
    final rawData = body['data'];
    if (rawData is! Map) {
      throw const FormatException(
        'Expected venue details in the API response.',
      );
    }
    final details = VenueDetails.fromJson(
      rawData.map((key, value) => MapEntry(key.toString(), value)),
    );
    if (!details.venue.isSelectable || details.venue.id != venueId) {
      throw const FormatException(
        'Venue details did not match the requested venue.',
      );
    }
    return details;
  }
}
