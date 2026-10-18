import 'package:app_quanly_giaidau/app.dart';
import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Khởi tạo giống main.dart (không Sentry, không Firebase). Gọi trong setUpAll.
Future<void> initializeAppForTests() async {
  await LiquidGlassWidgets.initialize(
    warmUpMode: GlassWarmUpMode.never,
    enablePerformanceMonitor: false,
  );
  await dotenv.load(fileName: '.env');
}

/// Dựng TournamentApp như main.dart và trả về container để điều hướng và đọc state.
/// Chờ SplashScreen chuyển trang xong trước khi trả về: splash gọi go('/home') sau khoảng 1,5 giây
/// và sẽ ghi đè điều hướng của test (ví dụ go('/login')) nếu test điều hướng sớm.
Future<ProviderContainer> pumpApp(WidgetTester tester) async {
  final container = ProviderContainer();
  await tester.pumpWidget(
    LiquidGlassWidgets.wrap(
      brightnessResolver: Theme.maybeBrightnessOf,
      child: UncontrolledProviderScope(
        container: container,
        child: const TournamentApp(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  final router = container.read(routerProvider);
  await pumpUntilCondition(
    tester,
    () => router.routerDelegate.currentConfiguration.uri.path != '/',
    timeout: const Duration(seconds: 60),
    what: 'SplashScreen chuyển khỏi đường dẫn "/"',
  );
  return container;
}

/// Pump theo khung thời gian thật, không dùng pumpAndSettle (app có animation vô hạn).
Future<void> pumpUntilCondition(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 30),
  required String what,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Hết ${timeout.inSeconds}s mà chưa thấy: $what');
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  await tester.pump();
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
  required String what,
}) => pumpUntilCondition(
  tester,
  () => finder.evaluate().isNotEmpty,
  timeout: timeout,
  what: what,
);

/// Tìm Text có một trong các chuỗi [texts] (khi app có thể hiện một trong vài nhãn).
Finder anyTextOf(List<String> texts) => find.byWidgetPredicate(
  (widget) => widget is Text && texts.contains(widget.data),
  description: 'Text là một trong ${texts.join(' | ')}',
);

/// Tìm Text bắt đầu bằng một trong các tiền tố [prefixes]. Nút gửi đăng ký ghép
/// nhãn với phí hoặc "(Miễn phí)" nên không khớp chính xác như [anyTextOf].
Finder anyTextStartingWith(List<String> prefixes) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      prefixes.any((prefix) => (widget.data ?? '').startsWith(prefix)),
  description: 'Text bắt đầu bằng một trong ${prefixes.join(' | ')}',
);

/// Cuộn danh sách dọc cho tới khi thấy [text]. Lỗi nếu không thấy sau [maxScrolls] lần.
Future<void> scrollToText(
  WidgetTester tester,
  String text, {
  int maxScrolls = 60,
}) async {
  final verticalScrollable = find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable &&
        (widget.axisDirection == AxisDirection.down ||
            widget.axisDirection == AxisDirection.up),
    description: 'Scrollable dọc',
  );
  expect(
    verticalScrollable,
    findsWidgets,
    reason:
        'Không có Scrollable dọc nào đang hiển thị để cuộn tới "$text" '
        '(Scrollable kể cả offstage: '
        '${find.byType(Scrollable, skipOffstage: false).evaluate().length})',
  );
  await tester.scrollUntilVisible(
    find.text(text),
    300,
    scrollable: verticalScrollable.first,
    maxScrolls: maxScrolls,
  );
  await tester.pump();
}

/// Chạm [finder] sau khi đưa nó về giữa viewport, tránh lớp header/kính đè lên mép trên.
Future<void> tapCentered(WidgetTester tester, Finder finder) async {
  final target = finder.first;
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
}

/// Đăng nhập bằng form màn /login (đúng luồng người dùng bấm).
Future<void> loginWithForm(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await pumpUntilFound(
    tester,
    find.text('Địa chỉ Email'),
    what: 'màn đăng nhập (nhãn Địa chỉ Email)',
  );
  final fields = find.byType(TextFormField);
  expect(
    fields,
    findsNWidgets(2),
    reason: 'Màn đăng nhập phải có đúng 2 ô: email, mật khẩu',
  );
  // Form đăng nhập hiện bằng animation (login_register_screen.dart:592: fadeIn trễ 250ms, thời lượng 400ms)
  // và sau route transition. Bấm khi còn đang chuyển thì hit test trượt, nên chờ hết trước khi nhập.
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  await tester.pump();
  await tester.tap(find.widgetWithText(TextButton, 'Đăng nhập'));
  await tester.pump();
}

/// Đăng xuất nếu còn phiên đăng nhập từ ca trước (state lưu trên thiết bị).
Future<void> ensureSignedOut(
  WidgetTester tester,
  ProviderContainer container,
) async {
  if (container.read(authProvider).isAuthenticated) {
    await container.read(authProvider.notifier).signOut();
    await pumpUntilCondition(
      tester,
      () => !container.read(authProvider).isAuthenticated,
      what: 'đã đăng xuất',
    );
  }
}
