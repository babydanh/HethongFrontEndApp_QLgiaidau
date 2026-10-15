import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_register_bar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {double width = 390}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('vi'),
  theme: AppTheme.lightTheme,
  home: Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  testWidgets('shows fee and deadline summary with a filled register button', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      _host(
        TournamentRegisterBar(
          entryFee: 150000,
          registrationEnd: DateTime(2026, 10, 23),
          onRegister: () => tapped++,
        ),
      ),
    );

    expect(find.text('150.000 đ'), findsOneWidget);
    expect(find.text('23/10/2026'), findsOneWidget);

    // Nút có nền màu (không còn nút chữ trơn trong suốt).
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.byType(FilledButton));
    expect(tapped, 1);
  });

  testWidgets('free tournament shows the free label, not 0 đ', (tester) async {
    await tester.pumpWidget(
      _host(
        TournamentRegisterBar(
          entryFee: 0,
          registrationEnd: null,
          onRegister: () {},
        ),
      ),
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(TournamentRegisterBar)),
    )!;
    expect(find.text(l10n.freePrice), findsOneWidget);
    expect(find.textContaining('0 đ'), findsNothing);
  });

  testWidgets('a missing deadline shows no deadline text instead of a fake one', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TournamentRegisterBar(
          entryFee: null,
          registrationEnd: null,
          onRegister: () {},
        ),
      ),
    );

    expect(find.textContaining('/20'), findsNothing);
  });

  testWidgets('fits a 320px phone with a large font without overflowing', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      _host(
        TournamentRegisterBar(
          entryFee: 1250000,
          registrationEnd: DateTime(2026, 10, 23),
          onRegister: () {},
        ),
        width: 320,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
