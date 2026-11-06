import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/repositories/series_legs_repository.dart';
import 'package:app_quanly_giaidau/features/series/screens/series_legs_manage_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/series_legs_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory backend: writes mutate the lists so the screen's reload shows them.
class _FakeLegs implements SeriesLegsRepository {
  _FakeLegs({required this.legs, this.events = const {}});

  List<SeriesLegRecord> legs;
  Map<String, List<SeriesLegEvent>> events;

  final created = <SeriesLegInput>[];
  final updated = <({String legId, SeriesLegInput input})>[];
  final deleted = <String>[];
  final linked = <({String legId, SeriesLinkInput input})>[];
  final unlinked = <({String legId, String eventId})>[];

  /// Thrown by the next write when set.
  Object? writeError;

  /// Thrown by reads while set (to drive the error + retry state).
  Object? readError;

  /// When set, a write waits for it (to observe the busy state).
  Completer<void>? gate;

  Future<void> _write() async {
    await gate?.future;
    if (writeError != null) throw writeError!;
  }

  @override
  Future<List<SeriesLegRecord>> getLegs(String seriesId) async {
    if (readError != null) throw readError!;
    return List.of(legs);
  }

  @override
  Future<List<SeriesLegEvent>> getLegEvents(
    String seriesId,
    String legId,
  ) async => List.of(events[legId] ?? const []);

  @override
  Future<void> createLeg(String seriesId, SeriesLegInput input) async {
    await _write();
    created.add(input);
    legs = [
      ...legs,
      SeriesLegRecord(
        id: 'l-new',
        name: input.name,
        order: input.order,
        directEntrySlots: input.directEntrySlots,
        wildcardSlots: input.wildcardSlots,
      ),
    ];
  }

  @override
  Future<void> updateLeg(
    String seriesId,
    String legId,
    SeriesLegInput input,
  ) async {
    await _write();
    updated.add((legId: legId, input: input));
  }

  @override
  Future<void> deleteLeg(String seriesId, String legId) async {
    await _write();
    deleted.add(legId);
    legs = legs.where((l) => l.id != legId).toList();
  }

  @override
  Future<void> linkTournament(
    String seriesId,
    String legId,
    SeriesLinkInput input,
  ) async {
    await _write();
    linked.add((legId: legId, input: input));
  }

  @override
  Future<void> unlinkTournament(
    String seriesId,
    String legId,
    String eventId,
  ) async {
    await _write();
    unlinked.add((legId: legId, eventId: eventId));
    events = {
      ...events,
      legId: (events[legId] ?? const []).where((e) => e.id != eventId).toList(),
    };
  }
}

class _FakeWorkspace extends MyTournamentWorkspaceNotifier {
  _FakeWorkspace(this.organized);

  final List<Tournament> organized;

  @override
  Future<TournamentWorkspace> build() async =>
      TournamentWorkspace(organizedTournaments: organized);
}

Tournament _tournament(String id, String name) => Tournament.fromJson({
  'name': name,
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'REGISTRATION',
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, id);

const _leg1 = SeriesLegRecord(id: 'l-1', name: 'Chặng Một', order: 1);
const _leg2 = SeriesLegRecord(id: 'l-2', name: 'Chặng Hai', order: 2);
const _event1 = SeriesLegEvent(
  id: 'e-1',
  tournamentId: 't-1',
  tournamentName: 'Giải Đã Gắn',
  order: 1,
);

_FakeLegs _twoLegs() => _FakeLegs(
  legs: const [_leg1, _leg2],
  events: const {
    'l-1': [_event1],
  },
);

AppLocalizations get _en => lookupAppLocalizations(const Locale('en'));

Future<void> _pump(
  WidgetTester tester,
  _FakeLegs repo, {
  List<Tournament>? organized,
}) async {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seriesLegsRepositoryProvider.overrideWithValue(repo),
        myTournamentWorkspaceProvider.overrideWith(
          () => _FakeWorkspace(
            organized ??
                [
                  _tournament('t-1', 'Giải Đã Gắn'),
                  _tournament('t-2', 'Giải Còn Trống'),
                ],
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SeriesLegsManageScreen(seriesId: 's-1'),
      ),
    ),
  );
  await _settle(tester);
}

/// No pumpAndSettle: the app has looping animations.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await _settle(tester);
}

DioException _status(int code) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.badResponse,
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: code,
  ),
);

void main() {
  group('list states', () {
    testWidgets('TC-SERIESLEGS-10: shows legs with their linked tournaments', (
      tester,
    ) async {
      await _pump(tester, _twoLegs());

      expect(find.text('Leg 1. Chặng Một'), findsOneWidget);
      expect(find.text('Leg 2. Chặng Hai'), findsOneWidget);
      expect(find.text('Giải Đã Gắn'), findsOneWidget);
      expect(find.text(_en.seriesLegsNoEvents), findsOneWidget);
    });

    testWidgets('TC-SERIESLEGS-11: empty series shows the empty state', (
      tester,
    ) async {
      await _pump(tester, _FakeLegs(legs: const []));

      expect(find.text(_en.seriesLegsEmpty), findsOneWidget);
      expect(find.byKey(const ValueKey('series-legs-add')), findsOneWidget);
    });

    testWidgets('TC-SERIESLEGS-12: a load error offers Retry that reloads', (
      tester,
    ) async {
      final repo = _twoLegs()..readError = StateError('boom');
      await _pump(tester, repo);

      expect(find.text(_en.seriesLegsLoadError), findsOneWidget);

      repo.readError = null;
      await _tap(tester, find.text(_en.infoRetry));

      expect(find.text('Leg 1. Chặng Một'), findsOneWidget);
    });
  });

  group('add and edit leg', () {
    testWidgets('TC-SERIESLEGS-13: a valid new leg is sent and listed', (
      tester,
    ) async {
      final repo = _twoLegs();
      await _pump(tester, repo);

      await _tap(tester, find.byKey(const ValueKey('series-legs-add')));
      await tester.enterText(
        find.byKey(const ValueKey('leg-form-name')),
        '  Chặng Ba ',
      );
      await _tap(tester, find.byKey(const ValueKey('leg-form-submit')));

      expect(repo.created, hasLength(1));
      expect(repo.created.single.name, 'Chặng Ba');
      expect(repo.created.single.order, 3);
      expect(repo.created.single.directEntrySlots, 2);
      expect(repo.created.single.wildcardSlots, 16);
      expect(find.text('Leg 3. Chặng Ba'), findsOneWidget);
      expect(find.text(_en.seriesLegsCreated), findsOneWidget);
    });

    testWidgets('TC-SERIESLEGS-14: an invalid leg is blocked with a message', (
      tester,
    ) async {
      final repo = _twoLegs();
      await _pump(tester, repo);

      await _tap(tester, find.byKey(const ValueKey('series-legs-add')));
      await _tap(tester, find.byKey(const ValueKey('leg-form-submit')));
      expect(find.text(_en.seriesLegsNameRequired), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('leg-form-name')),
        'Chặng Ba',
      );
      await tester.enterText(find.byKey(const ValueKey('leg-form-order')), '0');
      await _tap(tester, find.byKey(const ValueKey('leg-form-submit')));
      expect(find.text(_en.seriesLegsOrderInvalid), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('leg-form-order')), '3');
      await tester.enterText(
        find.byKey(const ValueKey('leg-form-direct')),
        '-1',
      );
      await _tap(tester, find.byKey(const ValueKey('leg-form-submit')));
      expect(find.text(_en.seriesLegsSlotsInvalid), findsOneWidget);

      expect(repo.created, isEmpty);
    });

    testWidgets(
      'TC-SERIESLEGS-15: edit prefills the form and patches the leg',
      (tester) async {
        final repo = _twoLegs();
        await _pump(tester, repo);

        await _tap(tester, find.byKey(const ValueKey('series-leg-edit-l-2')));
        expect(find.widgetWithText(TextField, 'Chặng Hai'), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('leg-form-name')),
          'Chặng Hai (mới)',
        );
        await _tap(tester, find.byKey(const ValueKey('leg-form-submit')));

        expect(repo.updated, hasLength(1));
        expect(repo.updated.single.legId, 'l-2');
        expect(repo.updated.single.input.name, 'Chặng Hai (mới)');
        expect(repo.updated.single.input.order, 2);
      },
    );

    testWidgets(
      'TC-SERIESLEGS-16: a network error keeps the form and says why',
      (tester) async {
        final repo = _twoLegs()
          ..writeError = DioException(
            requestOptions: RequestOptions(path: '/x'),
            type: DioExceptionType.connectionError,
          );
        await _pump(tester, repo);

        await _tap(tester, find.byKey(const ValueKey('series-legs-add')));
        await tester.enterText(
          find.byKey(const ValueKey('leg-form-name')),
          'Chặng Ba',
        );
        await _tap(tester, find.byKey(const ValueKey('leg-form-submit')));

        expect(find.text(_en.errorParserConnectionFailed), findsOneWidget);
        expect(find.byKey(const ValueKey('leg-form-name')), findsOneWidget);
        expect(repo.created, isEmpty);
      },
    );

    testWidgets('TC-SERIESLEGS-17: a double tap on save sends one request', (
      tester,
    ) async {
      final repo = _twoLegs()..gate = Completer<void>();
      await _pump(tester, repo);

      await _tap(tester, find.byKey(const ValueKey('series-legs-add')));
      await tester.enterText(
        find.byKey(const ValueKey('leg-form-name')),
        'Chặng Ba',
      );
      final submit = find.byKey(const ValueKey('leg-form-submit'));
      await tester.tap(submit);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(submit, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));

      repo.gate!.complete();
      await _settle(tester);

      expect(repo.created, hasLength(1));
    });
  });

  group('delete leg', () {
    testWidgets('TC-SERIESLEGS-18: delete needs a confirmation', (
      tester,
    ) async {
      final repo = _twoLegs();
      await _pump(tester, repo);

      await _tap(tester, find.byKey(const ValueKey('series-leg-delete-l-2')));
      expect(find.text(_en.seriesLegsDeleteTitle), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('series-legs-confirm-no')));
      expect(repo.deleted, isEmpty);
      expect(find.text('Leg 2. Chặng Hai'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('series-leg-delete-l-2')));
      await _tap(tester, find.byKey(const ValueKey('series-legs-confirm-yes')));

      expect(repo.deleted, ['l-2']);
      expect(find.text('Leg 2. Chặng Hai'), findsNothing);
    });

    testWidgets('TC-SERIESLEGS-19: a 409 on delete shows the conflict text', (
      tester,
    ) async {
      final repo = _twoLegs()..writeError = _status(409);
      await _pump(tester, repo);

      await _tap(tester, find.byKey(const ValueKey('series-leg-delete-l-2')));
      await _tap(tester, find.byKey(const ValueKey('series-legs-confirm-yes')));

      expect(find.text(_en.seriesLegsConflict), findsOneWidget);
      expect(find.text('Leg 2. Chặng Hai'), findsOneWidget);
    });
  });

  group('link and unlink tournament', () {
    testWidgets(
      'TC-SERIESLEGS-20: link lists only free tournaments and sends the pick',
      (tester) async {
        final repo = _twoLegs();
        await _pump(tester, repo);

        await _tap(tester, find.byKey(const ValueKey('series-leg-link-l-2')));

        // t-1 is already linked to a leg of this series, so it is not offered.
        expect(find.byKey(const ValueKey('link-tournament-t-1')), findsNothing);
        await _tap(tester, find.byKey(const ValueKey('link-tournament-t-2')));
        await _tap(tester, find.byKey(const ValueKey('link-form-submit')));

        expect(repo.linked, hasLength(1));
        expect(repo.linked.single.legId, 'l-2');
        expect(repo.linked.single.input.tournamentId, 't-2');
        expect(repo.linked.single.input.order, 1);
        expect(find.text(_en.seriesLegsLinked), findsOneWidget);
      },
    );

    testWidgets('TC-SERIESLEGS-21: link without a pick is blocked', (
      tester,
    ) async {
      final repo = _twoLegs();
      await _pump(tester, repo);

      await _tap(tester, find.byKey(const ValueKey('series-leg-link-l-2')));
      await _tap(tester, find.byKey(const ValueKey('link-form-submit')));

      expect(find.text(_en.seriesLegsTournamentRequired), findsOneWidget);
      expect(repo.linked, isEmpty);
    });

    testWidgets(
      'TC-SERIESLEGS-22: a backend refusal on link stays in the sheet',
      (tester) async {
        final repo = _twoLegs()
          ..writeError = DioException(
            requestOptions: RequestOptions(path: '/x'),
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: RequestOptions(path: '/x'),
              statusCode: 400,
              data: {
                'message': 'Giải đấu đã được liên kết với một chuỗi giải khác.',
              },
            ),
          );
        await _pump(tester, repo);

        await _tap(tester, find.byKey(const ValueKey('series-leg-link-l-2')));
        await _tap(tester, find.byKey(const ValueKey('link-tournament-t-2')));
        await _tap(tester, find.byKey(const ValueKey('link-form-submit')));

        expect(
          find.text('Giải đấu đã được liên kết với một chuỗi giải khác.'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('link-form-submit')), findsOneWidget);
      },
    );

    testWidgets('TC-SERIESLEGS-23: unlink needs a confirmation', (
      tester,
    ) async {
      final repo = _twoLegs();
      await _pump(tester, repo);

      await _tap(tester, find.byKey(const ValueKey('series-event-unlink-e-1')));
      await _tap(tester, find.byKey(const ValueKey('series-legs-confirm-no')));
      expect(repo.unlinked, isEmpty);

      await _tap(tester, find.byKey(const ValueKey('series-event-unlink-e-1')));
      await _tap(tester, find.byKey(const ValueKey('series-legs-confirm-yes')));

      expect(repo.unlinked, [(legId: 'l-1', eventId: 'e-1')]);
      expect(find.text('Giải Đã Gắn'), findsNothing);
    });
  });
}
