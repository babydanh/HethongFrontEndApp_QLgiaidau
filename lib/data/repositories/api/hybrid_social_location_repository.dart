import 'package:app_quanly_giaidau/core/utils/vietnam_address_parser.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/data/repositories/api/nominatim_reverse_datasource.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:latlong2/latlong.dart';

/// Tìm kiếm địa điểm kết hợp: Photon (sân/đường + tọa độ) và danh mục
/// hành chính backend (`provinces`/`wards` qua `GET /regions/search`).
///
/// - Kết quả Photon có pin xếp trước, kết quả khu vực (không pin) xếp sau
///   và vẫn `canApply` để host lưu `venueName`/`venueAddress` khi chưa cần
///   ghim chính xác (AC4/AC8: `latitude`/`longitude` optional).
/// - Hỏng một nguồn không giết nguồn còn lại; chỉ ném
///   [LocationNetworkFailure] khi **cả hai** đều lỗi mạng.
/// - `reverseLookup`: Photon trước, fallback Nominatim khi Photon rỗng/lỗi.
class HybridSocialLocationRepository implements ISocialLocationRepository {
  HybridSocialLocationRepository({
    required ISocialLocationRepository photon,
    required IRegionRepository regions,
    required NominatimReverseDataSource nominatim,
  }) : _photon = photon,
       _regions = regions,
       _nominatim = nominatim;

  final ISocialLocationRepository _photon;
  final IRegionRepository _regions;
  final NominatimReverseDataSource _nominatim;

  static const _maxResults = 10;
  static const _maxRegionResults = 5;

  @override
  Future<List<SocialPlace>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    List<SocialPlace> photonResults = const [];
    Object? photonError;
    List<Region> regionResults = const [];
    Object? regionError;

    await Future.wait([
      () async {
        try {
          photonResults = await _photon.search(trimmed);
        } catch (e) {
          photonError = e;
        }
      }(),
      () async {
        try {
          regionResults = await _regions.searchRegions(
            trimmed,
            limit: _maxRegionResults,
          );
        } catch (e) {
          regionError = e;
        }
      }(),
    ]);

    final merged = <SocialPlace>[
      ...photonResults.where((place) => place.canApply),
    ];
    final seen = merged.map(_dedupKey).toSet();
    for (final region in regionResults) {
      final place = _regionToPlace(region);
      if (!place.canApply) continue;
      final key = _dedupKey(place);
      if (seen.add(key)) merged.add(place);
    }

    if (merged.isEmpty && (photonError != null || regionError != null)) {
      throw const LocationNetworkFailure();
    }
    return merged.take(_maxResults).toList(growable: false);
  }

  @override
  Future<SocialPlace> resolveInput(String addressOrMapsUrl) async {
    final value = addressOrMapsUrl.trim();
    if (value.isEmpty) throw const LocationNotFound();
    // AC5 requires a pinned place for the preview. Administrative regions
    // have no pin and must not turn a failed address lookup into a selection.
    return _photon.resolveInput(value);
  }

  @override
  Future<SocialPlace> reverseLookup(LatLng pin) async {
    try {
      final place = await _photon.reverseLookup(pin);
      return _withRegionSuffix(place);
    } catch (photonError) {
      try {
        final place = await _nominatim.reverse(pin);
        return _withRegionSuffix(place);
      } catch (_) {
        if (photonError is SocialLocationFailure) throw photonError;
        throw const UnresolvableLocation();
      }
    }
  }

  /// Region → SocialPlace: tên + "Phường X, Tỉnh Y", chưa có pin.
  /// Vẫn `canApply` nên chọn từ danh sách là lưu được ngay (AC4).
  SocialPlace _regionToPlace(Region region) {
    final address = region.displayAddress.trim();
    final name = region.name.trim();
    return SocialPlace(
      name: name.isEmpty ? address : name,
      formattedAddress: address.isEmpty ? name : address,
    );
  }

  /// Chuẩn hóa hậu tố Tỉnh/Phường nếu địa chỉ Photon/Nominatim thiếu:
  /// append "Ward, Province" khi detect được và chưa có trong chuỗi.
  Future<SocialPlace> _withRegionSuffix(SocialPlace place) async {
    try {
      final provinces = await _regions.getProvinces();
      if (provinces.isEmpty) return place;
      final detected = VietnamAddressParser.detectProvince<Region>(
        rawAddress: place.formattedAddress,
        provinces: provinces,
        getCode: (region) => region.code,
        getName: (region) => region.name,
        getFullName: (region) => region.fullName ?? region.name,
      );
      if (detected == null) return place;
      final normalizedAddress = VietnamAddressParser.removeVietnameseTones(
        place.formattedAddress,
      );
      final normalizedProvince = VietnamAddressParser.removeVietnameseTones(
        detected.name,
      );
      if (normalizedProvince.isNotEmpty &&
          !normalizedAddress.contains(normalizedProvince)) {
        return SocialPlace(
          name: place.name,
          formattedAddress: '${place.formattedAddress}, ${detected.name}',
          latitude: place.latitude,
          longitude: place.longitude,
        );
      }
    } catch (_) {
      // Enrich thất bại thì giữ nguyên kết quả gốc.
    }
    return place;
  }

  String _dedupKey(SocialPlace place) =>
      '${VietnamAddressParser.removeVietnameseTones(place.name)}|${VietnamAddressParser.removeVietnameseTones(place.formattedAddress)}';
}
