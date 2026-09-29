/// Camera projection of a tournament court, as returned by
/// `GET /livestream/tournaments/{id}/cameras` and by the court playback-url
/// upsert.
///
/// This is a *court* camera — the backend calls it a PULL camera. It carries
/// the public playback URL and nothing else: no stream key, no RTSP
/// credential, no publish URL ever enters the app. It is deliberately a
/// different model from `CameraDeviceModel`, which describes the community
/// hardware fleet (pairing, heartbeats, operator assignment).
class TournamentCameraModel {
  const TournamentCameraModel({
    required this.id,
    required this.name,
    required this.mode,
    required this.status,
    this.courtId,
    this.playbackUrl,
  });

  final String id;
  final String name;
  final String mode;
  final String status;
  final String? courtId;
  final String? playbackUrl;

  factory TournamentCameraModel.fromJson(Map<String, Object?> json) {
    String? readText(Object? value) {
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return TournamentCameraModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mode: (json['mode'] ?? json['type'])?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      courtId: readText(json['courtId'] ?? json['court_id']),
      playbackUrl: readText(json['playbackUrl'] ?? json['playback_url']),
    );
  }

  /// A court only counts as "camera ready" when its camera actually publishes
  /// a playback URL. Same rule as the web organizer board, so the two clients
  /// never disagree about a court's state.
  bool get hasPlaybackUrl => playbackUrl != null && playbackUrl!.isNotEmpty;
}
