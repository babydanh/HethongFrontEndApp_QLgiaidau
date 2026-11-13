import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/camera_match_filter.dart';
import 'package:flutter_test/flutter_test.dart';

/// TC-CAMFILTER-APP-01..: hàm lọc thuần của tab Camera.
MatchModel _match(
  String id, {
  int round = 1,
  String? courtId,
  String? matchCode,
}) => MatchModel(
  updatedAt: DateTime(2026, 1, 1),
  id: id,
  round: round,
  matchNumber: 1,
  team1Id: '$id-a',
  team2Id: '$id-b',
  team1Name: 'A $id',
  team2Name: 'B $id',
  status: 'SCHEDULED',
  bracketPosition: BracketPosition(round: round, position: 1),
  courtId: courtId,
  matchCode: matchCode,
);

String _label(MatchModel match) => '${match.team1Name} – ${match.team2Name}';

/// Sân `c-cam` có camera, `c-none` thì không.
bool _hasCamera(String courtId) => courtId == 'c-cam';

List<String> _ids(List<MatchModel> matches) =>
    matches.map((match) => match.id).toList();

List<MatchModel> _filter(
  List<MatchModel> matches, {
  String query = '',
  int? round,
  bool onlyNoCamera = false,
  String Function(MatchModel)? labelOf,
}) => filterCameraMatches(
  matches: matches,
  query: query,
  round: round,
  onlyNoCamera: onlyNoCamera,
  labelOf: labelOf ?? _label,
  hasCameraOnCourt: _hasCamera,
);

void main() {
  final m1 = _match('m1', round: 1, courtId: 'c-cam', matchCode: 'R1-01');
  final m2 = _match('m2', round: 2, courtId: 'c-none', matchCode: 'R2-01');
  final m3 = _match('m3', round: 2); // chưa gán sân
  final all = [m1, m2, m3];

  test('TC-CAMFILTER-APP-01 returns empty list when there are no matches', () {
    expect(
      _filter(const [], query: 'x', round: 1, onlyNoCamera: true),
      isEmpty,
    );
  });

  test('TC-CAMFILTER-APP-02 returns every match when no filter is on', () {
    expect(_ids(_filter(all)), ['m1', 'm2', 'm3']);
  });

  test('TC-CAMFILTER-APP-03 keeps only the chosen round', () {
    expect(_ids(_filter(all, round: 2)), ['m2', 'm3']);
  });

  test('TC-CAMFILTER-APP-04 matches the query against either side name', () {
    expect(_ids(_filter(all, query: 'b m2')), ['m2']);
    expect(_ids(_filter(all, query: 'A m3')), ['m3']);
  });

  test('TC-CAMFILTER-APP-05 matches the query against the match code', () {
    expect(_ids(_filter(all, query: 'r2-01')), ['m2']);
  });

  test(
    'TC-CAMFILTER-APP-06 onlyNoCamera keeps matches on courts w/o camera',
    () {
      expect(_ids(_filter(all, onlyNoCamera: true)), ['m2']);
    },
  );

  test('TC-CAMFILTER-APP-07 a match without a court is never "no camera"', () {
    expect(_ids(_filter([m3], onlyNoCamera: true)), isEmpty);
    expect(_ids(_filter([m3])), ['m3']);
  });

  test('TC-CAMFILTER-APP-08 combines round, query and no-camera (AND)', () {
    expect(_ids(_filter(all, round: 2, query: 'm2', onlyNoCamera: true)), [
      'm2',
    ]);
    expect(_ids(_filter(all, round: 1, onlyNoCamera: true)), isEmpty);
  });

  test('TC-CAMFILTER-APP-09 ignores case, accents and surrounding spaces', () {
    final vn = _match('v1', courtId: 'c-none');
    String label(MatchModel _) => 'Nguyễn Đức – Trần Văn';
    expect(_ids(_filter([vn], query: '  nguyen duc ', labelOf: label)), ['v1']);
    expect(_ids(_filter([vn], query: 'TRẦN VĂN', labelOf: label)), ['v1']);
    expect(_ids(_filter([vn], query: 'tran van', labelOf: label)), ['v1']);
    expect(_ids(_filter([vn], query: 'khac', labelOf: label)), isEmpty);
  });

  test('TC-CAMFILTER-APP-10 keeps the input order and does not mutate it', () {
    final input = [m3, m1, m2];
    final out = _filter(input, round: 2);
    expect(_ids(out), ['m3', 'm2']);
    expect(_ids(input), ['m3', 'm1', 'm2']);
  });

  test('TC-CAMFILTER-APP-11 cameraMatchRounds is sorted and distinct', () {
    expect(cameraMatchRounds([m2, m1, m3]), [1, 2]);
    expect(cameraMatchRounds(const []), isEmpty);
  });

  test(
    'TC-CAMFILTER-APP-12 CameraMatchFilter reports whether it is active',
    () {
      expect(const CameraMatchFilter().isActive, isFalse);
      expect(const CameraMatchFilter(query: '  ').isActive, isFalse);
      expect(const CameraMatchFilter(query: 'a').isActive, isTrue);
      expect(const CameraMatchFilter(round: 1).isActive, isTrue);
      expect(const CameraMatchFilter(onlyNoCamera: true).isActive, isTrue);
    },
  );
}
