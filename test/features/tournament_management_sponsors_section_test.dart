import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_sponsor.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_sponsors_section.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SponsorRepository implements TournamentManagementRepository {
  _SponsorRepository(this.sponsor);

  final TournamentSponsor sponsor;
  Map<String, dynamic>? updatedSponsor;

  @override
  Future<List<TournamentSponsor>> getSponsors(String id) async => [sponsor];

  @override
  Future<TournamentSponsor> updateSponsor(
    String id,
    String sponsorId,
    Map<String, dynamic> payload,
  ) async {
    updatedSponsor = payload;
    return sponsor;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('sponsor parser preserves public visibility state', () {
    final sponsor = TournamentSponsor.fromJson({
      'id': 'sponsor-1',
      'displayName': 'Court Partner',
      'tier': 'GOLD',
      'logoUrl': 'https://cdn.example.test/logo.png',
      'status': 'DRAFT',
      'isPublic': false,
    });

    expect(sponsor.status, 'DRAFT');
    expect(sponsor.isPublic, false);
  });

  testWidgets('editing a sponsor exposes its public visibility control', (
    tester,
  ) async {
    final sponsor = TournamentSponsor(
      id: 'sponsor-1',
      displayName: 'Court Partner',
      tier: 'GOLD',
      logoUrl: 'https://cdn.example.test/logo.png',
      status: 'DRAFT',
      isPublic: false,
    );
    final repository = _SponsorRepository(sponsor);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentManagementRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(
            body: TournamentManagementSponsorsSection(
              tournamentId: 'tournament-1',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(TournamentManagementSponsorsSection)),
    )!;

    await tester.tap(find.byTooltip(l10n.tournamentManagementEdit));
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      false,
    );
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    final saveButton = find.widgetWithText(
      FilledButton,
      l10n.tournamentManagementSave,
    );
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(repository.updatedSponsor?['status'], 'PUBLISHED');
    expect(repository.updatedSponsor?['isPublic'], true);
  });
}
