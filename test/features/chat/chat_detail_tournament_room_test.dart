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
}

Map<String, FakeReply> _routes({FakeReply? messages}) => {
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
  'GET /chat/rooms/$_roomId': const FakeReply(200, {
    'data': {'id': _roomId, 'participants': []},
  }),
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
          roomType: 'TOURNAMENT',
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
}
