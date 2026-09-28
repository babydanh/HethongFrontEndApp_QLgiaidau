import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_finance_section.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Tournament _tournament({required String status, required String creatorId}) =>
    Tournament.fromJson({
      'name': 'City Pickleball Cup',
      'sport': 'pickleball',
      'format': 'doubles',
      'bracketType': 'single_elimination',
      'status': status,
      'creatorId': creatorId,
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-01T00:00:00Z',
    }, 'tournament-1');

Widget _app({
  required Tournament tournament,
  required UserProfile profile,
  required _FinanceRepository repository,
}) => ProviderScope(
  overrides: [
    tournamentManagementRepositoryProvider.overrideWithValue(repository),
    userProfileProvider.overrideWith((ref) async => profile),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: TournamentManagementFinanceSection(tournament: tournament),
    ),
  ),
);

class _FinanceRepository implements TournamentManagementRepository {
  int payoutHistoryRequests = 0;

  @override
  Future<Map<String, dynamic>> getFeesConfig() async => {
    'allowEntryFees': false,
  };

  @override
  Future<List<Map<String, dynamic>>> getMyPayouts() async {
    payoutHistoryRequests++;
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('payout controls require completed tournament creator role', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final repository = _FinanceRepository();
    await tester.pumpWidget(
      _app(
        tournament: _tournament(status: 'COMPLETED', creatorId: 'user-1'),
        profile: const UserProfile(id: 'user-1', role: 'ORGANIZER'),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.text(l10n.tournamentManagementBankAccountNumber),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.tournamentManagementBankAccountNumber),
      findsOneWidget,
    );
    expect(repository.payoutHistoryRequests, 1);
  });

  testWidgets('non-creator does not load or see payout controls', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final repository = _FinanceRepository();
    await tester.pumpWidget(
      _app(
        tournament: _tournament(status: 'COMPLETED', creatorId: 'creator-1'),
        profile: const UserProfile(id: 'user-1', role: 'ORGANIZER'),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.tournamentManagementPayoutCreatorOnly),
      findsOneWidget,
    );
    expect(find.text(l10n.tournamentManagementBankAccountNumber), findsNothing);
    expect(repository.payoutHistoryRequests, 0);
  });

  testWidgets('creator without organizer role cannot request payout', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final repository = _FinanceRepository();
    await tester.pumpWidget(
      _app(
        tournament: _tournament(status: 'COMPLETED', creatorId: 'user-1'),
        profile: const UserProfile(id: 'user-1', role: 'PLAYER'),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.tournamentManagementPayoutCreatorOnly),
      findsOneWidget,
    );
    expect(find.text(l10n.tournamentManagementBankAccountNumber), findsNothing);
    expect(repository.payoutHistoryRequests, 0);
  });

  testWidgets('unfinished tournament hides payout controls', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final repository = _FinanceRepository();
    await tester.pumpWidget(
      _app(
        tournament: _tournament(status: 'IN_PROGRESS', creatorId: 'user-1'),
        profile: const UserProfile(id: 'user-1', role: 'ORGANIZER'),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.tournamentManagementPayoutRequiresCompleted),
      findsOneWidget,
    );
    expect(find.text(l10n.tournamentManagementBankAccountNumber), findsNothing);
    expect(repository.payoutHistoryRequests, 0);
  });
}
