import 'dart:async';

import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/payment_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_payment_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/payment/screens/checkout_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockPaymentRepository extends Mock implements PaymentRepository {}

const _tournamentId = 'checkout-screen-test';
const _validUuid = '123e4567-e89b-42d3-a456-426614174000';

Tournament _tournament({
  String mode = 'PAYOS',
  num? entryFee = 150000,
  String name = 'Giải của hệ thống',
}) => Tournament.fromJson({
  'name': name,
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'REGISTRATION',
  'entryFee': entryFee,
  'feeCollectionMode': mode,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
}, _tournamentId);

Future<void> _pump(
  WidgetTester tester,
  PaymentRepository repo, {
  double amount = 150000,
  String? tournamentName,
  String? divisionId,
  Tournament? tournament,
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => CheckoutScreen(
          tournamentId: _tournamentId,
          participantId: 'p1',
          amount: amount,
          tournamentName: tournamentName,
          divisionId: divisionId,
        ),
      ),
      GoRoute(
        path: '/payments',
        builder: (_, _) => const Scaffold(body: Text('PAYMENTS PAGE')),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: Text('PROFILE PAGE')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        paymentRepositoryProvider.overrideWithValue(repo),
        tournamentProvider(
          _tournamentId,
        ).overrideWith((ref) => Stream.value(tournament ?? _tournament())),
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
  await tester.pump();
  await tester.pump();
}

Future<void> _tapPay(WidgetTester tester) async {
  final button = find.byType(ElevatedButton);
  await tester.ensureVisible(button);
  await tester.tap(button);
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

bool _payEnabled(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed !=
    null;

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  setUpAll(() {
    registerFallbackValue(const CreatePaymentDto(tournamentId: 't'));
  });

  group('CheckoutScreen hiển thị phí', () {
    testWidgets(
      'hiện nhãn lệ phí, số tiền có phân cách nghìn và nút thanh toán cùng số tiền',
      (tester) async {
        await _pump(tester, _MockPaymentRepository(), amount: 150000);

        expect(find.text(l10n.checkout_title), findsOneWidget);
        expect(find.text(l10n.checkout_entryFeeLabel), findsOneWidget);
        expect(find.text('150.000đ'), findsOneWidget);
        expect(find.text(l10n.checkout_payButton('150.000')), findsOneWidget);
        expect(find.text(l10n.checkout_confirmInstruction), findsOneWidget);
      },
    );

    testWidgets('số tiền lẻ được làm tròn lên ở cả tiêu đề và nút', (
      tester,
    ) async {
      await _pump(tester, _MockPaymentRepository(), amount: 99999.2);

      expect(find.text('100.000đ'), findsOneWidget);
      expect(find.text(l10n.checkout_payButton('100.000')), findsOneWidget);
    });

    testWidgets(
      'tên giải truyền vào được ưu tiên hơn tên giải tải từ hệ thống',
      (tester) async {
        await _pump(
          tester,
          _MockPaymentRepository(),
          tournamentName: 'Giải truyền vào',
        );

        expect(find.text('Giải truyền vào'), findsOneWidget);
        expect(find.text('Giải của hệ thống'), findsNothing);
      },
    );

    testWidgets('không truyền tên giải thì dùng tên giải tải từ hệ thống', (
      tester,
    ) async {
      await _pump(tester, _MockPaymentRepository());

      expect(find.text('Giải của hệ thống'), findsOneWidget);
    });

    testWidgets(
      'số tiền truyền vào bằng 0 thì lấy lệ phí của giải làm số tiền',
      (tester) async {
        await _pump(
          tester,
          _MockPaymentRepository(),
          amount: 0,
          tournament: _tournament(entryFee: 250000),
        );

        expect(find.text('250.000đ'), findsOneWidget);
        expect(find.text(l10n.checkout_payButton('250.000')), findsOneWidget);
        expect(find.text(l10n.checkout_freeBadge), findsNothing);
      },
    );
  });

  group('CheckoutScreen phương thức thanh toán', () {
    testWidgets('giải thu qua PayOS hiện mục phương thức PayOS', (
      tester,
    ) async {
      await _pump(tester, _MockPaymentRepository());

      expect(find.text(l10n.checkout_paymentMethodLabel), findsOneWidget);
      expect(find.text(l10n.checkout_payOSLabel), findsOneWidget);
      expect(find.text(l10n.checkout_payOSDescription), findsOneWidget);
    });

    testWidgets(
      'bấm lại PayOS vẫn giữ lựa chọn và nút thanh toán còn dùng được',
      (tester) async {
        await _pump(tester, _MockPaymentRepository());

        await tester.tap(find.text(l10n.checkout_payOSLabel));
        await tester.pump();

        expect(find.text(l10n.checkout_payOSLabel), findsOneWidget);
        expect(_payEnabled(tester), isTrue);
      },
    );

    testWidgets(
      'giải thu trực tiếp ẩn mục phương thức, hiện ghi chú và khoá nút',
      (tester) async {
        await _pump(
          tester,
          _MockPaymentRepository(),
          tournament: _tournament(mode: 'DIRECT'),
        );

        expect(find.text(l10n.checkout_paymentMethodLabel), findsNothing);
        expect(find.text(l10n.checkout_payOSLabel), findsNothing);
        expect(find.text(l10n.feeDirectNote), findsOneWidget);
        expect(find.text(l10n.checkout_confirmInstruction), findsNothing);
        expect(_payEnabled(tester), isFalse);
      },
    );
  });

  group('CheckoutScreen giải miễn phí', () {
    testWidgets(
      'không có lệ phí hiện nhãn miễn phí, 0đ, ẩn phương thức và nút xác nhận tham gia',
      (tester) async {
        await _pump(
          tester,
          _MockPaymentRepository(),
          amount: 0,
          tournament: _tournament(entryFee: 0),
        );

        expect(find.text(l10n.checkout_freeBadge), findsOneWidget);
        expect(find.text('0đ'), findsOneWidget);
        expect(find.text(l10n.checkout_paymentMethodLabel), findsNothing);
        expect(find.text(l10n.checkout_freeConfirmButton), findsOneWidget);
      },
    );

    testWidgets(
      'xác nhận miễn phí báo thành công, về trang thanh toán và không tạo link',
      (tester) async {
        final repo = _MockPaymentRepository();
        await _pump(
          tester,
          repo,
          amount: 0,
          tournament: _tournament(entryFee: 0),
        );

        await _tapPay(tester);

        expect(find.text(l10n.checkout_freeConfirm), findsOneWidget);
        expect(find.text('PAYMENTS PAGE'), findsOneWidget);
        verifyNever(() => repo.createPaymentLink(any()));
      },
    );
  });

  group('CheckoutScreen tạo link thanh toán', () {
    testWidgets(
      'gửi đúng giải và người tham gia, bỏ mã nội dung không phải UUID',
      (tester) async {
        final repo = _MockPaymentRepository();
        when(() => repo.createPaymentLink(any())).thenAnswer((_) async => null);
        await _pump(tester, repo, divisionId: 'khong-phai-uuid');

        await _tapPay(tester);

        final dto =
            verify(() => repo.createPaymentLink(captureAny())).captured.single
                as CreatePaymentDto;
        expect(dto.tournamentId, _tournamentId);
        expect(dto.participantId, 'p1');
        expect(dto.divisionId, isNull);
      },
    );

    testWidgets('mã nội dung UUID hợp lệ được gửi kèm', (tester) async {
      final repo = _MockPaymentRepository();
      when(() => repo.createPaymentLink(any())).thenAnswer((_) async => null);
      await _pump(tester, repo, divisionId: ' $_validUuid ');

      await _tapPay(tester);

      final dto =
          verify(() => repo.createPaymentLink(captureAny())).captured.single
              as CreatePaymentDto;
      expect(dto.divisionId, _validUuid);
    });

    testWidgets(
      'máy chủ không trả link thì báo không thể tạo liên kết và cho bấm lại',
      (tester) async {
        final repo = _MockPaymentRepository();
        when(() => repo.createPaymentLink(any())).thenAnswer((_) async => null);
        await _pump(tester, repo);

        await _tapPay(tester);

        expect(find.text(l10n.checkout_createGatewayError), findsOneWidget);
        expect(_payEnabled(tester), isTrue);
      },
    );

    testWidgets(
      'phản hồi thiếu cả paymentUrl và qrCode báo lỗi và không rời màn',
      (tester) async {
        final repo = _MockPaymentRepository();
        when(
          () => repo.createPaymentLink(any()),
        ).thenAnswer((_) async => {'paymentId': 'pay-1'});
        await _pump(tester, repo);

        await _tapPay(tester);

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text(l10n.checkout_title), findsOneWidget);
        expect(_payEnabled(tester), isTrue);
      },
    );

    testWidgets(
      'repository ném lỗi thì hiện thông báo lỗi khởi tạo thanh toán',
      (tester) async {
        final repo = _MockPaymentRepository();
        when(() => repo.createPaymentLink(any())).thenThrow(Exception('boom'));
        await _pump(tester, repo);

        await _tapPay(tester);

        expect(find.byType(SnackBar), findsOneWidget);
        expect(_payEnabled(tester), isTrue);
      },
    );

    testWidgets(
      'đang chờ link thì khoá nút và hiện vòng tải, xong mở khoá lại',
      (tester) async {
        final gate = Completer<Map<String, dynamic>?>();
        final repo = _MockPaymentRepository();
        when(
          () => repo.createPaymentLink(any()),
        ).thenAnswer((_) => gate.future);
        await _pump(tester, repo);

        final button = find.byType(ElevatedButton);
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump(const Duration(milliseconds: 100));

        expect(_payEnabled(tester), isFalse);
        expect(
          find.descendant(
            of: button,
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
        expect(find.text(l10n.checkout_payButton('150.000')), findsNothing);

        gate.complete(null);
        await tester.pump(const Duration(milliseconds: 200));
        expect(_payEnabled(tester), isTrue);
      },
    );
  });

  group('CheckoutScreen điều hướng', () {
    testWidgets('nút quay lại khi không có trang trước đưa về hồ sơ', (
      tester,
    ) async {
      await _pump(tester, _MockPaymentRepository());

      await tester.tap(find.byIcon(Icons.arrow_back_ios_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PROFILE PAGE'), findsOneWidget);
    });
  });
}
