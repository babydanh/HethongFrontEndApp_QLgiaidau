import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_side_avatars.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/resolved_rank_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rank_ring_helpers.dart';

void main() {
  testWidgets(
    'TC-RANK-RING-APP-B03 live details avatars ring by athlete tier',
    (tester) async {
      await pumpRanked(
        tester,
        const LiveSideAvatars(
          avatars: [LiveAvatarData(name: 'An', userId: 'u1')],
          diameter: 34,
          rankRing: true,
        ),
      );
      expect(ringOf(tester, find.byType(RankAvatar)), tierSRing);
    },
  );

  testWidgets(
    'TC-RANK-RING-APP-B04 data elo is used as is; unranked user stays grey',
    (tester) async {
      await pumpRanked(
        tester,
        const Column(
          children: [
            ResolvedRankAvatar(
              key: Key('data'),
              userId: 'u2',
              name: 'Bình',
              elo: 1850,
              tierName: 'Tier S',
            ),
            ResolvedRankAvatar(key: Key('none'), userId: 'u2', name: 'Bình'),
          ],
        ),
      );
      expect(ringOf(tester, find.byKey(const Key('data'))), tierSRing);
      expect(ringOf(tester, find.byKey(const Key('none'))), unrankedRing);
    },
  );

  testWidgets(
    'TC-RANK-RING-APP-B05 schedule-style avatar looks up ranking by userId',
    (tester) async {
      await pumpRanked(
        tester,
        const ResolvedRankAvatar(userId: 'u1', name: 'An', size: 13),
      );
      expect(ringOf(tester, find.byType(RankAvatar)), tierSRing);
    },
  );
}
