import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_new_messages_pill.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TC-LIVEFS-04 shows the unseen count and fires onTap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LiveNewMessagesPill(count: 3, onTap: () => taps++),
        ),
      ),
    );

    expect(find.text('3 new messages'), findsOneWidget);
    await tester.tap(find.byType(LiveNewMessagesPill));
    expect(taps, 1);
  });
}
