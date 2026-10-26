import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/wildcard_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock repository: ghi lại lần gán suất đặc cách (POST reserve-slots).
class _Repo implements TournamentManagementRepository {
  final reserved =
      <
        ({String email, String teamName, String? partner, String? divisionId})
      >[];

  @override
  Future<void> reserveSlots(
    String id, {
    required String userEmailOrPhone,
    required String teamName,
    String? partnerEmailOrPhone,
    String? divisionId,
  }) async {
    reserved.add((
      email: userEmailOrPhone,
      teamName: teamName,
      partner: partnerEmailOrPhone,
      divisionId: divisionId,
    ));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TournamentDivision _division(String id, String name, {bool doubles = false}) =>
    TournamentDivision(
      id: id,
      name: name,
      matchType: doubles ? 'DOUBLES' : 'SINGLES',
    );

/// Trang chủ có nút mở sheet: sheet chạy trong modal route thật nên đóng
/// được bằng Navigator.pop (pump trực tiếp vào home thì route gốc không pop
/// được).
Widget _app(
  _Repo repo,
  Future<void> Function(BuildContext context) openSheet,
) => ProviderScope(
  overrides: [
    tournamentManagementRepositoryProvider.overrideWith((ref) => repo),
  ],
  child: MaterialApp(
    theme: AppTheme.darkTheme,
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            key: const ValueKey('open-sheet'),
            onPressed: () => openSheet(context),
            child: const Text('Mở sheet'),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.tap(find.byKey(const ValueKey('open-sheet')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'TC-WP-03-08: suất đặc cách — validate email/tên đội chặn gửi, hợp lệ thì POST đúng payload',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _Repo();
      await _open(
        tester,
        _app(
          repo,
          (context) => WildcardSheet.show(
            context,
            tournamentId: 't1',
            divisions: [
              _division('div-1', 'Đơn nam'),
              _division('div-2', 'Đôi nam nữ', doubles: true),
            ],
            initialDivisionId: 'div-2',
          ),
        ),
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(WildcardSheet)),
      )!;

      // Nội dung đôi: hiện ô đồng đội; chưa nhập gì thì bấm gán báo thiếu.
      expect(find.byKey(const ValueKey('wildcard-partner')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('wildcard-division-select')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('wildcard-submit')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.wildcardContactRequired), findsOneWidget);
      expect(repo.reserved, isEmpty);

      // Email sai định dạng (có '@' nhưng thiếu domain) bị chặn.
      await tester.enterText(
        find.byKey(const ValueKey('wildcard-contact')),
        'nguoi-choi@',
      );
      await tester.enterText(
        find.byKey(const ValueKey('wildcard-team-name')),
        'Đội Khách Mời',
      );
      await tester.tap(find.byKey(const ValueKey('wildcard-submit')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.wildcardContactInvalid), findsOneWidget);
      expect(repo.reserved, isEmpty);

      // Đủ thông tin: POST với email, đồng đội, tên đội và hạng mục đang chọn.
      await tester.enterText(
        find.byKey(const ValueKey('wildcard-contact')),
        'nguoi-choi@test.vn',
      );
      await tester.enterText(
        find.byKey(const ValueKey('wildcard-partner')),
        'doi-test@test.vn',
      );
      await tester.tap(find.byKey(const ValueKey('wildcard-submit')));
      await tester.pumpAndSettle();

      expect(repo.reserved, hasLength(1));
      expect(repo.reserved.single.email, 'nguoi-choi@test.vn');
      expect(repo.reserved.single.partner, 'doi-test@test.vn');
      expect(repo.reserved.single.teamName, 'Đội Khách Mời');
      expect(repo.reserved.single.divisionId, 'div-2');
      expect(find.byType(WildcardSheet), findsNothing);
    },
  );

  testWidgets(
    'TC-WP-03-08b: nội dung đơn — không có ô đồng đội, gửi bằng SĐT không kèm partner',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _Repo();
      await _open(
        tester,
        _app(
          repo,
          (context) => WildcardSheet.show(
            context,
            tournamentId: 't1',
            divisions: [_division('div-1', 'Đơn nam')],
            initialDivisionId: 'div-1',
          ),
        ),
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(WildcardSheet)),
      )!;

      expect(find.byKey(const ValueKey('wildcard-partner')), findsNothing);
      // Thiếu tên đội vẫn bị chặn theo validate.
      await tester.enterText(
        find.byKey(const ValueKey('wildcard-contact')),
        '0912345678',
      );
      await tester.tap(find.byKey(const ValueKey('wildcard-submit')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.wildcardTeamNameRequired), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('wildcard-team-name')),
        'Đội SĐT',
      );
      await tester.tap(find.byKey(const ValueKey('wildcard-submit')));
      await tester.pumpAndSettle();

      expect(repo.reserved.single.email, '0912345678');
      expect(repo.reserved.single.partner, isNull);
      expect(repo.reserved.single.teamName, 'Đội SĐT');
      expect(repo.reserved.single.divisionId, 'div-1');
      expect(find.byType(WildcardSheet), findsNothing);
    },
  );
}
