import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/mock_participants_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock repository: ghi lại lần sinh VĐV ảo (POST mock-participants) và lần
/// dọn dẹp (DELETE mock-participants) để khẳng định đúng payload/route.
class _Repo implements TournamentManagementRepository {
  final seeds =
      <({List<String> names, String? divisionId, String? pairingMode})>[];
  final cleared = <String?>[];

  @override
  Future<void> seedMockParticipants(
    String id,
    List<String> names, {
    String? divisionId,
    String? pairingMode,
  }) async {
    seeds.add((names: names, divisionId: divisionId, pairingMode: pairingMode));
  }

  @override
  Future<void> clearMockParticipants(String id, {String? divisionId}) async {
    cleared.add(divisionId);
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

Future<void> _enterNames(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const ValueKey('mock-names')), text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'TC-WP-03-06: sinh VĐV ảo — nội dung đôi chọn chế độ ghép, gửi đúng payload rồi tự đóng',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _Repo();
      final divisions = [
        _division('div-1', 'Đơn nam'),
        _division('div-2', 'Đôi nam nữ', doubles: true),
      ];
      await _open(
        tester,
        _app(
          repo,
          (context) => MockParticipantsSheet.show(
            context,
            tournamentId: 't1',
            divisions: divisions,
            initialDivisionId: 'div-2',
          ),
        ),
      );

      // Nội dung đôi: hiện bộ chọn chế độ ghép, mặc định AUTO; chưa nhập tên
      // thì nút sinh bị khoá (Web: disabled khi danh sách tên trống).
      expect(
        find.byKey(const ValueKey('mock-division-select')),
        findsOneWidget,
      );
      expect(find.text('Chế độ ghép cặp'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('mock-generate')))
            .enabled,
        isFalse,
      );

      await _enterNames(tester, 'Nguyễn A\nNguyễn B\nTrần C');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('mock-generate')))
            .enabled,
        isTrue,
      );
      await tester.tap(find.byKey(const ValueKey('mock-generate')));
      await tester.pumpAndSettle();

      // Một lần POST với đủ 3 tên, đúng hạng mục và chế độ AUTO; sheet đóng.
      expect(repo.seeds, hasLength(1));
      expect(repo.seeds.single.names, ['Nguyễn A', 'Nguyễn B', 'Trần C']);
      expect(repo.seeds.single.divisionId, 'div-2');
      expect(repo.seeds.single.pairingMode, 'AUTO');
      expect(find.byType(MockParticipantsSheet), findsNothing);

      // Mở lại và đổi sang chế độ sinh VĐV lẻ: gửi INDIVIDUAL_WAITING.
      await _open(
        tester,
        _app(
          repo,
          (context) => MockParticipantsSheet.show(
            context,
            tournamentId: 't1',
            divisions: divisions,
            initialDivisionId: 'div-2',
          ),
        ),
      );
      await _enterNames(tester, 'Lê D');
      await tester.tap(
        find.byKey(const ValueKey('mock-pair-mode-individualWaiting')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mock-generate')));
      await tester.pumpAndSettle();

      expect(repo.seeds, hasLength(2));
      expect(repo.seeds.last.pairingMode, 'INDIVIDUAL_WAITING');
      expect(repo.seeds.last.divisionId, 'div-2');
      expect(find.byType(MockParticipantsSheet), findsNothing);
    },
  );

  testWidgets(
    'TC-WP-03-06b: nội dung đơn — không có bộ chọn chế độ ghép, nút sinh theo chế độ thường',
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
          (context) => MockParticipantsSheet.show(
            context,
            tournamentId: 't1',
            divisions: [_division('div-1', 'Đơn nam')],
            initialDivisionId: 'div-1',
          ),
        ),
      );

      expect(find.text('Chế độ ghép cặp'), findsNothing);
      expect(find.byKey(const ValueKey('mock-pair-mode-auto')), findsNothing);
      await _enterNames(tester, 'Nguyễn A');
      await tester.tap(find.byKey(const ValueKey('mock-generate')));
      await tester.pumpAndSettle();

      expect(repo.seeds.single.names, ['Nguyễn A']);
      expect(repo.seeds.single.pairingMode, 'AUTO');
      expect(repo.seeds.single.divisionId, 'div-1');
    },
  );

  testWidgets(
    'TC-WP-03-07: dọn dẹp VĐV ảo — huỷ confirm không gọi API, xác nhận thì DELETE đúng hạng mục',
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
          (context) => MockParticipantsSheet.show(
            context,
            tournamentId: 't1',
            divisions: [
              _division('div-1', 'Đơn nam'),
              _division('div-2', 'Đôi nam nữ', doubles: true),
            ],
            initialDivisionId: 'div-1',
          ),
        ),
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(MockParticipantsSheet)),
      )!;

      // Bấm Dọn dẹp hiện confirm; bấm Huỷ thì không gọi API.
      await tester.tap(find.byKey(const ValueKey('mock-clear')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.mockClearConfirmMessage), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(l10n.tournamentManagementCancel),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.cleared, isEmpty);

      // Xác nhận lần nữa: DELETE kèm divisionId, sheet giữ nguyên để tiếp tục.
      // Nút confirm trong dialog là FilledButton (tiêu đề dialog trùng nhãn
      // nên phải bấm theo loại nút).
      await tester.tap(find.byKey(const ValueKey('mock-clear')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l10n.mockClear));
      await tester.pumpAndSettle();

      expect(repo.cleared, ['div-1']);
      expect(find.byType(MockParticipantsSheet), findsOneWidget);
      expect(find.text(l10n.mockCleared), findsOneWidget);
    },
  );
}
