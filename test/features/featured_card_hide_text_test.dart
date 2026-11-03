import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/home_projection.dart';
import 'package:app_quanly_giaidau/features/home/widgets/featured_tournament_banner_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpCard(WidgetTester tester, HomeFeaturedTournament card) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FeaturedTournamentBannerCard(tournament: card, onTap: () {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TC-HIDECARD-02: HomeFeaturedTournament.fromJson', () {
    Map<String, dynamic> json(Object? flag) => {
      'id': 't1',
      'name': 'Giai A',
      'hideFeaturedCardText': ?flag,
    };

    test('reads hideFeaturedCardText=true from the API', () {
      expect(
        HomeFeaturedTournament.fromJson(json(true)).hideFeaturedCardText,
        true,
      );
    });

    test('missing or non-boolean values keep the text visible', () {
      expect(
        HomeFeaturedTournament.fromJson(json(null)).hideFeaturedCardText,
        false,
      );
      expect(
        HomeFeaturedTournament.fromJson(json('true')).hideFeaturedCardText,
        false,
      );
    });
  });

  testWidgets('TC-HIDECARD-03: the card shows the title by default', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      const HomeFeaturedTournament(
        id: 't1',
        name: 'Giai A',
        sport: 'PICKLEBALL',
      ),
    );

    expect(find.text('Giai A'), findsOneWidget);
  });

  testWidgets('TC-HIDECARD-04: the card hides the title but keeps its badges', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      const HomeFeaturedTournament(
        id: 't1',
        name: 'Giai A',
        sport: 'PICKLEBALL',
        registrationStatus: 'OPEN',
        hideFeaturedCardText: true,
      ),
    );

    expect(find.text('Giai A'), findsNothing);
    expect(find.byType(FeaturedTournamentBannerCard), findsOneWidget);
    expect(find.text('REGISTRATION OPEN'), findsOneWidget);
  });
}
