import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/community/screens/create_club_tournament_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/create_public_quick_tournament_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/regions_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';

void main() {
  const profile = UserProfile(id: 'u1', role: 'ORGANIZER');
  final categories = [
    CategoryModel(
      id: '1',
      name: 'Pickleball',
      slug: 'pickleball',
      description: '',
      isActive: true,
    ),
    CategoryModel(
      id: '2',
      name: 'Tennis',
      slug: 'tennis',
      description: '',
      isActive: true,
    ),
    CategoryModel(
      id: '3',
      name: 'Badminton',
      slug: 'badminton',
      description: '',
      isActive: true,
    ),
    CategoryModel(
      id: '4',
      name: 'Bóng đá',
      slug: 'football',
      description: '',
      isActive: true,
    ),
  ];

  Widget wrap(Widget child) => ProviderScope(
    overrides: [
      categoriesProvider.overrideWith((ref) async => categories),
      provincesProvider.overrideWith((ref) async => <Province>[]),
      userProfileProvider.overrideWith((ref) async => profile),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );

  testWidgets('public tournament creation renders all form sections', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const CreatePublicQuickTournamentScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('Tạo giải đấu'), findsWidgets);
    expect(find.text('Sơ đồ thi đấu *'), findsOneWidget);
  });

  testWidgets('club tournament creation renders without widget assertions', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const CreateClubTournamentScreen(clubId: '')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Tạo giải đấu'), findsOneWidget);
  });
}
