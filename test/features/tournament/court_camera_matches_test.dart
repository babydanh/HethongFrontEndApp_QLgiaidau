import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/court_camera_matches.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-APP-CAM-01..05: thứ tự trận trong popup sân. Trận chưa xong (đang đấu,
/// sắp tới) ở trên, trận đã xong ở dưới.
MatchModel _match(
  String id, {
  String status = 'SCHEDULED',
  String? courtId = 'c1',
  DateTime? at,
  int number = 1,
  bool bye = false,
}) => MatchModel(
  updatedAt: DateTime(2026, 1, 1),
  id: id,
  round: 1,
  matchNumber: number,
  team1Id: '$id-a',
  team2Id: bye ? 'BYE' : '$id-b',
  team1Name: 'A $id',
  team2Name: bye ? 'BYE' : 'B $id',
  status: status,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  courtId: courtId,
  scheduledTime: at,
);

List<String> _ids(List<MatchModel> matches) =>
    matches.map((m) => m.id).toList();

void main() {
  final t8 = DateTime(2026, 11, 15, 8);
  final t9 = DateTime(2026, 11, 15, 9);
  final t10 = DateTime(2026, 11, 15, 10);

  test('TC-APP-CAM-01 chỉ giữ trận thuộc sân được chọn', () {
    final result = courtCameraMatches([
      _match('a', courtId: 'c1', at: t8),
      _match('b', courtId: 'c2', at: t8),
      _match('c', courtId: null, at: t8),
    ], 'c1');
    expect(_ids(result), ['a']);
  });

  test(
    'TC-APP-CAM-02 đang đấu trước, rồi sắp tới theo giờ, trận xong cuối',
    () {
      final result = courtCameraMatches([
        _match('done', status: 'COMPLETED', at: t8),
        _match('soon9', at: t9),
        _match('live', status: 'ONGOING', at: t10),
        _match('soon8', at: t8),
      ], 'c1');
      expect(_ids(result), ['live', 'soon8', 'soon9', 'done']);
    },
  );

  test('TC-APP-CAM-03 trận xong: trận muộn hơn nằm trên', () {
    final result = courtCameraMatches([
      _match('early', status: 'COMPLETED', at: t8),
      _match('late', status: 'COMPLETED', at: t10),
    ], 'c1');
    expect(_ids(result), ['late', 'early']);
  });

  test('TC-APP-CAM-04 trận chưa có giờ xuống cuối nhóm, theo số trận', () {
    final result = courtCameraMatches([
      _match('noTime2', number: 2),
      _match('noTime1', number: 1),
      _match('timed', at: t9),
    ], 'c1');
    expect(_ids(result), ['timed', 'noTime1', 'noTime2']);
  });

  test(
    'TC-APP-CAM-05 bỏ trận BYE và trận đã huỷ; sân trống trả danh sách rỗng',
    () {
      final result = courtCameraMatches([
        _match('bye', bye: true),
        _match('cancelled', status: 'CANCELLED'),
      ], 'c1');
      expect(result, isEmpty);
      expect(courtCameraMatches(const [], 'c1'), isEmpty);
    },
  );

  test('TC-APP-CAM-06 giai đoạn: live, done, còn lại là upcoming', () {
    expect(courtMatchPhase(_match('x', status: 'LIVE')), CourtMatchPhase.live);
    expect(
      courtMatchPhase(_match('x', status: 'FINISHED')),
      CourtMatchPhase.done,
    );
    expect(courtMatchPhase(_match('x')), CourtMatchPhase.upcoming);
  });
}
