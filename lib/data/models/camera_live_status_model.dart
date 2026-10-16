enum CameraLiveStatus { live, idle, archived }

/// Allowlisted, read-only projection of a backend camera signal check.
class CameraLiveStatusModel {
  const CameraLiveStatusModel({
    required this.cameraId,
    required this.online,
    required this.status,
  });

  final String cameraId;
  final bool online;
  final CameraLiveStatus status;

  factory CameraLiveStatusModel.fromJson(Map<String, Object?> json) {
    final cameraId = json['cameraId'];
    final online = json['online'];
    final status = switch (json['status']) {
      'LIVE' => CameraLiveStatus.live,
      'IDLE' => CameraLiveStatus.idle,
      'ARCHIVED' => CameraLiveStatus.archived,
      _ => null,
    };

    if (cameraId is! String || cameraId.trim().isEmpty) {
      throw const FormatException('Invalid camera status response.');
    }
    if (online is! bool || status == null) {
      throw const FormatException('Invalid camera status response.');
    }

    return CameraLiveStatusModel(
      cameraId: cameraId,
      online: online,
      status: status,
    );
  }
}
