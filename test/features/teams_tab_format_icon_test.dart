import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/teams_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _tab({required bool withDivision}) => MaterialApp(
  theme: AppTheme.lightTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: TeamsTab(
      teams: [
        Team(
          id: 't1',
          name: 'A / B',
          group: 'Doi Nam',
          divisionId: 'd1',
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
      selectedDivision: 'Doi Nam',
      selectedDivisionId: 'd1',
      divisions: withDivision
          ? const [
              TournamentDivision(
                id: 'd1',
                name: 'Doi Nam',
                matchType: 'DOUBLES',
                bracketType: 'group_stage_knockout',
              ),
            ]
          : const [],
    ),
  ),
);

void main() {
  testWidgets('TC-TEAMS-FORMAT-ICON-01 division heading shows the format icon', (
    tester,
  ) async {
    await tester.pumpWidget(_tab(withDivision: true));
    await tester.pump();
    expect(find.text('Doi Nam'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('heading shows no icon when the division is unknown', (tester) async {
    await tester.pumpWidget(_tab(withDivision: false));
    await tester.pump();
    expect(find.text('Doi Nam'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });
}
