import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/payment_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_payment_repository.dart';
import 'package:app_quanly_giaidau/features/payment/screens/payment_result_screen.dart';
import 'package:app_quanly_giaidau/features/payment/screens/payos_verify_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockPaymentRepository extends Mock implements PaymentRepository {}

PaymentModel _payment(String status) => PaymentModel(
  id: 'pay-1',
  tournamentId: 't1',
  participantId: 'p1',
  amount: 150000,
  status: status,
  gateway: 'PAYOS',
  createdAt: DateTime(2026, 1, 1),
);

/// Đích giả: ghi lại `extra` mà màn xác minh truyền sang `/payment/result`.
class _ResultProbe extends StatelessWidget {
  const _ResultProbe();

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map?;
    return Scaffold(
      body: Text('RESULT ${extra?['status']} ${extra?['amount']}'),
    );
  }
}

Future<GoRouter> _pumpWithRouter(
  WidgetTester tester,
  Widget home, {
  String initialLocation = '/start',
  PaymentRepository? repo,
  Object? extra,
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: initialLocation,
    initialExtra: extra,
    routes: [
      GoRoute(path: '/start', builder: (_, _) => home),
      GoRoute(path: '/payment-result', builder: (_, _) => home),
      GoRoute(path: '/payment/result', builder: (_, _) => const _ResultProbe()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('HOME PAGE')),
      ),
      GoRoute(
        path: '/intro/:id',
        builder: (_, state) =>
            Scaffold(body: Text('INTRO ${state.pathParameters['id']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repo != null) paymentRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: ThemeData.light(),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 2));
  return router;
}

/// Chờ chuyển trang và hoạt ảnh vào (không dùng pumpAndSettle vì có Timer lặp).
Future<void> _advance(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<void> _disposeScreen(WidgetTester tester) async {
  // Huỷ màn để Timer.periodic của màn xác minh không treo cuối test.
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  group('PaymentResultScreen', () {
    testWidgets('trạng thái success hiện số tiền làm tròn lên và lời chúc', (
      tester,
    ) async {
      await _pumpWithRouter(
        tester,
        const PaymentResultScreen(),
        extra: {'status': 'success', 'amount': 150000.4, 'tournamentId': 't9'},
      );

      expect(find.text('Thanh toán thành công'), findsOneWidget);
      expect(find.text('Số tiền: 150.001đ'), findsOneWidget);
      expect(find.text('Chúc bạn thi đấu tốt!'), findsOneWidget);
    });

    testWidgets('trạng thái PAID và COMPLETED cũng được coi là thành công', (
      tester,
    ) async {
      for (final status in ['PAID', 'COMPLETED']) {
        await _pumpWithRouter(
          tester,
          const PaymentResultScreen(),
          extra: {'status': status, 'amount': 1000},
        );
        expect(
          find.text('Thanh toán thành công'),
          findsOneWidget,
          reason: status,
        );
      }
    });

    testWidgets(
      'trạng thái khác hiện thất bại, không có số tiền hay lời chúc',
      (tester) async {
        await _pumpWithRouter(
          tester,
          const PaymentResultScreen(),
          extra: {'status': 'fail', 'amount': 150000},
        );

        expect(find.text('Thanh toán thất bại'), findsOneWidget);
        expect(
          find.text('Thao tác thanh toán bị hủy hoặc không thành công.'),
          findsOneWidget,
        );
        expect(find.textContaining('Số tiền'), findsNothing);
        expect(find.text('Chúc bạn thi đấu tốt!'), findsNothing);
      },
    );

    testWidgets('đọc status và amount từ query khi không có extra', (
      tester,
    ) async {
      await _pumpWithRouter(
        tester,
        const PaymentResultScreen(),
        initialLocation: '/payment-result?status=PAID&amount=50000',
      );

      expect(find.text('Thanh toán thành công'), findsOneWidget);
      expect(find.text('Số tiền: 50.000đ'), findsOneWidget);
    });

    testWidgets('có tournamentId thì nút quay lại dẫn tới trang giải', (
      tester,
    ) async {
      await _pumpWithRouter(
        tester,
        const PaymentResultScreen(),
        extra: {'status': 'success', 'amount': 1, 'tournamentId': 't9'},
      );

      await tester.tap(find.text('Quay lại giải đấu'));
      await _advance(tester);

      await _advance(tester);
      expect(find.text('INTRO t9'), findsOneWidget);
    });

    testWidgets('không có tournamentId thì nút quay lại về trang chủ', (
      tester,
    ) async {
      await _pumpWithRouter(
        tester,
        const PaymentResultScreen(),
        extra: {'status': 'fail'},
      );

      await tester.tap(find.text('Quay lại giải đấu'));
      await _advance(tester);

      expect(find.text('HOME PAGE'), findsOneWidget);
    });
  });

  group('PayOSVerifyScreen', () {
    Widget screen({String? qrCode, String? paymentUrl}) => PayOSVerifyScreen(
      paymentId: 'pay-1',
      amount: 150000,
      tournamentId: 't1',
      qrCode: qrCode,
      paymentUrl: paymentUrl,
    );

    testWidgets(
      'hiện số tiền, trạng thái chờ và ẩn QR/nút mở trang khi thiếu dữ liệu',
      (tester) async {
        await _pumpWithRouter(tester, screen(), repo: _MockPaymentRepository());

        expect(find.text('150.000đ'), findsOneWidget);
        expect(find.text('Đang chờ thanh toán...'), findsOneWidget);
        expect(find.text('Mã QR thanh toán PayOS'), findsNothing);
        expect(find.text('Mở trang thanh toán PayOS'), findsNothing);
        await _disposeScreen(tester);
      },
    );

    testWidgets(
      'có qrCode và paymentUrl thì hiện mã QR và nút mở trang thanh toán',
      (tester) async {
        await _pumpWithRouter(
          tester,
          screen(qrCode: '00020101', paymentUrl: 'https://pay.example/x'),
          repo: _MockPaymentRepository(),
        );

        expect(find.text('Mã QR thanh toán PayOS'), findsOneWidget);
        expect(find.text('Mở trang thanh toán PayOS'), findsOneWidget);
        await _disposeScreen(tester);
      },
    );

    testWidgets(
      'bấm Tôi đã thanh toán khi PayOS đã ghi nhận thì chuyển sang kết quả thành công',
      (tester) async {
        final repo = _MockPaymentRepository();
        when(
          () => repo.getPaymentById('pay-1'),
        ).thenAnswer((_) async => _payment('PAID'));
        await _pumpWithRouter(tester, screen(), repo: repo);

        await tester.tap(find.text('Tôi đã thanh toán'));
        await _advance(tester);

        expect(find.text('RESULT success 150000.0'), findsOneWidget);
      },
    );

    testWidgets(
      'thanh toán bị hủy hoặc hết hạn thì chuyển sang kết quả thất bại',
      (tester) async {
        final repo = _MockPaymentRepository();
        when(
          () => repo.getPaymentById('pay-1'),
        ).thenAnswer((_) async => _payment('EXPIRED'));
        await _pumpWithRouter(tester, screen(), repo: repo);

        await tester.tap(find.text('Tôi đã thanh toán'));
        await _advance(tester);

        expect(find.text('RESULT fail 150000.0'), findsOneWidget);
      },
    );

    testWidgets(
      'thanh toán còn PENDING thì báo chưa nhận được và ở lại màn xác minh',
      (tester) async {
        final repo = _MockPaymentRepository();
        when(
          () => repo.getPaymentById('pay-1'),
        ).thenAnswer((_) async => _payment('PENDING'));
        await _pumpWithRouter(tester, screen(), repo: repo);

        await tester.tap(find.text('Tôi đã thanh toán'));
        await _advance(tester);

        expect(
          find.text(
            'Hệ thống chưa nhận được thanh toán. Vui lòng kiểm tra lại sau vài giây.',
          ),
          findsOneWidget,
        );
        expect(find.text('Xác nhận thanh toán'), findsOneWidget);
        await _disposeScreen(tester);
      },
    );

    testWidgets('kiểm tra lỗi mạng thì báo lỗi xác minh', (tester) async {
      final repo = _MockPaymentRepository();
      when(() => repo.getPaymentById('pay-1')).thenThrow(Exception('mạng'));
      await _pumpWithRouter(tester, screen(), repo: repo);

      await tester.tap(find.text('Tôi đã thanh toán'));
      await _advance(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Xác nhận thanh toán'), findsOneWidget);
      await _disposeScreen(tester);
    });

    testWidgets(
      'tự kiểm tra mỗi 5 giây và chuyển sang kết quả khi đã thanh toán, không cần bấm nút',
      (tester) async {
        final repo = _MockPaymentRepository();
        var calls = 0;
        when(() => repo.getPaymentById('pay-1')).thenAnswer((_) async {
          calls++;
          return _payment(calls < 2 ? 'PENDING' : 'COMPLETED');
        });
        await _pumpWithRouter(tester, screen(), repo: repo);
        expect(calls, 0);

        await tester.pump(const Duration(seconds: 5));
        await tester.pump(const Duration(seconds: 5));
        await _advance(tester);

        expect(calls, 2);
        expect(find.text('RESULT success 150000.0'), findsOneWidget);
      },
    );

    testWidgets('Hủy và quay về trang chủ dừng kiểm tra và về trang chủ', (
      tester,
    ) async {
      final repo = _MockPaymentRepository();
      await _pumpWithRouter(tester, screen(), repo: repo);

      await tester.tap(find.text('Hủy và quay về trang chủ'));
      await _advance(tester);
      await tester.pump(const Duration(seconds: 10));

      expect(find.text('HOME PAGE'), findsOneWidget);
      verifyNever(() => repo.getPaymentById(any()));
    });
  });
}
