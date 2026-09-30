/// A location chosen for a Social session. Coordinates are optional for old
/// sessions and search results, but address/link previews require both.
class SocialPlace {
  const SocialPlace({
    required this.name,
    required this.formattedAddress,
    this.latitude,
    this.longitude,
  });

  final String name;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;

  bool get hasReadableAddress => formattedAddress.trim().isNotEmpty;
  bool get hasPin => latitude != null && longitude != null;
  bool get canApply => name.trim().isNotEmpty && hasReadableAddress;
  bool get canPreview => canApply && hasPin;
}
