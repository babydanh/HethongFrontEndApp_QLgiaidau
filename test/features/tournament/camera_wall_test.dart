import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_wall.dart';
import 'package:flutter_test/flutter_test.dart';

TournamentCameraModel _camera(
  String id, {
  String status = 'LIVE',
  String? courtId,
  String? playbackUrl = 'https://cdn.example/live.m3u8',
}) => TournamentCameraModel(
  id: id,
  name: 'Camera $id',
  mode: 'PULL',
  status: status,
  courtId: courtId,
  playbackUrl: playbackUrl,
);

MatchModel _match(
  String id, {
  String status = 'SCHEDULED',
  String? courtId,
  String? code,
  int number = 1,
  DateTime? scheduledTime,
  bool isBye = false,
  String team1 = 'Đội A',
  String team2 = 'Đội B',
}) => MatchModel(
  id: id,
  round: 1,
  matchNumber: number,
  matchCode: code,
  status: status,
  courtId: courtId,
  scheduledTime: scheduledTime,
  isBye: isBye,
  team1Id: 't1-$id',
  team2Id: 't2-$id',
  team1Name: team1,
  team2Name: team2,
  score1: 11,
  score2: 7,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime(2026, 11, 12),
);

MatchLivestreamSummary _stream(
  String matchId,
  String cameraId, {
  MatchStreamStatus status = MatchStreamStatus.live,
}) => MatchLivestreamSummary(
  matchId: matchId,
  cameraId: cameraId,
  streamStatus: status,
);

void main() {
  group('cameraWallPage', () {
    final cameras = [for (var i = 1; i <= 20; i++) _camera('c$i')];

    test('TC-APP-CAMWALL-01 trang 1 của lưới 4×4 có 16 ô, trang 2 có 4 ô', () {
      final first = cameraWallPage(cameras, 4, 1);
      final second = cameraWallPage(cameras, 4, 2);

      expect(first.items, hasLength(16));
      expect(first.pageCount, 2);
      expect(second.items.map((c) => c.id), ['c17', 'c18', 'c19', 'c20']);
      expect(second.page, 2);
    });

    test(
      'TC-APP-CAMWALL-02 kẹp trang ngoài khoảng và luôn có pageCount >= 1',
      () {
        expect(cameraWallPage(cameras, 4, 99).page, 2);
        expect(cameraWallPage(cameras, 4, -3).page, 1);
        final empty = cameraWallPage(const [], 2, 1);
        expect(empty.items, isEmpty);
        expect(empty.pageCount, 1);
        expect(empty.page, 1);
      },
    );
  });

  group('shouldMountCameraPlayer', () {
    test(
      'TC-APP-CAMWALL-03 chỉ mở khi LIVE, có playbackUrl và xem thử bật',
      () {
        expect(shouldMountCameraPlayer(_camera('a'), true), isTrue);
        expect(shouldMountCameraPlayer(_camera('a'), false), isFalse);
        expect(
          shouldMountCameraPlayer(_camera('a', status: 'OFFLINE'), true),
          isFalse,
        );
        expect(
          shouldMountCameraPlayer(_camera('a', playbackUrl: null), true),
          isFalse,
        );
      },
    );
  });

  group('cameraWallPageOf', () {
    test('TC-APP-CAMWALL-04 trả trang chứa camera, không thấy thì trang 1', () {
      final cameras = [for (var i = 1; i <= 20; i++) _camera('c$i')];

      expect(cameraWallPageOf(cameras, 'c17', 4), 2);
      expect(cameraWallPageOf(cameras, 'c5', 1), 5);
      expect(cameraWallPageOf(cameras, 'khong-co', 2), 1);
    });
  });

  group('cameraWallMatchLabel', () {
    test(
      'TC-APP-CAMWALL-05 ưu tiên trận đang phát qua camera, mã #CK01, không tỉ số',
      () {
        final camera = _camera('cam1', courtId: 'court1');
        final matches = [
          _match('m1', status: 'ONGOING', courtId: 'court1', code: 'ON1'),
          _match('m2', code: 'CK01'),
        ];

        final label = cameraWallMatchLabel(camera, {
          'm2': _stream('m2', 'cam1'),
        }, matches);

        expect(label, isNotNull);
        expect(label!.kind, 'live');
        expect(label.code, 'CK01');
        expect(label.team1, 'Đội A');
        expect(label.team2, 'Đội B');
      },
    );

    test(
      'TC-APP-CAMWALL-06 rơi về ONGOING rồi SCHEDULED sớm nhất trên sân, bỏ BYE, rỗng thì null',
      () {
        final camera = _camera('cam1', courtId: 'court1');
        final early = DateTime(2026, 11, 12, 8);
        final late = DateTime(2026, 11, 12, 9);

        final ongoing = cameraWallMatchLabel(camera, const {}, [
          _match('a', courtId: 'court1', code: 'S1', scheduledTime: early),
          _match('b', status: 'ONGOING', courtId: 'court1', code: 'ON'),
        ]);
        expect(ongoing!.kind, 'ongoing');
        expect(ongoing.code, 'ON');

        final next = cameraWallMatchLabel(camera, const {}, [
          _match('a', courtId: 'court1', code: 'LATE', scheduledTime: late),
          _match('b', courtId: 'court1', code: 'EARLY', scheduledTime: early),
          _match(
            'c',
            courtId: 'court1',
            code: 'BYE',
            scheduledTime: DateTime(2026),
            isBye: true,
          ),
          _match(
            'd',
            courtId: 'khac',
            code: 'OTHER',
            scheduledTime: DateTime(2025),
          ),
        ]);
        expect(next!.kind, 'next');
        expect(next.code, 'EARLY');

        final noCode = cameraWallMatchLabel(camera, const {}, [
          _match('e', courtId: 'court1', number: 7),
        ]);
        expect(noCode!.code, '7');

        expect(
          cameraWallMatchLabel(_camera('free'), const {}, [
            _match('a', courtId: 'court1'),
          ]),
          isNull,
        );
        expect(cameraWallMatchLabel(camera, const {}, const []), isNull);
      },
    );
  });
}
