import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/list_skeletons.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/rankings/screens/leaderboard_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

final _categories = [
  CategoryModel(
    id: 'cat-pickleball',
    name: 'Pickleball',
    slug: 'pickleball',
    description: '',
    isActive: true,
  ),
];

Widget _app({
  Future<List<CategoryModel>> Function()? categories,
  Future<List<dynamic>> Function()? rankings,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(_GuestAuthNotifier.new),
      userProfileProvider.overrideWith(
        (ref) async => const UserProfile(id: 'user-1', fullName: 'Alex'),
      ),
      categoriesProvider.overrideWith(
        (ref) => (categories ?? () async => _categories)(),
      ),
      footballTeamRankingsProvider.overrideWith((ref, categoryId) async => []),
      rankingsProvider.overrideWith(
        (ref, query) async => (await (rankings ?? () async => [])()).cast(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: const LeaderboardScreen(standalone: true),
    ),
  );
}

void main() {
  testWidgets('shows row skeletons while the sports list loads', (tester) async {
    final gate = Completer<List<CategoryModel>>();

    await tester.pumpWidget(_app(categories: () => gate.future));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LeaderboardRowSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('keeps the filters and shows row skeletons while rankings load', (
    tester,
  ) async {
    final gate = Completer<List<dynamic>>();

    await tester.pumpWidget(_app(rankings: () => gate.future));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LeaderboardRowSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Nam'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
