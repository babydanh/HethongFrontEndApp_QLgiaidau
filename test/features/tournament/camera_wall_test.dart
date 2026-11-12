import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_wall.dart';
import 'package:flutter_test/flutter_test.dart';

TournamentCameraModel _camera(
  String id, {
  String status = 'LIVE',
  String? courtId,
}) => TournamentCameraModel(
  id: id,
  name: 'Camera $id',
  mode: 'PULL',
  status: status,
  courtId: courtId,
  playbackUrl: 'https://cdn.test/$id.m3u8',
);

MatchModel _match(
  String id, {
  String status = 'SCHEDULED',
  String? courtId,
  DateTime? scheduledTime,
}) => MatchModel(
  id: id,
  tournamentId: 't1',
  round: 1,
  matchNumber: 1,
  bracketPosition: BracketPosition(round: 1, position: 1),
  team1Id: 'a',
  team2Id: 'b',
  team1Name: 'A $id',
  team2Name: 'B $id',
  status: status,
  courtId: courtId,
  scheduledTime: scheduledTime,
  updatedAt: DateTime.utc(2026, 1, 1),
);

String _label(MatchModel match) => 'L:${match.id}';

String _wallLabel(
  TournamentCameraModel camera,
  List<MatchModel> matches, [
  Map<String, MatchLivestreamSummary> streams = const {},
]) => cameraMatchLabel(
  camera: camera,
  matches: matches,
  livestreams: streams,
  labelOf: _label,
  noMatchLabel: 'Chưa có trận',
);

void main() {
  final cameras = [for (var i = 1; i <= 10; i++) _camera('c$i')];

  group('wallPage', () {
    test('TC-CAMWALL-APP-01 layout 2 gives 4 cells per page and 3 pages for '
        '10 cameras', () {
      final first = wallPage(cameras, 2, 1);
      expect(first.items.map((c) => c.id), ['c1', 'c2', 'c3', 'c4']);
      expect(first.pageCount, 3);
      expect(first.page, 1);
      expect(wallPage(cameras, 2, 3).items.map((c) => c.id), ['c9', 'c10']);
    });

    test('TC-CAMWALL-APP-02 page is clamped into [1, pageCount]', () {
      expect(wallPage(cameras, 2, 0).page, 1);
      expect(wallPage(cameras, 2, 99).page, 3);
      expect(wallPage(cameras, 2, 99).items.map((c) => c.id), ['c9', 'c10']);
    });

    test('TC-CAMWALL-APP-03 layout 1 shows one camera per page', () {
      final result = wallPage(cameras, 1, 4);
      expect(result.items.map((c) => c.id), ['c4']);
      expect(result.pageCount, 10);
    });

    test('TC-CAMWALL-APP-04 no cameras still has one empty page', () {
      final result = wallPage(const <TournamentCameraModel>[], 3, 5);
      expect(result.items, isEmpty);
      expect(result.pageCount, 1);
      expect(result.page, 1);
    });

    test('TC-CAMWALL-APP-05 layout below 1 is treated as 1', () {
      expect(wallPage(cameras, 0, 1).pageCount, 10);
    });
  });

  group('shouldMountPlayer', () {
    test('TC-CAMWALL-APP-06 mounts only for a LIVE camera with preview on', () {
      expect(shouldMountPlayer(_camera('a'), true), isTrue);
      expect(shouldMountPlayer(_camera('a'), false), isFalse);
      for (final status in [
        'IDLE',
        'ASSIGNED',
        'WAITING',
        'OFFLINE',
        'ERROR',
      ]) {
        expect(
          shouldMountPlayer(_camera('a', status: status), true),
          isFalse,
          reason: status,
        );
      }
    });

    test(
      'TC-CAMWALL-APP-07 a LIVE camera without playback url never mounts',
      () {
        const camera = TournamentCameraModel(
          id: 'a',
          name: 'A',
          mode: 'PULL',
          status: 'LIVE',
        );
        expect(shouldMountPlayer(camera, true), isFalse);
      },
    );
  });

  group('cameraMatchLabel', () {
    final camera = _camera('c1', courtId: 'court-1');

    test(
      'TC-CAMWALL-APP-08 prefers the match streaming through the camera',
      () {
        final matches = [
          _match('ongoing', status: 'ONGOING', courtId: 'court-1'),
          _match('streamed', courtId: 'court-1'),
        ];
        final streams = {
          'streamed': const MatchLivestreamSummary(
            matchId: 'streamed',
            cameraId: 'c1',
            streamStatus: MatchStreamStatus.live,
          ),
        };
        expect(_wallLabel(camera, matches, streams), 'L:streamed');
      },
    );

    test('TC-CAMWALL-APP-09 ignores a stream on another camera', () {
      final matches = [_match('m', status: 'ONGOING', courtId: 'court-1')];
      final streams = {
        'm': const MatchLivestreamSummary(
          matchId: 'm',
          cameraId: 'other',
          streamStatus: MatchStreamStatus.live,
        ),
      };
      expect(_wallLabel(camera, matches, streams), 'L:m');
    });

    test('TC-CAMWALL-APP-10 falls back to the ONGOING match on the court', () {
      final matches = [
        _match('later', courtId: 'court-1'),
        _match('ongoing', status: 'ONGOING', courtId: 'court-1'),
        _match('elsewhere', status: 'ONGOING', courtId: 'court-2'),
      ];
      expect(_wallLabel(camera, matches), 'L:ongoing');
    });

    test(
      'TC-CAMWALL-APP-11 then the earliest SCHEDULED match on the court',
      () {
        final matches = [
          _match(
            'b',
            courtId: 'court-1',
            scheduledTime: DateTime.utc(2026, 5, 2),
          ),
          _match(
            'a',
            courtId: 'court-1',
            scheduledTime: DateTime.utc(2026, 5, 1),
          ),
          _match('none', courtId: 'court-1'),
        ];
        expect(_wallLabel(camera, matches), 'L:a');
      },
    );

    test('TC-CAMWALL-APP-12 says there is no match when nothing applies', () {
      final matches = [
        _match('done', status: 'COMPLETED', courtId: 'court-1'),
        _match('other', courtId: 'court-2'),
      ];
      expect(_wallLabel(camera, matches), 'Chưa có trận');
      expect(
        _wallLabel(_camera('free'), [_match('m', courtId: 'court-1')]),
        'Chưa có trận',
      );
    });
  });

  group('cameraSummary / cameraSignal', () {
    test('TC-CAMWALL-APP-13 counts cameras, LIVE and failing ones', () {
      final summary = cameraSummary([
        _camera('a'),
        _camera('b'),
        _camera('c', status: 'OFFLINE'),
        _camera('d', status: 'ERROR'),
        _camera('e', status: 'IDLE'),
      ]);
      expect(summary.total, 5);
      expect(summary.live, 2);
      expect(summary.failing, 2);
    });

    test('TC-CAMWALL-APP-14 signal: green LIVE, yellow connecting, red '
        'OFFLINE/ERROR, grey the rest', () {
      expect(cameraSignal(_camera('a')), CameraSignal.live);
      expect(
        cameraSignal(
          const TournamentCameraModel(
            id: 'a',
            name: 'A',
            mode: 'PULL',
            status: 'LIVE',
          ),
        ),
        CameraSignal.connecting,
      );
      expect(
        cameraSignal(_camera('a', status: 'OFFLINE')),
        CameraSignal.failed,
      );
      expect(cameraSignal(_camera('a', status: 'ERROR')), CameraSignal.failed);
      for (final status in ['IDLE', 'ASSIGNED', 'WAITING', 'XYZ']) {
        expect(
          cameraSignal(_camera('a', status: status)),
          CameraSignal.idle,
          reason: status,
        );
      }
    });
  });
}
