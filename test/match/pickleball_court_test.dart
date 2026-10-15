import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:flutter_test/flutter_test.dart';

CourtContext ctx({
  int s1 = 0,
  int s2 = 0,
  bool doubles = true,
  int? serving = 1,
  int serverNumber = 1,
  CourtScoringMode mode = CourtScoringMode.sideOut,
  int setIndex = 0,
  int? target = 11,
  bool deciding = false,
}) => CourtContext(
  score1: s1,
  score2: s2,
  isDoubles: doubles,
  team1PlayerCount: doubles ? 2 : 1,
  team2PlayerCount: doubles ? 2 : 1,
  servingTeam: serving,
  serverNumber: serverNumber,
  scoringMode: mode,
  setIndex: setIndex,
  targetPoints: target,
  isDecidingSet: deciding,
);

void main() {
  group('vị trí và ô giao', () {
    test('đôi 0-0 giao lần 2: VĐV ô phải giao, lời hô 2', () {
      final layout = resolveCourtLayout(
        const CourtState(),
        ctx(serverNumber: 2),
      );
      expect(layout.servingTeam, 1);
      expect(layout.serverPlayerIndex, 0);
      expect(layout.serverCell, CourtCell.right);
      expect(layout.callServerNumber, 2);
      expect(layout.team1First, isTrue);
      expect(layout.team1.rightPlayerIndex, 0);
      expect(layout.team1.leftPlayerIndex, 1);
    });

    test('đôi điểm lẻ: đảo ô, người giao đứng ô trái', () {
      final layout = resolveCourtLayout(
        const CourtState(),
        ctx(s1: 1, mode: CourtScoringMode.rally),
      );
      expect(layout.serverPlayerIndex, 0);
      expect(layout.serverCell, CourtCell.left);
      expect(layout.team1.rightPlayerIndex, 1);
      expect(layout.team1.leftPlayerIndex, 0);
      expect(layout.callServerNumber, isNull);
    });

    test('đơn: điểm chẵn ở ô phải, lẻ ở ô trái', () {
      final even = resolveCourtLayout(
        const CourtState(),
        ctx(doubles: false, mode: CourtScoringMode.rally),
      );
      expect(even.serverCell, CourtCell.right);
      expect(even.team1.rightPlayerIndex, 0);
      expect(even.team1.leftPlayerIndex, isNull);

      final odd = resolveCourtLayout(
        const CourtState(),
        ctx(s1: 1, doubles: false, mode: CourtScoringMode.rally),
      );
      expect(odd.serverCell, CourtCell.left);
      expect(odd.team1.rightPlayerIndex, isNull);
      expect(odd.team1.leftPlayerIndex, 0);
    });

    test('rally chưa biết đội giao: không vẽ người giao', () {
      final layout = resolveCourtLayout(
        const CourtState(),
        ctx(serving: null, mode: CourtScoringMode.rally),
      );
      expect(layout.servingTeam, isNull);
      expect(layout.serverPlayerIndex, isNull);
      expect(layout.serverCell, isNull);
      expect(layout.team1.rightPlayerIndex, 0);
    });

    test('rally: người giao theo chẵn/lẻ của đội giao và không mở lượt', () {
      final before = const CourtState(startingRightTeam1: 1);
      final c = ctx(s1: 2, s2: 1, mode: CourtScoringMode.rally);
      final state = reconcileCourtState(before, c);
      expect(state.turnStart, isNull);
      expect(needsServerWrite(before, state), isFalse);

      final layout = resolveCourtLayout(before, c);
      expect(layout.serverPlayerIndex, 1);
      expect(layout.serverCell, CourtCell.right);
    });
  });

  group('lượt giao (side-out)', () {
    test('1 → 2 mở lượt với đồng đội; 2 → 1 cùng đội giữ nguyên người', () {
      var state = reconcileCourtState(
        const CourtState(),
        ctx(serving: 1, serverNumber: 1),
      );
      expect(
        state.turnStart,
        const CourtTurnStart(
          team: 1,
          serverNumber: 1,
          teamScoreAtStart: 0,
          serverPlayerIndex: 0,
        ),
      );

      state = reconcileCourtState(
        state,
        ctx(s1: 1, serving: 1, serverNumber: 2),
      );
      expect(
        state.turnStart,
        const CourtTurnStart(
          team: 1,
          serverNumber: 2,
          teamScoreAtStart: 1,
          serverPlayerIndex: 1,
        ),
      );

      state = reconcileCourtState(
        state,
        ctx(s1: 2, serving: 1, serverNumber: 1),
      );
      expect(
        state.turnStart,
        const CourtTurnStart(
          team: 1,
          serverNumber: 1,
          teamScoreAtStart: 1,
          serverPlayerIndex: 1,
        ),
      );
    });

    test('đổi đội giao mở lượt mới theo điểm đội mới và xoá người giao chỉ định', () {
      var state = reconcileCourtState(const CourtState(), ctx(serving: 1));
      state = setServerOverride(state, ctx(serving: 1), 1, 1);
      expect(
        state.serverOverride,
        const CourtServerOverride(team: 1, playerIndex: 1),
      );

      state = reconcileCourtState(state, ctx(s2: 1, serving: 2));
      expect(
        state.turnStart,
        const CourtTurnStart(
          team: 2,
          serverNumber: 1,
          teamScoreAtStart: 1,
          serverPlayerIndex: 1,
        ),
      );
      expect(state.serverOverride, isNull);
    });

    test('override chỉ có tác dụng khi đúng đội giao', () {
      final state = setServerOverride(
        const CourtState(),
        ctx(mode: CourtScoringMode.rally, serving: 1),
        1,
        1,
      );

      final other = resolveCourtLayout(
        state,
        ctx(mode: CourtScoringMode.rally, serving: 2),
      );
      expect(other.servingTeam, 2);
      expect(other.serverPlayerIndex, 0);

      final same = resolveCourtLayout(
        state,
        ctx(mode: CourtScoringMode.rally, serving: 1),
      );
      expect(same.serverPlayerIndex, 1);
      expect(same.serverCell, CourtCell.left);
    });
  });

  group('đổi sân', () {
    test('set lẻ (0-based) lật sân, set chẵn không lật', () {
      expect(
        resolveCourtLayout(const CourtState(), ctx(setIndex: 0)).team1First,
        isTrue,
      );
      expect(
        resolveCourtLayout(const CourtState(), ctx(setIndex: 1)).team1First,
        isFalse,
      );
      expect(
        resolveCourtLayout(const CourtState(), ctx(setIndex: 2)).team1First,
        isTrue,
      );
    });

    test('tắt tự đổi sân thì không lật tự động', () {
      final state = setAutoSwitchEnds(
        const CourtState(),
        ctx(setIndex: 1),
        false,
      );
      expect(
        resolveCourtLayout(state, ctx(setIndex: 1)).team1First,
        isTrue,
      );
    });

    test('endsOverride ép trạng thái, không phụ thuộc set', () {
      expect(
        resolveCourtLayout(
          const CourtState(endsOverride: true),
          ctx(setIndex: 0),
        ).team1First,
        isFalse,
      );
      expect(
        resolveCourtLayout(
          const CourtState(endsOverride: false),
          ctx(setIndex: 1),
        ).team1First,
        isTrue,
      );
    });

    test('set quyết định lật một lần ở mốc ceil(target/2)', () {
      final c = ctx(s1: 6, s2: 3, setIndex: 2, deciding: true);
      final flipped = reconcileCourtState(const CourtState(), c);
      expect(flipped.midSetSwitchDone, isTrue);
      expect(resolveCourtLayout(flipped, c).team1First, isFalse);

      final later = ctx(s1: 6, s2: 5, setIndex: 2, deciding: true);
      expect(resolveCourtLayout(flipped, later).team1First, isFalse);
      expect(reconcileCourtState(flipped, later).midSetSwitchDone, isTrue);
    });

    test('mốc giữa set: 11→6, 15→8, 21→11', () {
      CourtState at(int target, int score) => reconcileCourtState(
        const CourtState(),
        ctx(s1: score, setIndex: 2, target: target, deciding: true),
      );

      expect(at(11, 5).midSetSwitchDone, isFalse);
      expect(at(11, 6).midSetSwitchDone, isTrue);
      expect(at(15, 7).midSetSwitchDone, isFalse);
      expect(at(15, 8).midSetSwitchDone, isTrue);
      expect(at(21, 10).midSetSwitchDone, isFalse);
      expect(at(21, 11).midSetSwitchDone, isTrue);
    });

    test('tắt tự đổi sân thì mốc giữa set không lật', () {
      final off = reconcileCourtState(
        const CourtState(autoSwitchEnds: false),
        ctx(s1: 6, setIndex: 2, deciding: true),
      );
      expect(off.midSetSwitchDone, isFalse);
    });

    test('ngoài set quyết định, cờ giữa set được reset', () {
      final reset = reconcileCourtState(
        const CourtState(midSetSwitchDone: true),
        ctx(s1: 2, s2: 1, setIndex: 2),
      );
      expect(reset.midSetSwitchDone, isFalse);
      expect(resolveCourtLayout(reset, ctx(setIndex: 2)).team1First, isTrue);
    });

    test('chuyển cờ giữa set cần ghi server', () {
      const before = CourtState();
      final after = reconcileCourtState(
        before,
        ctx(s1: 6, s2: 3, setIndex: 2, deciding: true, serving: null),
      );
      expect(needsServerWrite(before, after), isTrue);
    });
  });

  group('cài đặt, hoàn tác và khôi phục', () {
    final c0 = ctx();
    CourtState base() => reconcileCourtState(const CourtState(), c0);

    test('đổi VĐV ô phải ở 0-0 cập nhật VĐV giao và ghi history', () {
      final state = setStartingRight(base(), c0, 1, 1);
      expect(state.startingRightTeam1, 1);
      expect(state.turnStart!.serverPlayerIndex, 1);
      expect(state.history, hasLength(1));
      expect(state.history.single.startingRightTeam1, 0);
      expect(state.history.single.history, isEmpty);
    });

    test('hoàn tác trả lại cài đặt và lượt trước đó', () {
      final changed = setStartingRight(base(), c0, 1, 1);
      final undone = undoCourtChange(changed);
      expect(undone.startingRightTeam1, 0);
      expect(undone.turnStart!.serverPlayerIndex, 0);
      expect(undone.history, isEmpty);
      expect(undoCourtChange(undone), undone);
    });

    test('thao tác không đổi gì không đẩy history', () {
      expect(setStartingRight(base(), c0, 1, 0).history, isEmpty);
      expect(setAutoSwitchEnds(base(), c0, true).history, isEmpty);
    });

    test('history giữ tối đa 20 snapshot, snapshot không chứa history', () {
      var state = base();
      for (var i = 0; i < 25; i++) {
        state = setAutoSwitchEnds(state, c0, i.isOdd);
      }
      expect(state.history, hasLength(CourtState.historyLimit));
      expect(state.history.every((h) => h.history.isEmpty), isTrue);
      expect(state.autoSwitchEnds, isFalse);
    });

    test('swapEndsNow đảo trạng thái đang hiển thị', () {
      final once = swapEndsNow(base(), c0);
      expect(once.endsOverride, isTrue);
      expect(resolveCourtLayout(once, c0).team1First, isFalse);

      final twice = swapEndsNow(once, c0);
      expect(twice.endsOverride, isFalse);
      expect(resolveCourtLayout(twice, c0).team1First, isTrue);
    });

    test('restoreAutomaticCourt xoá ép và người giao chỉ định, giữ VĐV ô phải và lượt', () {
      var state = setStartingRight(base(), c0, 1, 1);
      state = swapEndsNow(state, c0);
      state = setServerOverride(state, c0, 1, 0);
      state = setAutoSwitchEnds(state, c0, false);

      final restored = restoreAutomaticCourt(state, c0);
      expect(restored.endsOverride, isNull);
      expect(restored.serverOverride, isNull);
      expect(restored.autoSwitchEnds, isTrue);
      expect(restored.midSetSwitchDone, isFalse);
      expect(restored.startingRightTeam1, 1);
      expect(restored.turnStart, state.turnStart);
    });

    test('team hoặc VĐV ngoài phạm vi ném ArgumentError', () {
      expect(() => setStartingRight(base(), c0, 3, 0), throwsArgumentError);
      expect(() => setStartingRight(base(), c0, 1, 2), throwsArgumentError);
      expect(() => setServerOverride(base(), c0, 0, 0), throwsArgumentError);
    });
  });

  group('ghi server và JSON hợp đồng', () {
    test('needsServerWrite: đổi lượt và thao tác cần ghi, đọc lại không ghi', () {
      final c0 = ctx();
      final base = reconcileCourtState(const CourtState(), c0);
      expect(needsServerWrite(const CourtState(), base), isTrue);
      expect(needsServerWrite(base, reconcileCourtState(base, c0)), isFalse);
      expect(needsServerWrite(base, setAutoSwitchEnds(base, c0, false)), isTrue);
    });

    test('toJson đúng hợp đồng: version 1, history không lồng, bỏ meta khi null', () {
      final c0 = ctx();
      final state = setStartingRight(
        reconcileCourtState(const CourtState(), c0),
        c0,
        1,
        1,
      );
      final json = state.toJson();
      expect(json['version'], 1);
      expect(json['startingRight'], {'team1': 1, 'team2': 0});
      expect(json.containsKey('updatedAt'), isFalse);

      final history = json['history'] as List;
      expect(history, hasLength(1));
      final first = history.single as Map;
      expect(first.containsKey('history'), isFalse);
      expect(first.containsKey('version'), isFalse);
    });

    test('fromJson(toJson) giữ cài đặt, history và meta', () {
      final c0 = ctx();
      final built = setStartingRight(
        reconcileCourtState(const CourtState(), c0),
        c0,
        1,
        1,
      );
      final withMeta = CourtState.fromJson({
        ...built.toJson(),
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'updatedBy': 'u1',
      });
      expect(withMeta.updatedAt, '2026-01-01T00:00:00.000Z');
      expect(withMeta.updatedBy, 'u1');
      expect(withMeta.startingRightTeam1, 1);
      expect(withMeta.history, hasLength(1));
      expect(CourtState.fromJson(withMeta.toJson()), withMeta);
    });

    test('thiếu, sai kiểu hoặc khác version đều về mặc định', () {
      expect(CourtState.currentVersion, 1);
      expect(CourtState.fromJson(null), const CourtState());
      expect(
        CourtState.fromJson({
          'startingRight': {'team1': 1, 'team2': 1},
        }),
        const CourtState(),
      );
      expect(
        CourtState.fromJson({
          'version': 2,
          'startingRight': {'team1': 1, 'team2': 1},
        }),
        const CourtState(),
      );
      expect(CourtState.fromJson('hỏng'), const CourtState());
    });

    test('giá trị lệch trong từng field được chuẩn hoá', () {
      final state = CourtState.fromJson({
        'version': 1,
        'startingRight': {'team1': 7, 'team2': 1},
        'endsOverride': 'yes',
        'serverOverride': {'team': 1, 'playerIndex': 5},
        'turnStart': {
          'team': 3,
          'serverNumber': 1,
          'teamScoreAtStart': 0,
          'serverPlayerIndex': 0,
        },
        'history': [
          'hỏng',
          {
            'startingRight': {'team1': 1, 'team2': 0},
          },
        ],
      });
      expect(state.startingRightTeam1, 0);
      expect(state.startingRightTeam2, 1);
      expect(state.endsOverride, isNull);
      expect(state.autoSwitchEnds, isTrue);
      expect(state.serverOverride, isNull);
      expect(state.turnStart, isNull);
      expect(state.history, hasLength(1));
      expect(state.history.single.startingRightTeam1, 1);
    });

    test('history đọc vào bị cắt còn tối đa 20', () {
      final entries = [
        for (var i = 0; i < 22; i++)
          {
            'startingRight': {'team1': 0, 'team2': i % 2},
          },
      ];
      final state = CourtState.fromJson({'version': 1, 'history': entries});
      expect(state.history, hasLength(CourtState.historyLimit));
    });
  });
}
