import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_quanly_giaidau/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  testWidgets('TournamentApp builds inside ProviderScope', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    // main.dart wraps TournamentApp in ProviderScope; the app needs it to build.
    await tester.pumpWidget(const ProviderScope(child: TournamentApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
