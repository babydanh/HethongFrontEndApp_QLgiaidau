import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/pairing.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tierSRing = 0xFFFBBF24;
const _unrankedRing = 0xFFCBD5E1;

/// `u1` is Tier S (elo 1850), `u2` has no ranking.
const _tierSRanking = PlayerRanking(
  id: 'r1',
  userId: 'u1',
  fullName: 'Nguyễn Văn An',
  eloPoints: 1850,
  tierName: 'Tier S',
  matchesPlayed: 5,
  categoryId: 'c',
  categoryName: 'Cat',
);

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('vi'),
  home: Scaffold(body: Center(child: child)),
);

Future<void> _pumpRanked(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        userRankingsSummaryProvider(
          'u1',
        ).overrideWith((ref) async => const [_tierSRanking]),
        userRankingsSummaryProvider('u2').overrideWith((ref) async => const []),
      ],
      child: _app(child),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Fill colour of RankAvatar's outermost Container (the ring).
int _ringOf(WidgetTester tester, Finder avatar) {
  final outer = find
      .descendant(of: avatar, matching: find.byType(Container))
      .first;
  final deco = tester.widget<Container>(outer).decoration! as BoxDecoration;
  return deco.color!.toARGB32();
}

void main() {
  testWidgets(
    'TC-RANK-RING-APP-D01: ParticipantLabel player with userId gets the Tier S ring',
    (tester) async {
      await _pumpRanked(
        tester,
        const ParticipantLabel(
          teamName: null,
          players: [
            ParticipantPlayer(slot: 1, userId: 'u1', fullName: 'Nguyễn Văn An'),
          ],
        ),
      );

      final avatar = find.byType(RankAvatar);
      expect(avatar, findsOneWidget);
      expect(_ringOf(tester, avatar), _tierSRing);
      // Outer size stays the old 22px (radius 11) avatar.
      expect(tester.getSize(avatar), const Size(22, 22));
    },
  );

  testWidgets(
    'TC-RANK-RING-APP-D02: rank carried in the data rings without a provider lookup',
    (tester) async {
      // No ProviderScope: data-backed rings must not need one.
      await tester.pumpWidget(
        _app(
          const ParticipantLabel(
            teamName: null,
            compact: true,
            players: [
              ParticipantPlayer(
                slot: 1,
                userId: 'u9',
                fullName: 'Trần Văn Bình',
                eloPoints: 1850,
                tierName: 'Tier S',
              ),
            ],
          ),
        ),
      );

      final avatar = find.byType(RankAvatar);
      expect(avatar, findsOneWidget);
      expect(_ringOf(tester, avatar), _tierSRing);
      expect(tester.getSize(avatar), const Size(14, 14));
    },
  );

  testWidgets(
    'TC-RANK-RING-APP-D03: guest without userId keeps the plain avatar',
    (tester) async {
      await tester.pumpWidget(
        _app(
          const ParticipantLabel(
            teamName: null,
            players: [ParticipantPlayer(slot: 1, fullName: 'Khách Lẻ')],
          ),
        ),
      );

      expect(find.byType(RankAvatar), findsNothing);
      expect(find.byType(CircleAvatar), findsOneWidget);
    },
  );

  testWidgets(
    'TC-RANK-RING-APP-D04: ParticipantSideLines rings each account, guest stays plain',
    (tester) async {
      await _pumpRanked(
        tester,
        const ParticipantSideLines(
          teamName: null,
          players: [
            ParticipantPlayer(slot: 1, userId: 'u1', fullName: 'Nguyễn Văn An'),
            ParticipantPlayer(slot: 2, userId: 'u2', fullName: 'Lê Thị Cúc'),
            ParticipantPlayer(slot: 3, fullName: 'Khách Lẻ'),
          ],
        ),
      );

      final avatars = find.byType(RankAvatar);
      expect(avatars, findsNWidgets(2));
      expect(_ringOf(tester, avatars.at(0)), _tierSRing);
      expect(_ringOf(tester, avatars.at(1)), _unrankedRing);
      expect(tester.getSize(avatars.at(0)), const Size(18, 18));
      expect(find.byType(CircleAvatar), findsOneWidget);
    },
  );

  test('TC-RANK-RING-APP-D05: players keep elo/tier from roster data', () {
    final fromInfos = participantPlayersFromMemberInfos(const [
      MatchMemberInfo(
        userId: 'u1',
        fullName: 'Nguyễn Văn An',
        eloPoints: 1450,
        tierName: 'Vàng',
      ),
    ]);
    expect(fromInfos.single.eloPoints, 1450);
    expect(fromInfos.single.tierName, 'Vàng');

    final fromJson = toParticipantPlayers({
      'players': [
        {'userId': 'u1', 'fullName': 'Nguyễn Văn An', 'eloPoints': 1450},
        {
          'user': {'id': 'u2', 'fullName': 'Trần Văn Bình'},
          'ranking': {'eloPoints': 1320, 'tierName': 'Bạc'},
        },
      ],
    });
    expect(fromJson[0].eloPoints, 1450);
    expect(fromJson[1].eloPoints, 1320);
    expect(fromJson[1].tierName, 'Bạc');
  });

  test('TC-RANK-RING-APP-D06: pairing candidate reads the roster userId', () {
    final candidate = PairingCandidate.fromJson({
      'id': 'p1',
      'teamStatus': 'PENDING_PARTNER',
      'rosters': [
        {
          'userId': 'u1',
          'profile': {'fullName': 'Nguyễn Văn An'},
        },
      ],
    });
    expect(candidate.userId, 'u1');
  });
}
