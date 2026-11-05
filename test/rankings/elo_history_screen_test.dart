import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_history_log.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/elo_history_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
