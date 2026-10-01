/// A location chosen for a Social session. Coordinates are optional for old
/// sessions and search results, but address/link previews require both.
class SocialPlace {
  const SocialPlace({
    required this.name,
    required this.formattedAddress,
    this.latitude,
    this.longitude,
    this.placeId,
    this.sourceProvince,
    this.sourceWard,
    this.provinceCode,
    this.wardCode,
    this.regionEstimated = false,
  });

  final String name;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;
  final String? placeId;
  final String? sourceProvince;
  final String? sourceWard;
  final String? provinceCode;
  final String? wardCode;
  final bool regionEstimated;

  bool get hasReadableAddress => formattedAddress.trim().isNotEmpty;
  bool get hasPin => latitude != null && longitude != null;
  bool get canApply => name.trim().isNotEmpty && hasReadableAddress;
  bool get canPreview => canApply && hasPin;

  factory SocialPlace.fromJson(Map<dynamic, dynamic> json) {
    return SocialPlace(
      name: json['name']?.toString().trim() ?? '',
      formattedAddress: json['formattedAddress']?.toString().trim() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      placeId: json['placeId']?.toString(),
      sourceProvince: json['sourceProvince']?.toString(),
      sourceWard: json['sourceWard']?.toString(),
      provinceCode: json['provinceCode']?.toString(),
      wardCode: json['wardCode']?.toString(),
      regionEstimated: json['regionEstimated'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'formattedAddress': formattedAddress,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (placeId != null) 'placeId': placeId,
    if (sourceProvince != null) 'sourceProvince': sourceProvince,
    if (sourceWard != null) 'sourceWard': sourceWard,
    if (provinceCode != null) 'provinceCode': provinceCode,
    if (wardCode != null) 'wardCode': wardCode,
    if (regionEstimated) 'regionEstimated': regionEstimated,
  };
}
