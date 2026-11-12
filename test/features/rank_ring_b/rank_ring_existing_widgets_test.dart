import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/features/match/widgets/match_discussion_message.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_team_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rank_ring_helpers.dart';

void main() {
  testWidgets(
    'TC-RANK-RING-APP-B01 discussion message avatar rings by author tier',
    (tester) async {
      await pumpRanked(
        tester,
        const MatchDiscussionMessage(
          userId: 'u1',
          name: 'An',
          text: 'Hay quá',
          timeLabel: '10:00',
        ),
      );
      expect(ringOf(tester, find.byType(RankAvatar)), tierSRing);
    },
  );

  testWidgets(
    'TC-RANK-RING-APP-B02 team sheet member without elo data uses best ranking',
    (tester) async {
      await pumpRanked(
        tester,
        TournamentTeamSheet(
          team: Team(
            id: 't1',
            name: 'Đội A',
            members: const ['An'],
            memberInfos: const [MatchMemberInfo(userId: 'u1', fullName: 'An')],
            createdAt: DateTime.utc(2026, 11, 1),
          ),
        ),
      );
      expect(ringOf(tester, find.byType(RankAvatar)), tierSRing);
    },
  );
}
