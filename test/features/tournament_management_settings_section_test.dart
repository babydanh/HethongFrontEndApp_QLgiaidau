import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
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

class _ManagementRepository implements TournamentManagementRepository {
  String? regeneratedInviteFor;

  @override
  Future<List<String>> getGallery(String id) async => const [];

  @override
  Future<Map<String, dynamic>> regenerateInviteCode(String id) async {
    regeneratedInviteFor = id;
    return const {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament() => Tournament.fromJson({
  'name': 'City Pickleball Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'REGISTRATION_OPEN',
  'visibility': 'PUBLIC',
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

Future<_SettingsRepository> _pumpSection(
  WidgetTester tester,
  TournamentManagementSection section, {
  _ManagementRepository? managementRepository,
}) async {
  final tournament = _tournament();
  final repository = _SettingsRepository(tournament);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentRepositoryProvider.overrideWithValue(repository),
        tournamentManagementRepositoryProvider.overrideWithValue(
          managementRepository ?? _ManagementRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: TournamentManagementSectionScreen(
            tournament: tournament,
            section: section,
            opsWorkspaceRoute: '/organizer/ops/tournament-1',
            actionRouteBase: '/organizer/tournaments/tournament-1/manage',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Future<void> _tapSave(WidgetTester tester, AppLocalizations l10n) async {
  final saveButton = find.widgetWithText(
    FilledButton,
    l10n.tournamentManagementSave,
  );
  await tester.ensureVisible(saveButton);
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('information saves name, description and config only', (
    tester,
  ) async {
    final repository = await _pumpSection(
      tester,
      TournamentManagementSection.information,
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(TournamentManagementSectionScreen)),
    )!;

    final toggle = find.byKey(const ValueKey('hide-featured-card-text'));
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pump();
    await _tapSave(tester, l10n);

    expect(
      repository.updatedPayload?.keys,
      unorderedEquals(['name', 'description', 'tournamentConfig']),
    );
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

  testWidgets('registration saves visibility alone when only visibility changes', (
    tester,
  ) async {
    final repository = await _pumpSection(
      tester,
      TournamentManagementSection.registration,
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(TournamentManagementSectionScreen)),
    )!;

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tournamentManagementPrivate).last);
    await tester.pumpAndSettle();
    await _tapSave(tester, l10n);

    expect(repository.updatedPayload, {'visibility': 'PRIVATE'});
  });

  testWidgets('registration regenerates the invite code after confirmation', (
    tester,
  ) async {
    final management = _ManagementRepository();
    await _pumpSection(
      tester,
      TournamentManagementSection.registration,
      managementRepository: management,
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(TournamentManagementSectionScreen)),
    )!;

    final regenerate = find.widgetWithText(
      OutlinedButton,
      l10n.tournamentManagementRegenerateInvite,
    );
    await tester.ensureVisible(regenerate);
    await tester.tap(regenerate);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.tournamentManagementConfirm).last);
    await tester.pumpAndSettle();

    expect(management.regeneratedInviteFor, 'tournament-1');
    expect(tester.takeException(), isNull);
  });
}
