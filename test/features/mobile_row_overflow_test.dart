import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/auto_draw_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'layout-test-tournament';

Tournament _tournament() => Tournament.fromJson({
  'name': 'Layout regression tournament',
  'sport': 'badminton',
  'format': 'SINGLES',
  'bracketType': 'single_elimination',
  'status': 'upcoming',
  'maxTeams': 8,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
}, _tournamentId);

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _localizedApp(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('vi'),
  home: child,
);

void main() {
  testWidgets('auto and manual draw actions fit a narrow viewport', (
    tester,
  ) async {
    _setPhoneViewport(tester);
    const tournamentId = _tournamentId;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teamsProvider(
            tournamentId,
          ).overrideWith((ref) => Stream.value(<Team>[])),
          tournamentProvider(
            tournamentId,
          ).overrideWith((ref) => Stream.value(_tournament())),
          matchesProvider(
            tournamentId,
          ).overrideWith((ref) => Stream.value(<MatchModel>[])),
        ],
        child: _localizedApp(const AutoDrawScreen(tournamentId: tournamentId)),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(AutoDrawScreen));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.autoDraw_auto), findsOneWidget);
    expect(find.text(l10n.autoDraw_manual), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
