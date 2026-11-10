import 'dart:convert';

import 'package:app_quanly_giaidau/app.dart';
import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/core/widgets/app_menu_sheet.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_location_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app_driver.dart';
import 'backend_api.dart';
import 'shot.dart';

/// Hàm dùng chung cho các journey Social (buổi giao lưu) chạy trên emulator với Backend thật.
/// Không sửa `backend_api.dart`: gọi API Social ở đây, cùng cách gọi (Dio, bao `{data: ...}`).

/// Mã duy nhất mỗi lượt chạy, đặt vào tên buổi và tên tài khoản để không lẫn dữ liệu giữa các ca.
String socialTag(String prefix) =>
    '$prefix${DateTime.now().millisecondsSinceEpoch % 100000000}';

/// Lỗi gọi API Social: có mã HTTP và 300 ký tự đầu của body.
class SocialApiError implements Exception {
  SocialApiError(this.method, this.path, this.statusCode, this.body);

  final String method;
  final String path;
  final int? statusCode;
  final String body;

  @override
  String toString() => 'SocialApi $method $path -> HTTP ${statusCode ?? '?'}: $body';
}

/// Buổi giao lưu vừa dựng bằng API.
class SeededSession {
  const SeededSession({required this.id, required this.title, required this.raw});

  final String id;
  final String title;
  final Map<String, dynamic> raw;
}

/// Tài khoản phụ tạo mới bằng API (không đăng nhập trên app).
class SeededUser {
  const SeededUser({required this.id, required this.fullName, required this.email});

  final String id;
  final String fullName;
  final String email;
}

/// Gọi Backend Social bằng token của từng vai. Mọi hàm ném [SocialApiError] khi HTTP không phải 2xx.
class SocialApi {
  SocialApi({Dio? dio, BackendApi? backend})
    : _dio = dio ?? _defaultDio(),
      _backend = backend ?? BackendApi();

  static Dio _defaultDio() => Dio(
    BaseOptions(
      baseUrl: kE2eApiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      contentType: Headers.jsonContentType,
      validateStatus: (_) => true,
    ),
  );

  final Dio _dio;
  final BackendApi _backend;
  String? _sportSlug;
  int _pinCounter = 0;

  Future<String> login(String email, [String password = kE2ePassword]) =>
      _backend.login(email, password);

  /// Tạo tài khoản mới (đăng ký công khai) làm người chơi phụ; trả id và tên.
  Future<SeededUser> registerUser({
    required String tag,
    required String label,
  }) async {
    final email = '${tag.toLowerCase()}-${label.toLowerCase().replaceAll(' ', '')}@example.com';
    final fullName = '$tag $label';
    final id = await _backend.registerAccount(
      email: email,
      password: kE2ePassword,
      fullName: fullName,
    );
    return SeededUser(id: id, fullName: fullName, email: email);
  }

  /// Hồ sơ của chính người gọi (`GET /users/profile`).
  /// Backend lồng họ tên trong `profile`: gộp lên cùng cấp như `UserProfile.fromJson` của app.
  Future<Map<String, dynamic>> profile(String token) async {
    final map = _asMap(await _send('GET', '/users/profile', token: token));
    final nested = map['profile'];
    if (nested is Map) {
      nested.forEach((k, v) => map.putIfAbsent('$k', () => v));
    }
    return map;
  }

  /// Môn thể thao đầu tiên đang bật (giống form tạo kèo chọn sẵn), ưu tiên pickleball.
  Future<String> sportSlug() async {
    final cached = _sportSlug;
    if (cached != null) return cached;
    final body = _unwrap(await _send('GET', '/categories'));
    final list = body is List ? body : const [];
    final slugs = [
      for (final item in list)
        if (item is Map &&
            (item['isActive'] == true || item['is_active'] == true) &&
            '${item['slug'] ?? ''}'.isNotEmpty)
          '${item['slug']}',
    ];
    if (slugs.isEmpty) {
      throw SocialApiError('GET', '/categories', 200, 'không có môn thể thao đang bật');
    }
    return _sportSlug = slugs.contains('pickleball') ? 'pickleball' : slugs.first;
  }

  /// Tạo buổi qua `POST /social-sessions` (cùng payload `CreateSocialSessionRequest.toJson`).
  /// [deferred] = true: chưa chọn địa điểm ("Quyết định sau"). Ngược lại ghim sân mới có toạ độ riêng mỗi lần.
  Future<SeededSession> createSession({
    required String token,
    required String title,
    DateTime? startAt,
    int maxSlots = 6,
    int feePerSlot = 0,
    bool deferred = true,
    String playFormat = 'Giao lưu',
    String? description,
  }) async {
    final start = (startAt ?? DateTime.now().add(const Duration(hours: 2))).toUtc();
    _pinCounter++;
    // Toạ độ lệch theo thời gian và bộ đếm để hai lần ghim không bị coi là cùng một sân.
    final jitter = (DateTime.now().millisecondsSinceEpoch % 100000) / 1000000.0;
    final payload = <String, dynamic>{
      'sport': await sportSlug(),
      'title': title,
      'description': ?description,
      'playFormat': playFormat,
      'startAt': start.toIso8601String(),
      'durationMinutes': 120,
      if (deferred)
        'locationDeferred': true
      else
        'newVenue': {
          'name': 'Sân E2E $title',
          'locationAddress': '$_pinCounter Đường E2E, Quận 1, TP.HCM',
          'latitude': 10.70 + jitter,
          'longitude': 106.60 + jitter,
        },
      'maxSlots': maxSlots,
      'feePerSlot': feePerSlot,
      'levelRequirement': 'ALL',
      'visibility': 'PUBLIC',
    };
    final data = _asMap(
      await _send(
        'POST',
        '/social-sessions',
        token: token,
        data: payload,
        headers: {'Idempotency-Key': 'e2e-${DateTime.now().microsecondsSinceEpoch}-$_pinCounter'},
      ),
    );
    final id = '${data['id'] ?? ''}';
    if (id.isEmpty) {
      throw SocialApiError('POST', '/social-sessions', 201, 'thiếu id: ${_snippet(data)}');
    }
    return SeededSession(id: id, title: title, raw: data);
  }

  Future<Map<String, dynamic>> getSession(String token, String sessionId) async =>
      _asMap(await _send('GET', '/social-sessions/$sessionId', token: token));

  /// Người trong buổi (`participants` của chi tiết), gồm host.
  Future<List<Map<String, dynamic>>> participants(String token, String sessionId) async {
    final session = await getSession(token, sessionId);
    final list = session['participants'];
    if (list is! List) return const [];
    return [for (final p in list) if (p is Map) Map<String, dynamic>.from(p)];
  }

  /// Host thêm một tài khoản vào buổi (`POST /participants`).
  Future<void> addUser(String token, String sessionId, String userId) async {
    await _send(
      'POST',
      '/social-sessions/$sessionId/participants',
      token: token,
      data: {'userId': userId, 'ticketCount': 1},
    );
  }

  /// Người chơi gửi yêu cầu tham gia (`POST /requests`).
  Future<void> requestJoin(String token, String sessionId) async {
    await _send(
      'POST',
      '/social-sessions/$sessionId/requests',
      token: token,
      data: {'ticketCount': 1},
    );
  }

  /// Id của buổi có đúng tiêu đề [title], hoặc null khi chưa có.
  Future<String?> idByTitle(String token, String title) async {
    final body = _unwrap(
      await _send(
        'GET',
        '/social-sessions',
        token: token,
        query: {'search': title, 'limit': 20},
      ),
    );
    final items = body is Map ? body['items'] : body;
    if (items is! List) return null;
    for (final e in items) {
      if (e is Map && e['title'] == title) return '${e['id']}';
    }
    return null;
  }

  /// Số buổi có đúng tiêu đề [title] (tìm bằng `search`, không cần ngày).
  Future<int> countByTitle(String token, String title) async {
    final body = _unwrap(
      await _send(
        'GET',
        '/social-sessions',
        token: token,
        query: {'search': title, 'limit': 20},
      ),
    );
    final items = body is Map ? body['items'] : body;
    if (items is! List) return 0;
    return items.where((e) => e is Map && e['title'] == title).length;
  }

  Future<void> cancelSession(String token, String sessionId) async {
    await _send('PATCH', '/social-sessions/$sessionId/cancel', token: token);
  }

  Future<void> sendMessage(String token, String sessionId, String text) async {
    await _send(
      'POST',
      '/social-sessions/$sessionId/messages',
      token: token,
      data: {'messageText': text},
    );
  }

  /// Nội dung các tin nhắn của buổi (`GET /messages`), mới nhất theo thứ tự Backend trả.
  Future<List<String>> messageTexts(String token, String sessionId) async {
    final body = _unwrap(
      await _send(
        'GET',
        '/social-sessions/$sessionId/messages',
        token: token,
        query: {'limit': 50},
      ),
    );
    final list = body is List ? body : const [];
    return [
      for (final m in list)
        if (m is Map) '${m['messageText'] ?? m['message'] ?? m['content'] ?? ''}',
    ];
  }

  Future<Object?> _send(
    String method,
    String path, {
    String? token,
    Object? data,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async {
    final Response<Object?> response;
    try {
      response = await _dio.request<Object?>(
        path,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            ...?headers,
          },
        ),
      );
    } on DioException catch (e) {
      throw _fail(method, path, null, 'lỗi mạng: ${e.message}');
    }
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw _fail(method, path, code, _snippet(response.data));
    }
    return response.data;
  }

  SocialApiError _fail(String method, String path, int? code, String body) {
    final error = SocialApiError(method, path, code, body);
    debugPrint(error.toString());
    return error;
  }

  static Object? _unwrap(Object? body) =>
      body is Map && body.containsKey('data') ? body['data'] : body;

  Map<String, dynamic> _asMap(Object? body) {
    final data = _unwrap(body);
    if (data is! Map) {
      throw SocialApiError('GET', '?', 200, 'không phải object: ${_snippet(body)}');
    }
    return Map<String, dynamic>.from(data);
  }

  static String _snippet(Object? value) {
    final text = value is String ? value : jsonEncode(value);
    return text.length > 300 ? text.substring(0, 300) : text;
  }
}

/// Chụp ảnh từng bước: gom vào log cloud qua `shot()`. `convertFlutterSurfaceToImage` chỉ gọi một lần mỗi test.
class SocialShooter {
  SocialShooter(this.tester, this.binding, this.prefix);

  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;
  final String prefix;
  bool _converted = false;
  int _count = 0;

  Future<void> snap(String name) async {
    if (!_converted) {
      await binding.convertFlutterSurfaceToImage();
      _converted = true;
    }
    await tester.pump();
    _count++;
    final index = _count.toString().padLeft(2, '0');
    await shot(binding, '$prefix-$index-$name');
  }
}

/// Pump theo thời gian thật (mạng, animation) mà không dùng pumpAndSettle (app có animation vô hạn).
Future<void> socialWait(WidgetTester tester, [Duration duration = const Duration(seconds: 1)]) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Đăng nhập bằng form của app như người dùng thật. Trả container để điều hướng và đọc state.
Future<ProviderContainer> signInAs(
  WidgetTester tester, {
  required String email,
  String password = kE2ePassword,
}) async {
  final container = await _pumpAppWithoutGps(tester);
  await ensureSignedOut(tester, container);
  container.read(routerProvider).go('/login');
  await loginWithForm(tester, email: email, password: password);
  await pumpUntilCondition(
    tester,
    () => container.read(authProvider).isAuthenticated,
    what: 'đã đăng nhập $email',
  );
  await socialWait(tester, const Duration(seconds: 2));
  return container;
}

/// Mở màn chi tiết buổi (route `/social/:id`, đẩy lên trên trang hiện tại) và chờ tiêu đề cùng thanh tab hiện ra.
Future<void> openSession(
  WidgetTester tester,
  ProviderContainer container,
  SeededSession session,
) async {
  // Về trang chủ trước để dọn ngăn xếp trang còn sót, rồi push (không go): thoát buổi (huỷ buổi, nút back)
  // cần còn trang bên dưới để pop.
  final router = container.read(routerProvider);
  router.go('/home');
  await socialWait(tester, const Duration(seconds: 1));
  router.push('/social/${session.id}');
  await pumpUntilFound(
    tester,
    find.text(session.title.toUpperCase()),
    what: 'tiêu đề buổi "${session.title}" trên chi tiết buổi',
    timeout: const Duration(seconds: 45),
  );
  await pumpUntilFound(tester, find.text('Chi tiết'), what: 'tab Chi tiết');
}

/// Bấm một tab của chi tiết buổi theo nhãn ("Người tham gia", "Trận đấu", "Thanh toán", "Trò chuyện").
Future<void> openSocialTab(WidgetTester tester, String label) async {
  final tab = find.text(label);
  await pumpUntilFound(tester, tab, what: 'tab "$label"');
  // Thanh tab cuộn ngang: tab cuối (Thanh toán, Trò chuyện) nằm ngoài màn nên phải cuộn vào giữa trước khi bấm.
  await tapCentered(tester, tab);
  await socialWait(tester, const Duration(milliseconds: 1500));
}

/// Chạm chữ [text] sau khi cuộn nó vào giữa màn (tránh header/kính đè).
Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await pumpUntilFound(tester, finder, what: 'chữ "$text"');
  await tapCentered(tester, finder);
}

/// Chạm widget đầu tiên khớp [finder] mà không cuộn.
Future<void> tapFinder(WidgetTester tester, Finder finder, {required String what}) async {
  await pumpUntilFound(tester, finder, what: what);
  await tester.tap(finder.first);
  await tester.pump();
}

/// Số widget Text có đúng nội dung [text] đang hiện.
int countText(String text) => find.text(text).evaluate().length;

/// Widget `Text` đầu tiên có nội dung [text] (để đọc style, ví dụ gạch chân).
Text textWidget(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text).first);

/// Chữ cái đầu như avatar chữ (SocialAvatar): hai chữ đầu của họ và tên cuối, hoặc một chữ.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

/// Mở form tạo kèo bằng đúng đường người dùng đi: tab "Tôi" -> nút "+" trong menu -> "Tạo kèo giao lưu".
Future<void> openCreateSocialForm(WidgetTester tester) async {
  final navProfile = find.descendant(
    of: find.byType(FloatingBottomNav),
    matching: find.text('Tôi'),
  );
  await tapFinder(tester, navProfile, what: 'nhãn "Tôi" trên thanh điều hướng');
  final plus = find.descendant(
    of: find.byType(AppMenuSheet),
    matching: find.byIcon(Icons.add_rounded),
  );
  await tapFinder(tester, plus, what: 'nút "+" trong menu');
  await tapText(tester, 'Tạo kèo giao lưu');
  await pumpUntilFound(
    tester,
    find.text('Tạo kèo'),
    what: 'form tạo kèo (tiêu đề "Tạo kèo")',
  );
}

/// Từ trang chủ sang tab Khám phá, cuộn tới thẻ buổi [title] của ngày đang chọn rồi bấm mở chi tiết.
Future<void> openSessionFromExplore(WidgetTester tester, String title) async {
  final navExplore = find.descendant(
    of: find.byType(FloatingBottomNav),
    matching: find.text('Khám phá'),
  );
  await tapFinder(tester, navExplore, what: 'nhãn Khám phá trên thanh điều hướng');
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('explore_social')),
    what: 'danh sách Khám phá (explore_social)',
  );
  await scrollToText(tester, title);
  await tapCentered(tester, find.text(title));
  await pumpUntilFound(
    tester,
    find.text(title.toUpperCase()),
    what: 'chi tiết buổi "$title" mở từ thẻ ở Khám phá',
    timeout: const Duration(seconds: 45),
  );
}

/// Không xin quyền vị trí trong E2E: hộp xin quyền hệ thống không ai bấm, yêu cầu treo qua các ca và ca sau
/// ném "A request for permissions is already running". Quyền vị trí không thuộc phạm vi Social E2E.
class _NoGpsLocation extends UserLocationNotifier {
  @override
  Future<void> requestWhenInUse() async {}

  @override
  Future<void> refreshSilently() async {}
}

/// Container của các lần dựng app trước trong cùng tiến trình test. Phải huỷ hết: provider `HomeMatchFeedNotifier`
/// hẹn giờ 60s đóng keepAlive khi hết người nghe, huỷ container mới cancel được hẹn giờ đó. Để sót thì hẹn giờ bắn
/// giữa hai ca và Flutter tính lỗi "Cannot schedule a task on an unmounted element" vào ca vừa chạy xong.
final List<ProviderContainer> _liveContainers = [];

void _disposeLiveContainersExcept(ProviderContainer keep) {
  for (final old in _liveContainers.where((c) => !identical(c, keep))) {
    old.dispose();
  }
  _liveContainers
    ..clear()
    ..add(keep);
}

/// Giống `pumpApp` của app_driver, chỉ thêm override vị trí ở trên.
Future<ProviderContainer> _pumpAppWithoutGps(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [userLocationProvider.overrideWith(_NoGpsLocation.new)],
  );
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
  _liveContainers.add(container);
  _disposeLiveContainersExcept(container);
  return container;
}

/// Gỡ khỏi hàng đợi các lỗi sản phẩm ĐÃ BIẾT (ghi `BUG-SAN-PHAM` vào log, không nuốt im lặng); lỗi khác thì fail.
/// Đã biết: (1) sheet "Yêu cầu tham gia Social" tràn ngang 36px khi đóng, (2) `ChatDetailScreen` gọi setState
/// sau dispose khi socket đóng (chat_detail_screen.dart:164-171). Cả hai là lỗi của `lib/`, ngoài phạm vi change này.
int drainKnownProductErrors(WidgetTester tester) {
  var count = 0;
  while (true) {
    final error = tester.takeException();
    if (error == null) return count;
    final text = '$error';
    final known = text.contains('overflowed by') ||
        text.contains('_lifecycleState') ||
        text.contains('Cannot schedule a task on an unmounted element');
    if (!known) fail('Lỗi ngoài danh sách đã biết: $text');
    count++;
    debugPrint('BUG-SAN-PHAM đã biết: ${text.split('\n').first}');
  }
}

/// Rời chi tiết buổi về trang chủ trong thân test (chat socket đóng ở đây) rồi gỡ lỗi sản phẩm đã biết.
Future<void> leaveSocialSession(WidgetTester tester, ProviderContainer container) async {
  container.read(routerProvider).go('/home');
  await socialWait(tester, const Duration(seconds: 2));
  drainKnownProductErrors(tester);
  // Gỡ cây widget rồi huỷ container: bộ hẹn giờ keepAlive của provider cũ không được bắn sau khi test kết thúc
  // (lỗi "Cannot schedule a task on an unmounted element" bị tính vào ca chạy sau).
  await tester.pumpWidget(const SizedBox.shrink());
  drainKnownProductErrors(tester);
  _liveContainers.remove(container);
  container.dispose();
}
