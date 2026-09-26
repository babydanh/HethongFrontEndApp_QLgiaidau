class VenueSuggestion {
  final String? id;
  final String name;
  final String locationAddress;

  const VenueSuggestion({
    this.id,
    required this.name,
    required this.locationAddress,
  });

  factory VenueSuggestion.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawName = json['name'];
    final rawAddress = json['locationAddress'];

    return VenueSuggestion(
      id: rawId is String ? rawId : null,
      name: rawName is String ? rawName.trim() : '',
      locationAddress: rawAddress is String ? rawAddress.trim() : '',
    );
  }

  bool get isSelectable => name.isNotEmpty && locationAddress.isNotEmpty;
}

class VenueCourtSuggestion {
  final String id;
  final String name;
  final String status;

  const VenueCourtSuggestion({
    required this.id,
    required this.name,
    required this.status,
  });

  bool get isAvailable => status.toUpperCase() == 'AVAILABLE';

  factory VenueCourtSuggestion.fromJson(Map<String, dynamic> json) {
    return VenueCourtSuggestion(
      id: json['id']?.toString() ?? '',
      name: (json['courtName'] ?? json['name'])?.toString().trim() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class VenueDetails {
  final VenueSuggestion venue;
  final List<VenueCourtSuggestion> courts;

  const VenueDetails({required this.venue, this.courts = const []});

  factory VenueDetails.fromJson(Map<String, dynamic> json) {
    final rawCourts = json['courts'];
    final courts = rawCourts is List
        ? rawCourts
              .whereType<Map>()
              .map(
                (row) => VenueCourtSuggestion.fromJson(
                  row.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .where((court) => court.isAvailable && court.id.isNotEmpty)
              .toList(growable: false)
        : const <VenueCourtSuggestion>[];
    return VenueDetails(venue: VenueSuggestion.fromJson(json), courts: courts);
  }
}
