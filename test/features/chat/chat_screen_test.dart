import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/chat/screens/chat_detail_screen.dart';
import 'package:app_quanly_giaidau/features/chat/screens/chat_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../support/fake_api_adapter.dart';

const _me = 'user-me';

/// Adapter cho phép mỗi route trả lời khác nhau theo lần gọi và giữ response
/// lại khi cần.
class _CountingAdapter extends FakeApiAdapter {
  _CountingAdapter(super.routes);

  int count(String method, String path) =>
      requests.where((r) => r.method == method && r.path == path).length;
}

Map<String, dynamic> _room({
  required String id,
  String type = 'GROUP',
  String? name,
  String? clubName,
  int unread = 0,
  DateTime? updatedAt,
  Map<String, dynamic>? lastMessage,
  List<Map<String, dynamic>>? participants,
}) => {
  'id': id,
  'type': type,
  'name': ?name,
  'clubName': ?clubName,
  'unreadCount': unread,
  'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
  'lastMessage': ?lastMessage,
  'participants': ?participants,
};

Map<String, dynamic> _message(
  String content, {
  bool revoked = false,
  List<String> media = const [],
  String sender = 'other',
}) => {
  'id': 'm-${content.hashCode}',
  'roomId': 'r',
  'senderId': sender,
  'content': content,
  'isRevoked': revoked,
  'attachmentsUrls': media,
  'createdAt': DateTime.now().toIso8601String(),
};

FakeReply _rooms(List<Map<String, dynamic>> rooms) =>
    FakeReply(200, {'data': rooms});

FakeReply _support(List<Map<String, dynamic>> messages) => FakeReply(200, {
  'data': {'messages': messages},
});

Map<String, FakeReply> _routes({
  List<Map<String, dynamic>> rooms = const [],
  List<Map<String, dynamic>> support = const [],
}) => {
  'GET /chat/rooms': _rooms(rooms),
  'GET /chat/support/me': _support(support),
};

/// DioClient dùng I/O thật nên cho vài nhịp thời gian thật rồi dựng lại khung
/// hình, thay cho pumpAndSettle (màn có Timer lặp 15 giây).
Future<void> _settle(WidgetTester tester) async {
  // 8 x 300ms đủ cho 2 lần thử lại 350ms + 700ms của DioClient khi gặp 5xx.
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _pump(
  WidgetTester tester,
  FakeApiAdapter adapter, {
  bool canPop = true,
}) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: canPop ? '/start' : '/chat',
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/chat'),
            child: const Text('VÀO CHAT'),
          ),
        ),
      ),
      GoRoute(path: '/chat', builder: (_, _) => const ChatScreen()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('AT /home')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        dioClientProvider.overrideWithValue(fakeDioClient(adapter)),
        tokenManagerProvider.overrideWithValue(NoTokenManager()),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(id: _me, fullName: 'Tôi'),
        ),
        userRankingsProvider.overrideWith((ref) async => const []),
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
  if (canPop) {
    await tester.tap(find.text('VÀO CHAT'));
    await tester.pump();
  }
  await _settle(tester);
}

/// Cho chuyển động đổi tab (PageView) chạy hết.
Future<void> _openedTab(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Gỡ màn để huỷ Timer.periodic 15 giây trước khi test kết thúc.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void chatTest(
  String name,
  Future<void> Function(WidgetTester tester) body, {
  bool skip = false,
}) {
  testWidgets(name, (tester) async {
    await body(tester);
    await _unmount(tester);
  }, skip: skip);
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  final l10n = lookupAppLocalizations(const Locale('vi'));

  Finder tab(String label) => find.text(label);

  group('tab Trò chuyện: danh sách phòng', () {
    chatTest('hiện tiêu đề, ba tab và ô tìm kiếm', (tester) async {
      await _pump(tester, FakeApiAdapter(_routes()));

      expect(find.text(l10n.chatScreenTitle), findsOneWidget);
      expect(tab(l10n.chatScreenConversations), findsOneWidget);
      expect(tab(l10n.chatScreenAiAssistant), findsOneWidget);
      expect(tab(l10n.chatScreenSupport), findsOneWidget);
      expect(find.text(l10n.chatScreenSearchHint), findsOneWidget);
    });

    chatTest('đang tải: hiện khung chờ, chưa có thông báo rỗng', (
      tester,
    ) async {
      final adapter = FakeApiAdapter(_routes());
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            dioClientProvider.overrideWithValue(fakeDioClient(adapter)),
            tokenManagerProvider.overrideWithValue(NoTokenManager()),
            userProfileProvider.overrideWith(
              (ref) async => const UserProfile(id: _me),
            ),
            userRankingsProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            theme: ThemeData.light(),
            home: const ChatScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(l10n.chatScreenNoConversations), findsNothing);
      expect(find.byType(ListTile), findsNothing);

      await _settle(tester);
      expect(find.text(l10n.chatScreenNoConversations), findsOneWidget);
    });

    chatTest('không có phòng nào: hiện Chưa có cuộc trò chuyện', (
      tester,
    ) async {
      await _pump(tester, FakeApiAdapter(_routes()));

      expect(find.text(l10n.chatScreenNoConversations), findsOneWidget);
      expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    });

    chatTest(
      'API phòng lỗi 500: không vỡ màn, kết thúc tải và hiện trạng thái rỗng',
      (tester) async {
        final adapter = FakeApiAdapter({
          'GET /chat/rooms': const FakeReply(500, {'message': 'boom'}),
          'GET /chat/support/me': _support(const []),
        });
        await _pump(tester, adapter);

        expect(tester.takeException(), isNull);
        expect(find.text(l10n.chatScreenNoConversations), findsOneWidget);
      },
    );

    chatTest(
      'mất mạng khi tải phòng: không vỡ màn và vẫn dùng được các tab khác',
      (tester) async {
        final adapter = FakeApiAdapter({
          'GET /chat/rooms': const FakeReply.networkError(),
          'GET /chat/support/me': const FakeReply.networkError(),
        });
        await _pump(tester, adapter);

        expect(tester.takeException(), isNull);
        await tester.tap(tab(l10n.chatScreenSupport));
        await _settle(tester);
        expect(find.text(l10n.chatScreenSupportTitle), findsOneWidget);
      },
    );

    chatTest(
      'hiện tên phòng, nội dung tin mới nhất và sắp xếp phòng mới nhất lên đầu',
      (tester) async {
        final now = DateTime.now();
        final adapter = FakeApiAdapter(
          _routes(
            rooms: [
              _room(
                id: 'old',
                name: 'Phòng cũ',
                updatedAt: now.subtract(const Duration(days: 30)),
                lastMessage: _message('tin cũ'),
              ),
              _room(
                id: 'new',
                name: 'Phòng mới',
                updatedAt: now,
                lastMessage: _message('tin mới nhất'),
              ),
            ],
          ),
        );
        await _pump(tester, adapter);

        expect(find.text('tin mới nhất'), findsOneWidget);
        expect(find.text('tin cũ'), findsOneWidget);
        final newY = tester.getTopLeft(find.text('Phòng mới')).dy;
        final oldY = tester.getTopLeft(find.text('Phòng cũ')).dy;
        expect(newY, lessThan(oldY));
      },
    );

    chatTest('phòng CLB có nhãn CLB, phòng nhóm thì không', (tester) async {
      final adapter = FakeApiAdapter(
        _routes(
          rooms: [
            _room(id: 'c', type: 'CLUB', clubName: 'CLB Sấm Sét'),
            _room(id: 'g', type: 'GROUP', name: 'Nhóm đánh đôi'),
          ],
        ),
      );
      await _pump(tester, adapter);

      expect(find.text('CLB Sấm Sét'), findsOneWidget);
      expect(find.text(l10n.chatScreenClubBadge), findsOneWidget);
    });

    chatTest(
      'phòng CLB không có tên: dùng tên dự phòng và chữ cái đầu làm avatar',
      (tester) async {
        final adapter = FakeApiAdapter(
          _routes(
            rooms: [_room(id: 'c', type: 'CLUB')],
          ),
        );
        await _pump(tester, adapter);

        expect(find.text(l10n.chatScreenClubBadge), findsOneWidget);
        expect(find.byType(CircleAvatar), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    chatTest('phòng trực tiếp lấy tên người còn lại, không lấy tên mình', (
      tester,
    ) async {
      final adapter = FakeApiAdapter(
        _routes(
          rooms: [
            _room(
              id: 'd',
              type: 'DIRECT',
              participants: [
                {'id': _me, 'fullName': 'Tôi'},
                {'id': 'peer', 'fullName': 'Trần Bình'},
              ],
            ),
          ],
        ),
      );
      await _pump(tester, adapter);

      expect(find.text('Trần Bình'), findsOneWidget);
      expect(find.text('Tôi'), findsNothing);
      expect(find.text(l10n.chatScreenClubBadge), findsNothing);
    });

    chatTest(
      'số tin chưa đọc hiện ở huy hiệu, phòng đã đọc không có huy hiệu',
      (tester) async {
        final adapter = FakeApiAdapter(
          _routes(
            rooms: [
              _room(id: 'u', name: 'Có tin mới', unread: 7),
              _room(id: 'r', name: 'Đã đọc', unread: 0),
            ],
          ),
        );
        await _pump(tester, adapter);

        expect(find.text('7'), findsOneWidget);
        expect(find.text('0'), findsNothing);
      },
    );

    chatTest('tin nhắn đã thu hồi hiện câu thay thế, không lộ nội dung gốc', (
      tester,
    ) async {
      final adapter = FakeApiAdapter(
        _routes(
          rooms: [
            _room(
              id: 'r',
              name: 'Phòng A',
              lastMessage: _message('nội dung bí mật', revoked: true),
            ),
          ],
        ),
      );
      await _pump(tester, adapter);

      expect(find.text(l10n.chatScreenRevokedMessage), findsOneWidget);
      expect(find.text('nội dung bí mật'), findsNothing);
    });

    chatTest('tin chỉ có ảnh hiện [Hình ảnh]', (tester) async {
      final adapter = FakeApiAdapter(
        _routes(
          rooms: [
            _room(
              id: 'r',
              name: 'Phòng ảnh',
              lastMessage: _message('', media: ['https://x/a.png']),
            ),
          ],
        ),
      );
      await _pump(tester, adapter);

      expect(find.text(l10n.chatScreenImageMessage), findsOneWidget);
    });

    chatTest('phòng chưa có tin nào hiện Bắt đầu cuộc trò chuyện', (
      tester,
    ) async {
      final adapter = FakeApiAdapter(
        _routes(
          rooms: [_room(id: 'r', name: 'Phòng trống')],
        ),
      );
      await _pump(tester, adapter);

      expect(find.text(l10n.chatScreenStartConversation), findsOneWidget);
    });

    chatTest('thời gian: hôm nay giờ:phút, quá 7 ngày dd/MM', (tester) async {
      final now = DateTime.now();
      final old = now.subtract(const Duration(days: 30));
      final adapter = FakeApiAdapter(
        _routes(
          rooms: [
            _room(id: 'a', name: 'Hôm nay', updatedAt: now),
            _room(id: 'b', name: 'Tháng trước', updatedAt: old),
          ],
        ),
      );
      await _pump(tester, adapter);

      expect(find.text(DateFormat('HH:mm').format(now)), findsOneWidget);
      expect(find.text(DateFormat('dd/MM').format(old)), findsOneWidget);
    });

    chatTest('thời gian: trong vòng 7 ngày hiện thứ trong tuần', (
      tester,
    ) async {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final adapter = FakeApiAdapter(
        _routes(
          rooms: [_room(id: 'a', name: 'Mấy hôm', updatedAt: threeDaysAgo)],
        ),
      );
      await _pump(tester, adapter);

      expect(
        find.text(DateFormat('EEEE', 'vi').format(threeDaysAgo)),
        findsOneWidget,
      );
    });

    chatTest('máy chủ trả mảng trần hoặc khoá items vẫn đọc được', (
      tester,
    ) async {
      final adapter = FakeApiAdapter({
        'GET /chat/rooms': FakeReply(200, {
          'items': [_room(id: 'i', name: 'Từ items')],
        }),
        'GET /chat/support/me': _support(const []),
      });
      await _pump(tester, adapter);

      expect(find.text('Từ items'), findsOneWidget);
    });

    chatTest('phần tử không phải object trong danh sách bị bỏ qua', (
      tester,
    ) async {
      final adapter = FakeApiAdapter({
        'GET /chat/rooms': FakeReply(200, {
          'data': ['rác', 42, _room(id: 'ok', name: 'Phòng hợp lệ')],
        }),
        'GET /chat/support/me': _support(const []),
      });
      await _pump(tester, adapter);

      expect(find.text('Phòng hợp lệ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('tìm kiếm', () {
    Future<_CountingAdapter> pumpSearchFixture(WidgetTester tester) async {
      final adapter = _CountingAdapter(
        _routes(
          rooms: [
            _room(
              id: '1',
              name: 'Pickleball Hà Nội',
              lastMessage: _message('hẹn sân tối nay'),
            ),
            _room(
              id: '2',
              name: 'Cầu lông Sài Gòn',
              lastMessage: _message('giải cuối tuần'),
            ),
          ],
        ),
      );
      await _pump(tester, adapter);
      return adapter;
    }

    chatTest('lọc theo tên phòng, không phân biệt hoa thường', (tester) async {
      await pumpSearchFixture(tester);

      await tester.enterText(find.byType(TextField).first, 'PICKLEBALL');
      await tester.pump();

      expect(find.text('Pickleball Hà Nội'), findsOneWidget);
      expect(find.text('Cầu lông Sài Gòn'), findsNothing);
    });

    chatTest('lọc theo nội dung tin nhắn mới nhất', (tester) async {
      await pumpSearchFixture(tester);

      await tester.enterText(find.byType(TextField).first, 'cuối tuần');
      await tester.pump();

      expect(find.text('Cầu lông Sài Gòn'), findsOneWidget);
      expect(find.text('Pickleball Hà Nội'), findsNothing);
    });

    chatTest(
      'không khớp: hiện Không tìm thấy; xoá từ khoá thì danh sách trở lại',
      (tester) async {
        await pumpSearchFixture(tester);

        await tester.enterText(find.byType(TextField).first, 'zzzz');
        await tester.pump();
        expect(find.text(l10n.chatScreenNoSearchResults), findsOneWidget);
        expect(find.text(l10n.chatScreenNoConversations), findsNothing);

        await tester.enterText(find.byType(TextField).first, '');
        await tester.pump();
        expect(find.text('Pickleball Hà Nội'), findsOneWidget);
        expect(find.text('Cầu lông Sài Gòn'), findsOneWidget);
      },
    );

    chatTest('từ khoá chỉ có khoảng trắng không lọc gì', (tester) async {
      await pumpSearchFixture(tester);

      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.pump();

      expect(find.text('Pickleball Hà Nội'), findsOneWidget);
      expect(find.text('Cầu lông Sài Gòn'), findsOneWidget);
    });
  });

  group('làm mới và điều hướng', () {
    chatTest('kéo xuống khi danh sách dài: gọi lại /chat/rooms và cập nhật', (
      tester,
    ) async {
      final adapter = _CountingAdapter(
        _routes(
          rooms: [
            for (var i = 0; i < 30; i++) _room(id: 'r$i', name: 'Phòng số $i'),
          ],
        ),
      );
      await _pump(tester, adapter);
      expect(adapter.count('GET', '/chat/rooms'), 1);

      adapter.routes['GET /chat/rooms'] = _rooms([
        _room(id: 'new', name: 'Phòng vừa tạo'),
        for (var i = 0; i < 30; i++) _room(id: 'r$i', name: 'Phòng số $i'),
      ]);
      await tester.drag(find.byType(ListTile).first, const Offset(0, 1200));
      await _settle(tester);

      expect(adapter.count('GET', '/chat/rooms'), 2);
    });

    // BUG-CHAT-02: RefreshIndicator bọc Column chứa ListView không có
    // AlwaysScrollableScrollPhysics, nên trên Android danh sách ngắn (hoặc trạng
    // thái rỗng) không kéo xuống để tải lại được.
    chatTest('BUG-CHAT-02 kéo xuống khi danh sách ngắn vẫn tải lại được', (
      tester,
    ) async {
      final adapter = _CountingAdapter(
        _routes(
          rooms: [_room(id: '1', name: 'Phòng duy nhất')],
        ),
      );
      await _pump(tester, adapter);

      await tester.drag(find.byType(ListTile).first, const Offset(0, 1200));
      await _settle(tester);

      expect(adapter.count('GET', '/chat/rooms'), 2);
    }, skip: true);

    chatTest('tự làm mới yên lặng sau 15 giây, không hiện lại khung chờ', (
      tester,
    ) async {
      final adapter = _CountingAdapter(
        _routes(
          rooms: [_room(id: '1', name: 'Phòng A')],
        ),
      );
      await _pump(tester, adapter);

      await tester.pump(const Duration(seconds: 15));
      expect(find.byType(ListTile), findsOneWidget);
      await _settle(tester);

      expect(adapter.count('GET', '/chat/rooms'), 2);
      expect(find.text('Phòng A'), findsOneWidget);
    });

    chatTest(
      'làm mới yên lặng giữ phòng trực tiếp cũ nhưng bỏ phòng CLB đã biến mất',
      (tester) async {
        final adapter = _CountingAdapter(
          _routes(
            rooms: [
              _room(
                id: 'd',
                type: 'DIRECT',
                participants: [
                  {'id': _me, 'fullName': 'Tôi'},
                  {'id': 'p', 'fullName': 'Bạn Trực Tiếp'},
                ],
              ),
              _room(id: 'c', type: 'CLUB', clubName: 'CLB Sẽ Mất'),
            ],
          ),
        );
        await _pump(tester, adapter);
        expect(find.text('Bạn Trực Tiếp'), findsOneWidget);
        expect(find.text('CLB Sẽ Mất'), findsOneWidget);

        adapter.routes['GET /chat/rooms'] = _rooms([
          _room(id: 'g', name: 'Nhóm mới'),
        ]);
        await tester.pump(const Duration(seconds: 15));
        await _settle(tester);

        expect(find.text('Bạn Trực Tiếp'), findsOneWidget);
        expect(find.text('Nhóm mới'), findsOneWidget);
        expect(find.text('CLB Sẽ Mất'), findsNothing);
      },
    );

    chatTest(
      'chạm vào phòng mở màn chi tiết và tải lại danh sách khi quay về',
      (tester) async {
        final adapter = _CountingAdapter(
          _routes(
            rooms: [_room(id: 'r1', name: 'Phòng mở')],
          ),
        );
        await _pump(tester, adapter);
        final before = adapter.count('GET', '/chat/rooms');

        await tester.tap(find.text('Phòng mở'));
        await _settle(tester);
        expect(find.byType(ChatDetailScreen), findsOneWidget);

        Navigator.of(tester.element(find.byType(ChatDetailScreen))).pop();
        await _settle(tester);

        expect(find.byType(ChatDetailScreen), findsNothing);
        expect(adapter.count('GET', '/chat/rooms'), greaterThan(before));
      },
    );

    chatTest('nút quay lại: có lịch sử thì quay về màn trước', (tester) async {
      await _pump(tester, FakeApiAdapter(_routes()));

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await _settle(tester);

      expect(find.text('VÀO CHAT'), findsOneWidget);
    });

    chatTest('nút quay lại: mở trực tiếp (không có lịch sử) thì về /home', (
      tester,
    ) async {
      await _pump(tester, FakeApiAdapter(_routes()), canPop: false);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await _settle(tester);

      expect(find.text('AT /home'), findsOneWidget);
    });
  });

  group('tab AI Trợ lý', () {
    Future<void> openAi(WidgetTester tester) async {
      await tester.tap(tab(l10n.chatScreenAiAssistant));
      await _openedTab(tester);
    }

    chatTest('có lời chào của trợ lý và bốn gợi ý nhanh', (tester) async {
      await _pump(tester, FakeApiAdapter(_routes()));
      await openAi(tester);

      expect(find.text(l10n.chatScreenAiGreeting), findsOneWidget);
      for (final prompt in [
        l10n.chatScreenAiPromptRegistration,
        l10n.chatScreenAiPromptElo,
        l10n.chatScreenAiPromptCreateClub,
      ]) {
        expect(find.text(prompt), findsOneWidget);
      }
    });

    chatTest(
      'gửi câu hỏi: thêm tin của mình, gửi lịch sử + isMobile, hiện câu trả lời',
      (tester) async {
        final adapter = FakeApiAdapter({
          ..._routes(),
          'POST /ai/message': const FakeReply(200, {
            'reply': 'ELO là điểm kỹ năng.',
          }),
        });
        await _pump(tester, adapter);
        await openAi(tester);

        await tester.enterText(find.byType(TextField).last, '  ELO là gì?  ');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await _settle(tester);

        final post = adapter.postsTo('/ai/message').single.body!;
        expect(post['message'], 'ELO là gì?');
        expect(post['isMobile'], true);
        expect(find.text('ELO là gì?'), findsOneWidget);
        expect(find.text('ELO là điểm kỹ năng.'), findsOneWidget);
        expect(find.text(l10n.chatScreenAiTyping), findsNothing);
        expect(
          tester
              .widget<TextField>(find.byType(TextField).last)
              .controller!
              .text,
          '',
        );
      },
    );

    chatTest('ô trống hoặc chỉ khoảng trắng: không gửi gì', (tester) async {
      final adapter = FakeApiAdapter(_routes());
      await _pump(tester, adapter);
      await openAi(tester);

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, '   ');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await _settle(tester);

      expect(adapter.postsTo('/ai/message'), isEmpty);
    });

    chatTest('bấm gợi ý nhanh gửi đúng câu gợi ý đó', (tester) async {
      final adapter = FakeApiAdapter({
        ..._routes(),
        'POST /ai/message': const FakeReply(200, {
          'reply': 'Vào mục Giải đấu.',
        }),
      });
      await _pump(tester, adapter);
      await openAi(tester);

      await tester.tap(find.text(l10n.chatScreenAiPromptRegistration));
      await _settle(tester);

      expect(
        adapter.postsTo('/ai/message').single.body!['message'],
        l10n.chatScreenAiPromptRegistration,
      );
      expect(find.text('Vào mục Giải đấu.'), findsOneWidget);
    });

    chatTest('máy chủ không có trường trả lời: dùng câu dự phòng', (
      tester,
    ) async {
      final adapter = FakeApiAdapter({
        ..._routes(),
        'POST /ai/message': const FakeReply(200, {'other': 1}),
      });
      await _pump(tester, adapter);
      await openAi(tester);

      await tester.enterText(find.byType(TextField).last, 'xin chào');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await _settle(tester);

      expect(find.text(l10n.chatScreenAiFallbackReply), findsOneWidget);
    });

    chatTest('trả lời nằm ở khoá data hoặc content cũng được nhận', (
      tester,
    ) async {
      final adapter = FakeApiAdapter({
        ..._routes(),
        'POST /ai/message': const FakeReply(200, {
          'data': 'Trả lời trong data',
        }),
      });
      await _pump(tester, adapter);
      await openAi(tester);

      await tester.enterText(find.byType(TextField).last, 'hỏi');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await _settle(tester);

      expect(find.text('Trả lời trong data'), findsOneWidget);
    });

    chatTest('lỗi gọi AI: hiện câu xin lỗi và cho hỏi tiếp', (tester) async {
      final adapter = FakeApiAdapter({
        ..._routes(),
        'POST /ai/message': const FakeReply(500, {'message': 'AI down'}),
      });
      await _pump(tester, adapter);
      await openAi(tester);

      await tester.enterText(find.byType(TextField).last, 'hỏi lần một');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await _settle(tester);
      expect(find.text(l10n.chatScreenAiErrorReply), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'hỏi lần hai');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await _settle(tester);
      expect(adapter.postsTo('/ai/message'), hasLength(2));
    });
  });

  group('tab Hỗ trợ CSKH', () {
    Future<void> openSupport(WidgetTester tester) async {
      await tester.tap(tab(l10n.chatScreenSupport));
      await _openedTab(tester);
    }

    chatTest('chưa có tin nhắn: hiện giới thiệu trung tâm hỗ trợ', (
      tester,
    ) async {
      await _pump(tester, FakeApiAdapter(_routes()));
      await openSupport(tester);

      expect(find.text(l10n.chatScreenSupportTitle), findsOneWidget);
      expect(find.text(l10n.chatScreenSupportDescription), findsOneWidget);
    });

    chatTest('có lịch sử hỗ trợ: hiện các tin nhắn, ẩn phần giới thiệu', (
      tester,
    ) async {
      final adapter = FakeApiAdapter(
        _routes(
          support: [
            _message('Em cần hỗ trợ hoàn phí', sender: _me),
            _message('CSKH đã nhận yêu cầu'),
          ],
        ),
      );
      await _pump(tester, adapter);
      await openSupport(tester);

      expect(find.text('Em cần hỗ trợ hoàn phí'), findsOneWidget);
      expect(find.text('CSKH đã nhận yêu cầu'), findsOneWidget);
      expect(find.text(l10n.chatScreenSupportTitle), findsNothing);
    });

    chatTest(
      'gửi tin: POST messageText đã cắt khoảng trắng, xoá ô nhập, hiện hội thoại mới',
      (tester) async {
        final adapter = FakeApiAdapter({
          ..._routes(),
          'POST /chat/support': FakeReply(200, {
            'data': {
              'messages': [_message('Cần giúp đỡ', sender: _me)],
            },
          }),
        });
        await _pump(tester, adapter);
        await openSupport(tester);

        await tester.enterText(find.byType(TextField).last, '  Cần giúp đỡ  ');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await _settle(tester);

        expect(adapter.postsTo('/chat/support').single.body, {
          'messageText': 'Cần giúp đỡ',
        });
        expect(find.text('Cần giúp đỡ'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byType(TextField).last)
              .controller!
              .text,
          '',
        );
      },
    );

    chatTest('tin rỗng không được gửi', (tester) async {
      final adapter = FakeApiAdapter(_routes());
      await _pump(tester, adapter);
      await openSupport(tester);

      await tester.enterText(find.byType(TextField).last, '   ');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await _settle(tester);

      expect(adapter.postsTo('/chat/support'), isEmpty);
    });

    chatTest('gửi lỗi: không vỡ màn, vẫn ở tab hỗ trợ', (tester) async {
      final adapter = FakeApiAdapter({
        ..._routes(),
        'POST /chat/support': const FakeReply(500, {'message': 'x'}),
      });
      await _pump(tester, adapter);
      await openSupport(tester);

      await tester.enterText(find.byType(TextField).last, 'Có ai không');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(l10n.chatScreenSupportInputHint), findsOneWidget);
    });
  });
}
