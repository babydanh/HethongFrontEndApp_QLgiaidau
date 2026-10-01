import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:latlong2/latlong.dart';

abstract class ISocialLocationRepository {
  Future<List<SocialPlace>> search(String query, {LatLng? bias});
  Future<SocialPlace> resolveInput(String addressOrMapsUrl);
  Future<SocialPlace> reverseLookup(LatLng pin);
  Future<SocialPlace> getPlaceDetail(String placeId);
}

sealed class SocialLocationFailure implements Exception {
  const SocialLocationFailure();
}

class LocationNotFound extends SocialLocationFailure {
  const LocationNotFound();
}

class UnsupportedLocationLink extends SocialLocationFailure {
  const UnsupportedLocationLink();
}

class UnresolvableLocation extends SocialLocationFailure {
  const UnresolvableLocation();
}

class LocationNetworkFailure extends SocialLocationFailure {
  const LocationNetworkFailure();
}
