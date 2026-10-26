import 'package:app_quanly_giaidau/core/config/app_theme.dart';
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

Future<List<RankingQuery>> _pumpScreen(WidgetTester tester) async {
  final queries = <RankingQuery>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_GuestAuthNotifier.new),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(id: 'user-1', fullName: 'Alex'),
        ),
        categoriesProvider.overrideWith((ref) async => _categories),
        footballTeamRankingsProvider.overrideWith((ref, categoryId) async => []),
        rankingsProvider.overrideWith((ref, query) async {
          queries.add(query);
          return [];
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: const LeaderboardScreen(standalone: true),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return queries;
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('first open sends no matchType and shows Nam/Nữ chips', (
    tester,
  ) async {
    final queries = await _pumpScreen(tester);

    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Nam'), findsOneWidget);
    expect(find.text('Nữ'), findsOneWidget);
    expect(queries.last.matchType, '');
    expect(queries.last.genderRestriction, 'MALE');
  });

  testWidgets('Đôi sends DOUBLES with the selected gender', (tester) async {
    final queries = await _pumpScreen(tester);

    await tester.tap(find.text('Đôi'));
    await tester.pumpAndSettle();

    expect(queries.last.matchType, 'DOUBLES');
    expect(queries.last.genderRestriction, 'MALE');
    expect(find.text('Nam'), findsOneWidget);
  });

  testWidgets('Đơn sends SINGLES', (tester) async {
    final queries = await _pumpScreen(tester);

    await tester.tap(find.text('Đơn'));
    await tester.pumpAndSettle();

    expect(queries.last.matchType, 'SINGLES');
  });

  testWidgets('Đôi nam nữ sends MIXED_DOUBLES without gender and hides Nam/Nữ', (
    tester,
  ) async {
    final queries = await _pumpScreen(tester);

    await tester.tap(find.text('Đôi nam nữ'));
    await tester.pumpAndSettle();

    expect(queries.last.matchType, 'MIXED_DOUBLES');
    expect(queries.last.genderRestriction, isNull);
    expect(find.text('Nam'), findsNothing);
    expect(find.text('Nữ'), findsNothing);
  });

  testWidgets('leaving Đôi nam nữ restores the chips and the chosen gender', (
    tester,
  ) async {
    final queries = await _pumpScreen(tester);

    await tester.tap(find.text('Nữ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đôi nam nữ'));
    await tester.pumpAndSettle();
    // Pick a format not requested yet: the family provider caches by query.
    await tester.tap(find.text('Đôi'));
    await tester.pumpAndSettle();

    expect(queries.last.matchType, 'DOUBLES');
    expect(queries.last.genderRestriction, 'FEMALE');
    expect(find.text('Nam'), findsOneWidget);
  });
}
