import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'create_quick_tournament_harness.dart';

void main() {
  setUpAll(setUpEnv);

  group('CreatePublicQuickTournamentScreen thông tin cơ bản', () {
    testWidgets('hiện tiêu đề, công tắc công khai và nút tạo giải', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      expect(find.text(vi.quickCreateTitle), findsOneWidget);
      expect(find.text('Công khai'), findsOneWidget);
      expect(submitEnabled(tester), isTrue);
    });

    testWidgets('mặc định công khai và đã chọn 1 nội dung', (tester) async {
      await pumpCreateScreen(tester);
      expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
      expect(find.text('Đã chọn 1 nội dung'), findsOneWidget);
    });

    testWidgets('ô tên trống: báo bắt buộc và không gửi yêu cầu', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await tapSubmit(tester);
      expect(find.text(vi.quickCreateNameRequired), findsOneWidget);
      expect(h.submitCount, 0);
    });

    testWidgets('tên chỉ gồm khoảng trắng bị coi là trống', (tester) async {
      final h = await pumpCreateScreen(tester);
      await enterName(tester, '     ');
      await tapSubmit(tester);
      expect(find.text(vi.quickCreateNameRequired), findsOneWidget);
      expect(h.submitCount, 0);
    });

    testWidgets('tên 2 ký tự bị từ chối vì ngắn hơn 3 ký tự', (tester) async {
      final h = await pumpCreateScreen(tester);
      await enterName(tester, 'ab');
      await tapSubmit(tester);
      expect(find.text('Tên giải đấu phải có ít nhất 3 ký tự'), findsOneWidget);
      expect(h.submitCount, 0);
    });

    testWidgets('tên 3 ký tự là hợp lệ và được gửi đi', (tester) async {
      final h = await pumpCreateScreen(tester);
      await enterName(tester, 'abc');
      await tapSubmit(tester);
      expect(find.text('Tên giải đấu phải có ít nhất 3 ký tự'), findsNothing);
      expect(h.submitCount, 1);
      expect(h.lastBody['name'], 'abc');
    });

    testWidgets('tên có khoảng trắng hai đầu được cắt trước khi gửi', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await enterName(tester, '  Giải mùa hè  ');
      await tapSubmit(tester);
      expect(h.lastBody['name'], 'Giải mùa hè');
    });

    testWidgets('lỗi tên biến mất sau khi nhập tên hợp lệ và gửi lại', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await tapSubmit(tester);
      expect(find.text(vi.quickCreateNameRequired), findsOneWidget);
      await enterName(tester, 'Giải mùa hè');
      await tapSubmit(tester);
      expect(find.text(vi.quickCreateNameRequired), findsNothing);
      expect(h.submitCount, 1);
    });

    testWidgets('tắt công khai thì gửi visibility PRIVATE', (tester) async {
      final h = await pumpCreateScreen(tester);
      await tester.tap(find.byType(Switch).first);
      await tester.pump();
      await enterName(tester, 'Giải riêng tư');
      await tapSubmit(tester);
      expect(h.lastBody['visibility'], 'PRIVATE');
      expect(h.lastBody['tournamentType'], 'PUBLIC');
    });

    testWidgets('để nguyên công khai thì gửi visibility PUBLIC', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await enterName(tester, 'Giải công khai');
      await tapSubmit(tester);
      expect(h.lastBody['visibility'], 'PUBLIC');
    });

    testWidgets('không nhập mô tả thì body không có khoá description', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await enterName(tester, 'Giải không mô tả');
      await tapSubmit(tester);
      expect(h.lastBody.containsKey('description'), isFalse);
    });

    testWidgets('mũi tên quay lại về trang chủ khi không có trang trước', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await settle(tester);
      expect(find.text('HOME PAGE'), findsOneWidget);
    });

    testWidgets('người không phải BTC bị chặn bằng hộp thoại yêu cầu BTC', (
      tester,
    ) async {
      await pumpCreateScreen(tester, roles: const ['USER']);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('ADMIN được tạo giải mà không bị chặn', (tester) async {
      await pumpCreateScreen(tester, roles: const ['ADMIN']);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('hộp thoại yêu cầu BTC nêu tiêu đề và mô tả', (tester) async {
      await pumpCreateScreen(tester, roles: const ['USER']);
      expect(find.text(vi.organizer_reqTitle), findsOneWidget);
      expect(find.text(vi.organizer_reqDesc), findsOneWidget);
    });

    testWidgets('người không phải BTC đóng hộp thoại rồi bấm tạo giải vẫn bị '
        'chặn và không gửi yêu cầu', (tester) async {
      final h = await pumpCreateScreen(tester, roles: const ['USER']);
      await tester.tap(find.text(vi.commonCancel));
      await settle(tester);
      expect(find.byType(AlertDialog), findsNothing);
      await enterName(tester, 'Giải thử');
      await tapSubmit(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(h.submitCount, 0);
    });
  });
}
