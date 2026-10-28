import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_reconfirm_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ConfirmRepository
    implements TournamentManagementRepository, TournamentLifecycleRepository {
  final confirmedIds = <String>[];
  Object? failWith;

  @override
  Future<void> confirmTournamentResults(String id) async {
    confirmedIds.add(id);
    if (failWith != null) throw failWith!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<AppLocalizations> _pump(
  WidgetTester tester,
  _ConfirmRepository repository, {
  required String status,
  required bool needsReconfirm,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentManagementRepositoryProvider.overrideWithValue(repository),
        tournamentResultProvider((
          tournamentId: 'tournament-1',
          divisionId: null,
        )).overrideWith(
          (ref) => Stream.value({
            'awards': const [],
            'needsReconfirm': needsReconfirm,
          }),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: ResultsReconfirmCard(
            tournamentId: 'tournament-1',
            status: status,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
}

const _action = ValueKey('results-reconfirm-action');

void main() {
  testWidgets('an unfinished tournament never offers the action', (
    tester,
  ) async {
    await _pump(
      tester,
      _ConfirmRepository(),
      status: 'IN_PROGRESS',
      needsReconfirm: true,
    );

    expect(find.byKey(_action), findsNothing);
  });

  testWidgets('a completed tournament that needs no reconfirm hides it', (
    tester,
  ) async {
    await _pump(
      tester,
      _ConfirmRepository(),
      status: 'COMPLETED',
      needsReconfirm: false,
    );

    expect(find.byKey(_action), findsNothing);
  });

  testWidgets('cancelling the dialog does not call the endpoint', (
    tester,
  ) async {
    final repository = _ConfirmRepository();
    final l10n = await _pump(
      tester,
      repository,
      status: 'COMPLETED',
      needsReconfirm: true,
    );

    await tester.tap(find.byKey(_action));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.lifecycleResultsReconfirmDialogMessage),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.tournamentManagementCancel));
    await tester.pumpAndSettle();

    expect(repository.confirmedIds, isEmpty);
  });

  testWidgets('confirming posts once and reports success', (tester) async {
    final repository = _ConfirmRepository();
    final l10n = await _pump(
      tester,
      repository,
      status: 'COMPLETED',
      needsReconfirm: true,
    );

    await tester.tap(find.byKey(_action));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.lifecycleResultsReconfirmAction),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.confirmedIds, ['tournament-1']);
    expect(find.text(l10n.lifecycleResultsReconfirmed), findsOneWidget);
  });

  testWidgets('a failed confirm shows the generic action error', (
    tester,
  ) async {
    final repository = _ConfirmRepository()..failWith = StateError('boom');
    final l10n = await _pump(
      tester,
      repository,
      status: 'COMPLETED',
      needsReconfirm: true,
    );

    await tester.tap(find.byKey(_action));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text(l10n.lifecycleResultsReconfirmAction),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.tournamentManagementActionError), findsOneWidget);
    expect(find.text(l10n.lifecycleResultsReconfirmed), findsNothing);
  });
}
