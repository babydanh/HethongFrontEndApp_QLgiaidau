import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_register_bar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('vi'),
  theme: AppTheme.lightTheme,
  home: Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(width: 390, child: child),
    ),
  ),
);

void main() {
  testWidgets('TC-FEEMODE-APP-06 DIRECT shows the fee with the direct note', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TournamentRegisterBar(
          entryFee: 150000,
          isDirectFee: true,
          registrationEnd: null,
          onRegister: () {},
        ),
      ),
    );

    expect(find.text('150.000 đ'), findsOneWidget);
    expect(find.text('Thanh toán trực tiếp cho BTC'), findsOneWidget);
  });

  testWidgets('TC-FEEMODE-APP-07 PAYOS shows no direct note', (tester) async {
    await tester.pumpWidget(
      _host(
        TournamentRegisterBar(
          entryFee: 150000,
          registrationEnd: null,
          onRegister: () {},
        ),
      ),
    );

    expect(find.text('150.000 đ'), findsOneWidget);
    expect(find.text('Thanh toán trực tiếp cho BTC'), findsNothing);
  });

  testWidgets('TC-FEEMODE-APP-08 a free DIRECT tournament shows no note', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TournamentRegisterBar(
          entryFee: 0,
          isDirectFee: true,
          registrationEnd: null,
          onRegister: () {},
        ),
      ),
    );

    expect(find.text('Thanh toán trực tiếp cho BTC'), findsNothing);
  });
}
