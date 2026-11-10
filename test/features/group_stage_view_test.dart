import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/group_stage_config.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/group_stage_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _an = 'Nguyễn Văn An';
const _binh = 'Trần Thị Bình';
const _cuong = 'Lê Hoàng Cường';
const _dung = 'Phạm Minh Dũng';

Map<String, dynamic> _participant(List<String> names) => {
  'players': [
    for (final n in names) {'fullName': n},
  ],
};

MatchModel _match({
  required String id,
  bool done = true,
  int round = 1,
  String? winnerId,
}) => MatchModel.fromJson({
  'tournamentId': 't-1',
  'round': round,
  'matchNumber': 1,
  'status': done ? 'COMPLETED' : 'SCHEDULED',
  'team1Id': 't1',
  'team2Id': 't2',
  'team1Name': '',
  'team2Name': '',
  'participant1': _participant([_an, _binh]),
  'participant2': _participant([_cuong, _dung]),
  'groupName': 'A',
  'winnerId': ?winnerId,
  if (done)
    'sets': [
      {'score1': 11, 'score2': 8},
      {'score1': 9, 'score2': 11},
      {'score1': 11, 'score2': 5},
    ],
}, id);

final _standings = [
  Standing(
    id: 't1',
    teamName: '',
    group: 'A',
    played: 1,
    won: 1,
    players: const [
      ParticipantPlayer(slot: 1, fullName: _an),
      ParticipantPlayer(slot: 2, fullName: _binh),
    ],
  ),
  Standing(
    id: 't2',
    teamName: '',
    group: 'A',
    played: 1,
    lost: 1,
    players: const [
      ParticipantPlayer(slot: 1, fullName: _cuong),
      ParticipantPlayer(slot: 2, fullName: _dung),
    ],
  ),
];

Future<void> _pump(WidgetTester tester, List<MatchModel> matches) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        standingsWithDivisionProvider((
          tournamentId: 't-1',
          divisionId: null,
        )).overrideWith((ref) => Stream.value(_standings)),
        matchesWithDivisionProvider((
          tournamentId: 't-1',
          divisionId: null,
        )).overrideWith((ref) => Stream.value(matches)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: GroupStageView(matches: matches, tournamentId: 't-1'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-GSV-10 matrix: explicit group name, abbreviated doubles, '
      'one line per set, no hint text or scrollbar', (tester) async {
    await _pump(tester, [_match(id: 'm1', winnerId: 't1')]);

    expect(find.text('Bảng A'), findsOneWidget);
    expect(find.text('2 Đội'), findsOneWidget);
    expect(find.text('STT'), findsOneWidget);
    expect(find.text('VĐV / Đội'), findsOneWidget);
    expect(find.text('T / B'), findsOneWidget);
    expect(find.text(abbreviateName(_an)), findsOneWidget);
    expect(find.text(abbreviateName(_dung)), findsOneWidget);
    expect(find.text(_an), findsNothing);
    for (final line in ['11-8', '9-11', '11-5', '8-11', '11-9', '5-11']) {
      expect(find.text(line), findsOneWidget, reason: line);
    }
    expect(find.text('1 / 0'), findsOneWidget);
    expect(find.textContaining('Cách tính'), findsNothing);
    expect(find.byType(Scrollbar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'TC-GSV-11 tapping a played cell opens the sheet with full names',
    (tester) async {
      await _pump(tester, [_match(id: 'm1', winnerId: 't1')]);

      await tester.tap(find.text('11-8'));
      await tester.pumpAndSettle();

      expect(find.text('Bảng A · Lượt 1'), findsOneWidget);
      expect(find.text(_an), findsOneWidget);
      expect(find.text(_dung), findsOneWidget);
      expect(find.text('THẮNG'), findsOneWidget);
      expect(find.text('THUA'), findsOneWidget);
      expect(find.text('Xem trận'), findsOneWidget);
      expect(find.text('Đã xong'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-GSV-12 unplayed cell shows a dash and still opens the sheet',
    (tester) async {
      await _pump(tester, [_match(id: 'm1', done: false)]);

      expect(find.text('-'), findsNWidgets(2));
      await tester.tap(find.text('-').first);
      await tester.pumpAndSettle();

      expect(find.text('Sắp diễn ra'), findsOneWidget);
      expect(find.text('Chưa xếp sân'), findsOneWidget);
      expect(find.text('THẮNG'), findsNothing);
    },
  );

  testWidgets('TC-GSV-13 modes: standings columns and by-round list', (
    tester,
  ) async {
    await _pump(tester, [_match(id: 'm1', winnerId: 't1')]);

    await tester.tap(find.text('Bảng xếp hạng'));
    await tester.pumpAndSettle();
    expect(find.text('Điểm'), findsOneWidget);
    expect(find.text('Hiệu số'), findsOneWidget);

    await tester.tap(find.text('Theo lượt'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Vòng'), findsNothing);
    expect(find.text('Đã xong'), findsOneWidget);

    await tester.tap(find.text('Bảng chéo'));
    await tester.pumpAndSettle();
    expect(find.text('STT'), findsOneWidget);
  });

  group('drag a team to another group (TC-GROUP-DND)', () {
    final standings = [
      const Standing(id: 't1', teamName: 'Đội Một', group: 'A'),
      const Standing(id: 't2', teamName: 'Đội Hai', group: 'A'),
      const Standing(id: 't3', teamName: 'Đội Ba', group: 'B'),
    ];
    const config = GroupStageConfig(
      groups: [
        GroupStageGroup(name: 'A', participantIds: ['t1', 't2']),
        GroupStageGroup(name: 'B', participantIds: ['t3']),
      ],
      unassignedParticipantIds: [],
      participantIds: ['t1', 't2', 't3'],
      teamsAdvancing: 1,
      teamsPerGroup: 2,
    );

    Future<void> pumpEditable(
      WidgetTester tester, {
      Future<void> Function(GroupStageConfig next)? onConfigChanged,
      bool editLocked = false,
      GroupStageConfig editableConfig = config,
      List<Team> teams = const [],
      double viewHeight = 1200,
    }) async {
      tester.view.physicalSize = Size(400, viewHeight);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            standingsWithDivisionProvider((
              tournamentId: 't-1',
              divisionId: null,
            )).overrideWith((ref) => Stream.value(standings)),
            matchesWithDivisionProvider((
              tournamentId: 't-1',
              divisionId: null,
            )).overrideWith((ref) => Stream.value(const <MatchModel>[])),
            teamsProvider('t-1').overrideWith((ref) => Stream.value(teams)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: GroupStageView(
                  matches: const [],
                  tournamentId: 't-1',
                  editableConfig: editableConfig,
                  onConfigChanged: onConfigChanged,
                  editLocked: editLocked,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> dragTeamTo(
      WidgetTester tester,
      String team,
      String groupTitle,
    ) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(team)),
      );
      await tester.pump(kLongPressTimeout);
      await gesture.moveTo(tester.getCenter(find.text(groupTitle)));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    Future<void> dragTeamToGroupB(WidgetTester tester, String team) =>
        dragTeamTo(tester, team, 'Bảng B');

    GroupStageConfig configWith({
      required List<GroupStageGroup> groups,
      List<String> unassigned = const [],
    }) => GroupStageConfig(
      groups: groups,
      unassignedParticipantIds: unassigned,
      participantIds: [
        for (final group in groups) ...group.participantIds,
        ...unassigned,
      ],
      teamsAdvancing: 1,
      teamsPerGroup: 2,
    );

    testWidgets(
      'TC-GROUP-DND-10 an empty group shows a card that takes a drop',
      (tester) async {
        final saved = <GroupStageConfig>[];
        await pumpEditable(
          tester,
          editableConfig: configWith(
            groups: const [
              GroupStageGroup(name: 'A', participantIds: ['t1', 't2']),
              GroupStageGroup(name: 'B', participantIds: ['t3']),
              GroupStageGroup(name: 'C', participantIds: []),
            ],
          ),
          onConfigChanged: (next) async => saved.add(next),
        );

        expect(
          find.byKey(const ValueKey('group-empty-Bảng C')),
          findsOneWidget,
        );
        await dragTeamTo(tester, 'Đội Hai', 'Bảng C');

        expect(saved, hasLength(1));
        expect(saved.single.groups[2].participantIds, ['t2']);
      },
    );

    testWidgets(
      'TC-GROUP-DND-11 an unassigned team can be dragged into a group',
      (tester) async {
        final saved = <GroupStageConfig>[];
        await pumpEditable(
          tester,
          editableConfig: configWith(
            groups: const [
              GroupStageGroup(name: 'A', participantIds: ['t1', 't2']),
              GroupStageGroup(name: 'B', participantIds: ['t3']),
            ],
            unassigned: const ['t4'],
          ),
          teams: [
            Team(
              id: 't4',
              name: 'Đội Bốn',
              approvalStatus: 'COMPLETE',
              createdAt: DateTime.utc(2026),
            ),
          ],
          onConfigChanged: (next) async => saved.add(next),
        );

        expect(
          find.byKey(const ValueKey('group-unassigned-lane')),
          findsOneWidget,
        );
        await dragTeamTo(tester, 'Đội Bốn', 'Bảng B');

        expect(saved, hasLength(1));
        expect(saved.single.groups[1].participantIds, ['t3', 't4']);
        expect(saved.single.unassignedParticipantIds, isEmpty);
      },
    );

    testWidgets(
      'TC-GROUP-DND-12 no lane or empty card without a need or edit',
      (tester) async {
        // Edit mode, every team already in a group: no unassigned lane.
        await pumpEditable(tester, onConfigChanged: (next) async {});
        expect(
          find.byKey(const ValueKey('group-unassigned-lane')),
          findsNothing,
        );

        // Read-only view: extra config groups and unassigned teams stay hidden.
        await pumpEditable(
          tester,
          editableConfig: configWith(
            groups: const [
              GroupStageGroup(name: 'A', participantIds: ['t1', 't2']),
              GroupStageGroup(name: 'B', participantIds: ['t3']),
              GroupStageGroup(name: 'C', participantIds: []),
            ],
            unassigned: const ['t4'],
          ),
        );
        expect(find.byKey(const ValueKey('group-empty-Bảng C')), findsNothing);
        expect(
          find.byKey(const ValueKey('group-unassigned-lane')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'TC-GROUP-DND-01 dropping on another group reports new config',
      (tester) async {
        final saved = <GroupStageConfig>[];
        await pumpEditable(
          tester,
          onConfigChanged: (next) async => saved.add(next),
        );

        await dragTeamToGroupB(tester, 'Đội Một');

        expect(saved, hasLength(1));
        expect(saved.single.groups[0].participantIds, ['t2']);
        expect(saved.single.groups[1].participantIds, ['t3', 't1']);
      },
    );

    testWidgets('TC-GROUP-DND-02 editLocked renders no draggable team', (
      tester,
    ) async {
      var calls = 0;
      await pumpEditable(
        tester,
        editLocked: true,
        onConfigChanged: (next) async => calls++,
      );

      expect(find.byType(LongPressDraggable<String>), findsNothing);
      await dragTeamToGroupB(tester, 'Đội Một');
      expect(calls, 0);
    });

    testWidgets('TC-GROUP-DND-08 team missing from the config is not saved', (
      tester,
    ) async {
      var calls = 0;
      await pumpEditable(
        tester,
        // t1 is shown in the standings but unknown to this config.
        editableConfig: const GroupStageConfig(
          groups: [
            GroupStageGroup(name: 'A', participantIds: ['t2']),
            GroupStageGroup(name: 'B', participantIds: ['t3']),
          ],
          unassignedParticipantIds: [],
          participantIds: ['t2', 't3'],
          teamsAdvancing: 1,
          teamsPerGroup: 2,
        ),
        onConfigChanged: (next) async => calls++,
      );

      await dragTeamToGroupB(tester, 'Đội Một');

      expect(calls, 0);
    });

    testWidgets('TC-GROUP-DND-09 group names match ignoring case', (
      tester,
    ) async {
      final saved = <GroupStageConfig>[];
      await pumpEditable(
        tester,
        editableConfig: const GroupStageConfig(
          groups: [
            GroupStageGroup(name: 'bảng a', participantIds: ['t1', 't2']),
            GroupStageGroup(name: 'BẢNG B', participantIds: ['t3']),
          ],
          unassignedParticipantIds: [],
          participantIds: ['t1', 't2', 't3'],
          teamsAdvancing: 1,
          teamsPerGroup: 2,
        ),
        onConfigChanged: (next) async => saved.add(next),
      );

      await dragTeamToGroupB(tester, 'Đội Một');

      expect(saved, hasLength(1));
    });

    testWidgets('TC-GROUP-DND-03 no onConfigChanged keeps view read-only', (
      tester,
    ) async {
      await pumpEditable(tester);

      expect(find.byType(LongPressDraggable<String>), findsNothing);
      expect(find.byType(DragTarget<String>), findsNothing);
    });

    testWidgets('TC-GROUP-DND-05 a drop while saving is ignored', (
      tester,
    ) async {
      final pending = Completer<void>();
      var calls = 0;
      await pumpEditable(
        tester,
        onConfigChanged: (next) {
          calls++;
          return pending.future;
        },
      );

      await dragTeamToGroupB(tester, 'Đội Một');
      await dragTeamToGroupB(tester, 'Đội Hai');
      expect(calls, 1);

      pending.complete();
      await tester.pumpAndSettle();
      await dragTeamToGroupB(tester, 'Đội Hai');
      expect(calls, 2);
    });

    testWidgets(
      'TC-GROUP-DND-13 dropping on a team inserts before it, no-op keeps config',
      (tester) async {
        final saved = <GroupStageConfig>[];
        await pumpEditable(
          tester,
          onConfigChanged: (next) async => saved.add(next),
        );

        // Same group: Hai goes before Một.
        await dragTeamTo(tester, 'Đội Hai', 'Đội Một');
        expect(saved, hasLength(1));
        expect(saved.last.groups[0].participantIds, ['t2', 't1']);

        // Other group: Ba goes before Một, group B becomes empty.
        await dragTeamTo(tester, 'Đội Ba', 'Đội Một');
        expect(saved, hasLength(2));
        expect(saved.last.groups[0].participantIds, ['t3', 't1', 't2']);
        expect(saved.last.groups[1].participantIds, isEmpty);

        // Already right before the target, or dropped on itself: no save.
        await dragTeamTo(tester, 'Đội Một', 'Đội Hai');
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Đội Một')),
        );
        await tester.pump(kLongPressTimeout);
        await gesture.moveBy(const Offset(2, 0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
        expect(saved, hasLength(2));
      },
    );

    testWidgets(
      'TC-GROUP-DND-14 unassigned lane takes a team back and shows while dragging',
      (tester) async {
        final saved = <GroupStageConfig>[];
        await pumpEditable(
          tester,
          onConfigChanged: (next) async => saved.add(next),
        );
        expect(find.text('Chưa xếp'), findsNothing);

        // The lane appears once a drag starts, even with no unassigned team.
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Đội Hai')),
        );
        await tester.pump(kLongPressTimeout);
        await tester.pump();
        expect(find.text('Chưa xếp'), findsOneWidget);
        expect(find.text('Kéo đội vào đây'), findsOneWidget);
        await gesture.moveTo(tester.getCenter(find.text('Chưa xếp')));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(saved, hasLength(1));
        expect(saved.single.groups[0].participantIds, ['t1']);
        expect(saved.single.unassignedParticipantIds, ['t2']);
        expect(find.text('Chưa xếp'), findsNothing);
      },
    );

    testWidgets('TC-GROUP-DND-14b dropping an unassigned team on its lane is '
        'ignored', (tester) async {
      final saved = <GroupStageConfig>[];
      await pumpEditable(
        tester,
        editableConfig: configWith(
          groups: const [
            GroupStageGroup(name: 'A', participantIds: ['t1', 't2']),
            GroupStageGroup(name: 'B', participantIds: ['t3']),
          ],
          unassigned: const ['t4'],
        ),
        teams: [
          Team(
            id: 't4',
            name: 'Đội Bốn',
            approvalStatus: 'COMPLETE',
            createdAt: DateTime.utc(2026),
          ),
        ],
        onConfigChanged: (next) async => saved.add(next),
      );

      await dragTeamTo(tester, 'Đội Bốn', 'Chưa xếp');

      expect(saved, isEmpty);
    });

    testWidgets('TC-GROUP-DND-15 dragging near the bottom edge auto-scrolls', (
      tester,
    ) async {
      await pumpEditable(
        tester,
        viewHeight: 300,
        onConfigChanged: (next) async {},
      );
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
      expect(scrollable.position.pixels, 0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Đội Một')),
      );
      await tester.pump(kLongPressTimeout);
      await gesture.moveTo(const Offset(200, 290));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(scrollable.position.pixels, greaterThan(0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
