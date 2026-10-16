import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_quanly_giaidau/app.dart';

void main() {
  testWidgets('TournamentApp builds inside ProviderScope', (
    WidgetTester tester,
  ) async {
    // main.dart wraps TournamentApp in ProviderScope; the app needs it to build.
    await tester.pumpWidget(const ProviderScope(child: TournamentApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
