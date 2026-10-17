import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/features/lite/screens/lite_management_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api_adapter.dart';

const _tournamentId = 't1';
const _liteBase = '/tournaments/lite/t1';

const _divisions = [
  {'id': 'd1', 'name': 'Đơn nam', 'matchType': 'SINGLES'},
  {'id': 'd2', 'name': 'Đôi nam', 'matchType': 'DOUBLES'},
];

FakeApiAdapter _adapter({Map<String, FakeReply> routes = const {}}) {
  return FakeApiAdapter({
    'GET /tournaments/$_tournamentId': FakeReply(200, {
      'status': 'OK',
      'data': {
        'id': _tournamentId,
        'name': 'Giải test',
        'matchType': 'SINGLES',
        'tournamentConfig': {'isLite': true},
        'divisions': _divisions,
      },
    }),
    'GET $_liteBase/participants': const FakeReply(200, {
      'status': 'OK',
      'data': <Object>[],
    }),
    ...routes,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );
  final l10n = lookupAppLocalizations(const Locale('vi'));

  Finder maxParticipantsField() => find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        widget.decoration?.labelText == l10n.lite_maxParticipantsLimit,
  );

  Finder formatDropdown() => find.ancestor(
    of: find.text(l10n.formatLabel),
    matching: find.byType(DropdownButtonFormField<String>),
  );

  Finder inDialog(Finder matching) =>
      find.descendant(of: find.byType(AlertDialog), matching: matching);

  // Màn có animation lặp nên pumpAndSettle không bao giờ "yên". runAsync cho
  // phép future giả của Dio hoàn tất; pump theo thời gian cố định.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpScreen(WidgetTester tester, FakeApiAdapter adapter) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioClientProvider.overrideWithValue(fakeDioClient(adapter)),
        ],
        child: MaterialApp(
          // AppTheme tải font qua google_fonts (mạng), flutter_test chặn mạng.
          theme: ThemeData.light(),
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LiteManagementScreen(tournamentId: _tournamentId),
        ),
      ),
    );
    // Chờ tab tổng quan (ListView) được dựng sau khi tải xong.
    for (var i = 0; i < 20 && find.byType(ListView).evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 500));
    }
    await settle(tester);
  }

  // Tab tổng quan là ListView lazy: card thể thức và ô sức chứa chỉ được build
  // khi cuộn tới, nên phải cuộn trước khi chạm.
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await settle(tester);
  }

  // Ô sức chứa gọi notifier sau debounce 900ms; chờ đủ thời gian giả để timer
  // chạy và hộp chọn nội dung được dựng.
  Future<void> typeMaxParticipants(WidgetTester tester, String value) async {
    await tester.enterText(maxParticipantsField(), value);
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
  }

  Future<void> pickDivisionInDialog(WidgetTester tester, String name) async {
    await tester.tap(inDialog(find.byType(DropdownButtonFormField<String>)));
    await settle(tester);
    await tester.tap(find.text(name).last);
    await settle(tester);
  }

  Iterable<String> patchPaths(FakeApiAdapter adapter) => adapter.requests
      .where((request) => request.method == 'PATCH')
      .map((request) => request.path);

  testWidgets(
    'nhập sức chứa khi chưa chọn nội dung: hỏi nội dung, huỷ thì không PATCH',
    (tester) async {
      final adapter = _adapter();
      await pumpScreen(tester, adapter);

      await scrollTo(tester, maxParticipantsField());
      await typeMaxParticipants(tester, '32');

      expect(inDialog(find.text(l10n.registerSelectDivision)), findsOneWidget);
      await tester.tap(inDialog(find.text(l10n.commonCancel)));
      await settle(tester);

      expect(patchPaths(adapter), isEmpty);
    },
  );

  testWidgets(
    'lưu thể thức khi chưa chọn nội dung: hỏi nội dung trước, huỷ thì không PATCH',
    (tester) async {
      final adapter = _adapter();
      await pumpScreen(tester, adapter);

      await scrollTo(tester, formatDropdown());
      await tester.tap(formatDropdown());
      await settle(tester);
      await tester.tap(find.text(l10n.lite_doubles).last);
      await settle(tester);
      await scrollTo(tester, find.text(l10n.matchSaveChanges));
      await tester.tap(find.text(l10n.matchSaveChanges));
      await settle(tester);

      expect(inDialog(find.text(l10n.registerSelectDivision)), findsOneWidget);
      await tester.tap(inDialog(find.text(l10n.commonCancel)));
      await settle(tester);

      expect(patchPaths(adapter), isEmpty);
    },
  );

  testWidgets(
    'chọn nội dung trong hộp rồi đổi sức chứa: chỉ PATCH nội dung vừa chọn',
    (tester) async {
      final adapter = _adapter(
        routes: {
          'PATCH /tournaments/$_tournamentId': const FakeReply(200, {
            'status': 'OK',
            'data': {},
          }),
          'PATCH /tournaments/$_tournamentId/divisions/d2/config':
              const FakeReply(200, {'status': 'OK', 'data': {}}),
        },
      );
      await pumpScreen(tester, adapter);

      await scrollTo(tester, maxParticipantsField());
      await typeMaxParticipants(tester, '32');
      await pickDivisionInDialog(tester, 'Đôi nam');
      await tester.tap(inDialog(find.text(l10n.lite_confirmButton)));
      await settle(tester);
      // Notifier đặt lại trạng thái 'saved' sau 2,5 giây bằng Future.delayed;
      // chờ hết thời gian giả để timer không còn treo khi kết thúc test.
      await tester.pump(const Duration(seconds: 3));

      expect(
        patchPaths(adapter).toList(),
        unorderedEquals([
          '/tournaments/t1',
          '/tournaments/t1/divisions/d2/config',
        ]),
      );
    },
  );
}
