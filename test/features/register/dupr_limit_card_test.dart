import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:app_quanly_giaidau/domain/repositories/external_rating_repository.dart';
import 'package:app_quanly_giaidau/features/register/widgets/dupr_limit_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRatings implements ExternalRatingRepository {
  _FakeRatings({this.rating, this.saveError});

  double? rating;
  Object? saveError;
  Completer<void>? saveGate;
  int getCalls = 0;
  final saved = <double>[];

  @override
  Future<double?> getMyDuprRating({
    required String categoryId,
    required String matchType,
  }) async {
    getCalls++;
    return rating;
  }

  @override
  Future<void> saveMyDuprRating({
    required String categoryId,
    required String matchType,
    required double value,
  }) async {
    await saveGate?.future;
    if (saveError != null) throw saveError!;
    saved.add(value);
    rating = value;
  }
}

TournamentDivisionOption _division({double? min, double? max}) =>
    TournamentDivisionOption(
      id: 'div-1',
      name: 'Đôi 3.0',
      matchType: 'DOUBLES',
      categoryId: 'cat-1',
      minDupr: min,
      maxDupr: max,
    );

Future<List<bool>> _pump(
  WidgetTester tester,
  _FakeRatings repo,
  TournamentDivisionOption division,
) async {
  final validity = <bool>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [externalRatingRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: DuprLimitCard(
              division: division,
              onValidityChanged: validity.add,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return validity;
}

void main() {
  testWidgets('no limit: nothing shown and the repository is never called', (
    tester,
  ) async {
    final repo = _FakeRatings(rating: 3.2);
    final validity = await _pump(tester, repo, _division());

    expect(repo.getCalls, 0);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('DUPR'), findsNothing);
    expect(validity.isEmpty || validity.last, isTrue);
  });

  testWidgets('3.2 inside 3.0 - 3.5 is valid', (tester) async {
    final repo = _FakeRatings(rating: 3.2);
    final validity = await _pump(tester, repo, _division(min: 3.0, max: 3.5));

    expect(repo.getCalls, 1);
    expect(find.text('Điểm DUPR của bạn phù hợp với nội dung này'), findsOne);
    expect(validity.last, isTrue);
  });

  testWidgets('3.62 above max 3.5 is blocked and names the range', (
    tester,
  ) async {
    final repo = _FakeRatings(rating: 3.62);
    final validity = await _pump(tester, repo, _division(min: 3.0, max: 3.5));

    expect(find.textContaining('cao hơn'), findsOneWidget);
    expect(find.textContaining('3.0 – 3.5'), findsOneWidget);
    expect(find.textContaining('3.62'), findsOneWidget);
    expect(validity.last, isFalse);
  });

  testWidgets('below min is blocked', (tester) async {
    final repo = _FakeRatings(rating: 2.5);
    final validity = await _pump(tester, repo, _division(min: 3.0, max: 3.5));

    expect(find.textContaining('thấp hơn'), findsOneWidget);
    expect(validity.last, isFalse);
  });

  testWidgets('missing rating: declaring it then makes the card valid', (
    tester,
  ) async {
    final repo = _FakeRatings();
    final validity = await _pump(tester, repo, _division(min: 3.0, max: 3.5));

    expect(validity.last, isFalse);
    await tester.enterText(
      find.byKey(const ValueKey('dupr-limit-input')),
      '3,2',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('dupr-limit-save')));
    await tester.pumpAndSettle();

    expect(repo.saved, [3.2]);
    expect(find.text('Điểm DUPR của bạn phù hợp với nội dung này'), findsOne);
    expect(validity.last, isTrue);
  });

  testWidgets('save button is disabled while the save is in flight', (
    tester,
  ) async {
    final repo = _FakeRatings()..saveGate = Completer<void>();
    await _pump(tester, repo, _division(min: 3.0, max: 3.5));

    await tester.enterText(
      find.byKey(const ValueKey('dupr-limit-input')),
      '3.2',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('dupr-limit-save')));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('dupr-limit-save')),
    );
    expect(button.onPressed, isNull);

    repo.saveGate!.complete();
    await tester.pumpAndSettle();
    expect(repo.saved, [3.2]);
  });

  testWidgets('failed save keeps the typed number and re-enables the button', (
    tester,
  ) async {
    final repo = _FakeRatings(saveError: Exception('network'));
    final validity = await _pump(tester, repo, _division(min: 3.0, max: 3.5));

    await tester.enterText(
      find.byKey(const ValueKey('dupr-limit-input')),
      '3.62',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('dupr-limit-save')));
    await tester.pumpAndSettle();

    expect(find.text('Không lưu được điểm DUPR. Vui lòng thử lại.'), findsOne);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('dupr-limit-input')),
    );
    expect(field.controller!.text, '3.62');
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('dupr-limit-save')),
    );
    expect(button.onPressed, isNotNull);
    expect(validity.last, isFalse);
  });

  testWidgets('rating lookup failure blocks and says so', (tester) async {
    final repo = _FakeRatings();
    // Force the GET to throw.
    final failing = _ThrowingGet(repo);
    final validity = await _pump(tester, failing, _division(min: 3.0));

    expect(find.textContaining('Không kiểm tra được điểm DUPR'), findsOne);
    expect(validity.last, isFalse);
  });
}

class _ThrowingGet extends _FakeRatings {
  _ThrowingGet(_FakeRatings _);

  @override
  Future<double?> getMyDuprRating({
    required String categoryId,
    required String matchType,
  }) async => throw Exception('offline');
}
