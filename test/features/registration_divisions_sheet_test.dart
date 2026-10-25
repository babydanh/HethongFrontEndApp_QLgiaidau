import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/registration_divisions_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock repository: ghi lại mỗi lần đóng theo nhóm id và mở lại theo
/// divisionIds + hạn mới (POST close/reopen-registration).
class _Repo implements TournamentManagementRepository {
  final closedBatches = <List<String>>[];
  final reopened = <({List<String>? divisionIds, DateTime? endDate})>[];

  @override
  Future<Map<String, dynamic>> closeDivisionRegistrations(
    String id,
    List<String> divisionIds,
  ) async {
    closedBatches.add(List.of(divisionIds));
    return const {};
  }

  @override
  Future<Map<String, dynamic>> reopenRegistration(
    String id, {
    DateTime? registrationEndDate,
    List<String>? divisionIds,
  }) async {
    reopened.add((divisionIds: divisionIds, endDate: registrationEndDate));
    return const {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _division(
  String id,
  String name, {
  bool open = true,
  int? max,
  int registered = 0,
  String? deadline,
}) => {
  'id': id,
  'name': name,
  'matchType': 'SINGLES',
  'bracketType': 'SINGLE_ELIMINATION',
  if (max != null) 'maxParticipants': max,
  '_count': {'participants': registered},
  'registrationOpen': open,
  if (deadline != null) 'registrationEndDate': deadline,
};

/// Trang chủ có nút mở sheet: sheet chạy trong modal route thật nên đóng
/// được bằng maybePop (pump trực tiếp vào home thì route gốc không pop được).
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
    'TC-WP-01-05: hạng mục đủ chỗ — prompt liệt kê đúng, đóng theo từng hàng, giữ mở không gửi',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _Repo();
      final decided = <String>[];
      await _open(
        tester,
        _app(
          repo,
          (context) => FullDivisionsPromptSheet.show(
            context,
            tournamentId: 't1',
            divisions: [
              _division('div-1', 'Đơn Nam', max: 32, registered: 32),
              _division('div-2', 'Đôi Nữ', max: 16, registered: 16),
            ],
            onDecided: decided.add,
          ),
        ),
      );

      // Chỉ 2 hàng đủ chỗ; hiện đúng số đã đăng ký/sức chứa.
      expect(find.text('Đơn Nam'), findsOneWidget);
      expect(find.text('Đôi Nữ'), findsOneWidget);
      expect(find.textContaining('32/32'), findsOneWidget);
      expect(find.textContaining('16/16'), findsOneWidget);

      // Đóng div-1: một lần close đúng [div-1].
      await tester.tap(find.byKey(const ValueKey('division-full-close-div-1')));
      await tester.pumpAndSettle();
      expect(repo.closedBatches, [
        ['div-1'],
      ]);
      expect(decided, contains('div-1'));

      // Giữ mở div-2: không thêm lần close nào, chỉ đánh dấu đã hỏi.
      await tester.tap(find.byKey(const ValueKey('division-full-keep-div-2')));
      await tester.pumpAndSettle();
      expect(repo.closedBatches, hasLength(1));
      expect(decided, contains('div-2'));
      // Quyết hết hai hàng thì sheet tự đóng.
      expect(find.byType(FullDivisionsPromptSheet), findsNothing);
    },
  );

  testWidgets(
    'TC-WP-01-06: đóng hàng loạt — chọn sẵn hạng mục đang mở, một lần close đúng nhóm id',
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
          (context) => RegistrationDivisionsBulkSheet.show(
            context,
            tournamentId: 't1',
            tournamentStatus: 'REGISTRATION_OPEN',
            tournamentDeadline: null,
            divisions: [
              _division('div-1', 'Đơn Nam A'),
              _division('div-2', 'Đơn Nam B'),
              _division('div-3', 'Đôi Nam'),
              _division('div-4', 'Đơn Nữ', open: false),
            ],
          ),
        ),
      );

      // Chế độ đóng: 3 hạng mục đang mở được chọn sẵn; hạng mục đã đóng mờ.
      expect(find.text('Đóng 3 hạng mục'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('division-bulk-row-div-4')),
          matching: find.byType(Checkbox),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('division-bulk-confirm')));
      await tester.pumpAndSettle();

      // Một lần gọi duy nhất với đúng 3 id đang mở.
      expect(repo.closedBatches, hasLength(1));
      expect(
        repo.closedBatches.single,
        containsAll(['div-1', 'div-2', 'div-3']),
      );
      expect(repo.closedBatches.single, isNot(contains('div-4')));
      expect(find.byType(RegistrationDivisionsBulkSheet), findsNothing);
    },
  );

  testWidgets(
    'TC-WP-01-07: mở lại hạng mục quá hạn — bắt chọn hạn mới rồi mới gửi reopen',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _Repo();
      final newDeadline = DateTime.now().add(const Duration(days: 3));
      await _open(
        tester,
        _app(
          repo,
          (context) => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => RegistrationDivisionsBulkSheet(
              tournamentId: 't1',
              tournamentStatus: 'REGISTRATION_CLOSED',
              tournamentDeadline: null,
              initialMode: RegistrationDivisionsMode.open,
              pickDeadline: (_) async => newDeadline,
              divisions: [
                _division(
                  'div-1',
                  'Đơn Nam',
                  open: false,
                  deadline: DateTime.now()
                      .subtract(const Duration(days: 1))
                      .toIso8601String(),
                ),
              ],
            ),
          ),
        ),
      );

      // Chế độ mở lại: hạng mục đã đóng được chọn sẵn nhưng quá hạn → nút
      // xác nhận bị khoá tới khi chọn hạn mới ở tương lai.
      expect(find.text('Mở lại 1 hạng mục'), findsOneWidget);
      final confirm = find.byKey(const ValueKey('division-bulk-confirm'));
      expect(tester.widget<FilledButton>(confirm).enabled, isFalse);

      await tester.tap(
        find.byKey(const ValueKey('division-bulk-pick-deadline')),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(confirm).enabled, isTrue);

      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(repo.reopened, hasLength(1));
      expect(repo.reopened.single.divisionIds, ['div-1']);
      expect(repo.reopened.single.endDate, newDeadline);
    },
  );
}
