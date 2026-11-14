import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api_adapter.dart';
import 'create_quick_tournament_harness.dart';

Future<void> _fillAndSubmit(WidgetTester tester, {bool wait = true}) async {
  await enterName(tester, 'Giải mùa hè');
  await tapSubmit(tester, wait: wait);
}

void main() {
  setUpAll(setUpEnv);

  group('CreatePublicQuickTournamentScreen gửi form: thành công', () {
    testWidgets('gửi đúng một yêu cầu POST tới /tournaments/lite', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await _fillAndSubmit(tester);
      expect(h.submitCount, 1);
      expect(h.adapter.requests.last.method, 'POST');
      expect(h.adapter.requests.last.path, '/tournaments/lite');
    });

    testWidgets('body mang các trường cốt lõi của giải công khai', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await _fillAndSubmit(tester);
      expect(h.lastBody, containsPair('name', 'Giải mùa hè'));
      expect(h.lastBody, containsPair('sport', 'pickleball'));
      expect(h.lastBody, containsPair('tournamentType', 'PUBLIC'));
      expect(h.lastBody, containsPair('registrationMode', 'APPROVAL'));
      expect(h.lastBody, containsPair('bracketType', 'single_elimination'));
      expect(h.lastBody, containsPair('maxTeams', 16));
      expect(h.lastBody['divisions'], hasLength(1));
    });

    testWidgets('thành công thì chuyển sang trang quản lý giải vừa tạo', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      await _fillAndSubmit(tester);
      expect(find.text('MANAGE new-1'), findsOneWidget);
    });

    testWidgets('thành công hiện thông báo kèm tên giải do máy chủ trả về', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      await _fillAndSubmit(tester);
      expect(
        find.text('Tạo giải đấu "Giải mùa hè" thành công!'),
        findsOneWidget,
      );
    });

    testWidgets('máy chủ trả dữ liệu không bọc trong data vẫn đọc được id', (
      tester,
    ) async {
      final routes = defaultRoutes(
        submit: const FakeReply(201, {
          'id': 'flat-9',
          'name': 'Giải phẳng',
          'status': 'DRAFT',
        }),
      );
      await pumpCreateScreen(tester, routes: routes);
      await _fillAndSubmit(tester);
      expect(find.text('MANAGE flat-9'), findsOneWidget);
    });
  });

  group('CreatePublicQuickTournamentScreen gửi form: máy chủ báo lỗi', () {
    final failing = defaultRoutes(
      submit: const FakeReply(409, {'message': 'Tên giải đã tồn tại'}),
    );

    testWidgets('lỗi máy chủ giữ nguyên form, không chuyển trang', (
      tester,
    ) async {
      await pumpCreateScreen(tester, routes: failing);
      await _fillAndSubmit(tester);
      expect(find.textContaining('MANAGE'), findsNothing);
      expect(find.text(vi.quickCreateTitle), findsOneWidget);
    });

    testWidgets('lỗi máy chủ hiện thông báo lỗi dưới dạng snackbar', (
      tester,
    ) async {
      await pumpCreateScreen(tester, routes: failing);
      await _fillAndSubmit(tester);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Tên giải đã tồn tại'), findsOneWidget);
    });

    testWidgets('lỗi máy chủ giữ nguyên những gì người dùng đã nhập', (
      tester,
    ) async {
      await pumpCreateScreen(tester, routes: failing);
      await tester.tap(find.text('Tennis'));
      await tester.pump();
      await enterMaxTeams(tester, '24');
      await _fillAndSubmit(tester);
      expect(
        tester.widget<TextFormField>(nameField).controller!.text,
        'Giải mùa hè',
      );
      expect(tester.widget<TextField>(maxTeamsField).controller!.text, '24');
    });

    testWidgets('sau lỗi nút tạo giải mở khoá lại', (tester) async {
      await pumpCreateScreen(tester, routes: failing);
      await _fillAndSubmit(tester);
      expect(submitEnabled(tester), isTrue);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('sau lỗi bấm lại khi máy chủ ổn thì tạo được giải', (
      tester,
    ) async {
      final routes = defaultRoutes(
        submit: const FakeReply(409, {'message': 'Tên giải đã tồn tại'}),
      );
      final h = await pumpCreateScreen(tester, routes: routes);
      await _fillAndSubmit(tester);
      routes[submitRoute] = createdReply;
      await tapSubmit(tester);
      expect(h.submitCount, 2);
      expect(find.text('MANAGE new-1'), findsOneWidget);
    });

    testWidgets('lỗi 400 không kèm thông điệp thì hiện thông báo mặc định', (
      tester,
    ) async {
      final routes = defaultRoutes(submit: const FakeReply(400, {}));
      await pumpCreateScreen(tester, routes: routes);
      await _fillAndSubmit(tester);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('MANAGE'), findsNothing);
    });

    testWidgets('lỗi 403 không chuyển trang và vẫn gửi đúng một yêu cầu', (
      tester,
    ) async {
      final routes = defaultRoutes(
        submit: const FakeReply(403, {'message': 'Không có quyền'}),
      );
      final h = await pumpCreateScreen(tester, routes: routes);
      await _fillAndSubmit(tester);
      expect(h.submitCount, 1);
      expect(find.textContaining('MANAGE'), findsNothing);
    });
  });

  group('CreatePublicQuickTournamentScreen gửi form: đang gửi', () {
    testWidgets('trong lúc chờ máy chủ nút bị khoá và hiện vòng xoay', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      h.adapter.gate = Completer<void>();
      await _fillAndSubmit(tester, wait: false);
      await settle(tester, rounds: 2);
      expect(submitEnabled(tester), isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Tạo giải đấu'), findsNothing);
      h.adapter.gate!.complete();
      await settle(tester);
    });

    testWidgets('bấm thêm lần nữa khi đang gửi không tạo yêu cầu thứ hai', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      h.adapter.gate = Completer<void>();
      await _fillAndSubmit(tester, wait: false);
      await settle(tester, rounds: 2);
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await settle(tester, rounds: 2);
      h.adapter.gate!.complete();
      await settle(tester);
      expect(h.submitCount, 1);
    });

    testWidgets('xong thì chuyển sang trang quản lý giải', (tester) async {
      final h = await pumpCreateScreen(tester);
      h.adapter.gate = Completer<void>();
      await _fillAndSubmit(tester, wait: false);
      await settle(tester, rounds: 2);
      h.adapter.gate!.complete();
      await settle(tester);
      expect(find.text('MANAGE new-1'), findsOneWidget);
    });

    testWidgets('form không hợp lệ thì không bao giờ vào trạng thái đang gửi', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      await tapSubmit(tester);
      expect(submitEnabled(tester), isTrue);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
