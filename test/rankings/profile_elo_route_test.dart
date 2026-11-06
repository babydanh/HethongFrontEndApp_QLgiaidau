import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_history_log.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/elo_history_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _profile = UserProfile(id: 'u1', fullName: 'An', email: 'a@x.com');

PlayerRanking _rank(int elo) => PlayerRanking(
  id: 'r$elo',
  userId: 'u1',
  fullName: 'An',
  eloPoints: elo,
  rank: 1,
  matchesPlayed: 1,
  matchesWon: 1,
  categoryId: 'c$elo',
);

Future<void> _pump(
  WidgetTester t,
  Future<List<PlayerRanking>> Function() rankings,
) async {
  final router = GoRouter(
    initialLocation: '/profile/elo',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: Text('PROFILE_PAGE')),
        routes: [
          GoRoute(
            path: 'elo',
            builder: (_, _) => const ProfileEloRouteScreen(),
          ),
        ],
      ),
    ],
  );
  await t.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        userProfileProvider.overrideWith((ref) async => _profile),
        userRankingsProvider.overrideWith((ref) => rankings()),
        eloHistoryProvider.overrideWith((ref, q) async => <EloHistoryLog>[]),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

void main() {
  testWidgets('rankings loading shows skeleton, no fake 1000 ELO screen', (
    t,
  ) async {
    final gate = Completer<List<PlayerRanking>>();
    await _pump(t, () => gate.future);
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byType(EloHistoryScreen), findsNothing);
    expect(find.byType(LavishRowSkeleton), findsOneWidget);
    gate.complete([_rank(1500)]);
    await t.pump(const Duration(milliseconds: 100));
    await t.pumpAndSettle();
    expect(find.byType(EloHistoryScreen), findsOneWidget);
    expect(find.text('1500'), findsWidgets);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('rankings error shows retry that refetches', (t) async {
    var calls = 0;
    await _pump(t, () async {
      calls++;
      if (calls == 1) throw Exception('boom');
      return [_rank(1320), _rank(1500)];
    });
    await t.pumpAndSettle();
    expect(find.byType(EloHistoryScreen), findsNothing);
    expect(find.byType(LavishErrorState), findsOneWidget);
    await t.tap(find.text('Retry'));
    await t.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(EloHistoryScreen), findsOneWidget);
    expect(find.text('1500'), findsWidgets);
  });

  testWidgets('successfully empty rankings fall back to 1000', (t) async {
    await _pump(t, () async => <PlayerRanking>[]);
    await t.pumpAndSettle();
    expect(find.byType(EloHistoryScreen), findsOneWidget);
    expect(find.text('1000'), findsWidgets);
  });

  testWidgets('back from error screen goes to /profile when nothing to pop', (
    t,
  ) async {
    await _pump(t, () async => throw Exception('boom'));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.arrow_back_rounded));
    await t.pumpAndSettle();
    expect(find.text('PROFILE_PAGE'), findsOneWidget);
  });
}
