import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'create_quick_tournament_harness.dart';

final _feeField = find.byWidgetPredicate(
  (w) =>
      w is TextField &&
      w.decoration?.labelText == vi.tournamentManagementEntryFee,
);

Future<void> _enableFee(WidgetTester tester) async {
  await openAdvanced(tester);
  await tester.tap(find.text(vi.tournamentCreateEntryFeeToggle));
  await tester.pump();
}

Future<void> _setFee(WidgetTester tester, String value) async {
  await tester.enterText(_feeField, value);
  await tester.pump();
}

Future<void> _submit(WidgetTester tester) async {
  await enterName(tester, 'Giải lệ phí');
  await tapSubmit(tester);
}

const _feeError = 'Nhập số nguyên lớn hơn hoặc bằng 0.';

void main() {
  setUpAll(setUpEnv);

  group('CreatePublicQuickTournamentScreen lệ phí: hiển thị', () {
    testWidgets(
      'khối cài đặt nâng cao thu gọn mặc định, chưa thấy công tắc lệ phí',
      (tester) async {
        await pumpCreateScreen(tester);
        expect(find.text(vi.tournamentCreateEntryFeeToggle), findsNothing);
      },
    );

    testWidgets(
      'mở cài đặt nâng cao khi hệ thống cho phép thì hiện công tắc lệ phí',
      (tester) async {
        await pumpCreateScreen(tester);
        await openAdvanced(tester);
        expect(find.text(vi.tournamentCreateEntryFeeToggle), findsOneWidget);
        expect(_feeField, findsNothing);
      },
    );

    testWidgets('bật công tắc thì hiện ô nhập lệ phí mặc định 0', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      await _enableFee(tester);
      expect(_feeField, findsOneWidget);
      expect(tester.widget<TextField>(_feeField).controller!.text, '0');
    });

    testWidgets(
      'hệ thống không cho thu lệ phí thì báo miễn phí và không có công tắc',
      (tester) async {
        await pumpCreateScreen(
          tester,
          routes: defaultRoutes(allowEntryFees: false),
        );
        await openAdvanced(tester);
        expect(
          find.text(vi.tournamentCreateEntryFeePolicyUnavailable),
          findsOneWidget,
        );
        expect(find.text(vi.tournamentCreateEntryFeeToggle), findsNothing);
      },
    );

    testWidgets('tải cấu hình lệ phí lỗi thì coi như miễn phí', (tester) async {
      final routes = defaultRoutes()..remove('GET /tournaments/fees');
      await pumpCreateScreen(tester, routes: routes);
      await openAdvanced(tester);
      expect(
        find.text(vi.tournamentCreateEntryFeePolicyUnavailable),
        findsOneWidget,
      );
    });

    testWidgets('hiện khu vực ảnh Logo và Banner trong cài đặt nâng cao', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      await openAdvanced(tester);
      expect(find.text('Ảnh giải đấu'), findsOneWidget);
      expect(find.text('Logo'), findsOneWidget);
      expect(find.text('Banner'), findsOneWidget);
    });
  });

  group('CreatePublicQuickTournamentScreen lệ phí: kiểm tra và gửi', () {
    testWidgets('không bật lệ phí thì body không có entryFee', (tester) async {
      final h = await pumpCreateScreen(tester);
      await _submit(tester);
      expect(h.lastBody.containsKey('entryFee'), isFalse);
      expect(h.lastBody.containsKey('logoUrl'), isFalse);
      expect(h.lastBody.containsKey('bannerUrl'), isFalse);
    });

    testWidgets('bật lệ phí và để 0 thì gửi entryFee 0 (miễn phí hợp lệ)', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await _enableFee(tester);
      await _submit(tester);
      expect(h.lastBody['entryFee'], 0);
    });

    testWidgets('lệ phí 150000 được gửi dạng số nguyên', (tester) async {
      final h = await pumpCreateScreen(tester);
      await _enableFee(tester);
      await _setFee(tester, '150000');
      await _submit(tester);
      expect(h.lastBody['entryFee'], 150000);
    });

    testWidgets('lệ phí có khoảng trắng hai đầu vẫn được chấp nhận', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await _enableFee(tester);
      await _setFee(tester, ' 50000 ');
      await _submit(tester);
      expect(h.lastBody['entryFee'], 50000);
    });

    testWidgets('lệ phí âm bị từ chối và không gửi yêu cầu', (tester) async {
      final h = await pumpCreateScreen(tester);
      await _enableFee(tester);
      await _setFee(tester, '-5000');
      await _submit(tester);
      expect(find.text(_feeError), findsOneWidget);
      expect(h.submitCount, 0);
    });

    for (final bad in ['abc', '1.5', '']) {
      testWidgets('lệ phí "$bad" không phải số nguyên bị từ chối', (
        tester,
      ) async {
        final h = await pumpCreateScreen(tester);
        await _enableFee(tester);
        await _setFee(tester, bad);
        await _submit(tester);
        expect(find.text(_feeError), findsOneWidget);
        expect(h.submitCount, 0);
      });
    }

    testWidgets('sửa lệ phí thành số hợp lệ rồi gửi lại thì thành công', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await _enableFee(tester);
      await _setFee(tester, '-1');
      await _submit(tester);
      expect(h.submitCount, 0);
      await _setFee(tester, '20000');
      await tapSubmit(tester);
      expect(h.submitCount, 1);
      expect(h.lastBody['entryFee'], 20000);
    });

    testWidgets(
      'tắt lại công tắc thì bỏ qua lệ phí sai và không gửi entryFee',
      (tester) async {
        final h = await pumpCreateScreen(tester);
        await _enableFee(tester);
        await _setFee(tester, '-1');
        await tester.tap(find.text(vi.tournamentCreateEntryFeeToggle));
        await tester.pump();
        await _submit(tester);
        expect(h.submitCount, 1);
        expect(h.lastBody.containsKey('entryFee'), isFalse);
      },
    );

    // BUG-QUICKCREATE-01: ExpansionTile không dựng con khi thu gọn nên validator
    // của ô lệ phí không chạy, _submit vẫn gửi entryFee âm. Bỏ skip khi app sửa.
    testWidgets(
      'BUG-QUICKCREATE-01 lệ phí âm rồi thu gọn khối nâng cao vẫn không được gửi lên',
      (tester) async {
        final h = await pumpCreateScreen(tester);
        await _enableFee(tester);
        await _setFee(tester, '-5000');
        await tester.tap(find.text('Cài đặt nâng cao')); // thu gọn
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        await _submit(tester);
        final sent = h.submitCount == 0 ? null : h.lastBody['entryFee'];
        expect(sent, isNull, reason: 'entryFee âm không được gửi lên máy chủ');
      },
      skip: true,
    );
  });
}
