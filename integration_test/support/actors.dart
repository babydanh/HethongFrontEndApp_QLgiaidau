import 'package:app_quanly_giaidau/app.dart';
import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_driver.dart';
import 'backend_api.dart';
import 'social_journey.dart';

/// Các vai một chuỗi test có thể xin. `organizer` và `admin` dùng tài khoản có sẵn của CI
/// (tạo mới không được); các vai còn lại là tài khoản mới tạo riêng cho chuỗi.
const Set<String> kActorRoles = {
  'organizer',
  'admin',
  'player',
  'referee',
  'coOrganizer',
  'viewer',
  'clubOwner',
  'member',
};

/// Một tài khoản E2E đã đăng ký: dùng [token] cho lệnh API, dùng [email] để đăng nhập trên giao diện.
class E2eActor {
  const E2eActor({
    required this.role,
    required this.email,
    required this.userId,
    required this.token,
    required this.fullName,
  });

  final String role;
  final String email;
  final String userId;
  final String token;
  final String fullName;
}

/// Tạo bộ tài khoản riêng cho chuỗi [chain] (tiền tố `E2E<timestamp>-<chain>`), nên các file test
/// chạy song song không đụng nhau. Vai `organizer` dùng `admin1` (kE2ePassword), vai `admin` dùng
/// `e2eadmin`; dữ liệu của chuỗi (giải, CLB) vẫn mang tiền tố chuỗi để tách bạch.
Future<Map<String, E2eActor>> createActors(
  BackendApi api, {
  required String chain,
  required List<String> roles,
}) async {
  final unknown = roles.where((r) => !kActorRoles.contains(r)).toList();
  if (unknown.isNotEmpty) {
    throw ArgumentError.value(unknown, 'roles', 'vai không hợp lệ');
  }
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final prefix = 'E2E$stamp-$chain';
  final actors = <String, E2eActor>{};
  for (final entry in roles.asMap().entries) {
    final role = entry.value;
    actors[role] = switch (role) {
      'organizer' => await _existing(api, role, kOrganizerEmail, 'BTC E2E'),
      'admin' => await _existing(api, role, kAdminEmail, 'Admin E2E'),
      _ => await _register(api, prefix, role, entry.key, stamp),
    };
  }
  return actors;
}

Future<E2eActor> _existing(
  BackendApi api,
  String role,
  String email,
  String fullName,
) async {
  final token = await api.login(email, kE2ePassword);
  return E2eActor(
    role: role,
    email: email,
    userId: '',
    token: token,
    fullName: fullName,
  );
}

Future<E2eActor> _register(
  BackendApi api,
  String prefix,
  String role,
  int index,
  int stamp,
) async {
  final email = '${prefix.toLowerCase()}-${role.toLowerCase()}@example.com';
  final fullName = '$prefix $role';
  final userId = await api.registerAccount(
    email: email,
    password: kE2ePassword,
    fullName: fullName,
  );
  final token = await api.login(email, kE2ePassword);
  if (role != 'viewer') {
    // SĐT đúng UpdateUserDto (0 + 9 + 8 chữ số), khác nhau theo thời gian và thứ tự vai.
    final digits = ((stamp % 10000000) * 10 + index) % 100000000;
    await api.completePlayerProfile(
      token: token,
      phoneNumber: '09${digits.toString().padLeft(8, '0')}',
      gender: 'MALE',
    );
  }
  return E2eActor(
    role: role,
    email: email,
    userId: userId,
    token: token,
    fullName: fullName,
  );
}

/// Đổi tài khoản trên giao diện: dựng lại app, đăng xuất người cũ, đăng nhập [actor] bằng form.
/// Giữ lần chờ 1,5 giây giữa đăng xuất và đăng nhập (Backend huỷ token theo giây).
Future<ProviderContainer> signInAs(WidgetTester tester, E2eActor actor) async {
  final container = await signInWithEmail(tester, email: actor.email);
  return container;
}

/// Container Riverpod của app đang chạy.
ProviderContainer appContainer(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(TournamentApp)));

/// Đường dẫn route đang hiện.
String currentPath(WidgetTester tester) => appContainer(
  tester,
).read(routerProvider).routerDelegate.currentConfiguration.uri.path;

/// Chờ [finder] hiện ra (đổi tên gọn của `pumpUntilFound`).
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) => pumpUntilFound(tester, finder, timeout: timeout, what: finder.toString());

/// Chữ báo thiếu quyền hoặc cần đăng nhập mà một màn bị chặn được phép hiện.
final Finder _blockedMessage = find.byWidgetPredicate(
  (w) =>
      w is Text &&
      RegExp(
        r'không có quyền|không đủ quyền|cần đăng nhập|vui lòng đăng nhập|đăng nhập để',
        caseSensitive: false,
      ).hasMatch(w.data ?? ''),
  description: 'Text báo thiếu quyền hoặc cần đăng nhập',
);

/// Mở [route] rồi khẳng định vai hiện tại bị chặn: được đưa về `/login` hoặc `/home`, hoặc thấy màn báo
/// không có quyền. Không chấp nhận màn trắng, màn lỗi 401/403 thô, hay vẫn ở nguyên route với màn chức năng.
Future<void> expectBlocked(WidgetTester tester, String route) async {
  final router = appContainer(tester).read(routerProvider);
  router.go(route);
  await socialWait(tester, const Duration(seconds: 3));
  final path = currentPath(tester);
  final redirected = path == '/login' || path == '/home';
  final message = _blockedMessage.evaluate().isNotEmpty;
  expect(
    redirected || message,
    isTrue,
    reason:
        'Mở $route phải bị chặn (về /login, /home hoặc báo không có quyền) '
        'nhưng đang ở "$path" và không có chữ báo thiếu quyền',
  );
}
