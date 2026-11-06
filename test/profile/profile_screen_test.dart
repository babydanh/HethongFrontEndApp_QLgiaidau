import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/profile/screens/profile_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Call {
  _Call(this.method, this.path, this.data);
  final String method;
  final String path;
  final Object? data;
}

/// Records every request and answers 200, or [failWith] when set.
class _RecordingAdapter implements HttpClientAdapter {
  final calls = <_Call>[];
  int? failWith;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(_Call(options.method, options.path, options.data));
    final status = failWith ?? 200;
    return ResponseBody.fromString(
      jsonEncode({'message': 'loi may chu'}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

const _profile = UserProfile(
  id: 'u1',
  fullName: 'Nguyen An',
  email: 'an@x.com',
  isEmailVerified: true,
  roles: ['ORGANIZER'],
  eloPoints: 1500,
);

const _rank = PlayerRanking(
  id: 'r1',
  userId: 'u1',
  fullName: 'Nguyen An',
  eloPoints: 1500,
  tierName: 'Gold',
  matchesPlayed: 10,
  matchesWon: 7,
  categoryName: 'Pickleball',
);

const _incoming = FriendshipItem(
  friendshipId: 'f1',
  status: 'PENDING',
  direction: 'INCOMING',
  senderId: 'u2',
  receiverId: 'u1',
  friendId: 'u2',
  friendName: 'Tran Binh',
);

const _outgoing = FriendshipItem(
  friendshipId: 'f2',
  status: 'PENDING',
  direction: 'OUTGOING',
  senderId: 'u1',
  receiverId: 'u3',
  friendId: 'u3',
  friendName: 'Le Chi',
);

const _accepted = FriendshipItem(
  friendshipId: 'f3',
  status: 'ACCEPTED',
  direction: 'OUTGOING',
  senderId: 'u1',
  receiverId: 'u4',
  friendId: 'u4',
  friendName: 'Pham Dung',
);

Tournament _tournament(String name) => Tournament(
  id: 't-$name',
  name: name,
  sport: 'pickleball',
  format: 'single',
  bracketType: 'single',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'u9',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  status: 'in_progress',
);

final _match = MatchModel(
  updatedAt: DateTime(2026, 1, 1),
  id: 'm1',
  round: 1,
  matchNumber: 1,
  team1Id: 'a',
  team2Id: 'b',
  team1Name: 'Doi Alpha',
  team2Name: 'Doi Beta',
  score1: 11,
  score2: 7,
  status: 'completed',
  bracketPosition: BracketPosition(round: 1, position: 1),
);

Future<_RecordingAdapter> _pump(
  WidgetTester tester, {
  ThemeData? theme,
  Future<UserProfile> Function()? profile,
  List<FriendshipItem> friends = const [],
  List<MatchModel>? matches,
  List<PlayerRanking> ranks = const [_rank],
  List<Tournament>? tournaments,
}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final adapter = _RecordingAdapter();
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = adapter;
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        authProvider.overrideWith(_FakeAuth.new),
        dioProvider.overrideWithValue(dio),
        userProfileProvider.overrideWith(
          (ref) => profile != null ? profile() : Future.value(_profile),
        ),
        userRankingsProvider.overrideWith((ref) async => ranks),
        publicUserMatchesProvider.overrideWith(
          (ref, id) async => matches ?? [_match],
        ),
        followedTournamentsProvider.overrideWith(
          (ref) async => tournaments ?? [_tournament('Giai Mua He')],
        ),
        userFriendsProvider.overrideWith((ref) async => friends),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.darkTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProfileScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return adapter;
}

Finder _tabLabel(String label) =>
    find.descendant(of: find.byType(TabBar), matching: find.text(label));

Future<void> _openFriends(WidgetTester tester) async {
  await tester.tap(_tabLabel('Bạn bè'));
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  group('FriendRequestActions', () {
    late _RecordingAdapter adapter;
    late FriendRequestActions actions;

    setUp(() {
      adapter = _RecordingAdapter();
      actions = FriendRequestActions(
        Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = adapter,
      );
    });

    test(
      'accept sends PATCH /social/friend-requests/:id action ACCEPTED',
      () async {
        await actions.accept('f1');
        expect(adapter.calls.single.method, 'PATCH');
        expect(adapter.calls.single.path, '/social/friend-requests/f1');
        expect(adapter.calls.single.data, {'action': 'ACCEPTED'});
      },
    );

    test(
      'reject sends PATCH /social/friend-requests/:id action REJECTED',
      () async {
        await actions.reject('f1');
        expect(adapter.calls.single.method, 'PATCH');
        expect(adapter.calls.single.path, '/social/friend-requests/f1');
        expect(adapter.calls.single.data, {'action': 'REJECTED'});
      },
    );

    test('remove sends DELETE /social/friendships/:id', () async {
      await actions.remove('f2');
      expect(adapter.calls.single.method, 'DELETE');
      expect(adapter.calls.single.path, '/social/friendships/f2');
    });

    test('failure is rethrown, not swallowed', () async {
      adapter.failWith = 500;
      expect(() => actions.accept('f1'), throwsA(isA<DioException>()));
    });
  });

  for (final dark in [true, false]) {
    testWidgets('renders header, stats and tabs from provider data '
        '(dark=$dark)', (tester) async {
      await _pump(
        tester,
        theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
      );
      expect(find.text('Nguyen An'), findsOneWidget);
      expect(find.text('@an'), findsOneWidget);
      expect(find.text('Ban tổ chức'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      // stat grid: ELO / Trận / Thắng% / Giải from provider data
      expect(find.text('1,500'), findsWidgets);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      expect(_tabLabel('Hoạt động'), findsOneWidget);
      expect(_tabLabel('Giải đấu'), findsOneWidget);
      expect(_tabLabel('Bạn bè'), findsOneWidget);
      expect(_tabLabel('Thành tích'), findsOneWidget);
      expect(find.text('Doi Alpha vs Doi Beta'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows skeleton while the profile loads', (tester) async {
    final never = Completer<UserProfile>();
    await _pump(tester, profile: () => never.future);
    expect(find.byType(ProfileShimmerLoading), findsOneWidget);
  });

  testWidgets('shows error and retries when the profile fails', (tester) async {
    var calls = 0;
    await _pump(
      tester,
      profile: () async {
        calls++;
        if (calls == 1) throw Exception('boom');
        return _profile;
      },
    );
    expect(find.text('Thử lại'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Nguyen An'), findsOneWidget);
  });

  testWidgets('empty states render with an action', (tester) async {
    await _pump(tester, matches: const [], tournaments: const []);
    expect(find.text('Chưa có trận nào'), findsOneWidget);
    expect(find.text('Tạo kèo'), findsOneWidget);
  });

  testWidgets('accept friend request calls PATCH ACCEPTED', (tester) async {
    final adapter = await _pump(tester, friends: [_incoming, _outgoing]);
    await _openFriends(tester);
    await tester.tap(find.text('Lời mời (1)'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Tran Binh'), findsOneWidget);
    await tester.tap(find.text('Đồng ý'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final call = adapter.calls.single;
    expect(call.method, 'PATCH');
    expect(call.path, '/social/friend-requests/f1');
    expect(call.data, {'action': 'ACCEPTED'});
  });

  testWidgets('decline friend request calls PATCH REJECTED', (tester) async {
    final adapter = await _pump(tester, friends: [_incoming]);
    await _openFriends(tester);
    await tester.tap(find.text('Lời mời (1)'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Từ chối'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final call = adapter.calls.single;
    expect(call.method, 'PATCH');
    expect(call.path, '/social/friend-requests/f1');
    expect(call.data, {'action': 'REJECTED'});
  });

  testWidgets('cancel sent request calls DELETE friendships', (tester) async {
    final adapter = await _pump(tester, friends: [_outgoing, _accepted]);
    await _openFriends(tester);
    await tester.tap(find.text('Đã gửi (1)'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Hủy'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final call = adapter.calls.single;
    expect(call.method, 'DELETE');
    expect(call.path, '/social/friendships/f2');
  });

  testWidgets('a failed accept shows an error snackbar', (tester) async {
    final adapter = await _pump(tester, friends: [_incoming]);
    adapter.failWith = 500;
    await _openFriends(tester);
    await tester.tap(find.text('Lời mời (1)'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Đồng ý'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
