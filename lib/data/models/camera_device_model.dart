enum CameraDeviceStatus {
  unpaired,
  ready,
  online,
  live,
  offline,
  revoked,
  unknown,
}

CameraDeviceStatus cameraDeviceStatusFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'UNPAIRED':
      return CameraDeviceStatus.unpaired;
    case 'READY':
      return CameraDeviceStatus.ready;
    case 'ONLINE':
      return CameraDeviceStatus.online;
    case 'LIVE':
      return CameraDeviceStatus.live;
    case 'OFFLINE':
      return CameraDeviceStatus.offline;
    case 'REVOKED':
      return CameraDeviceStatus.revoked;
    default:
      return CameraDeviceStatus.unknown;
  }
}

class CameraDeviceModel {
  const CameraDeviceModel({
    required this.id,
    required this.communityId,
    required this.name,
    required this.status,
    this.code,
    this.defaultCourtId,
    this.assignedOperatorId,
    this.lastHeartbeatAt,
    this.pairedAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String communityId;
  final String name;
  final String? code;
  final String? defaultCourtId;
  final String? assignedOperatorId;
  final CameraDeviceStatus status;
  final DateTime? lastHeartbeatAt;
  final DateTime? pairedAt;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CameraDeviceModel.fromJson(Map<String, Object?> json) {
    DateTime? parseDate(Object? value) {
      final text = value?.toString();
      return text == null ? null : DateTime.tryParse(text);
    }

    return CameraDeviceModel(
      id: json['id']?.toString() ?? '',
      communityId: json['communityId']?.toString() ?? json['community_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      defaultCourtId: json['defaultCourtId']?.toString() ?? json['default_court_id']?.toString(),
      assignedOperatorId: json['assignedOperatorId']?.toString() ?? json['assigned_operator_id']?.toString(),
      status: cameraDeviceStatusFromString(json['status']?.toString()),
      lastHeartbeatAt: parseDate(json['lastHeartbeatAt'] ?? json['last_heartbeat_at']),
      pairedAt: parseDate(json['pairedAt'] ?? json['paired_at']),
      notes: json['notes']?.toString(),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }
}

class DevicePairingTokenModel {
  const DevicePairingTokenModel({
    required this.device,
    required this.pairingToken,
    required this.expiresAt,
  });

  final CameraDeviceModel device;
  final String pairingToken;
  final DateTime expiresAt;

  factory DevicePairingTokenModel.fromJson(Map<String, Object?> json) {
    final deviceJson = json['device'];
    final expiresAt = DateTime.tryParse(json['expiresAt']?.toString() ?? '') ?? DateTime.now();
    return DevicePairingTokenModel(
      device: CameraDeviceModel.fromJson(
        deviceJson is Map ? Map<String, Object?>.from(deviceJson) : const <String, Object?>{},
      ),
      pairingToken: json['pairingToken']?.toString() ?? '',
      expiresAt: expiresAt,
    );
  }
}
