import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/home_skeletons.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/home/screens/home_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tournaments tab shows card skeletons while the first page loads', (
    tester,
  ) async {
    _phone(tester);
    final gate = Completer<void>();

    await tester.pumpWidget(_app(_Repository(gate: gate)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TournamentBannerCardSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // The status tabs stay real while the list loads.
    expect(find.text('Open registration'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _app(_Repository repository) {
  return ProviderScope(
    overrides: [
      tournamentRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(_AuthNotifier.new),
      categoriesProvider.overrideWith((ref) => Future.value(const [])),
      communityDetailProvider.overrideWith(
        (ref, id) async => Community(id: 'club', name: 'Club'),
      ),
      unreadCountProvider.overrideWith((ref) => Future.value(0)),
      regionRepositoryProvider.overrideWith((ref) => _RegionRepository()),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(initialTab: 1),
    ),
  );
}

class _Repository extends Fake implements ITournamentRepository {
  _Repository({required this.gate});

  final Completer<void> gate;

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
  }) async {
    await gate.future;
    return (tournaments: [_tournament], nextCursor: null, hasMore: false);
  }
}

final _tournament = Tournament(
  id: 'synthetic-tournament',
  name: 'Synthetic tournament',
  sport: 'pickleball',
  format: 'single_elimination',
  bracketType: 'SINGLE_ELIMINATION',
  status: 'registration',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'synthetic-user',
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  startDate: DateTime.utc(2026, 10, 1),
);

class _RegionRepository implements IRegionRepository {
  @override
  Future<List<Region>> getProvinces() async => const [];

  @override
  Future<List<Region>> getWardsByProvince(String provinceCode) async =>
      const [];

  @override
  Future<List<Region>> searchRegions(String query, {int limit = 10}) async =>
      const [];
}

class _AuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    role: UserRole.viewer,
    tokenCode: 'synthetic-token',
  );

  @override
  Future<void> init() async {}
}
