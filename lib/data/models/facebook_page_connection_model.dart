enum FacebookPageConnectionStatus { active, disconnected, revoked, unknown }

FacebookPageConnectionStatus facebookPageConnectionStatusFromString(
  String? value,
) {
  switch (value?.toUpperCase()) {
    case 'ACTIVE':
      return FacebookPageConnectionStatus.active;
    case 'DISCONNECTED':
      return FacebookPageConnectionStatus.disconnected;
    case 'REVOKED':
      return FacebookPageConnectionStatus.revoked;
    default:
      return FacebookPageConnectionStatus.unknown;
  }
}

/// Community-scoped Facebook Page connection as returned by
/// `GET /livestream/facebook/connection` and `POST /livestream/facebook/validate`.
///
/// Mirrors the backend's `PublicFacebookPageConnection` and deliberately carries
/// no page access token, no encrypted credential and no publish capability: the
/// backend never puts those in this payload, so the mobile app must not model
/// them either.
class FacebookPageConnectionModel {
  const FacebookPageConnectionModel({
    required this.id,
    required this.communityId,
    required this.pageId,
    required this.pageName,
    required this.status,
    this.connectedAt,
    this.lastValidatedAt,
  });

  final String id;
  final String communityId;
  final String pageId;
  final String pageName;
  final FacebookPageConnectionStatus status;
  final DateTime? connectedAt;
  final DateTime? lastValidatedAt;

  bool get isActive => status == FacebookPageConnectionStatus.active;

  factory FacebookPageConnectionModel.fromJson(Map<String, Object?> json) {
    return FacebookPageConnectionModel(
      id: json['id']?.toString() ?? '',
      communityId: json['communityId']?.toString() ?? '',
      pageId: json['pageId']?.toString() ?? '',
      pageName: json['pageName']?.toString() ?? '',
      status: facebookPageConnectionStatusFromString(
        json['status']?.toString(),
      ),
      connectedAt: DateTime.tryParse(json['connectedAt']?.toString() ?? ''),
      lastValidatedAt: DateTime.tryParse(
        json['lastValidatedAt']?.toString() ?? '',
      ),
    );
  }
}
