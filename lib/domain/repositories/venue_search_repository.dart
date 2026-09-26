import 'package:app_quanly_giaidau/data/models/venue_suggestion.dart';

abstract class IVenueSearchRepository {
  Future<List<VenueSuggestion>> search(String query, {int limit = 8});
  Future<VenueDetails> getById(String venueId);
}
