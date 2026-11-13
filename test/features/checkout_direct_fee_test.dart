import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/payment_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_payment_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/payment/screens/checkout_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

const _tournamentId = 'checkout-direct-fee-test';

class _MockPaymentRepository extends Mock implements PaymentRepository {}

Tournament _tournament(String mode) => Tournament.fromJson({
  'name': 'Giải thu trực tiếp',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'REGISTRATION',
  'entryFee': 150000,
  'feeCollectionMode': mode,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
}, _tournamentId);

Future<void> _pump(
  WidgetTester tester,
  PaymentRepository repo,
  String mode,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        paymentRepositoryProvider.overrideWithValue(repo),
        tournamentProvider(
          _tournamentId,
        ).overrideWith((ref) => Stream.value(_tournament(mode))),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: AppTheme.lightTheme,
        home: const CheckoutScreen(
          tournamentId: _tournamentId,
          participantId: 'p1',
          amount: 150000,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() {
    registerFallbackValue(const CreatePaymentDto(tournamentId: 't'));
  });

  testWidgets('TC-FEEMODE-APP-09 DIRECT blocks checkout and never pays', (
    tester,
  ) async {
    final repo = _MockPaymentRepository();
    await _pump(tester, repo, 'DIRECT');

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    expect(find.text('Thu trực tiếp'), findsWidgets);
    expect(find.text('Thanh toán trực tiếp cho BTC'), findsWidgets);
    verifyNever(() => repo.createPaymentLink(any()));
  });

  testWidgets('TC-FEEMODE-APP-10 PAYOS still creates a payment link', (
    tester,
  ) async {
    final repo = _MockPaymentRepository();
    when(() => repo.createPaymentLink(any())).thenAnswer((_) async => null);
    await _pump(tester, repo, 'PAYOS');

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pump();

    verify(() => repo.createPaymentLink(any())).called(1);
  });
}
