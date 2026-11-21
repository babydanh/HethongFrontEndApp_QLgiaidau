import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_facebook_code.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAMFB-01..05: pure rules behind "Xem mã phát" and "Sửa camera".
TournamentCameraModel _camera({
  String? playbackUrl,
  String status = 'IDLE',
  bool editable = false,
  String name = 'Cam A',
}) => TournamentCameraModel(
  id: 'cam-1',
  name: name,
  mode: 'PULL',
  status: status,
  playbackUrl: playbackUrl,
  playbackUrlEditable: editable,
);

DioException _dio(int status, Object? data) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: status,
    data: data,
  ),
);

const _fbUrl = 'https://www.facebook.com/page/videos/1234567890';

void main() {
  group('TC-CAMFB-01 TournamentCameraModel.playbackUrlEditable', () {
    test('defaults to false when the payload omits the flag', () {
      final camera = TournamentCameraModel.fromJson(const {
        'id': 'c',
        'name': 'n',
      });
      expect(camera.playbackUrlEditable, isFalse);
    });

    test('reads true only for a real boolean true', () {
      expect(
        TournamentCameraModel.fromJson(const {
          'id': 'c',
          'playbackUrlEditable': true,
        }).playbackUrlEditable,
        isTrue,
      );
      expect(
        TournamentCameraModel.fromJson(const {
          'id': 'c',
          'playbackUrlEditable': 'true',
        }).playbackUrlEditable,
        isFalse,
      );
    });
  });

  group('TC-CAMFB-02 canViewFacebookCode', () {
    test('true for a Facebook live link', () {
      expect(canViewFacebookCode(_camera(playbackUrl: _fbUrl)), isTrue);
    });

    test('false for YouTube, plain HLS, empty and missing links', () {
      expect(
        canViewFacebookCode(
          _camera(playbackUrl: 'https://www.youtube.com/watch?v=abcdefghijk'),
        ),
        isFalse,
      );
      expect(
        canViewFacebookCode(_camera(playbackUrl: 'https://p.example/1.m3u8')),
        isFalse,
      );
      expect(canViewFacebookCode(_camera()), isFalse);
    });
  });

  group('TC-CAMFB-03 canRegenerateFacebookCode', () {
    test('needs an editable URL and a camera that is not LIVE', () {
      expect(
        canRegenerateFacebookCode(_camera(editable: true, status: 'IDLE')),
        isTrue,
      );
      expect(
        canRegenerateFacebookCode(_camera(editable: true, status: 'LIVE')),
        isFalse,
      );
      expect(canRegenerateFacebookCode(_camera(editable: false)), isFalse);
    });
  });

  group('TC-CAMFB-04 isFacebookLiveCodeExpired', () {
    test('matches the backend code only', () {
      expect(
        isFacebookLiveCodeExpired(
          _dio(404, {'code': 'FACEBOOK_LIVE_CODE_EXPIRED'}),
        ),
        isTrue,
      );
      expect(isFacebookLiveCodeExpired(_dio(404, {'code': 'OTHER'})), isFalse);
      expect(isFacebookLiveCodeExpired(_dio(404, 'x')), isFalse);
      expect(isFacebookLiveCodeExpired(StateError('x')), isFalse);
    });
  });

  group('TC-CAMFB-05 buildCameraPatch', () {
    test('sends only the changed name', () {
      final patch = buildCameraPatch(
        _camera(name: 'Cam A', playbackUrl: _fbUrl, editable: true),
        name: ' Cam B ',
        playbackUrl: _fbUrl,
      );
      expect(patch.toJson(), {'name': 'Cam B'});
    });

    test('sends only the changed URL when it is editable', () {
      final patch = buildCameraPatch(
        _camera(name: 'Cam A', playbackUrl: _fbUrl, editable: true),
        name: 'Cam A',
        playbackUrl: ' https://p.example/2.m3u8 ',
      );
      expect(patch.toJson(), {'playbackUrl': 'https://p.example/2.m3u8'});
    });

    test('drops the URL when the backend does not allow editing it', () {
      final patch = buildCameraPatch(
        _camera(name: 'Cam A', playbackUrl: _fbUrl),
        name: 'Cam B',
        playbackUrl: 'https://p.example/2.m3u8',
      );
      expect(patch.toJson(), {'name': 'Cam B'});
    });

    test('is empty when nothing changed or the fields are blank', () {
      final camera = _camera(
        name: 'Cam A',
        playbackUrl: _fbUrl,
        editable: true,
      );
      expect(
        buildCameraPatch(camera, name: 'Cam A', playbackUrl: _fbUrl).isEmpty,
        isTrue,
      );
      expect(
        buildCameraPatch(camera, name: '  ', playbackUrl: '').isEmpty,
        isTrue,
      );
    });
  });
}
