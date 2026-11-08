import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/features/community/screens/create_club_tournament_screen.dart';
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

  testWidgets(
    'TC-LMT-APP-06 pickleball create screen: no scoring choice, no pickleballScoring sent',
    (tester) async {
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

      expect(find.text('Side-out scoring'), findsNothing);
      expect(find.text('Rally scoring'), findsNothing);

      await tester.enterText(find.byType(TextFormField).first, 'Giải thử');
      await tester.tap(find.text('Create tournament'));
      for (var i = 0; i < 20 && adapter.requests.isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      final body = adapter.postsTo('/tournaments/lite').first.body;

      expect(body, isNotNull);
      expect(body!.containsKey('pickleballScoring'), isFalse);
    },
  );
}
