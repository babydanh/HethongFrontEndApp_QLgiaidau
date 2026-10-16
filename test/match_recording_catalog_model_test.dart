import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:flutter_test/flutter_test.dart';

const _matchId = '550e8400-e29b-41d4-a716-446655440001';

void main() {
  test('control state consumes only the camera-assignment decision', () {
    final state = MatchStreamControlStateModel.fromJson(<String, Object?>{
      'matchId': _matchId,
      'hasCamera': false,
      'streamStatus': 'LIVE',
      'streamName': 'provider-secret-stream',
      'recordingUrl': 'https://media.example.test/private.mp4',
    });

    expect(state.matchId, _matchId);
    expect(state.hasCamera, isFalse);
    expect(
      () => (state as dynamic).streamName,
      throwsA(isA<NoSuchMethodError>()),
    );
  });

  test('recording days keep valid calendar dates in server order only', () {
    final days = MatchRecordingDaysModel.fromJson(<Object?>[
      '2026-10-09',
      '2026-02-30',
      '2026-10-08',
      '2026-10-09',
      20261007,
    ]);

    expect(days.days, <String>['2026-10-09', '2026-10-08']);
  });

  test('recording files retain safe names and valid optional byte sizes', () {
    final files = MatchRecordingFileModel.listFromJson(<Object?>[
      <String, Object?>{
        'name': 'court-final.mp4',
        'sizeBytes': 0,
        'recordingUrl': 'https://media.example.test/private.mp4',
        'rootPath': '/private/root',
      },
      <String, Object?>{'name': '../secret.mp4', 'sizeBytes': 25},
      <String, Object?>{'name': r'folder\secret.mp4', 'sizeBytes': 25},
      <String, Object?>{'name': 'fractional.mp4', 'sizeBytes': 1.5},
      <String, Object?>{'name': 'negative.mp4', 'sizeBytes': -1},
      <String, Object?>{'name': 'notes.txt', 'sizeBytes': 25},
    ]);

    expect(files.map((file) => file.name), <String>[
      'court-final.mp4',
      'fractional.mp4',
      'negative.mp4',
    ]);
    expect(files.map((file) => file.sizeBytes), <int?>[0, null, null]);
    expect(
      () => (files.first as dynamic).recordingUrl,
      throwsA(isA<NoSuchMethodError>()),
    );
  });
}
