import 'package:app_quanly_giaidau/core/widgets/sport_choice_tile.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses the shared sport asset and reports selection', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SportChoiceTile(
            sportKey: 'badminton',
            label: 'Cầu lông',
            selected: true,
            expanded: false,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(find.text('Cầu lông'), findsOneWidget);
    await tester.tap(find.text('Cầu lông'));
    expect(taps, 1);
  });
}
