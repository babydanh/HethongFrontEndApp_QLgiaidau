import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_section_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SettingsRepository implements ITournamentRepository {
  _SettingsRepository(this.tournament);

  final Tournament tournament;
  Map<String, dynamic>? updatedPayload;

  @override
  Future<Tournament?> getById(String id, {String? inviteCode}) async =>
      tournament;

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    updatedPayload = data;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('card headline visibility saves as a tournament config patch', (
    tester,
  ) async {
    final tournament = Tournament.fromJson({
      'name': 'City Pickleball Cup',
      'sport': 'pickleball',
      'format': 'doubles',
      'bracketType': 'single_elimination',
      'status': 'REGISTRATION_OPEN',
      'tournamentConfig': {
        'hideFeaturedCardText': true,
        'registrationMode': 'OPEN',
        'registrationForm': [
          {'id': 'skill', 'label': 'Playing level'},
        ],
        'location': {'venueName': 'North Court', 'address': '12 Lake Road'},
        'mode': 'FREE',
      },
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-01T00:00:00Z',
    }, 'tournament-1');
    final repository = _SettingsRepository(tournament);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tournamentRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: TournamentManagementSectionScreen(
              tournament: tournament,
              section: TournamentManagementSection.general,
              opsWorkspaceRoute: '/organizer/ops/tournament-1',
              actionRouteBase: '/organizer/tournaments/tournament-1/manage',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(TournamentManagementSectionScreen)),
    )!;

    final toggle = find.byKey(const ValueKey('hide-featured-card-text'));
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pump();
    final saveButton = find.widgetWithText(
      FilledButton,
      l10n.tournamentManagementSave,
    );
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(repository.updatedPayload?['tournamentConfig'], {
      'hideFeaturedCardText': false,
      'registrationMode': 'OPEN',
      'registrationForm': [
        {'id': 'skill', 'label': 'Playing level'},
      ],
      'location': {'venueName': 'North Court', 'address': '12 Lake Road'},
      'mode': 'FREE',
    });
  });
}
