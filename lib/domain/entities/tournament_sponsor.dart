class TournamentSponsor {
  final String id;
  final String displayName;
  final String tier;
  final String logoUrl;
  final String? websiteUrl;
  final String? shortDescription;
  final int displayOrder;
  final String status;
  final bool? isPublic;

  const TournamentSponsor({
    required this.id,
    required this.displayName,
    required this.tier,
    required this.logoUrl,
    this.websiteUrl,
    this.shortDescription,
    this.displayOrder = 0,
    this.status = 'PUBLISHED',
    this.isPublic,
  });

  factory TournamentSponsor.fromJson(Map<String, dynamic> json) {
    return TournamentSponsor(
      id: (json['id'] ?? '').toString(),
      displayName: (json['displayName'] ?? json['display_name'] ?? '')
          .toString(),
      tier: (json['tier'] ?? 'GOLD').toString(),
      logoUrl: (json['logoUrl'] ?? json['logo_url'] ?? '').toString(),
      websiteUrl: (json['websiteUrl'] ?? json['website_url'])?.toString(),
      shortDescription: (json['shortDescription'] ?? json['short_description'])
          ?.toString(),
      displayOrder: _toInt(json['displayOrder'] ?? json['display_order']) ?? 0,
      status: (json['status'] ?? 'PUBLISHED').toString(),
      isPublic: _toBool(json['isPublic'] ?? json['is_public']),
    );
  }

  /// Archived sponsors stay in the list but can no longer be shown or toggled.
  bool get isArchived => status.toUpperCase() == 'ARCHIVED';

  /// Mirrors the public sponsors page: published, flagged public, not archived.
  bool get isShownPublicly =>
      !isArchived && status.toUpperCase() == 'PUBLISHED' && (isPublic ?? true);

  static bool? _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return switch (value.toLowerCase()) {
        'true' => true,
        'false' => false,
        _ => null,
      };
    }
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

/// `displayOrder` updates needed after the list was reordered: only the
/// sponsors whose index differs from their stored order, keyed by id.
Map<String, int> sponsorOrderChanges(List<TournamentSponsor> ordered) => {
  for (var index = 0; index < ordered.length; index++)
    if (ordered[index].displayOrder != index) ordered[index].id: index,
};
