import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/home/widgets/global_search_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _PendingTournaments extends Fake implements ITournamentRepository {
  final pending =
      Completer<
        ({List<Tournament> tournaments, String? nextCursor, bool hasMore})
      >();

  @override
  Future<({List<Tournament> tournaments, String? nextCursor, bool hasMore})>
  getPublicTournamentsPaged({
    String? cursor,
    int limit = 6,
    String? categoryId,
    String? status,
    String? search,
    String? bracketType,
    bool? isRanked,
    String? region,
    DateTime? startDate,
    DateTime? endDate,
    bool rethrowOnError = false,
  }) => pending.future;
}

class _PendingMatches extends Fake implements IMatchRepository {
  final pending =
      Completer<
        ({
          List<MatchModel> matches,
          String? nextCursor,
          bool hasMore,
          int total,
        })
      >();

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
  }) => pending.future;
}

void main() {
  for (final scope in [0, 1]) {
    testWidgets('scope $scope: first search shows skeleton rows, no spinner', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesProvider.overrideWith((ref) async => []),
            tournamentRepositoryProvider.overrideWithValue(
              _PendingTournaments(),
            ),
            matchRepositoryProvider.overrideWithValue(_PendingMatches()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: GlobalSearchScreen(initialTabIndex: scope, initialQuery: ''),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
