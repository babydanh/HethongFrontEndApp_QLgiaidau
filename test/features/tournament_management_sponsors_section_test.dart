import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_sponsor.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_sponsors_section.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/sponsors_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SponsorRepository implements TournamentManagementRepository {
  _SponsorRepository(this.sponsors);

  final List<TournamentSponsor> sponsors;
  Map<String, dynamic>? updatedSponsor;
  final List<({String id, Map<String, dynamic> payload})> updates = [];
  final List<String> archived = [];

  @override
  Future<List<TournamentSponsor>> getSponsors(String id) async => sponsors;

  @override
  Future<TournamentSponsor> updateSponsor(
    String id,
    String sponsorId,
    Map<String, dynamic> payload,
  ) async {
    updatedSponsor = payload;
    updates.add((id: sponsorId, payload: payload));
    return sponsors.first;
  }

  @override
  Future<TournamentSponsor> archiveSponsor(String id, String sponsorId) async {
    archived.add(sponsorId);
    return sponsors.first;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TournamentSponsor _sponsor(
  String id, {
  int order = 0,
  String status = 'PUBLISHED',
  bool? isPublic,
  String tier = 'GOLD',
}) => TournamentSponsor(
  id: id,
  displayName: 'Partner $id',
  tier: tier,
  logoUrl: 'https://cdn.example.test/$id.png',
  displayOrder: order,
  status: status,
  isPublic: isPublic,
);

Future<AppLocalizations> _pump(
  WidgetTester tester,
  _SponsorRepository repository,
) async {
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
  return AppLocalizations.of(
    tester.element(find.byType(TournamentManagementSponsorsSection)),
  )!;
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
    final repository = _SponsorRepository([
      _sponsor('1', status: 'DRAFT', isPublic: false),
    ]);
    final l10n = await _pump(tester, repository);

    await tester.tap(find.byKey(const ValueKey('sponsor-row-1')));
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

  testWidgets('TC-SPONSOR-EDITOR-01 tier chips pick the saved tier', (
    tester,
  ) async {
    final repository = _SponsorRepository([_sponsor('1')]);
    final l10n = await _pump(tester, repository);

    await tester.tap(find.byKey(const ValueKey('sponsor-row-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sponsor-tier-SILVER')));
    await tester.pump();
    final saveButton = find.widgetWithText(
      FilledButton,
      l10n.tournamentManagementSave,
    );
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(repository.updatedSponsor?['tier'], 'SILVER');
  });

  testWidgets('TC-SPONSOR-EDITOR-02 editor fits a 320dp phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _SponsorRepository([_sponsor('1')]);
    final l10n = await _pump(tester, repository);

    await tester.tap(find.byKey(const ValueKey('sponsor-row-1')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(l10n.tournamentManagementUploadLogo), findsOneWidget);
    expect(find.byKey(const ValueKey('sponsor-tier-IN_KIND')), findsOneWidget);
  });

  testWidgets('row shows initial, tier, switch, hint and no order input', (
    tester,
  ) async {
    final repository = _SponsorRepository([_sponsor('1', order: 0)]);
    final l10n = await _pump(tester, repository);

    expect(find.text('P'), findsOneWidget);
    expect(
      find.text(
        l10n.tournamentManagementSponsorTierRank(
          l10n.tournamentManagementSponsorTierGold,
        ),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('sponsor-switch-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('sponsor-handle-1')), findsOneWidget);
    expect(find.text(l10n.tournamentManagementSponsorHint), findsOneWidget);
    expect(find.text(l10n.tournamentManagementAddSponsorShort), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sponsor-row-1')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tournamentManagementDisplayOrder), findsNothing);
  });

  testWidgets('empty state keeps the title and the add button', (tester) async {
    final l10n = await _pump(tester, _SponsorRepository(const []));

    expect(find.text(l10n.tournamentManagementSponsorsEmpty), findsOneWidget);
    expect(find.text(l10n.tournamentManagementAddSponsorShort), findsOneWidget);
  });

  testWidgets('the row switch toggles public visibility only', (tester) async {
    final repository = _SponsorRepository([_sponsor('1')]);
    await _pump(tester, repository);

    await tester.tap(find.byKey(const ValueKey('sponsor-switch-1')));
    await tester.pumpAndSettle();

    expect(repository.updates, hasLength(1));
    expect(repository.updates.single.id, '1');
    expect(repository.updates.single.payload, {
      'status': 'DRAFT',
      'isPublic': false,
    });
  });

  testWidgets('dragging the handle saves only the changed displayOrder', (
    tester,
  ) async {
    final repository = _SponsorRepository([
      _sponsor('a', order: 0),
      _sponsor('b', order: 1),
      _sponsor('c', order: 2),
    ]);
    await _pump(tester, repository);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('sponsor-handle-b'))),
    );
    for (var step = 0; step < 6; step++) {
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    final sent = {
      for (final update in repository.updates) update.id: update.payload,
    };
    expect(sent.keys.toSet(), {'a', 'b'});
    expect(sent['b'], {'displayOrder': 0});
    expect(sent['a'], {'displayOrder': 1});
  });

  testWidgets('swipe left asks first; cancel keeps, confirm archives', (
    tester,
  ) async {
    final repository = _SponsorRepository([_sponsor('1')]);
    final l10n = await _pump(tester, repository);
    final row = find.byKey(const ValueKey('sponsor-row-1'));

    await tester.drag(row, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text(l10n.tournamentManagementCancel));
    await tester.pumpAndSettle();
    expect(repository.archived, isEmpty);
    expect(row, findsOneWidget);

    await tester.drag(row, const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.tournamentManagementArchive),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.archived, ['1']);
  });

  testWidgets('an archived row cannot be toggled or swiped', (tester) async {
    final repository = _SponsorRepository([_sponsor('1', status: 'ARCHIVED')]);
    final l10n = await _pump(tester, repository);

    expect(
      find.textContaining(l10n.tournamentManagementSponsorArchived),
      findsOneWidget,
    );
    expect(
      tester
          .widget<LavishSwitch>(find.byKey(const ValueKey('sponsor-switch-1')))
          .onChanged,
      isNull,
    );
    await tester.drag(
      find.byKey(const ValueKey('sponsor-row-1')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('preview lists only publicly shown sponsors', (tester) async {
    final repository = _SponsorRepository([
      _sponsor('pub'),
      _sponsor('draft', status: 'DRAFT', isPublic: false),
    ]);
    final l10n = await _pump(tester, repository);

    await tester.tap(find.text(l10n.tournamentManagementSponsorPreview));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(SponsorsTab),
        matching: find.text('Partner pub'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SponsorsTab),
        matching: find.text('Partner draft'),
      ),
      findsNothing,
    );
  });

  testWidgets('fits a 320dp wide phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _SponsorRepository([
      _sponsor('a', tier: 'IN_KIND'),
      _sponsor('b', status: 'ARCHIVED'),
    ]);
    await _pump(tester, repository);

    expect(tester.takeException(), isNull);
  });
}
