import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_history_log.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/elo_history_screen.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/elo_progress_chart.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

EloHistoryLog _log(String id, int prev, int next) => EloHistoryLog(
  id: id,
  userId: 'u1',
  previousElo: prev,
  newElo: next,
  changedPoints: next - prev,
  createdAt: '2026-01-0${id}T10:00:00Z',
  reason: 'reason-$id',
);

Widget _app(
  Future<List<EloHistoryLog>> Function(EloHistoryQuery q) loader, {
  ThemeData? theme,
}) {
  return ProviderScope(
    retry: (_, _) => null,
    overrides: [eloHistoryProvider.overrideWith((ref, q) => loader(q))],
    child: MaterialApp(
      theme: theme ?? AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const EloHistoryScreen(
        userId: 'u1',
        userName: 'Minh Anh',
        currentElo: 1234,
      ),
    ),
  );
}

void main() {
  testWidgets('error shows LavishErrorState and retry refetches', (t) async {
    var calls = 0;
    await t.pumpWidget(
      _app((q) async {
        calls++;
        if (calls == 1) throw Exception('boom');
        return [_log('1', 1000, 1020)];
      }),
    );
    await t.pumpAndSettle();
    expect(find.byType(LavishErrorState), findsOneWidget);
    expect(find.byType(LavishEmptyState), findsNothing);

    await t.tap(find.byType(LavishButton));
    await t.pumpAndSettle();
    expect(find.byType(LavishErrorState), findsNothing);
    expect(find.text('reason-1'), findsOneWidget);
  });

  testWidgets('empty shows LavishEmptyState', (t) async {
    await t.pumpWidget(_app((q) async => []));
    await t.pumpAndSettle();
    expect(find.byType(LavishEmptyState), findsOneWidget);
    expect(find.byType(LavishErrorState), findsNothing);
    expect(find.text('1234'), findsWidgets);
  });

  testWidgets('loading shows skeleton', (t) async {
    await t.pumpWidget(
      _app((q) => Future.delayed(const Duration(seconds: 1), () => [])),
    );
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byType(LavishRowSkeleton), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    await t.pumpWidget(const SizedBox.shrink());
  });

  for (final dark in [false, true]) {
    testWidgets('data shows rows, real elo, signed diffs (dark=$dark)', (
      t,
    ) async {
      final theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
      await t.pumpWidget(
        _app(
          (q) async => [_log('2', 1020, 1000), _log('1', 1000, 1020)],
          theme: theme,
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('1234'), findsWidgets);
      expect(find.text('M'), findsOneWidget);
      expect(find.byType(LavishRow), findsNWidgets(2));
      expect(find.text('+20'), findsOneWidget);
      expect(find.text('-20'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
      expect(find.byType(LavishStatGrid), findsOneWidget);
    });
  }

  testWidgets('load more raises limit when page is full', (t) async {
    final limits = <int>[];
    await t.pumpWidget(
      _app((q) async {
        limits.add(q.limit);
        return List.generate(
          q.limit,
          (i) => _log('${(i % 9) + 1}', 1000, 1010),
        );
      }),
    );
    await t.pumpAndSettle();
    final more = find.byKey(const Key('elo_history_load_more'));
    await t.drag(find.byType(ListView), const Offset(0, -6000));
    await t.pumpAndSettle();
    await t.tap(more);
    await t.pumpAndSettle();
    expect(limits.last, greaterThan(limits.first));
  });

  Future<void> scrollToLoadMore(WidgetTester t) async {
    await t.drag(find.byType(ListView), const Offset(0, -6000));
    await t.pumpAndSettle();
  }

  testWidgets('load more keeps the list visible while the next page loads', (
    t,
  ) async {
    final gate = Completer<List<EloHistoryLog>>();
    await t.pumpWidget(
      _app((q) {
        if (q.limit > 50) return gate.future;
        return Future.value(
          List.generate(q.limit, (i) => _log('${(i % 9) + 1}', 1000, 1010)),
        );
      }),
    );
    await t.pumpAndSettle();
    await scrollToLoadMore(t);
    await t.tap(find.byKey(const Key('elo_history_load_more')));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byType(LavishRowSkeleton), findsNothing);
    expect(find.byType(EloProgressChart), findsOneWidget);
    expect(find.byType(LavishRow), findsWidgets);
    gate.complete(
      List.generate(100, (i) => _log('${(i % 9) + 1}', 1000, 1010)),
    );
    await t.pumpAndSettle();
    expect(find.byType(LavishErrorState), findsNothing);
  });

  testWidgets('load more failure keeps the list and offers retry at the end', (
    t,
  ) async {
    await t.pumpWidget(
      _app((q) async {
        if (q.limit > 50) throw Exception('boom');
        return List.generate(
          q.limit,
          (i) => _log('${(i % 9) + 1}', 1000, 1010),
        );
      }),
    );
    await t.pumpAndSettle();
    await scrollToLoadMore(t);
    await t.tap(find.byKey(const Key('elo_history_load_more')));
    await t.pumpAndSettle();
    expect(find.byType(LavishErrorState), findsNothing);
    expect(find.byType(LavishRow), findsWidgets);
    await scrollToLoadMore(t);
    expect(
      find.byKey(const Key('elo_history_load_more_retry')),
      findsOneWidget,
    );
  });

  testWidgets('unparseable createdAt shows a dash, not today', (t) async {
    final bad = EloHistoryLog(
      id: 'x',
      userId: 'u1',
      previousElo: 1000,
      newElo: 1010,
      changedPoints: 10,
      createdAt: 'not-a-date',
      reason: 'bad-date',
    );
    await t.pumpWidget(_app((q) async => [bad]));
    await t.pumpAndSettle();
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    expect(find.textContaining(today), findsNothing);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('row time is converted to local time', (t) async {
    await t.pumpWidget(_app((q) async => [_log('1', 1000, 1020)]));
    await t.pumpAndSettle();
    final local = DateTime.parse('2026-01-01T10:00:00Z').toLocal();
    final expected = DateFormat.yMd('en').add_Hm().format(local);
    expect(find.textContaining(expected), findsOneWidget);
  });
}
