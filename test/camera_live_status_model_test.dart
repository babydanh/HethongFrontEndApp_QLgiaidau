import 'package:app_quanly_giaidau/data/models/camera_live_status_model.dart';
import 'package:flutter_test/flutter_test.dart';

const _cameraId = '550e8400-e29b-41d4-a716-446655440000';

void main() {
  test('projects only signal fields and preserves archived status', () {
    final status = CameraLiveStatusModel.fromJson(<String, Object?>{
      'cameraId': _cameraId,
      'streamName': 'provider-secret-stream',
      'online': false,
      'status': 'ARCHIVED',
      'publishKey': 'secret-key',
      'recordingUrl': 'https://media.example.test/private.mp4',
    });

    expect(status.cameraId, _cameraId);
    expect(status.online, isFalse);
    expect(status.status, CameraLiveStatus.archived);
    expect(
      () => (status as dynamic).streamName,
      throwsA(isA<NoSuchMethodError>()),
    );
  });

  test('rejects malformed signal state instead of misreporting offline', () {
    expect(
      () => CameraLiveStatusModel.fromJson(<String, Object?>{
        'cameraId': _cameraId,
        'online': 'false',
        'status': 'IDLE',
      }),
      throwsFormatException,
    );
    expect(
      () => CameraLiveStatusModel.fromJson(<String, Object?>{
        'cameraId': _cameraId,
        'online': false,
        'status': 'UNKNOWN',
      }),
      throwsFormatException,
    );
  });
}
