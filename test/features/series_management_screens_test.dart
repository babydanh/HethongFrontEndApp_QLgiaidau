import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/list_skeletons.dart';
import 'package:app_quanly_giaidau/domain/entities/managed_series.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/series_management_repository.dart';
import 'package:app_quanly_giaidau/features/series/screens/my_series_screen.dart';
import 'package:app_quanly_giaidau/features/series/screens/series_form_screen.dart';
import 'package:app_quanly_giaidau/features/series/screens/series_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/series_management_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'loading_skeleton/loading_harness.dart' show pendingDioOverride;

const _rules = SeriesRules(
  pointsByRank: {1: 100, 2: 80},
  directEntryThreshold: 2,
  wildcardCount: 8,
  exclusionRule: true,
  exclusionScope: 'CATEGORY',
  description: 'Rules',
);

ManagedSeries _series(
  String id,
  String name, {
  String status = 'DRAFT',
  DateTime? start,
  DateTime? end,
}) => ManagedSeries(
  id: id,
  slug: '$id-slug',
  name: name,
  status: status,
  visibility: 'PUBLIC',
  rules: _rules,
  startDate: start,
  endDate: end,
);

DioException _dioError(int? status, String? message, {DioExceptionType? type}) {
  final options = RequestOptions(path: '/organizer/series');
  return DioException(
    requestOptions: options,
    type: type ?? DioExceptionType.badResponse,
    response: status == null
        ? null
        : Response<dynamic>(
            requestOptions: options,
            statusCode: status,
            data: {'message': message},
          ),
  );
}

class _FakeRepo implements SeriesManagementRepository {
  List<ManagedSeries> items = [];
  Object? listError;
  Object? getError;
  Object? createError;
  Object? updateError;
  Object? deleteError;
  Completer<void>? createGate;
  Completer<void>? deleteGate;

  int listCalls = 0;
  final List<SeriesInput> created = [];
  final List<(String, SeriesInput)> updated = [];
  final List<String> deleted = [];

  @override
  Future<List<ManagedSeries>> listMine(String organizerId) async {
    listCalls++;
    if (listError != null) throw listError!;
    return List.of(items);
  }

  @override
  Future<ManagedSeries> getById(String id) async {
    if (getError != null) throw getError!;
    return items.firstWhere((s) => s.id == id);
  }

  @override
  Future<ManagedSeries> create(SeriesInput input) async {
    created.add(input);
    await createGate?.future;
    if (createError != null) throw createError!;
    return _series('new', input.name);
  }

  @override
  Future<ManagedSeries> update(String id, SeriesInput input) async {
    updated.add((id, input));
    if (updateError != null) throw updateError!;
    return _series(id, input.name);
  }

  @override
  Future<void> delete(String id) async {
    deleted.add(id);
    await deleteGate?.future;
    if (deleteError != null) throw deleteError!;
    items = items.where((s) => s.id != id).toList();
  }
}

UserProfile _profile({List<String> roles = const ['ORGANIZER']}) =>
    UserProfile(id: 'org-1', fullName: 'Org', roles: roles);

Future<GoRouter> _pump(
  WidgetTester tester,
  _FakeRepo repo, {
  String location = '/organizer/series',
  UserProfile? profile,
  Future<UserProfile>? profileFuture,
  List<Override> extra = const [],
}) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/series', builder: (_, _) => const SeriesScreen()),
      GoRoute(
        path: '/organizer/series',
        builder: (_, _) => const MySeriesScreen(),
      ),
      GoRoute(
        path: '/organizer/series/create',
        builder: (_, _) => const SeriesFormScreen(),
      ),
      GoRoute(
        path: '/organizer/series/:id/edit',
        builder: (_, s) => SeriesFormScreen(seriesId: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/organizer/series/:id/manage',
        builder: (_, s) =>
            Scaffold(body: Text('MANAGE:${s.pathParameters['id']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seriesManagementRepositoryProvider.overrideWithValue(repo),
        userProfileProvider.overrideWith(
          (ref) => profileFuture ?? Future.value(profile ?? _profile()),
        ),
        ...extra,
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    ),
  );
  await _settle(tester);
  return router;
}

/// No `pumpAndSettle`: skeletons animate forever.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  group('my series list', () {
    testWidgets(
      'TC-SERIESMGMT-10 shows a skeleton while loading, then the rows',
      (tester) async {
        final repo = _FakeRepo()
          ..items = [
            _series(
              's-1',
              'Cup A',
              status: 'ACTIVE',
              start: DateTime(2026, 5, 1),
            ),
            _series('s-2', 'Cup B'),
          ];
        tester.view.physicalSize = const Size(390, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              seriesManagementRepositoryProvider.overrideWithValue(repo),
              userProfileProvider.overrideWith((ref) async => _profile()),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              home: const MySeriesScreen(),
            ),
          ),
        );
        expect(find.byType(TournamentListItemSkeleton), findsWidgets);

        await _settle(tester);

        expect(find.text('My series'), findsOneWidget);
        expect(find.text('Cup A'), findsOneWidget);
        expect(find.text('Cup B'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Draft'), findsOneWidget);
        expect(find.text('01/05/2026'), findsOneWidget);
      },
    );

    testWidgets('TC-SERIESMGMT-11 empty state offers creating a series', (
      tester,
    ) async {
      await _pump(tester, _FakeRepo());

      expect(find.text('You have no series yet'), findsOneWidget);
      await _tap(tester, _key('series-empty-create'));

      expect(_key('series-form-name'), findsOneWidget);
    });

    testWidgets('TC-SERIESMGMT-12 error shows a message and Retry reloads', (
      tester,
    ) async {
      final repo = _FakeRepo()
        ..listError = _dioError(
          null,
          null,
          type: DioExceptionType.connectionError,
        )
        ..items = [_series('s-1', 'Cup A')];
      await _pump(tester, repo);

      expect(find.text('Could not load your series.'), findsOneWidget);

      repo.listError = null;
      await _tap(tester, find.text('Retry'));

      expect(find.text('Cup A'), findsOneWidget);
      expect(repo.listCalls, 2);
    });

    testWidgets(
      'TC-SERIESMGMT-13 tapping a row opens the legs management route',
      (tester) async {
        final repo = _FakeRepo()..items = [_series('s-1', 'Cup A')];
        await _pump(tester, repo);

        await _tap(tester, _key('series-row-s-1'));

        expect(find.text('MANAGE:s-1'), findsOneWidget);
      },
    );

    testWidgets('TC-SERIESMGMT-14 edit action opens the form with the series', (
      tester,
    ) async {
      final repo = _FakeRepo()..items = [_series('s-1', 'Cup A')];
      await _pump(tester, repo);

      await _tap(tester, _key('series-edit-s-1'));

      expect(find.text('Edit series'), findsOneWidget);
      final name = tester.widget<AppTextFormField>(_key('series-form-name'));
      expect(name.controller!.text, 'Cup A');
    });

    testWidgets(
      'TC-SERIESMGMT-15 delete asks for confirmation; cancel keeps it',
      (tester) async {
        final repo = _FakeRepo()..items = [_series('s-1', 'Cup A')];
        await _pump(tester, repo);

        await _tap(tester, _key('series-delete-s-1'));
        expect(find.text('Delete this series?'), findsOneWidget);
        expect(repo.deleted, isEmpty);

        await _tap(tester, find.text('Cancel'));

        expect(repo.deleted, isEmpty);
        expect(find.text('Cup A'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-SERIESMGMT-16 confirmed delete calls the API once and refreshes',
      (tester) async {
        final repo = _FakeRepo()
          ..items = [_series('s-1', 'Cup A'), _series('s-2', 'Cup B')];
        await _pump(tester, repo);

        await _tap(tester, _key('series-delete-s-1'));
        await _tap(tester, _key('series-delete-confirm'));

        expect(repo.deleted, ['s-1']);
        expect(find.text('Cup A'), findsNothing);
        expect(find.text('Cup B'), findsOneWidget);
        expect(find.text('Series deleted.'), findsOneWidget);
      },
    );

    testWidgets('TC-SERIESMGMT-17 a 409 on delete shows the Backend message', (
      tester,
    ) async {
      final repo = _FakeRepo()
        ..items = [_series('s-1', 'Cup A')]
        ..deleteError = _dioError(409, 'Series has linked tournaments');
      await _pump(tester, repo);

      await _tap(tester, _key('series-delete-s-1'));
      await _tap(tester, _key('series-delete-confirm'));

      expect(find.text('Series has linked tournaments'), findsOneWidget);
      expect(find.text('Cup A'), findsOneWidget);
    });

    testWidgets(
      'TC-SERIESMGMT-18 no second delete dialog while one is running',
      (tester) async {
        final repo = _FakeRepo()
          ..items = [_series('s-1', 'Cup A')]
          ..deleteGate = Completer<void>();
        await _pump(tester, repo);

        await _tap(tester, _key('series-delete-s-1'));
        await _tap(tester, _key('series-delete-confirm'));
        await tester.tap(_key('series-delete-s-1'), warnIfMissed: false);
        await _settle(tester);

        expect(find.text('Delete this series?'), findsNothing);
        expect(repo.deleted, ['s-1']);
        repo.deleteGate!.complete();
        await _settle(tester);
      },
    );
  });

  group('series form', () {
    Future<GoRouter> openCreate(WidgetTester tester, _FakeRepo repo) async {
      final router = await _pump(tester, repo);
      unawaited(router.push('/organizer/series/create'));
      await _settle(tester);
      return router;
    }

    testWidgets(
      'TC-SERIESMGMT-20 empty name is rejected without calling the API',
      (tester) async {
        final repo = _FakeRepo();
        await openCreate(tester, repo);

        await _tap(tester, _key('series-form-submit'));

        expect(find.text('Please enter the series name'), findsOneWidget);
        expect(repo.created, isEmpty);
      },
    );

    testWidgets(
      'TC-SERIESMGMT-21 valid form creates once and returns to the list',
      (tester) async {
        final repo = _FakeRepo();
        await openCreate(tester, repo);

        await tester.enterText(_key('series-form-name'), '  Cup 2026  ');
        await tester.enterText(_key('series-form-prize'), '5000');
        await _tap(tester, _key('series-form-submit'));

        expect(repo.created, hasLength(1));
        final input = repo.created.single;
        expect(input.name, 'Cup 2026');
        expect(input.totalPrize, 5000);
        expect(input.visibility, 'PUBLIC');
        expect(input.status, isNull);
        expect(input.rules.pointsByRank, {
          1: 100,
          2: 80,
          3: 60,
          5: 40,
          9: 20,
          17: 10,
        });
        expect(input.rules.directEntryThreshold, 2);
        expect(find.text('Series created.'), findsOneWidget);
        expect(find.text('My series'), findsOneWidget);
        expect(repo.listCalls, 2);
      },
    );

    testWidgets('TC-SERIESMGMT-22 double tap while sending creates only once', (
      tester,
    ) async {
      final repo = _FakeRepo()..createGate = Completer<void>();
      await openCreate(tester, repo);
      await tester.enterText(_key('series-form-name'), 'Cup 2026');

      await tester.tap(_key('series-form-submit'));
      await tester.pump();
      await tester.tap(_key('series-form-submit'), warnIfMissed: false);
      await _settle(tester);

      expect(repo.created, hasLength(1));
      repo.createGate!.complete();
      await _settle(tester);
      expect(repo.created, hasLength(1));
    });

    testWidgets(
      'TC-SERIESMGMT-23 a 409 shows the Backend message and keeps the form',
      (tester) async {
        final repo = _FakeRepo()
          ..createError = _dioError(409, 'Slug already exists');
        await openCreate(tester, repo);
        await tester.enterText(_key('series-form-name'), 'Cup 2026');

        await _tap(tester, _key('series-form-submit'));

        expect(find.text('Slug already exists'), findsOneWidget);
        expect(_key('series-form-name'), findsOneWidget);

        // The button is usable again after a failure (once the snack bar is gone).
        await tester.pump(const Duration(seconds: 6));
        await _settle(tester);
        repo.createError = null;
        await _tap(tester, _key('series-form-submit'));
        expect(repo.created, hasLength(2));
      },
    );

    testWidgets('TC-SERIESMGMT-24 a network error shows the network message', (
      tester,
    ) async {
      final repo = _FakeRepo()
        ..createError = _dioError(
          null,
          null,
          type: DioExceptionType.connectionError,
        );
      await openCreate(tester, repo);
      await tester.enterText(_key('series-form-name'), 'Cup 2026');

      await _tap(tester, _key('series-form-submit'));

      expect(
        find.text(
          'Could not reach the server. Check your connection and try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('TC-SERIESMGMT-25 duplicate rank is rejected', (tester) async {
      final repo = _FakeRepo();
      await openCreate(tester, repo);
      await tester.enterText(_key('series-form-name'), 'Cup 2026');
      // Row 1 defaults to rank 2; make it a second rank 1.
      await tester.enterText(_key('series-rank-1'), '1');

      await _tap(tester, _key('series-form-submit'));

      expect(find.text('Duplicate rank'), findsWidgets);
      expect(repo.created, isEmpty);
    });

    testWidgets('TC-SERIESMGMT-26 rank rows can be added and removed', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await openCreate(tester, repo);
      await tester.enterText(_key('series-form-name'), 'Cup 2026');

      await _tap(tester, _key('series-add-rank'));
      await tester.enterText(_key('series-rank-6'), '33');
      await tester.enterText(_key('series-points-6'), '1');
      await _tap(tester, _key('series-remove-rank-0'));
      await _tap(tester, _key('series-form-submit'));

      expect(repo.created.single.rules.pointsByRank, {
        2: 80,
        3: 60,
        5: 40,
        9: 20,
        17: 10,
        33: 1,
      });
    });

    testWidgets(
      'TC-SERIESMGMT-27 edit mode prefills and updates by id with status',
      (tester) async {
        final repo = _FakeRepo()
          ..items = [_series('s-1', 'Cup A', status: 'ACTIVE')];
        final router = await _pump(tester, repo);
        unawaited(router.push('/organizer/series/s-1/edit'));
        await _settle(tester);

        await tester.enterText(_key('series-form-name'), 'Cup A2');
        await _tap(tester, _key('series-form-submit'));

        expect(repo.updated, hasLength(1));
        expect(repo.updated.single.$1, 's-1');
        expect(repo.updated.single.$2.name, 'Cup A2');
        expect(repo.updated.single.$2.status, 'ACTIVE');
        expect(repo.updated.single.$2.rules.pointsByRank, {1: 100, 2: 80});
        expect(find.text('Changes saved.'), findsOneWidget);
      },
    );

    testWidgets('TC-SERIESMGMT-28 end date before start date is rejected', (
      tester,
    ) async {
      final repo = _FakeRepo()
        ..items = [
          _series(
            's-1',
            'Cup A',
            start: DateTime(2026, 5, 10),
            end: DateTime(2026, 5, 1),
          ),
        ];
      final router = await _pump(tester, repo);
      unawaited(router.push('/organizer/series/s-1/edit'));
      await _settle(tester);

      await _tap(tester, _key('series-form-submit'));

      expect(
        find.text('End date must not be before the start date'),
        findsOneWidget,
      );
      expect(repo.updated, isEmpty);
    });

    testWidgets('TC-SERIESMGMT-29 edit load failure offers Retry', (
      tester,
    ) async {
      final repo = _FakeRepo()
        ..items = [_series('s-1', 'Cup A')]
        ..getError = _dioError(404, 'Không tìm thấy chuỗi giải đấu.');
      final router = await _pump(tester, repo);
      unawaited(router.push('/organizer/series/s-1/edit'));
      await _settle(tester);

      expect(find.text('Không tìm thấy chuỗi giải đấu.'), findsOneWidget);

      repo.getError = null;
      await _tap(tester, find.text('Retry'));
      expect(_key('series-form-name'), findsOneWidget);
    });
  });

  group('entry point on the public series screen', () {
    testWidgets(
      'TC-SERIESMGMT-30 organizer sees the entry and it opens my series',
      (tester) async {
        final repo = _FakeRepo();
        await _pump(
          tester,
          repo,
          location: '/series',
          extra: [pendingDioOverride],
        );

        await _tap(tester, find.byTooltip('Manage my series'));

        expect(find.text('My series'), findsOneWidget);
      },
    );

    testWidgets('TC-SERIESMGMT-31 admin sees the entry', (tester) async {
      await _pump(
        tester,
        _FakeRepo(),
        location: '/series',
        profile: _profile(roles: const ['ADMIN']),
        extra: [pendingDioOverride],
      );

      expect(find.byTooltip('Manage my series'), findsOneWidget);
    });

    testWidgets('TC-SERIESMGMT-32 a player does not see the entry', (
      tester,
    ) async {
      await _pump(
        tester,
        _FakeRepo(),
        location: '/series',
        profile: _profile(roles: const ['PLAYER']),
        extra: [pendingDioOverride],
      );

      expect(find.byTooltip('Manage my series'), findsNothing);
    });

    testWidgets(
      'TC-SERIESMGMT-33 no entry while the profile is still loading',
      (tester) async {
        await _pump(
          tester,
          _FakeRepo(),
          location: '/series',
          profileFuture: Completer<UserProfile>().future,
          extra: [pendingDioOverride],
        );

        expect(find.byTooltip('Manage my series'), findsNothing);
      },
    );
  });
}
