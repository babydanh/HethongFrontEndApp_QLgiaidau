import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_contact_form.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpForm(
  WidgetTester tester, {
  int? profileElo,
  String? profileTierName,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: TournamentContactForm(
            initial: const {'phone': '0900000001'},
            profileName: 'danh',
            profileElo: profileElo,
            profileTierName: profileTierName,
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  );
}

Color? _ringColor(WidgetTester tester) {
  final outer = find
      .descendant(of: find.byType(RankAvatar), matching: find.byType(Container))
      .first;
  final decoration = tester.widget<Container>(outer).decoration! as BoxDecoration;
  return decoration.color;
}

void main() {
  testWidgets('TC-RANK-RING-APP-02 contact form avatar ring follows the tier', (
    tester,
  ) async {
    await _pumpForm(tester, profileElo: 1850, profileTierName: 'Tier S');
    expect(_ringColor(tester), const Color(0xFFFBBF24));
  });

  testWidgets('TC-RANK-RING-APP-03 contact form avatar ring is gray unranked', (
    tester,
  ) async {
    await _pumpForm(tester);
    expect(_ringColor(tester), const Color(0xFFCBD5E1));
  });
}
