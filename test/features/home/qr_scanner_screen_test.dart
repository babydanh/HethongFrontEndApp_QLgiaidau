import 'dart:async';

import 'package:app_quanly_giaidau/core/di/usecase_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/entities/token.dart';
import 'package:app_quanly_giaidau/domain/repositories/token_repository.dart';
import 'package:app_quanly_giaidau/domain/usecases/auth/validate_invite_token_use_case.dart';
import 'package:app_quanly_giaidau/features/home/screens/qr_scanner_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Nền tảng quét giả: không cần camera, test tự đẩy mã QR vào luồng.
class _FakeScannerPlatform extends MobileScannerPlatform {
  final StreamController<BarcodeCapture?> _barcodes =
      StreamController<BarcodeCapture?>.broadcast();
  int stopCalls = 0;

  void scan(List<String?> rawValues) => _barcodes.add(
    BarcodeCapture(
      barcodes: [for (final raw in rawValues) Barcode(rawValue: raw)],
    ),
  );

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;

  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();

  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();

  @override
  Widget buildCameraView() => const SizedBox.expand();

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async =>
      const MobileScannerViewAttributes(
        cameraDirection: CameraFacing.back,
        currentTorchMode: TorchState.off,
        size: Size(640, 480),
      );

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Future<void> pause() async {}

  @override
  Future<void> updateScanWindow(Rect? window) async {}

  @override
  Future<void> dispose() async {}
}

/// AuthNotifier giả: ghi lại mã được kiểm tra và trả kết quả định sẵn.
class _FakeAuth extends AuthNotifier {
  _FakeAuth({this.result});

  /// null nghĩa là xác thực thất bại; khác null là trạng thái sau khi thành công.
  final AuthState? result;
  final List<String> validated = [];
  Completer<void>? gate;
  String? failureMessage;

  @override
  AuthState build() => const AuthState();

  @override
  Future<bool> validateToken(String tokenCode) async {
    validated.add(tokenCode);
    state = state.copyWith(status: AuthStatus.validating);
    await gate?.future;
    final ok = result;
    if (ok == null) {
      state = AuthState(
        status: AuthStatus.invalid,
        errorMessage: failureMessage,
      );
      return false;
    }
    state = ok;
    return true;
  }
}

class _NullTokenRepository implements ITokenRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #validateToken) {
      return Future<TokenModel?>.value(null);
    }
    throw UnimplementedError('${invocation.memberName}');
  }
}

AuthState _success(UserRole role) => AuthState(
  status: AuthStatus.authenticated,
  role: role,
  tournamentId: 't9',
  tokenCode: 'OK',
);

late _FakeScannerPlatform _scanner;
int _profileBuilds = 0;
int _rankingBuilds = 0;

/// Giữ hai provider được xem để kiểm chứng việc invalidate sau khi đăng nhập.
class _WatchProfiles extends ConsumerWidget {
  const _WatchProfiles({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userProfileProvider);
    ref.watch(userRankingsProvider);
    return child;
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required List<Override> authOverrides,
}) async {
  _profileBuilds = 0;
  _rankingBuilds = 0;
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/scan'),
              child: const Text('MỞ QUÉT'),
            ),
          ),
        ),
      ),
      GoRoute(path: '/scan', builder: (_, _) => const QrScannerScreen()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('AT /home')),
      ),
      GoRoute(
        path: '/admin/tournament/:id',
        builder: (_, s) => Scaffold(
          body: Text('AT /admin/tournament/${s.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/intro/:id',
        builder: (_, s) =>
            Scaffold(body: Text('AT /intro/${s.pathParameters['id']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        ...authOverrides,
        userProfileProvider.overrideWith((ref) async {
          _profileBuilds++;
          return const UserProfile(id: 'u1');
        }),
        userRankingsProvider.overrideWith((ref) async {
          _rankingBuilds++;
          return const [];
        }),
      ],
      child: _WatchProfiles(
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          theme: ThemeData.light(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('MỞ QUÉT'));
  await tester.pumpAndSettle();
}

Future<_FakeAuth> _pumpWithFake(
  WidgetTester tester, {
  AuthState? result,
  String? failureMessage,
  Completer<void>? gate,
}) async {
  final auth = _FakeAuth(result: result)
    ..failureMessage = failureMessage
    ..gate = gate;
  await _pump(tester, authOverrides: [authProvider.overrideWith(() => auth)]);
  return auth;
}

/// Đẩy một lần quét và cho các future/ chuyển trang chạy xong.
Future<void> _scan(WidgetTester tester, List<String?> values) async {
  _scanner.scan(values);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  setUp(() {
    _scanner = _FakeScannerPlatform();
    MobileScannerPlatform.instance = _scanner;
  });

  group('giao diện', () {
    testWidgets(
      'hiện tiêu đề, nút đóng và khung quét, chưa có lớp đang xác thực',
      (tester) async {
        await _pumpWithFake(tester);

        expect(find.text(l10n.qrScannerTitle), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is ScannerOverlayPainter,
          ),
          findsOneWidget,
        );
        expect(find.text(l10n.qrScannerVerifying), findsNothing);
      },
    );

    testWidgets('nút đóng quay về màn trước', (tester) async {
      await _pumpWithFake(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('MỞ QUÉT'), findsOneWidget);
      expect(find.text(l10n.qrScannerTitle), findsNothing);
    });

    test('khung quét chỉ vẽ lại khi cần: shouldRepaint luôn false', () {
      final painter = ScannerOverlayPainter(borderColor: Colors.red);
      expect(
        painter.shouldRepaint(ScannerOverlayPainter(borderColor: Colors.blue)),
        isFalse,
      );
    });
  });

  group('xử lý chuỗi mã', () {
    testWidgets('mã trơn được gửi nguyên văn để xác thực', (tester) async {
      final auth = await _pumpWithFake(
        tester,
        result: _success(UserRole.viewer),
      );

      await _scan(tester, ['ABCD1234']);

      expect(auth.validated, ['ABCD1234']);
    });

    testWidgets('liên kết app_quanly_giaidau:join?code=XYZ lấy ra XYZ', (
      tester,
    ) async {
      final auth = await _pumpWithFake(
        tester,
        result: _success(UserRole.viewer),
      );

      await _scan(tester, ['app_quanly_giaidau:join?code=XYZ789']);

      expect(auth.validated, ['XYZ789']);
    });

    testWidgets('URL https có thêm tham số khác vẫn lấy đúng code', (
      tester,
    ) async {
      final auth = await _pumpWithFake(
        tester,
        result: _success(UserRole.viewer),
      );

      await _scan(tester, ['https://giai.example/join?foo=1&code=TOK555&x=2']);

      expect(auth.validated, ['TOK555']);
    });

    testWidgets(
      'chuỗi chứa code= nhưng không phải URL hợp lệ: cắt thủ công tới dấu &',
      (tester) async {
        final auth = await _pumpWithFake(
          tester,
          result: _success(UserRole.viewer),
        );

        await _scan(tester, ['%zz join code=MANUAL1&rest=2']);

        expect(auth.validated, ['MANUAL1']);
      },
    );

    testWidgets('chỉ lấy mã vạch đầu tiên khi một khung hình có nhiều mã', (
      tester,
    ) async {
      final auth = await _pumpWithFake(
        tester,
        result: _success(UserRole.viewer),
      );

      await _scan(tester, ['FIRST001', 'SECOND02']);

      expect(auth.validated, ['FIRST001']);
    });

    testWidgets('khung hình không có mã, mã null hoặc rỗng bị bỏ qua', (
      tester,
    ) async {
      final auth = await _pumpWithFake(
        tester,
        result: _success(UserRole.viewer),
      );

      await _scan(tester, []);
      await _scan(tester, [null]);
      await _scan(tester, ['']);

      expect(auth.validated, isEmpty);
      expect(find.text(l10n.qrScannerVerifying), findsNothing);
    });
  });

  group('điều hướng sau khi xác thực thành công', () {
    final cases = <UserRole, String>{
      UserRole.admin: 'AT /admin/tournament/t9',
      UserRole.referee: 'AT /intro/t9',
      UserRole.viewer: 'AT /intro/t9',
      UserRole.organizer: 'AT /home',
    };
    for (final entry in cases.entries) {
      testWidgets('vai ${entry.key.name} chuyển tới "${entry.value}"', (
        tester,
      ) async {
        await _pumpWithFake(tester, result: _success(entry.key));

        await _scan(tester, ['GOODCODE']);
        await tester.pumpAndSettle();

        expect(find.text(entry.value), findsOneWidget);
        expect(find.text(l10n.qrScannerTitle), findsNothing);
      });
    }

    testWidgets('thành công: làm mới hồ sơ và xếp hạng, dừng camera', (
      tester,
    ) async {
      await _pumpWithFake(tester, result: _success(UserRole.admin));
      final profileBefore = _profileBuilds;
      final rankingBefore = _rankingBuilds;

      await _scan(tester, ['GOODCODE']);
      await tester.pumpAndSettle();

      expect(_profileBuilds, greaterThan(profileBefore));
      expect(_rankingBuilds, greaterThan(rankingBefore));
      expect(_scanner.stopCalls, greaterThanOrEqualTo(1));
    });
  });

  group('xác thực thất bại', () {
    testWidgets('mã sai: hiện thông điệp lỗi từ auth, ở lại màn quét', (
      tester,
    ) async {
      await _pumpWithFake(tester, failureMessage: 'Mã đã bị thu hồi');

      await _scan(tester, ['BADCODE1']);

      expect(find.text('Mã đã bị thu hồi'), findsOneWidget);
      expect(find.text(l10n.qrScannerTitle), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('mã sai không kèm thông điệp: dùng chuỗi Mã QR không hợp lệ', (
      tester,
    ) async {
      await _pumpWithFake(tester);

      await _scan(tester, ['BADCODE1']);

      expect(find.text(l10n.qrScannerInvalidCode), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('thất bại không làm mới hồ sơ và không chuyển trang', (
      tester,
    ) async {
      await _pumpWithFake(tester);
      final profileBefore = _profileBuilds;

      await _scan(tester, ['BADCODE1']);

      expect(_profileBuilds, profileBefore);
      expect(find.text('AT /home'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('trong 2 giây sau lỗi mã mới bị bỏ qua, sau đó quét lại được', (
      tester,
    ) async {
      final auth = await _pumpWithFake(tester);

      await _scan(tester, ['BADCODE1']);
      await _scan(tester, ['BADCODE2']);
      expect(auth.validated, ['BADCODE1']);

      await tester.pump(const Duration(seconds: 2));
      await _scan(tester, ['BADCODE3']);
      expect(auth.validated, ['BADCODE1', 'BADCODE3']);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('đang xác thực', () {
    testWidgets('hiện lớp Đang xác thực và bỏ qua mã quét thêm trong lúc chờ', (
      tester,
    ) async {
      final gate = Completer<void>();
      final auth = await _pumpWithFake(
        tester,
        result: _success(UserRole.viewer),
        gate: gate,
      );

      await _scan(tester, ['GOODCODE']);

      expect(find.text(l10n.qrScannerVerifying), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await _scan(tester, ['OTHER999']);
      expect(auth.validated, ['GOODCODE']);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('AT /intro/t9'), findsOneWidget);
    });

    testWidgets('rời màn khi đang chờ kết quả: không điều hướng, không lỗi', (
      tester,
    ) async {
      final gate = Completer<void>();
      await _pumpWithFake(tester, result: _success(UserRole.admin), gate: gate);
      await _scan(tester, ['GOODCODE']);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('MỞ QUÉT'), findsOneWidget);
      expect(find.textContaining('AT /admin'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('với AuthNotifier thật', () {
    testWidgets(
      'mã hợp lệ nhưng kho trả null: báo thông điệp token không hợp lệ',
      (tester) async {
        await _pump(
          tester,
          authOverrides: [
            validateInviteTokenUseCaseProvider.overrideWithValue(
              ValidateInviteTokenUseCase(_NullTokenRepository()),
            ),
          ],
        );

        await _scan(tester, ['LONGCODE']);

        expect(
          find.text(
            lookupAppLocalizations(const Locale('vi')).authTokenInvalid,
          ),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 3));
      },
    );

    // BUG-QR-01: AuthNotifier.validateToken gọi tokenCode.substring(0, 3) để ghi
    // log trước khi vào try; mã ngắn hơn 3 ký tự (vd. "code=AB") ném RangeError,
    // lớp "Đang xác thực" kẹt mãi và camera không quét lại được.
    testWidgets(
      'BUG-QR-01 mã quét ngắn hơn 3 ký tự: báo mã không hợp lệ và mở lại quét',
      (tester) async {
        await _pump(
          tester,
          authOverrides: [
            validateInviteTokenUseCaseProvider.overrideWithValue(
              ValidateInviteTokenUseCase(_NullTokenRepository()),
            ),
          ],
        );

        await _scan(tester, ['AB']);
        await tester.pump(const Duration(seconds: 3));

        expect(find.text(l10n.qrScannerVerifying), findsNothing);
        expect(find.text(l10n.authTokenInvalid), findsOneWidget);
      },
      skip: true,
    );
  });
}
