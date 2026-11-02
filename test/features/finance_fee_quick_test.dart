import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_finance_section.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/platform_fee.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// TC-WP-01-08: sửa lệ phí nhanh trong màn Tài chính — nút mức phí nhanh
/// (0đ / +20k / +50k / +100k / +200k) cộng dồn vào ô nhập, không giới hạn
/// trên (Web không có trần), và bảng phân tích phí sàn cập nhật theo giá trị
/// đang nhập với đúng công thức `getPlatformFeeBreakdown`.
Tournament _tournament({required String status, num entryFee = 100000}) =>
    Tournament.fromJson({
      'name': 'City Pickleball Cup',
      'sport': 'pickleball',
      'format': 'doubles',
      'bracketType': 'single_elimination',
      'status': status,
      'creatorId': 'user-1',
      'entryFee': entryFee,
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-01T00:00:00Z',
    }, 'tournament-1');

Widget _app({required Tournament tournament, bool focusEntryFee = false}) =>
    ProviderScope(
  overrides: [
    tournamentManagementRepositoryProvider.overrideWithValue(
      _FinanceRepository(),
    ),
    userProfileProvider.overrideWith(
      (ref) async => const UserProfile(id: 'user-1', role: 'ORGANIZER'),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: TournamentManagementFinanceSection(
        tournament: tournament,
        focusEntryFee: focusEntryFee,
      ),
    ),
  ),
);

Finder _quickButton(String label) =>
    find.widgetWithText(OutlinedButton, label, skipOffstage: false);

Future<void> _tapQuick(WidgetTester tester, String label) async {
  await tester.ensureVisible(_quickButton(label));
  await tester.pump();
  await tester.tap(_quickButton(label));
  await tester.pump();
}

void main() {
  late NumberFormat money;
  late AppLocalizations l10n;

  setUpAll(() async {
    money = NumberFormat.currency(
      locale: 'en',
      name: 'VND',
      symbol: '₫',
      decimalDigits: 0,
    );
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('TC-EDIT-05 focusEntryFee puts the cursor in the fee field', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(tournament: _tournament(status: 'DRAFT'), focusEntryFee: true),
    );
    await tester.pumpAndSettle();

    final feeInput = find.descendant(
      of: find.widgetWithText(TextField, '100000'),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(feeInput).focusNode.hasFocus, isTrue);
  });

  testWidgets('without focusEntryFee the fee field is not focused', (
    tester,
  ) async {
    await tester.pumpWidget(_app(tournament: _tournament(status: 'DRAFT')));
    await tester.pumpAndSettle();

    final feeInput = find.descendant(
      of: find.widgetWithText(TextField, '100000'),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(feeInput).focusNode.hasFocus, isFalse);
  });

  testWidgets('TC-WP-01-08 nút mức nhanh cộng dồn và bảng phân tích đúng số', (
    tester,
  ) async {
    await tester.pumpWidget(_app(tournament: _tournament(status: 'DRAFT')));
    await tester.pumpAndSettle();

    // Giá trị ban đầu: ô 100000; lệ phí >= ngưỡng 100000 -> phí 5% = 5000.
    expect(find.widgetWithText(TextField, '100000'), findsOneWidget);
    expect(find.text(money.format(100000)), findsOneWidget);
    expect(find.text('-${money.format(5000)}'), findsOneWidget);
    expect(find.text(money.format(95000)), findsOneWidget);

    // Bấm +20k hai lần -> 140000; phí 140000 x 5% = 7000, BTC nhận 133000.
    await _tapQuick(tester, l10n.financeFeeQuickAdd(20));
    await _tapQuick(tester, l10n.financeFeeQuickAdd(20));
    expect(find.widgetWithText(TextField, '140000'), findsOneWidget);
    expect(find.text('-${money.format(7000)}'), findsOneWidget);
    expect(find.text(money.format(133000)), findsOneWidget);

    // +200k hai lần -> 540000: Web không giới hạn trên, lệ phí cứ cộng dồn.
    await _tapQuick(tester, l10n.financeFeeQuickAdd(200));
    await _tapQuick(tester, l10n.financeFeeQuickAdd(200));
    expect(find.widgetWithText(TextField, '540000'), findsOneWidget);
    expect(find.text('-${money.format(27000)}'), findsOneWidget);
    expect(find.text(money.format(513000)), findsOneWidget);

    // Bấm 0đ -> ô về 0, hiển thị Miễn phí, phí 0, BTC nhận 0.
    await _tapQuick(tester, l10n.financeFeeQuickFree);
    expect(find.widgetWithText(TextField, '0'), findsOneWidget);
    expect(find.text(l10n.financeFeeFreeLabel), findsOneWidget);
    // Cả dòng phí sàn lẫn dòng BTC nhận đều hiển thị 0₫.
    expect(find.text(money.format(0)), findsNWidgets(2));
  });

  testWidgets('TC-WP-01-08 lệ phí dưới ngưỡng dùng phí cố định theo Web', (
    tester,
  ) async {
    // 50000 < ngưỡng 100000 -> phí cố định 5000, BTC nhận 45000.
    await tester.pumpWidget(
      _app(tournament: _tournament(status: 'DRAFT', entryFee: 50000)),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '50000'), findsOneWidget);
    expect(find.text('-${money.format(5000)}'), findsOneWidget);
    expect(find.text(money.format(45000)), findsOneWidget);
  });

  testWidgets('TC-WP-01-08 giải đã khoá thì nút nhanh vô hiệu như ô nhập', (
    tester,
  ) async {
    await tester.pumpWidget(_app(tournament: _tournament(status: 'COMPLETED')));
    await tester.pumpAndSettle();

    // Bảng phân tích vẫn hiện (chỉ đọc) nhưng mọi nút nhanh bị khoá.
    expect(find.text(money.format(95000)), findsOneWidget);
    final addButton = tester.widget<OutlinedButton>(
      _quickButton(l10n.financeFeeQuickAdd(20)),
    );
    expect(addButton.onPressed, isNull);
    final freeButton = tester.widget<OutlinedButton>(
      _quickButton(l10n.financeFeeQuickFree),
    );
    expect(freeButton.onPressed, isNull);
  });

  testWidgets('số bảng phân tích khớp util getPlatformFeeBreakdown', (
    tester,
  ) async {
    await tester.pumpWidget(_app(tournament: _tournament(status: 'DRAFT')));
    await tester.pumpAndSettle();

    final breakdown = getPlatformFeeBreakdown(100000, platformFeePercentage: 5);
    expect(breakdown.feePerPlayer, 5000);
    expect(breakdown.organizerNet, 95000);
    expect(
      find.text('-${money.format(breakdown.feePerPlayer)}'),
      findsOneWidget,
    );
    expect(find.text(money.format(breakdown.organizerNet)), findsOneWidget);
  });
}

class _FinanceRepository implements TournamentManagementRepository {
  @override
  Future<Map<String, dynamic>> getFeesConfig() async => {
    'allowEntryFees': true,
    // Giải public không xếp hạng (isRanked=false, không communityId).
    'pctPublicUnranked': 5,
    'feePublicUnranked': 50000,
  };

  @override
  Future<List<Map<String, dynamic>>> getMyPayouts() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
