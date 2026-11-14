import 'dart:async';

import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/payment_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_payment_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/payment/screens/payments_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/fake_api_adapter.dart';

class _MockPaymentRepository extends Mock implements PaymentRepository {}

const _tournamentId = 'payments-screen-test';

PaymentModel _payment(
  String id,
  String status, {
  double amount = 150000,
  String? tournamentName = 'Giải Cầu Lông Hè',
  String? reference,
  String gateway = 'PAYOS',
  DateTime? createdAt,
}) => PaymentModel(
  id: id,
  tournamentId: _tournamentId,
  participantId: 'p-$id',
  amount: amount,
  status: status,
  gateway: gateway,
  transactionReference: reference,
  tournamentName: tournamentName,
  createdAt: createdAt ?? DateTime(2026, 1, 5, 9, 30),
);

Tournament _tournament(String mode) => Tournament.fromJson({
  'name': 'Giải thu phí',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'REGISTRATION',
  'entryFee': 150000,
  'feeCollectionMode': mode,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
}, _tournamentId);

class _CheckoutProbe extends StatelessWidget {
  const _CheckoutProbe();

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map?;
    return Scaffold(
      body: Text('CHECKOUT ${extra?['tournamentId']} ${extra?['amount']}'),
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  List<Override> overrides, {
  String feeMode = 'PAYOS',
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        // Giữ provider giải đấu có người nghe (như app thật, nơi màn khác
        // đang theo dõi nó) để isDirectFeeTournament đọc được `.future`.
        builder: (_, _) => Consumer(
          builder: (context, ref, _) {
            ref.watch(tournamentProvider(_tournamentId));
            return const PaymentsScreen();
          },
        ),
      ),
      GoRoute(
        path: '/payment/checkout',
        builder: (_, _) => const _CheckoutProbe(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        tournamentProvider(
          _tournamentId,
        ).overrideWith((ref) => Stream.value(_tournament(feeMode))),
        ...overrides,
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
  await _settle(tester);
}

Future<void> _pumpWithPayments(
  WidgetTester tester,
  List<PaymentModel> payments, {
  _MockPaymentRepository? repo,
  String feeMode = 'PAYOS',
}) async {
  final r = repo ?? _MockPaymentRepository();
  when(r.getMyPayments).thenAnswer((_) async => payments);
  await _pump(tester, [
    paymentRepositoryProvider.overrideWithValue(r),
  ], feeMode: feeMode);
}

/// Chờ dữ liệu và hoạt ảnh (không dùng pumpAndSettle vì có hoạt ảnh lặp).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _tapFilter(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).first);
  await _settle(tester);
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  setUpAll(() {
    registerFallbackValue(const CreatePaymentDto(tournamentId: 't'));
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  final mixed = [
    _payment('a', 'COMPLETED', tournamentName: 'Giải Hoàn Thành'),
    _payment(
      'b',
      'PENDING',
      amount: 200000,
      tournamentName: 'Giải Đang Chờ',
      reference: 'REF-B',
    ),
    _payment('c', 'FAILED', tournamentName: 'Giải Thất Bại'),
    _payment('d', 'REFUNDED', tournamentName: 'Giải Hoàn Tiền'),
  ];

  group('PaymentsScreen trạng thái danh sách', () {
    testWidgets('đang tải hiện khung xương và chưa hiện danh sách', (
      tester,
    ) async {
      final gate = Completer<List<PaymentModel>>();
      final repo = _MockPaymentRepository();
      when(repo.getMyPayments).thenAnswer((_) => gate.future);
      await _pump(tester, [paymentRepositoryProvider.overrideWithValue(repo)]);

      expect(find.text(l10n.payments_emptyAll), findsNothing);
      expect(find.text(l10n.payments_totalTransactions), findsNothing);

      gate.complete(const []);
      await _settle(tester);
    });

    testWidgets(
      'danh sách rỗng hiện thông báo chưa có lịch sử và 0 giao dịch',
      (tester) async {
        await _pumpWithPayments(tester, const []);

        expect(find.text(l10n.payments_emptyAll), findsOneWidget);
        expect(find.text(l10n.payments_emptySubtitle), findsOneWidget);
        expect(find.text(l10n.payments_transactionCount(0)), findsOneWidget);
        expect(find.textContaining('chờ xử lý'), findsNothing);
      },
    );

    testWidgets('có dữ liệu hiện tổng số giao dịch và số giao dịch chờ xử lý', (
      tester,
    ) async {
      await _pumpWithPayments(tester, mixed);

      expect(find.text(l10n.payments_transactionCount(4)), findsOneWidget);
      expect(find.text(l10n.payments_pendingCount(1)), findsOneWidget);
      expect(find.text('Giải Hoàn Thành'), findsOneWidget);
      expect(find.text('Giải Đang Chờ'), findsOneWidget);
    });

    testWidgets(
      'thẻ giao dịch hiện số tiền làm tròn lên, cổng, ngày giờ và nhãn trạng thái',
      (tester) async {
        await _pumpWithPayments(tester, [
          _payment('a', 'COMPLETED', amount: 150000.2),
          _payment('b', 'FAILED', amount: 99000),
        ]);

        expect(find.text('150.001đ'), findsOneWidget);
        expect(find.text('99.000đ'), findsOneWidget);
        expect(find.text('PAYOS • 05/01/2026 09:30'), findsNWidgets(2));
        expect(find.text(l10n.paymentStatusCompleted), findsOneWidget);
        // Một ở chip lọc "Thất bại", một ở nhãn trạng thái của thẻ.
        expect(find.text(l10n.paymentStatusFailed), findsNWidgets(2));
      },
    );

    testWidgets('giao dịch không có tên giải dùng tên mặc định', (
      tester,
    ) async {
      await _pumpWithPayments(tester, [
        _payment('a', 'COMPLETED', tournamentName: null),
      ]);

      expect(find.text(l10n.payments_defaultTournamentName), findsOneWidget);
    });

    testWidgets(
      'giao dịch có mã tham chiếu hiện mã GD, chờ thanh toán còn có nút Thanh toán ngay',
      (tester) async {
        await _pumpWithPayments(tester, [
          _payment('b', 'PENDING', reference: 'REF-B'),
          _payment('a', 'COMPLETED', reference: 'REF-A'),
        ]);

        expect(
          find.text(l10n.payments_transactionRef('REF-B')),
          findsOneWidget,
        );
        expect(
          find.text(l10n.payments_transactionRef('REF-A')),
          findsOneWidget,
        );
        expect(find.text(l10n.payments_retryCta), findsOneWidget);
      },
    );
  });

  group('PaymentsScreen bộ lọc', () {
    testWidgets('lọc Thành công chỉ giữ giao dịch đã hoàn thành', (
      tester,
    ) async {
      await _pumpWithPayments(tester, mixed);

      await _tapFilter(tester, l10n.payments_filterCompleted);

      expect(find.text('Giải Hoàn Thành'), findsOneWidget);
      expect(find.text('Giải Đang Chờ'), findsNothing);
      expect(find.text('Giải Thất Bại'), findsNothing);
    });

    testWidgets('lọc Đang chờ chỉ giữ giao dịch chờ xử lý', (tester) async {
      await _pumpWithPayments(tester, mixed);

      await _tapFilter(tester, l10n.payments_filterPending);

      expect(find.text('Giải Đang Chờ'), findsOneWidget);
      expect(find.text('Giải Hoàn Thành'), findsNothing);
    });

    testWidgets('lọc Thất bại gồm cả giao dịch thất bại và đã hoàn tiền', (
      tester,
    ) async {
      await _pumpWithPayments(tester, mixed);

      await _tapFilter(tester, l10n.payments_filterFailed);

      expect(find.text('Giải Thất Bại'), findsOneWidget);
      expect(find.text('Giải Hoàn Tiền'), findsOneWidget);
      expect(find.text('Giải Hoàn Thành'), findsNothing);
      expect(find.text('Giải Đang Chờ'), findsNothing);
    });

    testWidgets(
      'bộ lọc không có kết quả hiện thông báo không tìm thấy, Tất cả khôi phục danh sách',
      (tester) async {
        await _pumpWithPayments(tester, [_payment('a', 'COMPLETED')]);

        await _tapFilter(tester, l10n.payments_filterPending);
        expect(find.text(l10n.payments_emptyFiltered), findsOneWidget);
        expect(find.text(l10n.payments_emptyAll), findsNothing);

        await _tapFilter(tester, l10n.payments_filterAll);
        expect(find.text(l10n.payments_emptyFiltered), findsNothing);
        expect(find.text('Giải Cầu Lông Hè'), findsOneWidget);
      },
    );
  });

  group('PaymentsScreen lỗi và làm mới', () {
    testWidgets(
      'tải lỗi hiện thông báo lỗi, bấm Thử lại sẽ tải lại và hiện dữ liệu',
      (tester) async {
        final repo = _MockPaymentRepository();
        var calls = 0;
        when(repo.getMyPayments).thenAnswer((_) async {
          calls++;
          if (calls == 1) throw Exception('mất kết nối');
          return [_payment('a', 'COMPLETED')];
        });
        await _pump(tester, [
          paymentRepositoryProvider.overrideWithValue(repo),
        ]);

        expect(find.textContaining(l10n.payments_loadError), findsOneWidget);
        expect(find.text('Giải Cầu Lông Hè'), findsNothing);

        await tester.tap(find.text(l10n.infoRetry));
        await _settle(tester);

        expect(calls, 2);
        expect(find.text('Giải Cầu Lông Hè'), findsOneWidget);
        expect(find.textContaining(l10n.payments_loadError), findsNothing);
      },
    );

    testWidgets('nút làm mới trên thanh tiêu đề gọi lại API lịch sử', (
      tester,
    ) async {
      final repo = _MockPaymentRepository();
      await _pumpWithPayments(tester, const [], repo: repo);

      await tester.tap(find.byTooltip(l10n.payments_refreshTooltip));
      await _settle(tester);

      verify(repo.getMyPayments).called(2);
    });

    // BUG-PAY-01: ApiPaymentRepository.getMyPayments nuốt mọi lỗi và trả [],
    // nên khi mất mạng/401 màn hiện "Chưa có lịch sử thanh toán" thay vì khung
    // lỗi có nút Thử lại (nhánh error của màn không bao giờ chạy).
    testWidgets(
      'BUG-PAY-01 mất mạng khi tải lịch sử phải hiện khung lỗi chứ không phải danh sách rỗng',
      skip: true,
      (tester) async {
        final adapter = FakeApiAdapter({
          'GET /payments/me': const FakeReply.networkError(),
        });
        await _pump(tester, [
          dioClientProvider.overrideWithValue(fakeDioClient(adapter)),
        ]);

        expect(find.textContaining(l10n.payments_loadError), findsOneWidget);
        expect(find.text(l10n.payments_emptyAll), findsNothing);
      },
    );
  });

  group('PaymentsScreen chi tiết giao dịch', () {
    testWidgets(
      'mở giao dịch hoàn thành hiện chi tiết, thông báo thành công và nút Đóng',
      (tester) async {
        await _pumpWithPayments(tester, [
          _payment('a', 'COMPLETED', reference: 'REF-A'),
        ]);

        await tester.tap(find.text('Giải Cầu Lông Hè'));
        await _settle(tester);

        expect(find.text(l10n.payments_detailTournament), findsOneWidget);
        expect(find.text(l10n.payments_detailGateway), findsOneWidget);
        expect(find.text(l10n.payments_detailTransactionId), findsOneWidget);
        expect(find.text('REF-A'), findsOneWidget);
        expect(find.text('05/01/2026 09:30:00'), findsOneWidget);
        expect(find.text(l10n.payments_successInfo), findsOneWidget);
        expect(find.text(l10n.payments_payNow), findsNothing);

        await tester.tap(find.text(l10n.payments_close));
        await _settle(tester);
        expect(find.text(l10n.payments_successInfo), findsNothing);
      },
    );

    testWidgets(
      'mở giao dịch đang chờ hiện hướng dẫn thử lại cùng nút Cập nhật và Thanh toán ngay',
      (tester) async {
        await _pumpWithPayments(tester, [_payment('b', 'PENDING')]);

        await tester.tap(find.text('Giải Cầu Lông Hè'));
        await _settle(tester);

        expect(find.text(l10n.payments_retryPendingInfo), findsOneWidget);
        expect(find.text(l10n.payments_refreshStatus), findsOneWidget);
        expect(find.text(l10n.payments_payNow), findsOneWidget);
        expect(find.text(l10n.payments_successInfo), findsNothing);
      },
    );

    testWidgets('giao dịch thất bại hiện hướng dẫn mở lại trang thanh toán', (
      tester,
    ) async {
      await _pumpWithPayments(tester, [_payment('c', 'FAILED')]);

      await tester.tap(find.text('Giải Cầu Lông Hè'));
      await _settle(tester);

      expect(find.text(l10n.payments_retryFailedInfo), findsOneWidget);
      expect(find.text(l10n.payments_retryPendingInfo), findsNothing);
    });

    testWidgets('Cập nhật trạng thái đóng chi tiết và tải lại danh sách', (
      tester,
    ) async {
      final repo = _MockPaymentRepository();
      await _pumpWithPayments(tester, [_payment('b', 'PENDING')], repo: repo);
      await tester.tap(find.text('Giải Cầu Lông Hè'));
      await _settle(tester);

      await tester.tap(find.text(l10n.payments_refreshStatus));
      await _settle(tester);

      verify(repo.getMyPayments).called(2);
      expect(find.text(l10n.payments_retryPendingInfo), findsNothing);
    });
  });

  group('PaymentsScreen thanh toán lại', () {
    testWidgets(
      'không tạo được link thì chuyển sang màn checkout với đúng giải và số tiền',
      (tester) async {
        final repo = _MockPaymentRepository();
        when(() => repo.createPaymentLink(any())).thenAnswer((_) async => null);
        await _pumpWithPayments(tester, [_payment('b', 'PENDING')], repo: repo);
        await tester.tap(find.text('Giải Cầu Lông Hè'));
        await _settle(tester);
        await tester.tap(find.text(l10n.payments_payNow));
        await _settle(tester);

        final dto =
            verify(() => repo.createPaymentLink(captureAny())).captured.single
                as CreatePaymentDto;
        expect(dto.tournamentId, _tournamentId);
        expect(dto.participantId, 'p-b');
        expect(find.text('CHECKOUT $_tournamentId 150000.0'), findsOneWidget);
      },
    );

    testWidgets('tạo link lỗi hiện thông báo và cho bấm lại', (tester) async {
      final repo = _MockPaymentRepository();
      when(() => repo.createPaymentLink(any())).thenThrow(Exception('boom'));
      await _pumpWithPayments(tester, [_payment('b', 'PENDING')], repo: repo);
      await tester.tap(find.text('Giải Cầu Lông Hè'));
      await _settle(tester);

      await tester.tap(find.text(l10n.payments_payNow));
      await _settle(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(l10n.payments_payNow), findsOneWidget);
    });

    testWidgets(
      'giải thu phí trực tiếp báo thanh toán trực tiếp cho BTC và không tạo link',
      (tester) async {
        final repo = _MockPaymentRepository();
        await _pumpWithPayments(
          tester,
          [_payment('b', 'PENDING')],
          repo: repo,
          feeMode: 'DIRECT',
        );
        await tester.tap(find.text('Giải Cầu Lông Hè'));
        await _settle(tester);

        await tester.tap(find.text(l10n.payments_payNow));
        await _settle(tester);

        expect(find.text(l10n.feeDirectNote), findsOneWidget);
        verifyNever(() => repo.createPaymentLink(any()));
      },
    );
  });
}
