import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/features/home/widgets/global_search_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmptyMatchRepository extends Fake implements IMatchRepository {
  @override
  Future<
    ({List<MatchModel> matches, String? nextCursor, bool hasMore, int total})
  >
  getPublicMatchesPaged({
    String? cursor,
    int limit = 10,
    String? search,
    String? categoryId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? trigger,
  }) async => (
    matches: const <MatchModel>[],
    nextCursor: null,
    hasMore: false,
    total: 0,
  );
}

Future<void> _pumpSearchHost(
  WidgetTester tester, {
  required bool disableAnimations,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => const <CategoryModel>[]),
        matchRepositoryProvider.overrideWithValue(_EmptyMatchRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('open-search'),
                onPressed: () => unawaited(
                  GlobalSearchScreen.show(
                    context: context,
                    initialTabIndex: 0,
                    initialQuery: '',
                  ),
                ),
                child: const Text('Open search'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('header search fades in and returns to Home', (
    tester,
  ) async {
    await _pumpSearchHost(tester, disableAnimations: false);

    await tester.tap(find.byKey(const Key('open-search')));
    await tester.pump();
    final searchScaffold = find.byType(Scaffold).last;
    final fade = find.ancestor(
      of: find.byType(GlobalSearchScreen),
      matching: find.byType(FadeTransition),
    );
    expect(fade, findsOneWidget);
    expect(
      tester.widget<FadeTransition>(fade).opacity.value,
      closeTo(0, 0.01),
    );
    expect(tester.getTopLeft(searchScaffold).dy, 0);

    await tester.pump(const Duration(milliseconds: 100));
    final midOpacity = tester.widget<FadeTransition>(fade).opacity.value;
    expect(midOpacity, greaterThan(0));
    expect(midOpacity, lessThan(1));
    expect(tester.getTopLeft(searchScaffold).dy, 0);

    await tester.pump(const Duration(milliseconds: 260));
    expect(
      tester.widget<FadeTransition>(fade).opacity.value,
      closeTo(1, 0.01),
    );
    expect(tester.getTopLeft(searchScaffold).dy, 0);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(find.byKey(const Key('open-search')), findsOneWidget);
  });

  testWidgets('reduced motion opens search without a slide', (tester) async {
    await _pumpSearchHost(tester, disableAnimations: true);

    await tester.tap(find.byKey(const Key('open-search')));
    await tester.pump();

    expect(find.byType(GlobalSearchScreen), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(GlobalSearchScreen),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    expect(tester.getTopLeft(find.byType(Scaffold).last).dy, 0);
  });
}
