import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match(String id) => MatchModel(
  id: id,
  tournamentId: 'tour-1',
  round: 1,
  matchNumber: 1,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  team1Id: 't1',
  team2Id: 't2',
  status: 'ONGOING',
  updatedAt: DateTime(2026, 1, 1),
);

/// Trả danh sách ở lần gọi đầu, các lần sau lỗi (mạng rớt giữa chừng).
class _FlakyRepository extends Fake implements ITournamentRepository {
  int calls = 0;

  @override
  Future<List<MatchModel>> getBracketMatches(
    String tournamentId, {
    String? divisionId,
  }) async {
    calls++;
    if (calls == 1) return [_match('m1')];
    throw StateError('network down');
  }
}

void main() {
  testWidgets(
    'TC-OPEN-SPEED-07 lite bracket keeps the last matches when a poll fails',
    (tester) async {
      final repo = _FlakyRepository();
      final container = ProviderContainer(
        overrides: [tournamentRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final seen = <List<String>>[];
      container.listen(liteBracketMatchesProvider('tour-1'), (_, next) {
        final value = next.value;
        if (value != null) seen.add(value.map((m) => m.id).toList());
      }, fireImmediately: true);

      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(seconds: 16));
      await tester.pump(const Duration(milliseconds: 10));

      expect(repo.calls, greaterThan(1));
      expect(seen.first, ['m1']);
      expect(seen.every((ids) => ids.isNotEmpty), isTrue);

      // Stop the 15 s poll timer before the framework checks for leftovers.
      container.dispose();
      await tester.pump();
    },
  );
}
