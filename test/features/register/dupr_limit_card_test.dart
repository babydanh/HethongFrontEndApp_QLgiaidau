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
  int failGets = 0;

  /// Answers of successive lookups, completed by the test (oldest first).
  final getGates = <Completer<double?>>[];
  final saved = <double>[];

  @override
  Future<double?> getMyDuprRating({
    required String categoryId,
    required String matchType,
  }) async {
    getCalls++;
    if (getGates.isNotEmpty) return getGates.removeAt(0).future;
    if (failGets > 0) {
      failGets--;
      throw Exception('offline');
    }
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

Widget _host(
  _FakeRatings repo,
  TournamentDivisionOption division,
  List<bool> validity,
) => ProviderScope(
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
    );

Future<List<bool>> _pump(
  WidgetTester tester,
  _FakeRatings repo,
  TournamentDivisionOption division,
) async {
  final validity = <bool>[];
  await tester.pumpWidget(_host(repo, division, validity));
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
    final repo = _FakeRatings()..failGets = 1;
    final validity = await _pump(tester, repo, _division(min: 3.0));

    expect(find.textContaining('Không kiểm tra được điểm DUPR'), findsOne);
    expect(validity.last, isFalse);
  });

  testWidgets('lookup failure offers a retry that recovers', (tester) async {
    final repo = _FakeRatings(rating: 3.2)..failGets = 1;
    final validity = await _pump(tester, repo, _division(min: 3.0, max: 3.5));

    expect(find.byKey(const ValueKey('dupr-card-retry')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dupr-card-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dupr-card-retry')), findsNothing);
    expect(find.text('Điểm DUPR của bạn phù hợp với nội dung này'), findsOne);
    expect(validity.last, isTrue);
  });

  testWidgets('a reload that fails right after a save also offers retry', (
    tester,
  ) async {
    final repo = _FakeRatings();
    await _pump(tester, repo, _division(min: 3.0, max: 3.5));

    repo.failGets = 1;
    await tester.enterText(
      find.byKey(const ValueKey('dupr-limit-input')),
      '3.2',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('dupr-limit-save')));
    await tester.pumpAndSettle();

    expect(repo.saved, [3.2]);
    expect(find.byKey(const ValueKey('dupr-card-retry')), findsOneWidget);
  });

  testWidgets('an older lookup answering late is ignored', (tester) async {
    final repo = _FakeRatings();
    final first = Completer<double?>();
    final second = Completer<double?>();
    repo.getGates.addAll([first, second]);
    final validity = <bool>[];

    await tester.pumpWidget(
      _host(repo, _division(min: 3.0, max: 3.5), validity),
    );
    await tester.pump();
    // Same division, limit edited: starts a second lookup while the first is open.
    await tester.pumpWidget(
      _host(repo, _division(min: 3.0, max: 3.1), validity),
    );
    await tester.pump();

    second.complete(3.05);
    await tester.pumpAndSettle();
    expect(validity.last, isTrue);

    first.complete(5.0);
    await tester.pumpAndSettle();
    expect(find.text('Điểm DUPR của bạn phù hợp với nội dung này'), findsOne);
    expect(validity.last, isTrue);
  });

  testWidgets('removing the card while blocked releases the parent', (
    tester,
  ) async {
    final repo = _FakeRatings(rating: 5.0);
    final validity = await _pump(tester, repo, _division(min: 3.0, max: 3.5));
    expect(validity.last, isFalse);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();

    expect(validity.last, isTrue);
  });

  testWidgets('a save finishing after the division changed is dropped', (
    tester,
  ) async {
    final repo = _FakeRatings()..saveGate = Completer<void>();
    final validity = <bool>[];
    await tester.pumpWidget(
      _host(repo, _division(min: 3.0, max: 3.5), validity),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('dupr-limit-input')),
      '3.2',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('dupr-limit-save')));
    await tester.pump();

    final other = TournamentDivisionOption(
      id: 'div-2',
      name: 'Khác',
      matchType: 'SINGLES',
      categoryId: 'cat-2',
      minDupr: 4.0,
    );
    await tester.pumpWidget(_host(repo, other, validity));
    await tester.pump();
    final callsBefore = repo.getCalls;

    repo.saveGate!.complete();
    await tester.pumpAndSettle();

    expect(find.text('Đã lưu điểm DUPR'), findsNothing);
    // Only the new division's own lookup ran; the stale save did not reload.
    expect(repo.getCalls, callsBefore);
  });
}
