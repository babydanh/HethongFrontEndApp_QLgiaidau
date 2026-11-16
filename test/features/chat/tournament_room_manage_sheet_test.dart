import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/chat/widgets/tournament_room_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api_adapter.dart';

const _room = 'room-1';
const _me = 'user-me';

Map<String, FakeReply> _routes({FakeReply? mute}) => {
  'GET /chat/rooms/$_room/participants': FakeReply(200, {
    'data': {
      'items': [
        {
          'userId': 'u1',
          'fullName': 'Bạn An',
          'registration': 'APPROVED',
          'online': true,
        },
        {
          'userId': 'u3',
          'fullName': 'Chị Cúc',
          'registration': 'PENDING',
          'mutedUntil': DateTime.now()
              .add(const Duration(minutes: 30))
              .toUtc()
              .toIso8601String(),
        },
        {'userId': _me, 'fullName': 'Tôi', 'registration': 'STAFF'},
      ],
      'nextCursor': null,
    },
  }),
  'GET /chat/rooms/$_room/kicks': const FakeReply(200, {
    'data': [
      {
        'userId': 'u2',
        'fullName': 'Anh Bình',
        'kickedByName': 'BTC Dũng',
        'kickedAt': '2026-11-16T09:00:00.000Z',
      },
    ],
  }),
  'POST /chat/rooms/$_room/mutes': mute ?? const FakeReply(201, {'data': {}}),
  'DELETE /chat/rooms/$_room/mutes/u3': const FakeReply(200, {'data': {}}),
  'DELETE /chat/rooms/$_room/kicks/u2': const FakeReply(200, {'data': {}}),
  'PATCH /chat/rooms/$_room/settings': const FakeReply(200, {'data': {}}),
};

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<List<(int, bool)>> _open(
  WidgetTester tester,
  FakeApiAdapter adapter, {
  Size size = const Size(390, 844),
}) async {
  final changes = <(int, bool)>[];
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        dioClientProvider.overrideWithValue(fakeDioClient(adapter)),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(id: _me, fullName: 'Tôi'),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => TournamentRoomManageSheet.show(
                context,
                roomId: _room,
                slowModeSeconds: 3,
                locked: false,
                onSettingsChanged: (s, l) => changes.add((s, l)),
              ),
              child: const Text('MỞ'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('MỞ'));
  await _settle(tester);
  return changes;
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  final l10n = lookupAppLocalizations(const Locale('vi'));

  testWidgets('TC-CHAT-UI-M-03 members tab lists people with their status', (
    tester,
  ) async {
    await _open(tester, FakeApiAdapter(_routes()));

    expect(find.text('Bạn An'), findsOneWidget);
    expect(find.text('Chị Cúc'), findsOneWidget);
    expect(find.text(l10n.chatRoomMemberOnline), findsOneWidget);
    expect(find.text(l10n.chatRoomMemberPending), findsOneWidget);
    expect(
      find.byKey(const ValueKey('room-member-actions-$_me')),
      findsNothing,
      reason: 'no actions on yourself',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-CHAT-UI-M-03 muting a member asks how long, then posts it', (
    tester,
  ) async {
    final adapter = FakeApiAdapter(_routes());
    await _open(tester, adapter);

    await tester.tap(find.byKey(const ValueKey('room-member-actions-u1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.chatRoomMuteAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.chatRoomMuteFor1h));
    await _settle(tester);

    final post = adapter.postsTo('/chat/rooms/$_room/mutes').single;
    expect(post.body, {'userId': 'u1', 'minutes': 60});
    expect(find.text(l10n.chatRoomMuteDone('Bạn An')), findsOneWidget);
  });

  testWidgets('TC-CHAT-UI-M-03 muting an organizer shows why it failed', (
    tester,
  ) async {
    await _open(
      tester,
      FakeApiAdapter(
        _routes(
          mute: const FakeReply(403, {
            'statusCode': 403,
            'code': 'CANNOT_MUTE_ORGANIZER',
            'message': 'CANNOT_MUTE_ORGANIZER',
          }),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('room-member-actions-u1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.chatRoomMuteAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.chatRoomMuteFor15m));
    await _settle(tester);

    expect(find.text(l10n.chatRoomCannotModerateStaff), findsOneWidget);
  });

  testWidgets(
    'TC-CHAT-UI-M-03 restricted tab lets the kicked back in and unmutes',
    (tester) async {
      final adapter = FakeApiAdapter(_routes());
      await _open(tester, adapter);

      await tester.tap(find.text(l10n.chatRoomManageTabRestricted));
      await tester.pumpAndSettle();

      expect(find.text('Anh Bình'), findsOneWidget);
      expect(find.textContaining('BTC Dũng'), findsOneWidget);
      expect(find.text('Chị Cúc'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('room-unkick-u2')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('room-unmute-u3')));
      await _settle(tester);

      final deletes = adapter.requests
          .where((r) => r.method == 'DELETE')
          .map((r) => r.path);
      expect(deletes, [
        '/chat/rooms/$_room/kicks/u2',
        '/chat/rooms/$_room/mutes/u3',
      ]);
    },
  );

  testWidgets('TC-CHAT-UI-M-03 settings tab locks the room', (tester) async {
    final adapter = FakeApiAdapter(_routes());
    final changes = await _open(tester, adapter);

    await tester.tap(find.text(l10n.chatRoomManageTabSettings));
    await tester.pumpAndSettle();
    expect(find.text(l10n.chatRoomSlowModeDuration(3)), findsOneWidget);

    await tester.tap(find.text(l10n.chatRoomLockLabel));
    await _settle(tester);

    final patch = adapter.requests.singleWhere((r) => r.method == 'PATCH');
    expect(patch.path, '/chat/rooms/$_room/settings');
    expect(patch.body, {'locked': true});
    expect(changes, [(3, true)]);
  });

  testWidgets('TC-CHAT-UI-M-03 the sheet fits a small phone without overflow', (
    tester,
  ) async {
    await _open(tester, FakeApiAdapter(_routes()), size: const Size(320, 568));

    expect(find.text('Bạn An'), findsOneWidget);
    await tester.tap(find.text(l10n.chatRoomManageTabSettings));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
