import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/shared/widgets/withdraw_sheet.dart';

class _PendingRefundRepository extends Fake implements ITournamentRepository {
  var withdrawCalls = 0;

  @override
  Future<Map<String, dynamic>> withdraw({
    required String tournamentId,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    String? divisionId,
  }) async {
    withdrawCalls++;
    return {'refundStatus': 'PENDING_REFUND', 'feeDeducted': '0.00'};
  }
}

void main() {
  testWidgets(
    'shows pending refund copy when server reports an existing request',
    (tester) async {
      final repository = _PendingRefundRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(repository),
            userProfileProvider.overrideWith(
              (ref) async => const UserProfile(
                id: 'user-1',
                bankName: 'Example Bank',
                bankAccountNumber: '1234567890',
                bankAccountName: 'TEST USER',
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => WithdrawSheet.show(
                      context,
                      tournamentId: 'tournament-1',
                      hasPaid: true,
                    ),
                    child: const Text('Open withdrawal'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open withdrawal'));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(WithdrawSheet)),
      )!;
      expect(find.text(l10n.withdraw_bankNameLabel), findsNothing);

      await tester.tap(find.text(l10n.withdraw_confirm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repository.withdrawCalls, 1);
      expect(find.text(l10n.withdraw_existingRefundPending), findsOneWidget);
    },
  );
}
