import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'create_quick_tournament_harness.dart';

final _address = find.byWidgetPredicate(
  (w) =>
      w is TextField &&
      w.decoration?.hintText == 'VD: 238 Kỳ Đồng, Quận 3, TP.HCM',
);

Future<void> _chooseProvince(WidgetTester tester, String name) async {
  await tester.tap(find.text('Chọn tỉnh'));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.text(name).last);
  await settle(tester);
}

Future<void> _chooseWard(WidgetTester tester, String name) async {
  await tester.tap(find.text('Chọn phường'));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.text(name).last);
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _submit(WidgetTester tester) async {
  await enterName(tester, 'Giải khu vực');
  await tapSubmit(tester);
}

void main() {
  setUpAll(setUpEnv);

  group('CreatePublicQuickTournamentScreen tỉnh và phường', () {
    testWidgets('chưa chọn tỉnh thì ô phường nhắc "Chọn tỉnh trước"', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      expect(find.text('Chọn tỉnh'), findsOneWidget);
      expect(find.text('Chọn tỉnh trước'), findsOneWidget);
    });

    testWidgets('không chọn khu vực thì body không có tỉnh và phường', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await _submit(tester);
      for (final key in ['province', 'provinceCode', 'ward', 'wardCode']) {
        expect(h.lastBody.containsKey(key), isFalse, reason: key);
      }
    });

    testWidgets('chọn tỉnh thì gửi tên và mã tỉnh', (tester) async {
      final h = await pumpCreateScreen(tester);
      await _chooseProvince(tester, 'Hà Nội');
      await _submit(tester);
      expect(h.lastBody['province'], 'Hà Nội');
      expect(h.lastBody['provinceCode'], '01');
      expect(h.lastBody.containsKey('wardCode'), isFalse);
    });

    testWidgets('chọn tỉnh xong ô phường chuyển sang "Chọn phường"', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      await _chooseProvince(tester, 'TP. Hồ Chí Minh');
      expect(find.text('Chọn phường'), findsOneWidget);
    });

    testWidgets('chọn tỉnh và phường thì gửi cả hai cặp tên và mã', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await _chooseProvince(tester, 'TP. Hồ Chí Minh');
      await _chooseWard(tester, 'Phường Bến Nghé');
      await _submit(tester);
      expect(h.lastBody['provinceCode'], '79');
      expect(h.lastBody['wardCode'], '9001');
      expect(h.lastBody['ward'], 'Phường Bến Nghé');
    });

    testWidgets('chọn phường gọi API phường theo mã tỉnh đã chọn', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await _chooseProvince(tester, 'TP. Hồ Chí Minh');
      final wardCalls = h.adapter.requests.where(
        (r) => r.path == '/regions/wards',
      );
      expect(wardCalls.single.query['provinceCode'], '79');
    });

    testWidgets('đổi sang tỉnh khác thì phường đã chọn bị xoá', (tester) async {
      final h = await pumpCreateScreen(tester);
      await _chooseProvince(tester, 'TP. Hồ Chí Minh');
      await _chooseWard(tester, 'Phường Bến Nghé');
      await tester.tap(find.text('TP. Hồ Chí Minh').last);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Hà Nội').last);
      await settle(tester);
      await _submit(tester);
      expect(h.lastBody['provinceCode'], '01');
      expect(h.lastBody.containsKey('wardCode'), isFalse);
    });

    testWidgets(
      'không tải được danh sách tỉnh thì vẫn tạo được giải không có khu vực',
      (tester) async {
        final routes = defaultRoutes()..remove('GET /regions/provinces');
        final h = await pumpCreateScreen(tester, routes: routes);
        await _submit(tester);
        expect(h.submitCount, 1);
        expect(h.lastBody.containsKey('provinceCode'), isFalse);
      },
    );
  });

  group('CreatePublicQuickTournamentScreen nhận diện địa chỉ', () {
    testWidgets('địa chỉ có tên tỉnh thì hiện gợi ý "Đã tự nhận diện"', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      await tester.enterText(_address, '238 Kỳ Đồng, Quận 3, Hà Nội');
      await settle(tester);
      expect(find.textContaining(vi.lite_aiDetectedAddress), findsOneWidget);
      expect(find.textContaining('Hà Nội'), findsWidgets);
    });

    testWidgets('bấm Áp dụng điền tỉnh đã nhận diện vào ô tỉnh', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await tester.enterText(_address, '238 Kỳ Đồng, Quận 3, Hà Nội');
      await settle(tester);
      await tester.tap(find.text(vi.filterApply));
      await settle(tester);
      await _submit(tester);
      expect(h.lastBody['provinceCode'], '01');
    });

    testWidgets('chưa bấm Áp dụng thì gợi ý chưa ảnh hưởng tới body', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await tester.enterText(_address, '238 Kỳ Đồng, Quận 3, Hà Nội');
      await settle(tester);
      await _submit(tester);
      expect(h.lastBody.containsKey('provinceCode'), isFalse);
    });

    testWidgets('địa chỉ không chứa tên tỉnh thì không có gợi ý', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      await tester.enterText(_address, '12 Đường không rõ');
      await settle(tester);
      expect(find.textContaining(vi.lite_aiDetectedAddress), findsNothing);
    });

    testWidgets('xoá địa chỉ thì gợi ý biến mất', (tester) async {
      await pumpCreateScreen(tester);
      await tester.enterText(_address, '238 Kỳ Đồng, Quận 3, Hà Nội');
      await settle(tester);
      await tester.enterText(_address, '');
      await settle(tester);
      expect(find.textContaining(vi.lite_aiDetectedAddress), findsNothing);
    });
  });
}
