import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_driver.dart';
import 'shot.dart';

/// Chờ [duration] theo thời gian thật (mạng, animation), vẫn pump khung hình.
Future<void> chupWait(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

String _slug(String route) {
  final cleaned = route.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
  final trimmed = cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
  return trimmed.isEmpty ? 'root' : trimmed;
}

/// Chụp ảnh các trang bằng tài khoản thật trên emulator. Mỗi trang: đầu trang,
/// từng tab (nếu có TabBar) và tối đa [maxScrolls] lần cuộn xuống. Một trang
/// lỗi chỉ ghi `CHUP-LOI` rồi đi tiếp, không làm hỏng cả lượt.
class Chup {
  Chup(this.tester, this.binding, this.container, this.prefix);

  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;
  final ProviderContainer container;
  final String prefix;
  bool _converted = false;
  int _count = 0;
  final failures = <String>[];

  /// Đăng nhập bằng form như người dùng thật rồi chờ vào app.
  static Future<Chup> signIn(
    WidgetTester tester,
    IntegrationTestWidgetsFlutterBinding binding, {
    required String email,
    required String password,
    required String prefix,
  }) async {
    final container = await pumpApp(tester);
    await ensureSignedOut(tester, container);
    container.read(routerProvider).go('/login');
    await loginWithForm(tester, email: email, password: password);
    await pumpUntilCondition(
      tester,
      () => container.read(authProvider).isAuthenticated,
      what: 'đã đăng nhập $email',
    );
    await chupWait(tester, const Duration(seconds: 4));
    return Chup(tester, binding, container, prefix);
  }

  Future<void> snap(String name) async {
    if (!_converted) {
      await binding.convertFlutterSurfaceToImage();
      _converted = true;
    }
    await tester.pump();
    _count++;
    final index = _count.toString().padLeft(3, '0');
    await shot(binding, '$prefix-$index-$name');
  }

  Finder get _verticalScrollable => find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .hitTestable();

  Future<void> _scrollShots(String label, int maxScrolls) async {
    for (var i = 1; i <= maxScrolls; i++) {
      final finder = _verticalScrollable;
      if (finder.evaluate().isEmpty) return;
      final state = tester.state<ScrollableState>(finder.first);
      final position = state.position;
      if (position.pixels >= position.maxScrollExtent - 1) return;
      await tester.drag(finder.first, const Offset(0, -650));
      await chupWait(tester, const Duration(milliseconds: 900));
      await snap('$label-cuon$i');
    }
  }

  /// Mở [route] rồi chụp. [maxScrolls] giới hạn số ảnh cuộn cho mỗi màn/tab.
  Future<void> page(
    String route, {
    int maxScrolls = 2,
    Duration settle = const Duration(seconds: 5),
  }) async {
    final slug = _slug(route);
    try {
      container.read(routerProvider).go(route);
      await chupWait(tester, settle);
      await snap('$slug-dau');
      await _scrollShots(slug, maxScrolls);

      final tabBars = find.byType(TabBar).hitTestable();
      if (tabBars.evaluate().isEmpty) return;
      final tabs = find.descendant(
        of: tabBars.first,
        matching: find.byType(Tab),
      );
      final count = tabs.evaluate().length;
      for (var i = 1; i < count; i++) {
        await tester.tap(tabs.at(i));
        await chupWait(tester, const Duration(seconds: 3));
        await snap('$slug-tab${i + 1}');
        await _scrollShots('$slug-tab${i + 1}', maxScrolls);
      }
    } catch (error) {
      failures.add(route);
      debugPrintSynchronously('CHUP-LOI $route: $error');
    }
  }

  Future<void> pages(
    List<String> routes, {
    int maxScrolls = 2,
    Duration settle = const Duration(seconds: 5),
  }) async {
    for (final route in routes) {
      await page(route, maxScrolls: maxScrolls, settle: settle);
    }
    debugPrintSynchronously(
      'CHUP-XONG $prefix: $_count ảnh, ${failures.length} trang lỗi '
      '${failures.join(', ')}',
    );
  }
}
