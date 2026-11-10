import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/knockout_seed_labels.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_double_elim_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_seed_labels.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTournamentRepository extends Mock implements ITournamentRepository {}

const _tournamentId = 't-1';
const _divisionId = 'div-1';

List<String> _keys(List<AdvanceSlot> slots) => [
  for (final slot in slots)
    slot.wildcard ? 'W' : '${slot.groupIndex}:${slot.rank}',
];

Map<String, dynamic> _stage(
  String type, {
  Map<String, dynamic>? advanceMapping,
  List<Map<String, dynamic>> groups = const [],
  String id = 'stage',
}) => {
  'id': id,
  'type': type,
  'roundConfig': ?(advanceMapping == null
      ? null
      : {'advanceMapping': advanceMapping}),
  'groups': groups,
};

Map<String, dynamic> _stageMatch(
  String id,
  int matchOrder, {
  int round = 1,
  String? branch,
}) => {
  'id': id,
  'roundNumber': round,
  'matchOrder': matchOrder,
  'bracketBranch': ?branch,
};

List<Map<String, dynamic>> _stages({
  Map<String, dynamic>? mapping,
  List<Map<String, dynamic>>? knockoutMatches,
  List<String> groupNames = const ['Bảng A', 'Bảng B', 'Bảng C', 'Bảng D'],
}) => [
  _stage(
    'ROUND_ROBIN',
    id: 'stage-1',
    groups: [
      for (final name in groupNames) {'name': name},
    ],
  ),
  _stage(
    'DOUBLE_ELIMINATION',
    id: 'stage-2',
    advanceMapping:
        mapping ?? {'numGroups': groupNames.length, 'teamsAdvancing': 2},
    groups: [
      {
        'matches':
            knockoutMatches ?? [_stageMatch('m1', 1), _stageMatch('m2', 2)],
      },
    ],
  ),
];

void main() {
  group('defaultSlotOrder', () {
    test('TC-SEEDLABEL-01 two advancing crosses neighbouring groups', () {
      final order = defaultSlotOrder(
        numGroups: 4,
        teamsAdvancing: 2,
        allowWildcard: false,
        wildcardTeams: 0,
      );
      expect(_keys(order), [
        '0:1',
        '1:2',
        '1:1',
        '0:2',
        '2:1',
        '3:2',
        '3:1',
        '2:2',
      ]);
    });

    test('TC-SEEDLABEL-02 one advancing pairs the group winners in order', () {
      final order = defaultSlotOrder(
        numGroups: 4,
        teamsAdvancing: 1,
        allowWildcard: false,
        wildcardTeams: 0,
      );
      expect(_keys(order), ['0:1', '1:1', '2:1', '3:1']);
    });

    test('TC-SEEDLABEL-03 three or more advancing go group by group', () {
      final order = defaultSlotOrder(
        numGroups: 2,
        teamsAdvancing: 3,
        allowWildcard: false,
        wildcardTeams: 0,
      );
      expect(_keys(order), ['0:1', '0:2', '0:3', '1:1', '1:2', '1:3']);
    });

    test('TC-SEEDLABEL-04 wildcards come last', () {
      final order = defaultSlotOrder(
        numGroups: 2,
        teamsAdvancing: 1,
        allowWildcard: true,
        wildcardTeams: 2,
      );
      expect(_keys(order), ['0:1', '1:1', 'W', 'W']);
    });

    test('TC-SEEDLABEL-05 an odd last group is listed alone', () {
      final order = defaultSlotOrder(
        numGroups: 3,
        teamsAdvancing: 2,
        allowWildcard: false,
        wildcardTeams: 0,
      );
      expect(_keys(order), ['0:1', '1:2', '1:1', '0:2', '2:1', '2:2']);
    });

    test('TC-SEEDLABEL-06 zero advancing is read as one', () {
      final order = defaultSlotOrder(
        numGroups: 2,
        teamsAdvancing: 0,
        allowWildcard: false,
        wildcardTeams: 0,
      );
      expect(_keys(order), ['0:1', '1:1']);
    });
  });

  group('KnockoutSeedPlan.fromStages', () {
    test(
      'TC-SEEDLABEL-07 maps slots 2k and 2k+1 to the k-th round-one match',
      () {
        final plan = KnockoutSeedPlan.fromStages(_stages())!;
        expect(plan.stageId, 'stage-2');
        expect(plan.slotIndex('m1', 1), 0);
        expect(plan.slotIndex('m1', 2), 1);
        expect(plan.slotIndex('m2', 1), 2);
        expect(plan.slotIndex('m2', 2), 3);
        expect(plan.slotIndex('unknown', 1), isNull);
      },
    );

    test('TC-SEEDLABEL-08 sorts round one by matchOrder and skips losers', () {
      final plan = KnockoutSeedPlan.fromStages(
        _stages(
          knockoutMatches: [
            _stageMatch('late', 5),
            _stageMatch('loser', 1, branch: 'LOSERS'),
            _stageMatch('early', 2),
            _stageMatch('final', 1, round: 2),
          ],
        ),
      )!;
      expect(plan.roundOneMatchIds, ['early', 'late']);
    });

    test(
      'TC-SEEDLABEL-09 a saved slot order is used only if it is a permutation',
      () {
        final saved = [
          {'groupIndex': 1, 'rank': 1},
          {'groupIndex': 0, 'rank': 2},
          {'groupIndex': 0, 'rank': 1},
          {'groupIndex': 1, 'rank': 2},
        ];
        final used = KnockoutSeedPlan.fromStages(
          _stages(
            groupNames: const ['A', 'B'],
            mapping: {'numGroups': 2, 'teamsAdvancing': 2, 'slotOrder': saved},
          ),
        )!;
        expect(_keys(used.slotOrder), ['1:1', '0:2', '0:1', '1:2']);

        final ignored = KnockoutSeedPlan.fromStages(
          _stages(
            groupNames: const ['A', 'B'],
            mapping: {
              'numGroups': 2,
              'teamsAdvancing': 2,
              'slotOrder': [
                {'groupIndex': 0, 'rank': 1},
                {'groupIndex': 0, 'rank': 1},
                {'groupIndex': 1, 'rank': 1},
                {'groupIndex': 1, 'rank': 2},
              ],
            },
          ),
        )!;
        expect(_keys(ignored.slotOrder), ['0:1', '1:2', '1:1', '0:2']);
      },
    );

    test('TC-SEEDLABEL-10 returns null without a group stage mapping', () {
      expect(
        KnockoutSeedPlan.fromStages([_stage('DOUBLE_ELIMINATION')]),
        isNull,
      );
      expect(
        KnockoutSeedPlan.fromStages([
          _stage('ROUND_ROBIN', id: 'a'),
          _stage('DOUBLE_ELIMINATION', id: 'b'),
        ]),
        isNull,
      );
      expect(
        KnockoutSeedPlan.fromStages(
          _stages(mapping: {'source': 'SWISS', 'numGroups': 2}),
        ),
        isNull,
      );
    });

    test('TC-SEEDLABEL-11 an unnamed group falls back to a letter', () {
      final plan = KnockoutSeedPlan.fromStages(
        _stages(groupNames: const ['', 'Bảng B']),
      )!;
      expect(plan.groupName(0), 'A');
      expect(plan.groupName(1), 'Bảng B');
      expect(plan.groupName(7), 'H');
    });
  });

  group('KnockoutSeedPlan.withSwapped', () {
    test('TC-SEEDLABEL-12 swaps two slots and keeps the original intact', () {
      final plan = KnockoutSeedPlan.fromStages(_stages())!;
      final next = plan.withSwapped(0, 3);
      expect(_keys(next.slotOrder).take(4), ['0:2', '1:2', '1:1', '0:1']);
      expect(_keys(plan.slotOrder).take(4), ['0:1', '1:2', '1:1', '0:2']);
    });

    test('TC-SEEDLABEL-13 same or out-of-range slots return the same plan', () {
      final plan = KnockoutSeedPlan.fromStages(_stages())!;
      expect(identical(plan.withSwapped(1, 1), plan), isTrue);
      expect(identical(plan.withSwapped(0, 99), plan), isTrue);
      expect(identical(plan.withSwapped(-1, 2), plan), isTrue);
    });
  });

  group('playoff board labels', () {
    late _MockTournamentRepository repository;

    MatchModel match(String id, int round, {String status = 'SCHEDULED'}) =>
        MatchModel.fromJson({
          'tournamentId': _tournamentId,
          'round': round,
          'matchNumber': 1,
          'status': status,
          'team1Name': '',
          'team2Name': '',
          'stageType': 'DOUBLE_ELIMINATION',
          'bracketPosition': {
            'bracket': 'winners',
            'round': round,
            'position': 0,
          },
        }, id);

    List<MatchModel> bracket({String status = 'SCHEDULED'}) => [
      match('m1', 1, status: status),
      match('m2', 1),
      match('f', 2),
    ];

    setUp(() {
      repository = _MockTournamentRepository();
      when(
        () => repository.getDivisionStages(
          any(),
          divisionId: any(named: 'divisionId'),
        ),
      ).thenAnswer((_) async => _stages());
      when(
        () => repository.updateSeedOrder(
          any(),
          divisionId: any(named: 'divisionId'),
          stageId: any(named: 'stageId'),
          slotOrder: any(named: 'slotOrder'),
        ),
      ).thenAnswer((_) async {});
    });

    Future<void> pump(
      WidgetTester tester, {
      required bool canEdit,
      List<MatchModel>? matches,
    }) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final list = matches ?? bracket();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(repository),
            bracketMatchesWithDivisionProvider.overrideWith(
              (ref, arg) => Stream.value(list),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: PlayoffSeedHost(
                  tournamentId: _tournamentId,
                  divisionId: _divisionId,
                  matches: list,
                  canEdit: canEdit,
                  builder: (context, labels) => PlayoffDoubleElimView(
                    matches: list,
                    tournamentId: _tournamentId,
                    seedLabels: labels,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> drag(WidgetTester tester, String from, String to) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(from)),
      );
      await tester.pump(kLongPressTimeout);
      await gesture.moveTo(tester.getCenter(find.text(to)));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('TC-SEEDLABEL-14 empty round-one slots show their seed', (
      tester,
    ) async {
      await pump(tester, canEdit: false);

      expect(find.text('Nhất A'), findsOneWidget);
      expect(find.text('Nhì B'), findsOneWidget);
      expect(find.text('Nhất B'), findsOneWidget);
      expect(find.text('Nhì A'), findsOneWidget);
    });

    testWidgets('TC-SEEDLABEL-15 a viewer cannot drag the labels', (
      tester,
    ) async {
      await pump(tester, canEdit: false);

      expect(find.byKey(const ValueKey('seed-slot-0')), findsNothing);
      await drag(tester, 'Nhất A', 'Nhì B');
      verifyNever(
        () => repository.updateSeedOrder(
          any(),
          divisionId: any(named: 'divisionId'),
          stageId: any(named: 'stageId'),
          slotOrder: any(named: 'slotOrder'),
        ),
      );
    });

    testWidgets('TC-SEEDLABEL-16 a manager swaps two seeds by dragging', (
      tester,
    ) async {
      await pump(tester, canEdit: true);

      await drag(tester, 'Nhất A', 'Nhì B');

      final captured =
          verify(
                () => repository.updateSeedOrder(
                  _tournamentId,
                  divisionId: _divisionId,
                  stageId: 'stage-2',
                  slotOrder: captureAny(named: 'slotOrder'),
                ),
              ).captured.single
              as List;
      expect(captured.take(4).toList(), [
        {'groupIndex': 1, 'rank': 2},
        {'groupIndex': 0, 'rank': 1},
        {'groupIndex': 1, 'rank': 1},
        {'groupIndex': 0, 'rank': 2},
      ]);
    });

    testWidgets('TC-SEEDLABEL-17 labels are read-only once a match started', (
      tester,
    ) async {
      await pump(tester, canEdit: true, matches: bracket(status: 'LIVE'));

      expect(find.text('Nhất A'), findsOneWidget);
      expect(find.byKey(const ValueKey('seed-slot-0')), findsNothing);
    });

    testWidgets('TC-SEEDLABEL-18 a failed save shows an error message', (
      tester,
    ) async {
      when(
        () => repository.updateSeedOrder(
          any(),
          divisionId: any(named: 'divisionId'),
          stageId: any(named: 'stageId'),
          slotOrder: any(named: 'slotOrder'),
        ),
      ).thenThrow(Exception('boom'));
      await pump(tester, canEdit: true);

      await drag(tester, 'Nhất A', 'Nhì B');

      expect(find.textContaining('Không thể đổi vị trí'), findsOneWidget);
    });
  });
}
