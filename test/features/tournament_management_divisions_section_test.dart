import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_divisions_section.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _DivisionRepository implements TournamentManagementRepository {
  _DivisionRepository(this.division, {this.all});

  final Map<String, dynamic> division;

  /// When set, the list the screen loads instead of just [division].
  final List<Map<String, dynamic>>? all;
  final configPayloads = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> getManageDivisions(String id) async =>
      all ?? [division];

  @override
  Future<Map<String, dynamic>> updateDivisionConfig(
    String id,
    String divisionId,
    Map<String, dynamic> payload,
  ) async {
    configPayloads.add(payload);
    return division;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament(String status) => Tournament.fromJson({
  'name': 'City Pickleball Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': status,
  'maxTeams': 8,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

const _openDivision = <String, dynamic>{
  'id': 'div-1',
  'name': 'Đôi nam',
  'matchType': 'DOUBLES',
  'bracketType': 'SINGLE_ELIMINATION',
  'registrationOpen': true,
  'effectiveIsRegistrationLocked': false,
  'effectiveRegistrationEndDate': null,
};

Future<AppLocalizations> _pump(
  WidgetTester tester,
  String status,
  _DivisionRepository repository,
) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentManagementRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: TournamentManagementDivisionsSection(
            tournament: _tournament(status),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(
    tester.element(find.byType(TournamentManagementDivisionsSection)),
  )!;
}

Map<String, dynamic> _division(
  String id,
  String name,
  String matchType, {
  int? max,
  int registered = 0,
}) => {
  ..._openDivision,
  'id': id,
  'name': name,
  'matchType': matchType,
  'maxParticipants': ?max,
  '_count': {'participants': registered},
};

void main() {
  testWidgets('groups rows by match type with a count label', (tester) async {
    final divisions = [
      _division('a', 'Đơn Nam', 'SINGLES'),
      _division('b', 'Đôi Nam', 'DOUBLES'),
      _division('c', 'Đôi Nữ', 'DOUBLES'),
    ];
    final l10n = await _pump(
      tester,
      'REGISTRATION',
      _DivisionRepository(divisions.first, all: divisions),
    );

    expect(
      find.text('${l10n.tournamentManagementMatchSingles.toUpperCase()} · 1'),
      findsOneWidget,
    );
    expect(
      find.text('${l10n.tournamentManagementMatchDoubles.toUpperCase()} · 2'),
      findsOneWidget,
    );
    // No search box for a short list.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('a single group shows no group label', (tester) async {
    final l10n = await _pump(
      tester,
      'REGISTRATION',
      _DivisionRepository(_openDivision),
    );

    expect(
      find.textContaining(l10n.tournamentManagementMatchDoubles.toUpperCase()),
      findsNothing,
    );
  });

  testWidgets('shows registered over max and filters by search', (
    tester,
  ) async {
    final divisions = [
      for (var i = 1; i <= 9; i++)
        _division(
          'd$i',
          i == 9 ? 'Đơn Nữ 40+' : 'Nội dung $i',
          i == 9 ? 'SINGLES' : 'DOUBLES',
          max: 16,
          registered: i,
        ),
    ];
    final l10n = await _pump(
      tester,
      'REGISTRATION',
      _DivisionRepository(divisions.first, all: divisions),
    );

    expect(find.text('9/16'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nữ');
    await tester.pumpAndSettle();
    expect(find.text('Đơn Nữ 40+'), findsOneWidget);
    expect(find.text('Nội dung 1'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.tournamentManagementDivisionSearchEmpty),
      findsOneWidget,
    );
  });

  testWidgets('flat header: one primary action, bulk open in a menu', (
    tester,
  ) async {
    final l10n = await _pump(
      tester,
      'REGISTRATION',
      _DivisionRepository(_openDivision),
    );

    // No subtitle and no second button next to "Thêm nội dung".
    expect(
      find.text(l10n.tournamentManagementDivisionsDescription),
      findsNothing,
    );
    // The tab already names the screen: no repeated title in the body.
    expect(find.text(l10n.tournamentManagementDivisions), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text(l10n.tournamentManagementAddDivision), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('division-header-menu')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.divisionBulkOpenButton), findsOneWidget);
  });

  testWidgets('rows are flat and tapping a row opens the editor', (
    tester,
  ) async {
    final l10n = await _pump(
      tester,
      'REGISTRATION',
      _DivisionRepository({..._openDivision, 'maxParticipants': 16}),
    );

    // No decorative category icon in front of the name.
    expect(find.byIcon(Icons.category_outlined), findsNothing);
    // Meta is icons, not sentences: bracket + max participants, no format text.
    expect(find.byIcon(Icons.account_tree_outlined), findsOneWidget);
    expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
    expect(find.text('0/16'), findsOneWidget);
    expect(
      find.text(l10n.tournamentManagementBracketSingleElimination),
      findsNothing,
    );
    expect(find.text(l10n.tournamentManagementMatchDoubles), findsNothing);

    await tester.tap(find.byKey(const ValueKey('division-row-div-1')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.divisionEditorEditTitle), findsWidgets);
  });

  testWidgets(
    'TC-APP-DIVLOCK-01: an in-progress tournament can still lock one division',
    (tester) async {
      final repository = _DivisionRepository(_openDivision);
      final l10n = await _pump(tester, 'IN_PROGRESS', repository);

      // Còn mở mà không có hạn: thẻ nhắc để BTC tự khoá.
      expect(
        find.byTooltip(
          '${l10n.tournamentManagementDivisionRegistrationOpen} · ${l10n.tournamentManagementDivisionNoDeadline}',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(l10n.tournamentManagementDivisionLockRegistration),
      );
      await tester.pumpAndSettle();

      expect(repository.configPayloads, [
        {'isRegistrationLocked': true},
      ]);
    },
  );

  testWidgets(
    'TC-APP-DIVLOCK-02: a locked division reopens while registration is closed',
    (tester) async {
      final repository = _DivisionRepository({
        ..._openDivision,
        'registrationOpen': false,
        'effectiveIsRegistrationLocked': true,
      });
      final l10n = await _pump(tester, 'REGISTRATION_CLOSED', repository);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(l10n.tournamentManagementDivisionUnlockRegistration),
      );
      await tester.pumpAndSettle();

      expect(repository.configPayloads, [
        {'isRegistrationLocked': false},
      ]);
    },
  );

  testWidgets(
    'TC-APP-DIVLOCK-03: a completed tournament does not toggle registration',
    (tester) async {
      final repository = _DivisionRepository(_openDivision);
      final l10n = await _pump(tester, 'COMPLETED', repository);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(l10n.tournamentManagementDivisionLockRegistration),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(repository.configPayloads, isEmpty);
    },
  );
}
