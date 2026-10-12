import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:latlong2/latlong.dart';

abstract class ISocialLocationRepository {
  Future<List<SocialPlace>> search(String query, {LatLng? bias});
  Future<SocialPlace> getVenueDetail(String venueId);
  Future<SocialPlace> getPlaceDetail(String placeId);
  Future<SocialPlace> resolveInput(String addressOrMapsUrl);
  Future<SocialPlace> reverseLookup(LatLng pin);
}

sealed class SocialLocationFailure implements Exception {
  const SocialLocationFailure();
}

class LocationNotFound extends SocialLocationFailure {
  const LocationNotFound();
}

class UnresolvableLocation extends SocialLocationFailure {
  const UnresolvableLocation();
}

class LocationNetworkFailure extends SocialLocationFailure {
  const LocationNetworkFailure();
}

class UnsupportedLocationLink extends SocialLocationFailure {
  const UnsupportedLocationLink();
}
