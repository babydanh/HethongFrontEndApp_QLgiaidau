import 'dart:async';

import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/swiss_pairing_draft.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/swiss_pairing_notifier.dart';
// ignore: depend_on_referenced_packages -- transitive via flutter_test; no new package
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ITournamentRepository {}

const _args = SwissPairingArgs(
  tournamentId: 't1',
  divisionId: 'd1',
  stageId: 's1',
);

SwissPreviewParticipant _p(String id) => SwissPreviewParticipant(
  id: id,
  teamName: 'Team $id',
  totalPoints: 1,
  buchholz: 0,
  hadBye: false,
);

SwissPreview _preview({
  List<SwissWarning> warnings = const [],
  int round = 3,
}) => SwissPreview(
  roundNumber: round,
  totalRounds: 5,
  pairs: const [
    SwissPreviewPair(board: 1, participant1Id: 'a', participant2Id: 'b'),
    SwissPreviewPair(board: 2, participant1Id: 'c', participant2Id: 'd'),
  ],
  byeParticipantId: 'e',
  sitOutParticipantIds: const [],
  participants: [
    for (final id in ['a', 'b', 'c', 'd', 'e']) _p(id),
  ],
  warnings: warnings,
);

const _ok = SwissValidateResult(valid: true, errors: [], warnings: []);

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(
      const SwissRoundDraftRequest(divisionId: 'd', pairs: []),
    );
  });

  setUp(() {
    repo = _MockRepo();
    when(
      () => repo.swissPreview(
        any(),
        divisionId: any(named: 'divisionId'),
        stageId: any(named: 'stageId'),
      ),
    ).thenAnswer((_) async => _preview());
    when(() => repo.swissValidate(any(), any())).thenAnswer((_) async => _ok);
    when(
      () => repo.swissNextRound(
        any(),
        any(),
        confirmWarnings: any(named: 'confirmWarnings'),
      ),
    ).thenAnswer(
      (_) async => const SwissNextRoundResult(roundNumber: 3, matchIds: []),
    );
  });

  var bracketBuilds = 0;
  var stageBuilds = 0;

  ProviderContainer makeContainer() {
    bracketBuilds = 0;
    stageBuilds = 0;
    final container = ProviderContainer(
      overrides: [
        tournamentRepositoryProvider.overrideWithValue(repo),
        bracketMatchesWithDivisionProvider.overrideWith((ref, arg) {
          bracketBuilds++;
          return Stream<List<MatchModel>>.value(const []);
        }),
        swissStageProvider.overrideWith((ref, arg) {
          stageBuilds++;
          return Stream<SwissStageInfo?>.value(null);
        }),
      ],
    );
    addTearDown(container.dispose);
    // autoDispose providers: keep them alive for the whole test.
    container.listen(swissPairingProvider(_args), (_, _) {});
    final params = (tournamentId: 't1', divisionId: 'd1');
    container.listen(bracketMatchesWithDivisionProvider(params), (_, _) {});
    container.listen(swissStageProvider(params), (_, _) {});
    return container;
  }

  SwissPairingNotifier notifier(ProviderContainer c) =>
      c.read(swissPairingProvider(_args).notifier);
  SwissPairingState read(ProviderContainer c) =>
      c.read(swissPairingProvider(_args));

  test('loads the preview into a draft', () {
    fakeAsync((async) {
      final c = makeContainer();
      expect(read(c).loading, isTrue);
      async.flushMicrotasks();

      final state = read(c);
      expect(state.loading, isFalse);
      expect(state.preview?.roundNumber, 3);
      expect(state.draft?.pairs.length, 2);
      expect(state.draft?.byeId, 'e');
      expect(state.canConfirm, isTrue);
      expect(state.canUndo, isFalse);
      verify(
        () => repo.swissPreview('t1', divisionId: 'd1', stageId: 's1'),
      ).called(1);
    });
  });

  test('preview failure keeps no draft and reports the API code', () {
    when(
      () => repo.swissPreview(
        any(),
        divisionId: any(named: 'divisionId'),
        stageId: any(named: 'stageId'),
      ),
    ).thenThrow(
      const SwissApiException(status: 409, code: 'SWISS_ROUND_INCOMPLETE'),
    );
    fakeAsync((async) {
      final c = makeContainer();
      async.flushMicrotasks();

      expect(read(c).loading, isFalse);
      expect(read(c).preview, isNull);
      expect(read(c).draft, isNull);
      expect(read(c).errorKey, 'SWISS_ROUND_INCOMPLETE');
      expect(read(c).canConfirm, isFalse);
    });
  });

  test('three moves within 400 ms trigger one validate call', () {
    fakeAsync((async) {
      final c = makeContainer();
      async.flushMicrotasks();
      final n = notifier(c);

      n.move('b', const SwissPairSlot(1, 1)); // b <-> c
      async.elapse(const Duration(milliseconds: 100));
      n.move('b', const SwissPairSlot(0, 2)); // back
      async.elapse(const Duration(milliseconds: 100));
      n.move('d', const SwissPairSlot(0, 1)); // d <-> a
      expect(read(c).valid, isFalse, reason: 'unverified while debouncing');
      async.elapse(const Duration(milliseconds: 250));
      async.flushMicrotasks();

      verify(() => repo.swissValidate('t1', any())).called(1);
      expect(read(c).valid, isTrue);
      expect(read(c).draft?.pairs.first.p1, 'd');
    });
  });

  test('a late validate result from an older draft is ignored', () {
    fakeAsync((async) {
      // Completers must be created inside fakeAsync so their callbacks flush.
      final first = Completer<SwissValidateResult>();
      final second = Completer<SwissValidateResult>();
      final replies = [first, second];
      when(
        () => repo.swissValidate(any(), any()),
      ).thenAnswer((_) => replies.removeAt(0).future);
      final c = makeContainer();
      async.flushMicrotasks();
      final n = notifier(c);

      n.move('b', const SwissPairSlot(1, 1));
      async.elapse(const Duration(milliseconds: 260)); // validate #1 in flight
      n.move('b', const SwissPairSlot(0, 2));
      async.elapse(const Duration(milliseconds: 260)); // validate #2 in flight

      second.complete(_ok);
      async.flushMicrotasks();
      first.complete(
        const SwissValidateResult(
          valid: false,
          errors: [SwissError(code: 'MISSING_PARTICIPANT', participantIds: [])],
          warnings: [],
        ),
      );
      async.flushMicrotasks();

      expect(read(c).valid, isTrue);
      expect(read(c).errors, isEmpty);
    });
  });

  test('dropping on the original slot does not validate or change state', () {
    fakeAsync((async) {
      final c = makeContainer();
      async.flushMicrotasks();
      final before = read(c).draft;

      notifier(c).move('a', const SwissPairSlot(0, 1));
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();

      expect(read(c).draft, same(before));
      expect(read(c).canUndo, isFalse);
      verifyNever(() => repo.swissValidate(any(), any()));
    });
  });

  test('validate warnings and errors reach the state', () {
    when(() => repo.swissValidate(any(), any())).thenAnswer(
      (_) async => const SwissValidateResult(
        valid: true,
        errors: [],
        warnings: [
          SwissWarning(type: 'REMATCH', participantIds: ['a', 'c'], round: 2),
        ],
      ),
    );
    fakeAsync((async) {
      final c = makeContainer();
      async.flushMicrotasks();
      notifier(c).move('b', const SwissPairSlot(1, 1));
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();

      expect(read(c).warnings.single.type, 'REMATCH');
      expect(read(c).canConfirm, isTrue);
    });
  });

  test('moving someone to the pool blocks confirm until placed again', () {
    fakeAsync((async) {
      final c = makeContainer();
      async.flushMicrotasks();
      final n = notifier(c);

      n.move('d', const SwissPoolSlot());
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();
      expect(read(c).draft?.poolIds, ['d']);
      expect(read(c).canConfirm, isFalse);

      n.move('d', const SwissPairSlot(1, 2));
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();
      expect(read(c).canConfirm, isTrue);
    });
  });

  test('undo restores the previous draft', () {
    fakeAsync((async) {
      final c = makeContainer();
      async.flushMicrotasks();
      final n = notifier(c);
      final initial = read(c).draft;

      n.move('b', const SwissPairSlot(1, 1));
      expect(read(c).canUndo, isTrue);
      n.undo();
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();

      expect(read(c).draft?.pairs, initial?.pairs);
      expect(read(c).canUndo, isFalse);
    });
  });

  test('confirm twice sends a single request', () {
    fakeAsync((async) {
      final gate = Completer<SwissNextRoundResult>();
      when(
        () => repo.swissNextRound(
          any(),
          any(),
          confirmWarnings: any(named: 'confirmWarnings'),
        ),
      ).thenAnswer((_) => gate.future);
      final c = makeContainer();
      async.flushMicrotasks();
      final n = notifier(c);

      final first = n.confirm();
      final second = n.confirm();
      expect(read(c).submitting, isTrue);
      gate.complete(const SwissNextRoundResult(roundNumber: 3, matchIds: []));
      async.flushMicrotasks();

      bool? firstResult;
      bool? secondResult;
      first.then((v) => firstResult = v);
      second.then((v) => secondResult = v);
      async.flushMicrotasks();

      expect(firstResult, isTrue);
      expect(secondResult, isFalse);
      expect(read(c).submitting, isFalse);
      verify(
        () => repo.swissNextRound(
          't1',
          any(),
          confirmWarnings: any(named: 'confirmWarnings'),
        ),
      ).called(1);
    });
  });

  test('confirm sends the draft as the request body', () {
    fakeAsync((async) {
      final c = makeContainer();
      async.flushMicrotasks();

      notifier(c).confirm();
      async.flushMicrotasks();

      final request =
          verify(
                () => repo.swissNextRound(
                  't1',
                  captureAny(),
                  confirmWarnings: false,
                ),
              ).captured.single
              as SwissRoundDraftRequest;
      expect(request.divisionId, 'd1');
      expect(request.stageId, 's1');
      expect(request.pairs.length, 2);
      expect(request.byeParticipantId, 'e');
    });
  });

  test('409 SWISS_ROUND_EXISTS reloads the preview and reports the code', () {
    when(
      () => repo.swissNextRound(
        any(),
        any(),
        confirmWarnings: any(named: 'confirmWarnings'),
      ),
    ).thenThrow(
      const SwissApiException(status: 409, code: 'SWISS_ROUND_EXISTS'),
    );

    fakeAsync((async) {
      final c = makeContainer();
      async.flushMicrotasks();
      final n = notifier(c);
      n.move('b', const SwissPairSlot(1, 1));
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();

      bool? result;
      n.confirm().then((v) => result = v);
      async.flushMicrotasks();

      expect(result, isFalse);
      expect(read(c).errorKey, 'SWISS_ROUND_EXISTS');
      expect(read(c).submitting, isFalse);
      expect(read(c).draft?.pairs.first.p2, 'b', reason: 'stale draft dropped');
      expect(read(c).canUndo, isFalse);
      verify(
        () => repo.swissPreview(
          't1',
          divisionId: 'd1',
          stageId: any(named: 'stageId'),
        ),
      ).called(2);
    });
  });

  test('network failure keeps the draft and allows a retry', () {
    var calls = 0;
    when(
      () => repo.swissNextRound(
        any(),
        any(),
        confirmWarnings: any(named: 'confirmWarnings'),
      ),
    ).thenAnswer((_) async {
      if (calls++ == 0) throw const SwissApiException();
      return const SwissNextRoundResult(roundNumber: 3, matchIds: []);
    });

    fakeAsync((async) {
      final c = makeContainer();
      async.flushMicrotasks();
      final n = notifier(c);
      n.move('b', const SwissPairSlot(1, 1));
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();
      final edited = read(c).draft;

      bool? first;
      n.confirm().then((v) => first = v);
      async.flushMicrotasks();
      expect(first, isFalse);
      expect(read(c).errorKey, 'NETWORK');
      expect(read(c).draft, same(edited));
      expect(read(c).submitting, isFalse);
      expect(read(c).canConfirm, isTrue);

      bool? second;
      n.confirm().then((v) => second = v);
      async.flushMicrotasks();
      expect(second, isTrue);
      expect(read(c).errorKey, isNull);
    });
  });

  test('warnings block a plain confirm; confirmWarnings sends true', () {
    when(
      () => repo.swissPreview(
        any(),
        divisionId: any(named: 'divisionId'),
        stageId: any(named: 'stageId'),
      ),
    ).thenAnswer(
      (_) async => _preview(
        warnings: const [
          SwissWarning(type: 'SCORE_GAP', participantIds: ['a', 'b'], gap: 2),
        ],
      ),
    );

    fakeAsync((async) {
      final c = makeContainer();
      async.flushMicrotasks();
      final n = notifier(c);

      bool? plain;
      n.confirm().then((v) => plain = v);
      async.flushMicrotasks();
      expect(plain, isFalse);
      verifyNever(
        () => repo.swissNextRound(
          any(),
          any(),
          confirmWarnings: any(named: 'confirmWarnings'),
        ),
      );

      bool? forced;
      n.confirm(confirmWarnings: true).then((v) => forced = v);
      async.flushMicrotasks();
      expect(forced, isTrue);
      verify(
        () => repo.swissNextRound('t1', any(), confirmWarnings: true),
      ).called(1);
    });
  });

  test('autoPair reloads the preview and resets the draft history', () {
    fakeAsync((async) {
      final c = makeContainer();
      async.flushMicrotasks();
      final n = notifier(c);
      n.move('b', const SwissPairSlot(1, 1));

      n.autoPair();
      async.flushMicrotasks();

      expect(read(c).draft?.pairs.first.p2, 'b');
      expect(read(c).canUndo, isFalse);
      verify(
        () => repo.swissPreview(
          't1',
          divisionId: 'd1',
          stageId: any(named: 'stageId'),
        ),
      ).called(2);
    });
  });

  test('a created round refreshes the bracket and the Swiss stage', () {
    fakeAsync((async) {
      final c = makeContainer();
      async.flushMicrotasks();
      expect([bracketBuilds, stageBuilds], [1, 1]);

      notifier(c).confirm();
      async.flushMicrotasks();

      c.pump(); // let invalidated providers rebuild
      async.elapse(const Duration(milliseconds: 10));
      async.flushMicrotasks();
      expect([bracketBuilds, stageBuilds], [2, 2]);
    });
  });

  test(
    'ROUND_EXISTS then a failing reload drops the draft, keeps the reason',
    () {
      var previews = 0;
      when(
        () => repo.swissPreview(
          any(),
          divisionId: any(named: 'divisionId'),
          stageId: any(named: 'stageId'),
        ),
      ).thenAnswer((_) async {
        if (previews++ == 0) return _preview();
        throw const SwissApiException(
          status: 409,
          code: 'SWISS_ROUND_INCOMPLETE',
        );
      });
      when(
        () => repo.swissNextRound(
          any(),
          any(),
          confirmWarnings: any(named: 'confirmWarnings'),
        ),
      ).thenThrow(
        const SwissApiException(status: 409, code: 'SWISS_ROUND_EXISTS'),
      );

      fakeAsync((async) {
        final c = makeContainer();
        async.flushMicrotasks();

        notifier(c).confirm();
        async.flushMicrotasks();

        expect(read(c).preview, isNull);
        expect(read(c).draft, isNull);
        expect(read(c).errorKey, 'SWISS_ROUND_EXISTS');
        expect(read(c).canConfirm, isFalse);
        expect(read(c).loading, isFalse);
        c.pump();
        async.elapse(const Duration(milliseconds: 10));
        async.flushMicrotasks();
        expect([bracketBuilds, stageBuilds], [2, 2]);
      });
    },
  );

  test('a failed validate can be retried with revalidate()', () {
    var calls = 0;
    when(() => repo.swissValidate(any(), any())).thenAnswer((_) async {
      if (calls++ == 0) throw const SwissApiException();
      return _ok;
    });
    fakeAsync((async) {
      final c = makeContainer();
      async.flushMicrotasks();
      final n = notifier(c);

      n.move('b', const SwissPairSlot(1, 1));
      async.elapse(const Duration(milliseconds: 300));
      async.flushMicrotasks();
      expect(read(c).valid, isFalse);
      expect(read(c).errorKey, swissErrorNetwork);

      n.revalidate();
      async.flushMicrotasks();

      expect(read(c).valid, isTrue);
      expect(read(c).errorKey, isNull);
      expect(read(c).canConfirm, isTrue);
      verify(() => repo.swissValidate('t1', any())).called(2);
    });
  });

  test('SWISS_INVALID_PAIRING details.errors reach the state', () {
    when(
      () => repo.swissNextRound(
        any(),
        any(),
        confirmWarnings: any(named: 'confirmWarnings'),
      ),
    ).thenThrow(
      const SwissApiException(
        status: 400,
        code: 'SWISS_INVALID_PAIRING',
        errors: [
          SwissError(code: 'DUPLICATE_PARTICIPANT', participantIds: ['a']),
        ],
      ),
    );
    fakeAsync((async) {
      final c = makeContainer();
      async.flushMicrotasks();

      notifier(c).confirm();
      async.flushMicrotasks();

      expect(read(c).errorKey, 'SWISS_INVALID_PAIRING');
      expect(read(c).errors.single.code, 'DUPLICATE_PARTICIPANT');
      expect(read(c).valid, isFalse);
    });
  });
}
