/// AQP stream-key state of one PUSH camera, as returned by the
/// `.../cameras/{id}/aqp-stream-key` routes.
///
/// The key, the RTMP server and the QR payload are credentials: [toString] is
/// overridden so none of them can reach a log or an exception message.
class CameraStreamKeyModel {
  const CameraStreamKeyModel({
    required this.cameraId,
    required this.streamName,
    this.streamKeyId,
    this.status,
    this.qrPayloadString,
    this.rtmpServer,
    this.rtmpStreamKey,
  });

  final String cameraId;
  final String streamName;
  final String? streamKeyId;
  final String? status;

  /// The string the publisher app scans; the only part of `qrPayload` the app
  /// needs.
  final String? qrPayloadString;
  final String? rtmpServer;
  final String? rtmpStreamKey;

  /// A key is live only when the server returned the RTMP credentials. A
  /// `streamKeyId` without them means AQP forgot the key.
  bool get hasKey => rtmpServer != null && rtmpStreamKey != null;

  factory CameraStreamKeyModel.fromJson(Map<String, Object?> json) {
    String? readText(Object? value) {
      if (value is! String) return null;
      return value.isEmpty ? null : value;
    }

    final camera = json['camera'];
    final rtmp = json['rtmp'];
    final cameraMap = camera is Map ? camera : const <Object?, Object?>{};
    final rtmpMap = rtmp is Map ? rtmp : const <Object?, Object?>{};
    final server = readText(rtmpMap['server']);
    final key = readText(rtmpMap['streamKey']);
    return CameraStreamKeyModel(
      cameraId: cameraMap['id']?.toString() ?? '',
      streamName: cameraMap['streamName']?.toString() ?? '',
      streamKeyId: readText(json['streamKeyId']),
      status: readText(json['status']),
      qrPayloadString: readText(json['qrPayloadString']),
      rtmpServer: server != null && key != null ? server : null,
      rtmpStreamKey: server != null && key != null ? key : null,
    );
  }

  @override
  String toString() =>
      'CameraStreamKeyModel(cameraId: $cameraId, streamKeyId: $streamKeyId, hasKey: $hasKey)';
}
