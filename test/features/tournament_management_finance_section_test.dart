import 'dart:async';

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
  int payoutSubmissions = 0;
  Completer<void>? payoutGate;
  bool allowEntryFees = false;
  List<Map<String, dynamic>> payouts = [];

  @override
  Future<Map<String, dynamic>> getFeesConfig() async => {
    'allowEntryFees': allowEntryFees,
  };

  @override
  Future<void> requestPayout({
    required String tournamentId,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
    required num amountRequested,
  }) async {
    payoutSubmissions++;
    await payoutGate?.future;
  }

  @override
  Future<List<Map<String, dynamic>>> getMyPayouts() async {
    payoutHistoryRequests++;
    return payouts;
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

    // The bank form lives in a bottom sheet: only the payout row is on the page.
    expect(find.text(l10n.tournamentManagementBankAccountNumber), findsNothing);
    expect(
      find.text(l10n.tournamentManagementRequestPayout, skipOffstage: false),
      findsOneWidget,
    );
    expect(repository.payoutHistoryRequests, 1);
  });
  testWidgets(
    'creator with organizer membership among multiple roles can request payout',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final repository = _FinanceRepository();
      await tester.pumpWidget(
        _app(
          tournament: _tournament(status: 'COMPLETED', creatorId: 'user-1'),
          profile: UserProfile.fromJson({
            'id': 'user-1',
            'role': 'ADMIN',
            'roles': ['ADMIN', 'ORGANIZER'],
          }),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.tournamentManagementRequestPayout, skipOffstage: false),
        findsOneWidget,
      );
      expect(repository.payoutHistoryRequests, 1);
    },
  );

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
      find.text(
        l10n.tournamentManagementPayoutCreatorOnly,
        skipOffstage: false,
      ),
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
      find.text(
        l10n.tournamentManagementPayoutCreatorOnly,
        skipOffstage: false,
      ),
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
      find.text(
        l10n.tournamentManagementPayoutRequiresCompleted,
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.tournamentManagementBankAccountNumber), findsNothing);
    expect(repository.payoutHistoryRequests, 0);
  });

  Future<void> openPayoutSheet(WidgetTester tester, AppLocalizations l10n) async {
    final row = find.text(
      l10n.tournamentManagementRequestPayout,
      skipOffstage: false,
    );
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  Future<void> fillPayoutForm(WidgetTester tester, AppLocalizations l10n) async {
    // Obviously fake fixture values only.
    await tester.enterText(
      find.widgetWithText(TextField, l10n.tournamentManagementBankName),
      'Ngan hang thu nghiem',
    );
    await tester.enterText(
      find.widgetWithText(
        TextField,
        l10n.tournamentManagementBankAccountNumber,
      ),
      '000000000',
    );
    await tester.enterText(
      find.widgetWithText(TextField, l10n.tournamentManagementBankAccountName),
      'Nguoi Thu Nghiem',
    );
    await tester.enterText(
      find.widgetWithText(TextField, l10n.tournamentManagementAmountRequested),
      '20000',
    );
    await tester.pump();
  }

  Finder sheetSendButton(AppLocalizations l10n) => find.descendant(
    of: find.byType(BottomSheet),
    matching: find.widgetWithText(
      FilledButton,
      l10n.tournamentManagementRequestPayout,
    ),
  );

  testWidgets('payout row opens the bank form in a bottom sheet', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(
      _app(
        tournament: _tournament(status: 'COMPLETED', creatorId: 'user-1'),
        profile: const UserProfile(id: 'user-1', role: 'ORGANIZER'),
        repository: _FinanceRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await openPayoutSheet(tester, l10n);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      find.text(l10n.tournamentManagementBankAccountNumber),
      findsOneWidget,
    );
  });

  testWidgets('payout needs confirmation and is sent once on double tap', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final repository = _FinanceRepository()..payoutGate = Completer<void>();
    await tester.pumpWidget(
      _app(
        tournament: _tournament(status: 'COMPLETED', creatorId: 'user-1'),
        profile: const UserProfile(id: 'user-1', role: 'ORGANIZER'),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();
    await openPayoutSheet(tester, l10n);
    await fillPayoutForm(tester, l10n);

    // Cancel in the confirmation dialog: nothing is sent.
    await tester.tap(sheetSendButton(l10n));
    await tester.pumpAndSettle();
    expect(find.text(l10n.financePayoutConfirmTitle), findsOneWidget);
    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();
    expect(repository.payoutSubmissions, 0);

    // Confirm, then try to send again while the request is still running.
    await tester.tap(sheetSendButton(l10n));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(
          FilledButton,
          l10n.tournamentManagementRequestPayout,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(repository.payoutSubmissions, 1);
    final sending = find.widgetWithText(
      FilledButton,
      l10n.tournamentManagementSubmitting,
    );
    expect(tester.widget<FilledButton>(sending).onPressed, isNull);

    repository.payoutGate!.complete();
    await tester.pumpAndSettle();
    expect(repository.payoutSubmissions, 1);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('payout form rejects an amount below the minimum', (tester) async {
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
    await openPayoutSheet(tester, l10n);
    await fillPayoutForm(tester, l10n);
    await tester.enterText(
      find.widgetWithText(TextField, l10n.tournamentManagementAmountRequested),
      '9999',
    );
    await tester.tap(sheetSendButton(l10n));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.tournamentManagementPayoutValidationError),
      findsOneWidget,
    );
    expect(find.text(l10n.financePayoutConfirmTitle), findsNothing);
    expect(repository.payoutSubmissions, 0);
  });

  testWidgets('history row shows the count and opens the list', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final repository = _FinanceRepository()
      ..payouts = [
        {
          'tournamentId': 'tournament-1',
          'amountRequested': 50000,
          'status': 'PENDING',
        },
      ];
    await tester.pumpWidget(
      _app(
        tournament: _tournament(status: 'COMPLETED', creatorId: 'user-1'),
        profile: const UserProfile(id: 'user-1', role: 'ORGANIZER'),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    final historyRow = find.text(
      l10n.tournamentManagementPayoutHistory,
      skipOffstage: false,
    );
    await tester.ensureVisible(historyRow);
    await tester.pumpAndSettle();
    expect(find.text(l10n.financePayoutHistoryCount(1)), findsOneWidget);
    await tester.tap(historyRow);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(
      find.text(l10n.tournamentManagementPayoutStatusPending),
      findsOneWidget,
    );
  });

  testWidgets('pinned save button is disabled until the fee changes', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(
      _app(
        tournament: _tournament(status: 'DRAFT', creatorId: 'user-1'),
        profile: const UserProfile(id: 'user-1', role: 'ORGANIZER'),
        repository: _FinanceRepository()..allowEntryFees = true,
      ),
    );
    await tester.pumpAndSettle();

    final save = find.widgetWithText(FilledButton, l10n.financeFeeSave);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    final add20 = find.widgetWithText(OutlinedButton, l10n.financeFeeQuickAdd(20));
    await tester.ensureVisible(add20);
    await tester.tap(add20);
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
  });
}
