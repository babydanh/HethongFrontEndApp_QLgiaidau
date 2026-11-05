import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/repositories/pair_move_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/pair_move_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/pair_move_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Ops implements ITournamentRepository {
  _Ops(this.participants);

  final List<OrganizerOpsParticipant> participants;
  int calls = 0;

  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async {
    calls += 1;
    return participants;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Moves implements PairMoveRepository {
  final moves = <PairMoveRequest>[];
  final removes = <({String participantId, int slot, String expectedKey})>[];

  /// Thrown by the next write when set.
  Object? error;

  /// When set, a write waits for it (to observe the busy state).
  Completer<void>? gate;

  @override
  Future<List<String>> movePairMember(
    String tournamentId,
    PairMoveRequest request,
  ) async {
    await gate?.future;
    if (error != null) throw error!;
    moves.add(request);
    return const [];
  }

  @override
  Future<PairRemoveResult> removePairMember(
    String tournamentId, {
    required String participantId,
    required int slot,
    required String expectedKey,
  }) async {
    await gate?.future;
    if (error != null) throw error!;
    removes.add((
      participantId: participantId,
      slot: slot,
      expectedKey: expectedKey,
    ));
    return const PairRemoveResult(
      remainingParticipantId: 'p-1',
      removedParticipantId: 'gone',
    );
  }
}

OrganizerOpsParticipant _participant(
  String id,
  List<ParticipantPlayer> players, {
  String status = 'COMPLETE',
  Map<String, dynamic> customResponses = const {},
}) => OrganizerOpsParticipant(
  id: id,
  teamStatus: status,
  isPaid: false,
  members: const [],
  players: players,
  divisionId: 'div-1',
  customResponses: customResponses,
);

ParticipantPlayer _account(int slot, String userId, String name) =>
    ParticipantPlayer(slot: slot, userId: userId, fullName: name);

/// p-1: pair An + Bình; p-2: pair Khách (guest with email) + Cường;
/// p-3: Dũng waiting alone; p-4: withdrawn row that must not be listed.
List<OrganizerOpsParticipant> _fixture() => [
  _participant('p-1', [_account(1, 'u-a', 'An'), _account(2, 'u-b', 'Bình')]),
  _participant(
    'p-2',
    [
      const ParticipantPlayer(slot: 1, fullName: ' Khách ', isGuest: true),
      _account(2, 'u-c', 'Cường'),
    ],
    customResponses: {'player1Email': 'K@X.com'},
  ),
  _participant('p-3', [
    _account(1, 'u-d', 'Dũng'),
  ], status: 'PENDING_PARTNER'),
  _participant('p-4', [_account(1, 'u-e', 'Em')], status: 'WITHDRAWN'),
];

Widget _app(_Ops ops, _Moves moves) => ProviderScope(
  overrides: [
    tournamentRepositoryProvider.overrideWithValue(ops),
    pairMoveRepositoryProvider.overrideWithValue(moves),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          key: const ValueKey('open-sheet'),
          onPressed: () => PairMoveSheet.show(
            context,
            tournamentId: 't-1',
            divisionId: 'div-1',
          ),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

/// Runs a few frames instead of `pumpAndSettle` (the sheet keeps animating).
Future<void> _frames(WidgetTester tester, [int count = 6]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<(_Ops, _Moves)> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final ops = _Ops(_fixture());
  final moves = _Moves();
  await tester.pumpWidget(_app(ops, moves));
  await tester.tap(find.byKey(const ValueKey('open-sheet')));
  await _frames(tester);
  return (ops, moves);
}

PopupMenuButton<String> _menu(WidgetTester tester, String id, int slot) =>
    tester.widget<PopupMenuButton<String>>(
      find.byKey(ValueKey('pair-move-menu-$id-$slot')),
    );

/// A tap on a PopupMenu item is swallowed by its barrier in widget tests, so
/// the selection callback is called directly.
Future<void> _select(
  WidgetTester tester,
  String id,
  int slot,
  String value,
) async {
  _menu(tester, id, slot).onSelected!(value);
  await _frames(tester);
}

DioException _conflict() => DioException(
  requestOptions: RequestOptions(path: '/tournaments/t-1/pairing/move'),
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/tournaments/t-1/pairing/move'),
    statusCode: 409,
    data: {'message': 'Danh sách vừa thay đổi, tải lại'},
  ),
  type: DioExceptionType.badResponse,
);

void main() {
  testWidgets('TC-PAIRMOVE-06: lists the division rows, hides inactive ones', (
    tester,
  ) async {
    await _open(tester);

    expect(find.byKey(const ValueKey('pair-move-row-p-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pair-move-row-p-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('pair-move-row-p-4')), findsNothing);
    // The single waiting athlete has one empty slot.
    expect(
      find.byKey(const ValueKey('pair-move-empty-p-3-2')),
      findsOneWidget,
    );
  });

  testWidgets(
    'TC-PAIRMOVE-07: remove from pair asks first, then sends the slot and member key',
    (tester) async {
      final (ops, moves) = await _open(tester);

      await _select(tester, 'p-1', 2, 'remove');
      expect(moves.removes, isEmpty, reason: 'nothing is sent before confirm');

      await tester.tap(find.widgetWithText(FilledButton, 'Remove from pair'));
      await _frames(tester);

      expect(moves.removes, hasLength(1));
      expect(moves.removes.single.participantId, 'p-1');
      expect(moves.removes.single.slot, 2);
      expect(moves.removes.single.expectedKey, 'account:u-b');
      expect(ops.calls, 2, reason: 'list reloaded after the removal');
      expect(find.text('Athlete removed from the pair.'), findsOneWidget);
    },
  );

  testWidgets('TC-PAIRMOVE-08: cancelling the confirm sends nothing', (
    tester,
  ) async {
    final (_, moves) = await _open(tester);

    await _select(tester, 'p-1', 1, 'remove');
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await _frames(tester);

    expect(moves.removes, isEmpty);
  });

  testWidgets('TC-PAIRMOVE-09: a 409 on remove reloads the list and says so', (
    tester,
  ) async {
    final (ops, moves) = await _open(tester);
    moves.error = _conflict();

    await _select(tester, 'p-1', 1, 'remove');
    await tester.tap(find.widgetWithText(FilledButton, 'Remove from pair'));
    await _frames(tester);

    expect(ops.calls, 2);
    expect(
      find.text('The list just changed. It was reloaded, please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('TC-PAIRMOVE-10: a network error shows the generic failure', (
    tester,
  ) async {
    final (ops, moves) = await _open(tester);
    moves.error = DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionTimeout,
    );

    await _select(tester, 'p-1', 1, 'remove');
    await tester.tap(find.widgetWithText(FilledButton, 'Remove from pair'));
    await _frames(tester);

    expect(find.textContaining('Could not move the athlete'), findsOneWidget);
    expect(ops.calls, 1, reason: 'no reload on a plain failure');
  });

  testWidgets(
    'TC-PAIRMOVE-11: "Move to…" swaps with a slot of another pair using both member keys',
    (tester) async {
      final (ops, moves) = await _open(tester);

      await _select(tester, 'p-1', 1, 'move');
      await tester.tap(find.byKey(const ValueKey('pair-move-pick-p-2-1')));
      await _frames(tester);

      final request = moves.moves.single;
      expect(request.divisionId, 'div-1');
      expect(request.sourceParticipantId, 'p-1');
      expect(request.sourceSlot, 1);
      expect(request.target.participantId, 'p-2');
      expect(request.target.slot, 1);
      expect(request.expectedSource, 'account:u-a');
      expect(request.expectedTarget, 'guest:Khách|k@x.com');
      expect(ops.calls, 2);
      expect(find.text('Athlete moved.'), findsOneWidget);
    },
  );

  testWidgets('TC-PAIRMOVE-12: a 409 on move reloads the list and says so', (
    tester,
  ) async {
    final (ops, moves) = await _open(tester);
    moves.error = _conflict();

    await _select(tester, 'p-1', 1, 'move');
    await tester.tap(find.byKey(const ValueKey('pair-move-pick-p-2-1')));
    await _frames(tester);

    expect(moves.moves, isEmpty);
    expect(ops.calls, 2);
    expect(
      find.text('The list just changed. It was reloaded, please try again.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'TC-PAIRMOVE-13: moving into the empty slot of a waiting athlete sends a null expected target',
    (tester) async {
      final (_, moves) = await _open(tester);

      await _select(tester, 'p-1', 2, 'move');
      await tester.tap(find.byKey(const ValueKey('pair-move-pick-p-3-2')));
      await _frames(tester);

      expect(moves.moves.single.target.participantId, 'p-3');
      expect(moves.moves.single.target.slot, 2);
      expect(moves.moves.single.expectedTarget, isNull);
    },
  );

  testWidgets(
    'TC-PAIRMOVE-14: only a member of a pair can be removed or sent to the tray',
    (tester) async {
      await _open(tester);

      final waiting = _menu(tester, 'p-3', 1);
      final pair = _menu(tester, 'p-1', 1);
      final context = tester.element(
        find.byKey(const ValueKey('pair-move-menu-p-3-1')),
      );

      expect(waiting.itemBuilder(context), hasLength(1));
      expect(pair.itemBuilder(context), hasLength(2));

      await _select(tester, 'p-3', 1, 'move');
      expect(find.byKey(const ValueKey('pair-move-pick-tray')), findsNothing);
    },
  );

  testWidgets('TC-PAIRMOVE-15: the controls lock while a write is in flight', (
    tester,
  ) async {
    final (_, moves) = await _open(tester);
    moves.gate = Completer<void>();

    await _select(tester, 'p-1', 2, 'remove');
    await tester.tap(find.widgetWithText(FilledButton, 'Remove from pair'));
    await _frames(tester);

    expect(_menu(tester, 'p-1', 1).enabled, isFalse);
    expect(_menu(tester, 'p-3', 1).enabled, isFalse);

    moves.gate!.complete();
    await _frames(tester);

    expect(_menu(tester, 'p-1', 1).enabled, isTrue);
    expect(moves.removes, hasLength(1));
  });

  testWidgets('TC-PAIRMOVE-16: dragging a member onto the tray splits the pair', (
    tester,
  ) async {
    final (_, moves) = await _open(tester);

    final start =
        tester.getTopLeft(
          find.byKey(const ValueKey('pair-move-member-p-1-2')),
        ) +
        const Offset(20, 20);
    final gesture = await tester.startGesture(start, kind: PointerDeviceKind.touch);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('pair-move-tray'))),
    );
    await tester.pump();
    await gesture.up();
    await _frames(tester);

    final request = moves.moves.single;
    expect(request.target.tray, isTrue);
    expect(request.sourceParticipantId, 'p-1');
    expect(request.sourceSlot, 2);
    expect(request.expectedSource, 'account:u-b');
    expect(request.expectedTarget, isNull);
  });

  testWidgets('TC-PAIRMOVE-17: dragging a member onto another pair swaps them', (
    tester,
  ) async {
    final (_, moves) = await _open(tester);

    final start =
        tester.getTopLeft(
          find.byKey(const ValueKey('pair-move-member-p-1-1')),
        ) +
        const Offset(20, 20);
    final gesture = await tester.startGesture(start, kind: PointerDeviceKind.touch);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('pair-move-member-p-2-2'))),
    );
    await tester.pump();
    await gesture.up();
    await _frames(tester);

    final request = moves.moves.single;
    expect(request.target.participantId, 'p-2');
    expect(request.target.slot, 2);
    expect(request.expectedSource, 'account:u-a');
    expect(request.expectedTarget, 'account:u-c');
  });
}
