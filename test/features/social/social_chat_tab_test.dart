import 'dart:async';

import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_session_repository.dart';
import 'package:app_quanly_giaidau/features/chat/screens/chat_detail_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/features/social/widgets/chat_tab/social_chat_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo extends Fake implements ISocialSessionRepository {
  _FakeRepo(this.messages, {this.sendGate});

  List<SocialChatMessageModel> messages;
  final Completer<void>? sendGate;
  final List<String> sent = [];
  bool failSend = false;
  int getCalls = 0;

  @override
  Future<List<SocialChatMessageModel>> getMessages(
    String sessionId, {
    int limit = 30,
  }) async {
    getCalls++;
    return messages;
  }

  @override
  Future<void> sendMessage(String sessionId, String text) async {
    sent.add(text);
    await sendGate?.future;
    if (failSend) throw Exception('403');
  }
}

SocialChatMessageModel _msg(String id, String text, {String sender = 'u1'}) =>
    SocialChatMessageModel(
      id: id,
      senderId: sender,
      senderName: 'An Bình',
      senderInitials: 'AB',
      message: text,
      time: DateTime(2026, 11, 10, 9, 30),
    );

SocialSessionModel _session({String status = 'OPEN'}) => SocialSessionModel(
  id: 's1',
  hostUserId: 'h',
  title: 'Cầu lông giao lưu',
  playFormat: 'Giao lưu',
  startAt: DateTime(2026, 11, 10, 18),
  venueName: 'Sân A',
  venueAddress: '1 Đường B',
  sport: 'BADMINTON',
  sportName: 'Cầu lông',
  status: status,
);

Future<void> _pump(
  WidgetTester tester,
  _FakeRepo repo, {
  String status = 'OPEN',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [socialSessionRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Scaffold(
          body: SocialChatTab(session: _session(status: status)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'TC-SOCIAL-CHAT-04 shows API messages, no hardcoded system lines',
    (tester) async {
      final repo = _FakeRepo([_msg('m1', 'Chiều nay 5h nha')]);
      await _pump(tester, repo);

      expect(find.text('Chiều nay 5h nha'), findsOneWidget);
      expect(find.text('Sơn Bảo đã tham gia cuộc trò chuyện.'), findsNothing);
      expect(find.text('Bạn đã cập nhật lệ phí tham dự.'), findsNothing);
      expect(repo.getCalls, 1);
    },
  );

  testWidgets('TC-SOCIAL-CHAT-05 send posts text, clears input, reloads', (
    tester,
  ) async {
    final repo = _FakeRepo([_msg('m1', 'cũ')]);
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), '  xin chào  ');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(repo.sent, ['xin chào']);
    expect(find.widgetWithText(TextField, 'xin chào'), findsNothing);
    expect(repo.getCalls, 2); // initial load + reload after send
  });

  testWidgets('TC-SOCIAL-CHAT-05b double tap sends only once', (tester) async {
    final gate = Completer<void>();
    final repo = _FakeRepo([], sendGate: gate);
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), 'một lần');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded), warnIfMissed: false);
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();

    expect(repo.sent, ['một lần']);
  });

  testWidgets('TC-SOCIAL-CHAT-05c failed send keeps the text and shows error', (
    tester,
  ) async {
    final repo = _FakeRepo([])..failSend = true;
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), 'không gửi được');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'không gửi được'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('TC-SOCIAL-CHAT-06 closed session is read-only', (tester) async {
    final repo = _FakeRepo([_msg('m1', 'đã xong')]);
    await _pump(tester, repo, status: 'COMPLETED');

    expect(find.text('đã xong'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.send_rounded), findsNothing);
  });

  testWidgets('TC-SOCIAL-CHAT-07 empty chat shows a hint, not fake rows', (
    tester,
  ) async {
    final repo = _FakeRepo([]);
    await _pump(tester, repo);

    expect(find.text('Chưa có tin nhắn nào.'), findsOneWidget);
  });

  testWidgets('TC-SOCIAL-CHAT-08 session with a chat room embeds the app chat', (
    tester,
  ) async {
    final repo = _FakeRepo([]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [socialSessionRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SocialChatTab(
              session: _session().copyWith(chatRoomId: 'room-1'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final chat = tester.widget<ChatDetailScreen>(find.byType(ChatDetailScreen));
    expect(chat.roomId, 'room-1');
    expect(chat.embedded, isTrue);
    expect(find.byType(AppBar), findsNothing);
    expect(repo.getCalls, 0); // the old text-only list is not used
  });
}
