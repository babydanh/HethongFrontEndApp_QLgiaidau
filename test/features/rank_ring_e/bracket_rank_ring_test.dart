import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/live_match_card_v2.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_card_parts.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_match_sides.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tierSRing = 0xFFFBBF24;
const _ranking = PlayerRanking(
  id: 'r1',
  userId: 'u1',
  fullName: 'Nguyễn Văn An',
  eloPoints: 1850,
  tierName: 'Tier S',
  matchesPlayed: 5,
  categoryId: 'c',
  categoryName: 'Cat',
);

/// Participant JSON như Backend (`participant-display.ts`): players[] có userId.
const _account = {
  'slot': 1,
  'userId': 'u1',
  'fullName': 'Nguyễn Văn An',
  'avatarUrl': null,
  'isGuest': false,
};
const _guest = {
  'slot': 2,
  'userId': null,
  'fullName': 'Khách Lẻ',
  'avatarUrl': null,
  'isGuest': true,
};

MatchModel _match(Map<String, dynamic> p1, {String? sportKey}) =>
    MatchModel.fromJson({
      'id': 'm1',
      'tournamentId': 't',
      'status': 'SCHEDULED',
      'round': 1,
      'sport': ?sportKey,
      'participant1': p1,
      'participant2': null,
    }, 'm1');

Future<void> _pump(WidgetTester t, Widget child) async {
  await t.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        userRankingsSummaryProvider(
          'u1',
        ).overrideWith((ref) async => const [_ranking]),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: 360, child: child),
          ),
        ),
      ),
    ),
  );
  await t.pump();
  await t.pump();
}

int _ringOf(WidgetTester t, Finder avatar) {
  final outer = find
      .descendant(of: avatar, matching: find.byType(Container))
      .first;
  return (t.widget<Container>(outer).decoration! as BoxDecoration).color!
      .toARGB32();
}

void main() {
  testWidgets(
    'TC-RANK-RING-APP-E01: bracket card side with a team name still rings the account player',
    (tester) async {
      final m = _match({
        'teamName': 'Sấm Sét',
        'players': [_account],
      });
      await _pump(tester, BracketSideRow(match: m, side: 1));

      expect(find.byType(RankAvatar), findsOneWidget);
      expect(_ringOf(tester, find.byType(RankAvatar)), _tierSRing);
      expect(find.text('Sấm Sét'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-RANK-RING-APP-E02: team of guests keeps the team logo, football keeps the logo',
    (tester) async {
      final guests = _match({
        'teamName': 'Sấm Sét',
        'players': [_guest],
      });
      await _pump(tester, BracketSideRow(match: guests, side: 1));
      expect(find.byType(RankAvatar), findsNothing);
      expect(
        find.byKey(const ValueKey('side-lines-team-logo')),
        findsOneWidget,
      );

      final football = _match({
        'teamName': 'FC Sấm Sét',
        'players': [_account],
      }, sportKey: 'football');
      await _pump(tester, BracketSideRow(match: football, side: 1));
      expect(find.byType(RankAvatar), findsNothing);
      expect(
        find.byKey(const ValueKey('side-lines-team-logo')),
        findsOneWidget,
      );
    },
  );

  test(
    'TC-RANK-RING-APP-E03: live viewer avatars of a named team are its account players',
    () {
      final m = _match({
        'teamName': 'Sấm Sét',
        'players': [_account],
      });
      final avatars = matchSideAvatars(m, 1);

      expect(avatars.map((a) => a.userId), ['u1']);
      expect(avatars.single.name, 'Nguyễn Văn An');
    },
  );

  test(
    'TC-RANK-RING-APP-E04: member infos fall back to participant players',
    () {
      final m = _match({
        'players': [_account, _guest],
      });
      expect(m.team1MemberInfos, isEmpty);

      final infos = matchSideMemberInfos(m, 1);
      expect(infos.map((i) => i.userId), ['u1', null]);
      expect(infos.first.fullName, 'Nguyễn Văn An');
    },
  );

  testWidgets(
    'TC-RANK-RING-APP-E05: live match card rings a player known only from participant players[]',
    (tester) async {
      final m = _match({
        'players': [_account],
      });
      await _pump(tester, LiveMatchCardV2(match: m));

      expect(find.byType(RankAvatar), findsOneWidget);
      expect(_ringOf(tester, find.byType(RankAvatar)), _tierSRing);
    },
  );

  testWidgets(
    'TC-RANK-RING-APP-E06: live match card member without elo data reads best ranking',
    (tester) async {
      final m = MatchModel(
        id: 'm',
        round: 1,
        matchNumber: 1,
        status: 'SCHEDULED',
        team1Name: 'Nguyễn Văn An',
        team2Name: 'B',
        bracketPosition: const BracketPosition(round: 1, position: 1),
        team1MemberInfos: const [
          MatchMemberInfo(userId: 'u1', fullName: 'Nguyễn Văn An'),
        ],
        updatedAt: DateTime(2026, 11, 1),
      );
      await _pump(tester, LiveMatchCardV2(match: m));

      expect(_ringOf(tester, find.byType(RankAvatar).first), _tierSRing);
    },
  );

  test(
    'TC-RANK-RING-APP-E07: ParticipantDisplay lists account players of a team',
    () {
      final d = resolveParticipantDisplay(
        teamName: 'Sấm Sét',
        players: const [
          ParticipantPlayer(slot: 1, userId: 'u1', fullName: 'An'),
          ParticipantPlayer(slot: 2, fullName: 'Khách'),
        ],
      );
      expect(d.isTeam, isTrue);
      expect(d.accountPlayers.map((p) => p.userId), ['u1']);
    },
  );
}
