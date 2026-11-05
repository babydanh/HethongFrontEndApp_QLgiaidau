import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/features/notification/screens/notification_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNotifier extends NotificationNotifier {
  _FakeNotifier(this.initial);
  final NotificationState initial;
  int loads = 0;
  final read = <String>[];

  @override
  NotificationState build() => initial;

  @override
  Future<void> loadPage(int page) async => loads++;

  @override
  Future<void> markAsRead(String id) async => read.add(id);
}

class _EmptyWorkspace extends MyTournamentWorkspaceNotifier {
  @override
  Future<TournamentWorkspace> build() async => TournamentWorkspace.empty;
}

AppNotification _invite() => AppNotification(
  id: 'n1',
  type: 'PARTNER_INVITE_RECEIVED',
  title: 'Invite',
  redirectUrl: '/tournaments/participants/p1/accept-partner',
  createdAt: DateTime.now(),
);

Dio _dioFailing(int status) {
  final dio = Dio(BaseOptions(baseUrl: 'https://x.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (o, h) => h.reject(
        DioException.badResponse(
          statusCode: status,
          requestOptions: o,
          response: Response(requestOptions: o, statusCode: status),
        ),
      ),
    ),
  );
  return dio;
}

Future<_FakeNotifier> _pump(
  WidgetTester tester,
  NotificationState state, {
  ThemeData? theme,
  int? failStatus,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final fake = _FakeNotifier(state);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationStateProvider.overrideWith(() => fake),
        unreadCountProvider.overrideWith((ref) async => 0),
        myCommunityInvitesProvider.overrideWith((ref) async => []),
        myTournamentWorkspaceProvider.overrideWith(_EmptyWorkspace.new),
        if (failStatus != null) dioProvider.overrideWithValue(_dioFailing(failStatus)),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const NotificationScreen(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return fake;
}

void main() {
  testWidgets('empty state is centered with Lavish empty state', (t) async {
    await _pump(t, const NotificationState(hasMore: false));
    expect(find.byType(LavishEmptyState), findsOneWidget);
    final c = t.getCenter(find.byType(LavishEmptyState));
    expect(c.dx, closeTo(195, 1));
    expect(t.takeException(), isNull);
  });

  testWidgets('error state shows retry that reloads', (t) async {
    final fake = await _pump(
      t,
      const NotificationState(errorMessage: 'boom', hasMore: false),
    );
    expect(find.byType(LavishErrorState), findsOneWidget);
    await t.tap(find.text('Retry'));
    expect(fake.loads, greaterThan(0));
  });

  testWidgets('list renders Lavish rows and read-all tooltip (dark)', (t) async {
    await _pump(
      t,
      NotificationState(
        notifications: [
          AppNotification(
            id: 'a',
            type: 'SYSTEM',
            title: 'Hello',
            createdAt: DateTime.now(),
          ),
        ],
        hasMore: false,
      ),
      theme: AppTheme.darkTheme,
    );
    expect(find.byType(LavishRow), findsOneWidget);
    expect(find.byType(LavishChipButton), findsWidgets);
    expect(find.byTooltip('Mark all read'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('HTTP 400 on invite is an error, not "already handled"', (t) async {
    final fake = await _pump(
      t,
      NotificationState(notifications: [_invite()], hasMore: false),
      failStatus: 400,
    );
    await t.tap(find.text('Accept'));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 100));
    expect(fake.read, isEmpty);
    expect(find.text('Invite response recorded'), findsNothing);
    expect(find.text('Accept'), findsOneWidget);
  });

  testWidgets('HTTP 409 on invite is treated as already handled', (t) async {
    final fake = await _pump(
      t,
      NotificationState(notifications: [_invite()], hasMore: false),
      failStatus: 409,
    );
    await t.tap(find.text('Accept'));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 100));
    expect(fake.read, ['n1']);
  });
}
