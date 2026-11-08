import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/features/community/screens/create_club_tournament_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/lite_pickleball_scoring.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('TC-LPK-APP-08 payload field', () {
    test('pickleball sends the chosen scoring, Side-out by default', () {
      expect(LitePickleballScoring.values.first, LitePickleballScoring.sideOut);
      expect(
        litePickleballScoringPayload(
          sport: AppConstants.sportPickleball,
          scoring: LitePickleballScoring.sideOut,
        ),
        {'pickleballScoring': 'SIDE_OUT'},
      );
      expect(
        litePickleballScoringPayload(
          sport: AppConstants.sportPickleball,
          scoring: LitePickleballScoring.rally,
        ),
        {'pickleballScoring': 'RALLY'},
      );
    });

    test('other sports send nothing', () {
      for (final sport in [
        AppConstants.sportBadminton,
        AppConstants.sportTennis,
        AppConstants.sportTableTennis,
        AppConstants.sportFootball,
      ]) {
        expect(
          litePickleballScoringPayload(
            sport: sport,
            scoring: LitePickleballScoring.sideOut,
          ),
          isEmpty,
        );
      }
    });
  });

  group('TC-LPK-APP-09 club tournament create screen', () {
    const sideOutKey = ValueKey('lite-pickleball-scoring-SIDE_OUT');
    const rallyKey = ValueKey('lite-pickleball-scoring-RALLY');

    Future<FakeApiAdapter> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final adapter = FakeApiAdapter({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioClientProvider.overrideWithValue(fakeDioClient(adapter)),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const CreateClubTournamentScreen(clubId: ''),
          ),
        ),
      );
      await tester.pump();
      return adapter;
    }

    Future<Map<String, dynamic>?> submit(
      WidgetTester tester,
      FakeApiAdapter adapter,
    ) async {
      await tester.enterText(find.byType(TextFormField).first, 'Giải thử');
      await tester.tap(find.text('Create tournament'));
      for (var i = 0; i < 20 && adapter.requests.isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      return adapter.postsTo('/tournaments/lite').first.body;
    }

    bool selected(WidgetTester tester, Key key) =>
        tester.widget<LavishChoiceTile>(find.byKey(key)).selected;

    testWidgets('pickleball shows the choice, Side-out selected by default', (
      tester,
    ) async {
      final adapter = await pump(tester);

      expect(find.byKey(sideOutKey), findsOneWidget);
      expect(find.byKey(rallyKey), findsOneWidget);
      expect(selected(tester, sideOutKey), isTrue);
      expect(selected(tester, rallyKey), isFalse);

      final body = await submit(tester, adapter);
      expect(body?['pickleballScoring'], 'SIDE_OUT');
    });

    testWidgets('choosing Rally sends RALLY', (tester) async {
      final adapter = await pump(tester);

      await tester.tap(find.byKey(rallyKey));
      await tester.pump();
      expect(selected(tester, rallyKey), isTrue);

      final body = await submit(tester, adapter);
      expect(body?['pickleballScoring'], 'RALLY');
    });

    testWidgets('another sport hides the choice and sends no field', (
      tester,
    ) async {
      final adapter = await pump(tester);

      await tester.tap(find.text('Badminton'));
      await tester.pump();
      expect(find.byKey(sideOutKey), findsNothing);

      final body = await submit(tester, adapter);
      expect(body, isNotNull);
      expect(body!.containsKey('pickleballScoring'), isFalse);
    });
  });
}
