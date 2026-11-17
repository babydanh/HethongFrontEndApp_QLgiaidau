import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/di/socket_providers.dart';
import 'package:app_quanly_giaidau/core/services/chat_socket_service.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/chat/screens/chat_detail_screen.dart';
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
const _roomId = 'room-1';

/// Never opens a network connection; lets the test fire the server event.
class _FakeChatSocket extends ChatSocketService {
  _FakeChatSocket(super.tokenManager);

  static _FakeChatSocket? last;

  @override
  Future<void> connect(String roomId) async {
    last = this;
  }

  void emitKicked(Map<String, dynamic> data) => onRoomKicked?.call(data);

  void emitEvicted(Map<String, dynamic> data) => onRoomEvicted?.call(data);

  void emitSettings(Map<String, dynamic> data) => onRoomSettings?.call(data);
}

Map<String, FakeReply> _routes({
  FakeReply? messages,
  FakeReply? send,
  Map<String, dynamic> room = const {},
  FakeReply? chatRoom,
}) => {
  'GET /chat/rooms/$_roomId/messages':
      messages ??
      FakeReply(200, {
        'data': {
          'data': [
            {
              'id': 'm1',
              'roomId': _roomId,
              'senderId': 'someone',
              'senderName': 'Bạn An',
              'content': 'Sân 3 nhé',
              'createdAt': DateTime.now().toIso8601String(),
            },
          ],
          'meta': {'hasMore': false},
        },
      }),
  'GET /chat/rooms/$_roomId': FakeReply(200, {
    'data': {'id': _roomId, 'participants': [], ...room},
  }),
  'POST /chat/messages': ?send,
  'GET /tournaments/t1/chat-room': ?chatRoom,
  'GET /chat/rooms/$_roomId/pinned': const FakeReply(200, {'data': null}),
  'POST /chat/rooms/$_roomId/kicks': const FakeReply(201, {'data': {}}),
};

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _pump(
  WidgetTester tester,
  FakeApiAdapter adapter, {
  bool readOnly = false,
  bool organizer = false,
  String roomType = 'TOURNAMENT',
}) async {
  _FakeChatSocket.last = null;
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/room'),
            child: const Text('VÀO PHÒNG'),
          ),
        ),
      ),
      GoRoute(
        path: '/room',
        builder: (_, _) => ChatDetailScreen(
          roomId: _roomId,
          roomName: 'Phòng giải',
          roomType: roomType,
          readOnly: readOnly,
          isRoomOrganizer: organizer,
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        dioClientProvider.overrideWithValue(fakeDioClient(adapter)),
        tokenManagerProvider.overrideWithValue(NoTokenManager()),
        chatSocketFactoryProvider.overrideWithValue(_FakeChatSocket.new),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(id: _me, fullName: 'Tôi'),
        ),
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
  await tester.tap(find.text('VÀO PHÒNG'));
  await tester.pump();
  await _settle(tester);
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  final l10n = lookupAppLocalizations(const Locale('vi'));

  testWidgets('TC-ROOM-A08 an open room has the input box and no closed strip', (
    tester,
  ) async {
    await _pump(tester, FakeApiAdapter(_routes()));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text(l10n.chatRoomClosedBanner), findsNothing);
    await _unmount(tester);
  });

  testWidgets('TC-ROOM-A09 a closed room hides the input and shows the closed strip', (
    tester,
  ) async {
    await _pump(tester, FakeApiAdapter(_routes()), readOnly: true);

    expect(find.byType(TextField), findsNothing);
    expect(find.text(l10n.chatRoomClosedBanner), findsOneWidget);
    expect(find.text('Sân 3 nhé'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('TC-ROOM-A10 a 403 ROOM_KICKED reply closes the screen with a notice', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeApiAdapter(
        _routes(
          messages: const FakeReply(403, {
            'statusCode': 403,
            'code': 'ROOM_KICKED',
            'message': 'ROOM_KICKED',
          }),
        ),
      ),
    );

    expect(find.byType(ChatDetailScreen), findsNothing);
    expect(find.text(l10n.chatRoomKickedNotice), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('TC-ROOM-A11 the chat:room:kicked event closes the screen with a notice', (
    tester,
  ) async {
    await _pump(tester, FakeApiAdapter(_routes()));
    expect(find.byType(ChatDetailScreen), findsOneWidget);

    _FakeChatSocket.last!.emitKicked({'roomId': _roomId});
    await tester.pumpAndSettle();

    expect(find.byType(ChatDetailScreen), findsNothing);
    expect(find.text(l10n.chatRoomKickedNotice), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('TC-ROOM-A11 a kicked event for another room is ignored', (
    tester,
  ) async {
    await _pump(tester, FakeApiAdapter(_routes()));

    _FakeChatSocket.last!.emitKicked({'roomId': 'other-room'});
    await tester.pump();

    expect(find.byType(ChatDetailScreen), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('TC-ROOM-A13 a plain member gets no pin or kick in the message menu', (
    tester,
  ) async {
    await _pump(tester, FakeApiAdapter(_routes()));

    await tester.longPress(find.text('Sân 3 nhé'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.chatReplyAction), findsOneWidget);
    expect(find.text(l10n.chatPinMessageAction), findsNothing);
    expect(find.text(l10n.chatKickUserAction), findsNothing);
    expect(find.text(l10n.chatRevokeMessageAction), findsNothing);
    await _unmount(tester);
  });

  testWidgets('TC-ROOM-A14 the organizer kicks the sender after one confirmation', (
    tester,
  ) async {
    final adapter = FakeApiAdapter(_routes());
    await _pump(tester, adapter, organizer: true);

    await tester.longPress(find.text('Sân 3 nhé'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.chatPinMessageAction), findsOneWidget);
    expect(find.text(l10n.chatRevokeMessageAction), findsOneWidget);

    await tester.tap(find.text(l10n.chatKickUserAction));
    await tester.pumpAndSettle();
    expect(find.text(l10n.chatKickConfirmBody('Bạn An')), findsOneWidget);
    expect(
      adapter.requests.where((r) => r.path.endsWith('/kicks')),
      isEmpty,
      reason: 'nothing is sent before the organizer confirms',
    );

    await tester.tap(find.text(l10n.chatKickConfirmAction));
    await _settle(tester);

    final kick = adapter.requests.singleWhere(
      (r) => r.method == 'POST' && r.path == '/chat/rooms/$_roomId/kicks',
    );
    expect(kick.body, {'userId': 'someone'});
    await _unmount(tester);
  });

  Future<void> send(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await _settle(tester);
  }

  testWidgets('TC-CHAT-UI-M-02 a SYSTEM message shows as a small centered notice', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeApiAdapter(
        _routes(
          messages: FakeReply(200, {
            'data': {
              'data': [
                {
                  'id': 's1',
                  'roomId': _roomId,
                  'type': 'SYSTEM',
                  'senderId': null,
                  'content': 'Bạn An đã tham gia phòng',
                  'metadata': {'event': 'JOINED', 'visibleTo': 'ALL'},
                  'createdAt': DateTime.now().toIso8601String(),
                },
              ],
              'meta': {'hasMore': false},
            },
          }),
        ),
      ),
    );

    final notice = find.byKey(const ValueKey('chat-system-s1'));
    expect(notice, findsOneWidget);
    expect(
      find.descendant(of: notice, matching: find.text('Bạn An đã tham gia phòng')),
      findsOneWidget,
    );

    await tester.longPress(find.text('Bạn An đã tham gia phòng'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.chatReplyAction), findsNothing);
    await _unmount(tester);
  });

  testWidgets('TC-CHAT-UI-M-03 only a moderator sees the manage-room button', (
    tester,
  ) async {
    await _pump(tester, FakeApiAdapter(_routes()));
    expect(find.byTooltip(l10n.chatRoomManageTooltip), findsNothing);
    await _unmount(tester);

    await _pump(tester, FakeApiAdapter(_routes()), organizer: true);
    expect(find.byTooltip(l10n.chatRoomManageTooltip), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('TC-CHAT-UI-M-03 a 403 TOURNAMENT_CHAT_MUTED says until when', (
    tester,
  ) async {
    final until = DateTime.now().add(const Duration(hours: 1));
    await _pump(
      tester,
      FakeApiAdapter(
        _routes(
          send: FakeReply(403, {
            'statusCode': 403,
            'code': 'TOURNAMENT_CHAT_MUTED',
            'message': 'TOURNAMENT_CHAT_MUTED',
            'until': until.toUtc().toIso8601String(),
          }),
        ),
      ),
    );

    await send(tester, 'xin chào');

    expect(
      find.text(l10n.chatRoomMutedNotice(DateFormat('HH:mm dd/MM').format(until))),
      findsOneWidget,
    );
    expect(find.byType(ChatDetailScreen), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('TC-CHAT-UI-M-03 a 403 TOURNAMENT_CHAT_LOCKED swaps the input for the locked strip', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeApiAdapter(
        _routes(
          send: const FakeReply(403, {
            'statusCode': 403,
            'code': 'TOURNAMENT_CHAT_LOCKED',
            'message': 'TOURNAMENT_CHAT_LOCKED',
          }),
        ),
      ),
    );

    await send(tester, 'xin chào');

    expect(find.byType(TextField), findsNothing);
    expect(find.text(l10n.chatRoomLockedBanner), findsWidgets);
    await _unmount(tester);
  });

  testWidgets('TC-CHAT-UI-M-03 a locked room from room details hides the input for members', (
    tester,
  ) async {
    await _pump(tester, FakeApiAdapter(_routes(room: {'locked': true})));

    expect(find.byType(TextField), findsNothing);
    expect(find.text(l10n.chatRoomLockedBanner), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('TC-CHAT-UI-M-03 chat:room:settings locks members but not moderators', (
    tester,
  ) async {
    await _pump(tester, FakeApiAdapter(_routes()));
    _FakeChatSocket.last!.emitSettings({
      'roomId': _roomId,
      'slowModeSeconds': 5,
      'locked': true,
    });
    await tester.pump();
    expect(find.byType(TextField), findsNothing);

    _FakeChatSocket.last!.emitSettings({'roomId': _roomId, 'locked': false});
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    await _unmount(tester);

    await _pump(tester, FakeApiAdapter(_routes()), organizer: true);
    _FakeChatSocket.last!.emitSettings({'roomId': _roomId, 'locked': true});
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('TC-CHAT-UI-M-03 chat:room:evicted closes the screen with a friendly notice', (
    tester,
  ) async {
    await _pump(tester, FakeApiAdapter(_routes()));

    _FakeChatSocket.last!.emitEvicted({
      'roomId': _roomId,
      'reason': 'REGISTRATION_LOST',
    });
    await tester.pumpAndSettle();

    expect(find.byType(ChatDetailScreen), findsNothing);
    expect(find.text(l10n.chatRoomEvictedNotice), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('TC-CHAT-UI-M-03 a moderator opening from the chat list gets rights from the server', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeApiAdapter(
        _routes(
          room: {'tournamentId': 't1', 'locked': true},
          chatRoom: const FakeReply(200, {
            'data': {
              'available': true,
              'roomId': _roomId,
              'status': 'OPEN',
              'canWrite': true,
              'role': 'MEMBER',
              'canModerate': true,
            },
          }),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip(l10n.chatRoomManageTooltip), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('TC-CHAT-UI-M-03 a locked flag on a non-tournament room is ignored', (
    tester,
  ) async {
    _FakeChatSocket.last = null;
    await _pump(tester, FakeApiAdapter(_routes(room: {'locked': true})), roomType: 'GROUP');

    expect(find.byType(TextField), findsOneWidget);
    await _unmount(tester);
  });
}
