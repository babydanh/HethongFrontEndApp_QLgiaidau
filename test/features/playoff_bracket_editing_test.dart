import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/models/bracket_slot_drag.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/playoff_double_elim_view.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/public_bracket_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTournamentRepository extends Mock implements ITournamentRepository {}

/// Round 1: m1 (Alpha v Bravo), m2 (Charlie v Delta); round 2: empty final.
List<MatchModel> _bracket({String m1Status = 'SCHEDULED'}) {
  MatchModel build(
    String id,
    int round,
    int position, {
    String status = 'SCHEDULED',
    String? t1,
    String? t2,
    String next = '',
  }) => MatchModel.fromJson({
    'tournamentId': 't-1',
    'round': round,
    'matchNumber': position + 1,
    'status': status,
    'team1Id': t1 == null ? '' : 'id-$t1',
    'team2Id': t2 == null ? '' : 'id-$t2',
    'team1Name': t1 ?? '',
    'team2Name': t2 ?? '',
    'nextMatchId': next,
    'bracketPosition': {
      'bracket': 'winners',
      'round': round,
      'position': position,
    },
  }, id);

  return [
    build('m1', 1, 0, status: m1Status, t1: 'Alpha', t2: 'Bravo', next: 'f'),
    build('m2', 1, 1, t1: 'Charlie', t2: 'Delta', next: 'f'),
    build('f', 2, 0),
  ];
}

Finder _slot(String matchId, int side) =>
    find.byKey(ValueKey('bracket-slot-$matchId-participant$side'));

Widget _host(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: AppTheme.lightTheme,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

Future<void> _setSize(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _drag(WidgetTester tester, Finder from, Finder to) async {
  final gesture = await tester.startGesture(tester.getCenter(from));
  await tester.pump(kLongPressTimeout);
  await gesture.moveTo(tester.getCenter(to));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  group('PlayoffDoubleElimView editing', () {
    late List<(BracketSlotDragData, BracketSlotDragData)> drops;
    late Future<void> Function(BracketSlotDragData, BracketSlotDragData) onDrop;

    setUp(() {
      drops = [];
      onDrop = (source, target) async => drops.add((source, target));
    });

    Future<void> pump(
      WidgetTester tester, {
      List<MatchModel>? matches,
      bool editable = true,
    }) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _host(
          PlayoffDoubleElimView(
            matches: matches ?? _bracket(),
            tournamentId: 't-1',
            onSlotDrop: editable ? (s, t) => onDrop(s, t) : null,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('TC-BRK-DND-01 dragging a team onto another swaps them', (
      tester,
    ) async {
      await pump(tester);

      await _drag(tester, _slot('m1', 1), _slot('m2', 1));

      expect(drops, hasLength(1));
      final (source, target) = drops.single;
      expect(source.participantId, 'id-Alpha');
      expect(target.participantId, 'id-Charlie');
      expect(bracketSlotOperation(source, target)?['operation'], 'SWAP');
    });

    testWidgets('TC-BRK-DND-02 dropping on an empty slot moves the team', (
      tester,
    ) async {
      await pump(tester);

      await _drag(tester, _slot('m2', 2), _slot('f', 1));

      expect(drops, hasLength(1));
      final (source, target) = drops.single;
      expect(source.participantId, 'id-Delta');
      expect(target.hasParticipant, isFalse);
      expect(bracketSlotOperation(source, target)?['operation'], 'MOVE');
    });

    testWidgets('TC-BRK-DND-03 a started match cannot be lifted', (
      tester,
    ) async {
      await pump(tester, matches: _bracket(m1Status: 'LIVE'));

      await _drag(tester, _slot('m1', 1), _slot('m2', 1));

      expect(drops, isEmpty);
    });

    testWidgets('TC-BRK-DND-04 tap one slot then another moves the team', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(_slot('m1', 2));
      await tester.pump();
      await tester.tap(_slot('m2', 2));
      await tester.pumpAndSettle();

      expect(drops, hasLength(1));
      expect(drops.single.$1.participantId, 'id-Bravo');
      expect(drops.single.$2.participantId, 'id-Delta');
    });

    testWidgets('TC-BRK-DND-05 tapping the picked slot again cancels it', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(_slot('m1', 1));
      await tester.pump();
      await tester.tap(_slot('m1', 1));
      await tester.pump();
      await tester.tap(_slot('m2', 1));
      await tester.pumpAndSettle();

      expect(drops, isEmpty);
    });

    testWidgets('TC-BRK-DND-06 read-only view has no draggable slots', (
      tester,
    ) async {
      await pump(tester, editable: false);

      expect(_slot('m1', 1), findsNothing);
      expect(find.text('Alpha'), findsWidgets);
    });

    testWidgets('TC-BRK-DND-10 double tap on a card reports that match', (
      tester,
    ) async {
      final opened = <String>[];
      await _setSize(tester);
      await tester.pumpWidget(
        _host(
          PlayoffDoubleElimView(
            matches: _bracket(),
            tournamentId: 't-1',
            onDoubleTapMatch: (match) => opened.add(match.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = find.byKey(const ValueKey('playoff-card-m1'));
      final header = tester.getTopLeft(card) + const Offset(20, 10);
      await tester.tapAt(header);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(header);
      await tester.pumpAndSettle();

      expect(opened, ['m1']);
    });

    testWidgets('TC-BRK-DND-07 a second drop waits for the running save', (
      tester,
    ) async {
      final pending = Completer<void>();
      onDrop = (source, target) {
        drops.add((source, target));
        return pending.future;
      };
      await pump(tester);

      await _drag(tester, _slot('m1', 1), _slot('m2', 1));
      await _drag(tester, _slot('m1', 2), _slot('m2', 2));
      expect(drops, hasLength(1));

      pending.complete();
      await tester.pumpAndSettle();
      await _drag(tester, _slot('m1', 2), _slot('m2', 2));
      expect(drops, hasLength(2));
    });
  });

  group('PublicBracketView manager mode', () {
    late _MockTournamentRepository repository;

    setUp(() {
      repository = _MockTournamentRepository();
      when(
        () => repository.updateBracketSlots(
          any(),
          divisionId: any(named: 'divisionId'),
          operations: any(named: 'operations'),
          isLite: any(named: 'isLite'),
        ),
      ).thenAnswer((_) async {});
    });

    Future<void> pump(WidgetTester tester, {required bool canEdit}) async {
      await _setSize(tester);
      await tester.pumpWidget(
        _host(
          PublicBracketView(
            tournamentId: 't-1',
            divisionId: 'div-1',
            matches: _bracket(),
            bracketType: 'single_elimination',
            canEditBracket: canEdit,
          ),
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(repository),
            tournamentProvider.overrideWith((ref, id) => Stream.value(null)),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('TC-BRK-DND-08 a manager drag is sent to the backend', (
      tester,
    ) async {
      await pump(tester, canEdit: true);

      expect(find.byKey(const Key('bracket-holding-tray')), findsOneWidget);
      await _drag(tester, _slot('m1', 1), _slot('m2', 1));

      final captured =
          verify(
                () => repository.updateBracketSlots(
                  't-1',
                  divisionId: 'div-1',
                  operations: captureAny(named: 'operations'),
                  isLite: false,
                ),
              ).captured.single
              as List;
      expect(captured.single, {
        'operation': 'SWAP',
        'fromMatchId': 'm1',
        'fromSlot': 'participant1',
        'toMatchId': 'm2',
        'toSlot': 'participant1',
      });
    });

    testWidgets('TC-BRK-DND-09 a viewer sees no tray and cannot drag', (
      tester,
    ) async {
      await pump(tester, canEdit: false);

      expect(find.byKey(const Key('bracket-holding-tray')), findsNothing);
      expect(_slot('m1', 1), findsNothing);
      await _drag(tester, find.text('Alpha'), find.text('Charlie'));
      verifyNever(
        () => repository.updateBracketSlots(
          any(),
          divisionId: any(named: 'divisionId'),
          operations: any(named: 'operations'),
          isLite: any(named: 'isLite'),
        ),
      );
    });
  });
}
