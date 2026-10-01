import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_avatar_tap.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_profile_bottom_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';

const _userId = 'user-42';

const _profile = UserPublicProfile(id: _userId, fullName: 'Nguyen Van A');

const _avatar = UserAvatarTap(userId: _userId, name: 'Nguyen Van A', size: 40);

/// A player who ranks in many categories, so the sheet's body is genuinely
/// taller than the height the hover popup caps itself at. Without that there
/// would be no fold and "reachable without scrolling" would be vacuous.
const _tallProfile = UserPublicProfile(
  id: _userId,
  fullName: 'Nguyen Van A',
  isVerified: true,
  roles: ['MEMBER'],
  bio: 'Chơi pickleball từ 2019, thi đấu đều mỗi cuối tuần.',
  ranks: [
    UserPublicRank(
      categoryId: 'c1',
      categoryName: 'Nam',
      eloPoints: 1780,
      tierName: 'Gold I',
      matchesPlayed: 120,
      matchesWon: 88,
    ),
    UserPublicRank(
      categoryId: 'c2',
      categoryName: 'Nữ',
      eloPoints: 1650,
      tierName: 'Gold II',
      matchesPlayed: 90,
      matchesWon: 60,
    ),
    UserPublicRank(
      categoryId: 'c3',
      categoryName: 'Đôi Nam',
      eloPoints: 1610,
      tierName: 'Gold II',
      matchesPlayed: 75,
      matchesWon: 47,
    ),
    UserPublicRank(
      categoryId: 'c4',
      categoryName: 'Đôi Nữ',
      eloPoints: 1580,
      tierName: 'Silver I',
      matchesPlayed: 64,
      matchesWon: 39,
    ),
    UserPublicRank(
      categoryId: 'c5',
      categoryName: 'Hỗn hợp',
      eloPoints: 1540,
      tierName: 'Silver I',
      matchesPlayed: 58,
      matchesWon: 33,
    ),
    UserPublicRank(
      categoryId: 'c6',
      categoryName: 'Đôi HM',
      eloPoints: 1510,
      tierName: 'Silver II',
      matchesPlayed: 51,
      matchesWon: 28,
    ),
    UserPublicRank(
      categoryId: 'c7',
      categoryName: 'U11',
      eloPoints: 1420,
      tierName: 'Bronze I',
      matchesPlayed: 44,
      matchesWon: 24,
    ),
    UserPublicRank(
      categoryId: 'c8',
      categoryName: 'U15',
      eloPoints: 1385,
      tierName: 'Bronze II',
      matchesPlayed: 37,
      matchesWon: 19,
    ),
    UserPublicRank(
      categoryId: 'c9',
      categoryName: 'U19',
      eloPoints: 1310,
      tierName: 'Bronze III',
      matchesPlayed: 29,
      matchesWon: 14,
    ),
    UserPublicRank(
      categoryId: 'c10',
      categoryName: 'U22',
      eloPoints: 1240,
      tierName: 'Bronze IV',
      matchesPlayed: 22,
      matchesWon: 9,
    ),
  ],
);

/// A focusable control belonging to the page, so Tab has somewhere to start.
///
/// Any real screen has one. Without it the home route has *no* focusable node
/// at all, and focus traversal — which starts from whatever currently holds
/// focus — never leaves the route's empty scope, so the popup's controls look
/// unreachable when they are not.
void _pageControl() {}

/// The avatar is the only subject under test, so the harness is a bare app
/// shell whose home route renders it and whose router records where the
/// profile flow ends up.
///
/// The avatar sits near the top-left of the page, like a row in a list: the
/// popup opens below the row and extends one [UserProfileTapTarget.previewWidth]
/// to the *left* of it, so a row close to the left edge would have its popup
/// clipped by the screen instead of by its own height cap.
GoRouter _router() => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (_, _) => const Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 420, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                onPressed: _pageControl,
                child: Text('Page control'),
              ),
              _avatar,
            ],
          ),
        ),
      ),
    ),
    GoRoute(path: '/user/:id', builder: (_, _) => const SizedBox()),
  ],
);

Widget _app(GoRouter router) => MaterialApp.router(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.lightTheme,
  routerConfig: router,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: const [Locale('en')],
);

Widget _scope(
  GoRouter router, {
  UserPublicProfile profile = _profile,
}) => ProviderScope(
  overrides: [
    userPublicProfileProvider(_userId).overrideWith((ref) async => profile),
  ],
  child: _app(router),
);

/// The avatar branches on `defaultTargetPlatform`, and the test binding
/// asserts the override is unset before it verifies a test body. The
/// `finally` guarantees that even when an expectation blows up mid-test.
void platformTest(
  String description,
  TargetPlatform platform,
  WidgetTesterCallback body,
) {
  testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = platform;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

/// A realistic desktop window, so the popup's own cap — the smaller of 62% of
/// the height and 520 logical pixels — is the thing under test rather than
/// the 600x600 test default.
void _useDesktopWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  platformTest(
    'tap on a touch device opens the quick preview sheet',
    TargetPlatform.android,
    (tester) async {
      await tester.pumpWidget(_scope(_router()));
      await tester.pumpAndSettle();
      expect(find.byType(UserProfileBottomSheet), findsNothing);

      await tester.tap(find.byType(UserAvatarTap));
      await tester.pumpAndSettle();

      // The sheet, not the profile page: touch has no hover to shortcut past.
      expect(find.byType(UserProfileBottomSheet), findsOneWidget);
      expect(find.text('View profile'), findsOneWidget);
    },
  );

  platformTest(
    'the mobile sheet keeps its actions in the scrolling body',
    TargetPlatform.android,
    (tester) async {
      await tester.pumpWidget(_scope(_router()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UserAvatarTap));
      await tester.pumpAndSettle();

      // Pinning is a hover-preview affordance. On a tall modal the actions
      // stay the last thing you scroll to, exactly as before.
      final body = find
          .descendant(
            of: find.byType(UserProfileBottomSheet),
            matching: find.byType(Scrollable),
          )
          .first;
      expect(
        find.descendant(of: body, matching: find.text('View profile')),
        findsOneWidget,
      );
    },
  );

  platformTest(
    'the preview detail button navigates to the profile route',
    TargetPlatform.android,
    (tester) async {
      final router = _router();
      await tester.pumpWidget(_scope(router));
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/home');

      await tester.tap(find.byType(UserAvatarTap));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View profile'));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/user/$_userId');
      // The sheet owned the modal route: it must be gone, not left behind the page.
      expect(find.byType(UserProfileBottomSheet), findsNothing);
    },
  );

  platformTest(
    'hover opens the preview and it auto-hides after five seconds',
    TargetPlatform.windows,
    (tester) async {
      final router = _router();
      await tester.pumpWidget(_scope(router));
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(UserAvatarTap)));

      await tester.pump();
      expect(
        find.byType(UserProfileBottomSheet),
        findsNothing,
        reason: 'the popup must wait out the hover delay',
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(UserProfileBottomSheet), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      expect(
        find.byType(UserProfileBottomSheet),
        findsOneWidget,
        reason: 'the five second budget is not spent yet',
      );

      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(UserProfileBottomSheet), findsNothing);

      // A hover is a preview only — it must never navigate on its own.
      expect(router.state.uri.toString(), '/home');
    },
  );

  platformTest(
    'the hover popup keeps the profile action reachable without scrolling',
    TargetPlatform.windows,
    (tester) async {
      _useDesktopWindow(tester);
      final semantics = tester.ensureSemantics();
      final router = _router();
      await tester.pumpWidget(_scope(router, profile: _tallProfile));
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(UserAvatarTap)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final popup = find.byType(UserProfileBottomSheet);
      expect(popup, findsOneWidget);

      // The popup is pinned against its own cap, so this is the case that used
      // to swallow the action: a 1440x900 window gives min(558, 520) = 520.
      final popupRect = tester.getRect(popup);
      expect(popupRect.height, closeTo(520, 0.5));
      expect(popupRect.top, greaterThan(0));
      expect(popupRect.bottom, lessThanOrEqualTo(900));

      // There really is a fold here: the body overflows its viewport, so
      // "the action is above it" is a claim about this layout, not about a
      // profile short enough to fit.
      final body = find
          .descendant(of: popup, matching: find.byType(Scrollable))
          .first;
      final bodyPosition = tester.state<ScrollableState>(body).position;
      expect(
        bodyPosition.maxScrollExtent,
        greaterThan(100),
        reason: 'the fixture must be taller than the popup can show',
      );
      expect(
        bodyPosition.pixels,
        0,
        reason: 'nothing has been scrolled yet — this is the un-scrolled state',
      );

      final profileAction = find.widgetWithText(OutlinedButton, 'View profile');
      expect(
        profileAction,
        findsOneWidget,
        reason: 'pinned, not duplicated: one action, reachable',
      );

      // (1) Rendered inside the popup's visible box, not past its lower edge.
      final beforeScroll = tester.getRect(profileAction);
      expect(
        beforeScroll.top,
        greaterThanOrEqualTo(popupRect.top),
        reason: 'the action must sit inside the popup, not above it',
      );
      expect(
        beforeScroll.bottom,
        lessThanOrEqualTo(popupRect.bottom),
        reason: 'the action must not be clipped below the popup edge',
      );
      expect(tester.getSize(profileAction).height, greaterThanOrEqualTo(44));

      // (2) Scrolling the body leaves it exactly where it was: pinned.
      await tester.drag(popup, const Offset(0, -160));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(body).position.pixels,
        greaterThan(0),
        reason: 'the body must actually have scrolled for this to mean anything',
      );
      expect(
        tester.getRect(profileAction),
        beforeScroll,
        reason: 'a pinned action cannot move when the content above it scrolls',
      );

      // (3) The pointer lands on the control. `hitTestable` hit tests the
      // action's own centre: a button parked past the popup's edge, or behind
      // the scroll view, would not be returned here.
      expect(
        profileAction.hitTestable(),
        findsOneWidget,
        reason: 'the action must be hittable, not merely present in the tree',
      );

      // (4) It is a real control: announced as a button, and a tab stop.
      final actionSemantics = tester.getSemantics(profileAction);
      expect(actionSemantics.flagsCollection.isButton, isTrue);
      expect(
        tester.getSemantics(profileAction).label,
        contains('View profile'),
      );
      var reachedByTab = false;
      for (var i = 0; i < 6 && !reachedByTab; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focus = FocusManager.instance.primaryFocus;
        if (focus?.context == null) continue;
        reachedByTab = find
            .descendant(
              of: profileAction,
              matching: find.byWidget(focus!.context!.widget),
            )
            .evaluate()
            .isNotEmpty;
      }
      expect(reachedByTab, isTrue, reason: 'keyboard must reach the action');

      // (5) One click, no scrolling, lands on the profile page.
      await tester.tap(profileAction);
      await tester.pumpAndSettle();
      expect(router.state.uri.toString(), '/user/$_userId');
      expect(find.byType(UserProfileBottomSheet), findsNothing);
      semantics.dispose();
    },
  );

  platformTest(
    'the keyboard alone drives the popup to the profile page',
    TargetPlatform.windows,
    (tester) async {
      _useDesktopWindow(tester);
      final router = _router();
      await tester.pumpWidget(_scope(router, profile: _tallProfile));
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(UserAvatarTap)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final profileAction = find.widgetWithText(OutlinedButton, 'View profile');
      expect(profileAction, findsOneWidget);

      // No mouse from here on: Tab until the action holds focus, then Enter.
      // The popup is built into the overlay beside the page rather than
      // inside it, so this is the claim that the action is genuinely a tab
      // stop of this screen and not merely a control the pointer can hit.
      var reachedByTab = false;
      for (var i = 0; i < 6 && !reachedByTab; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focus = FocusManager.instance.primaryFocus;
        if (focus?.context == null) continue;
        reachedByTab = find
            .descendant(
              of: profileAction,
              matching: find.byWidget(focus!.context!.widget),
            )
            .evaluate()
            .isNotEmpty;
      }
      expect(reachedByTab, isTrue, reason: 'keyboard must reach the action');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/user/$_userId');
      // Activating from the keyboard must dismiss the popup first, exactly as
      // the pointer path does — the route is pushed from a clean state.
      expect(find.byType(UserProfileBottomSheet), findsNothing);
    },
  );

  platformTest(
    'the popup outlives the pointer leaving it, then closes on the grace',
    TargetPlatform.windows,
    (tester) async {
      _useDesktopWindow(tester);
      await tester.pumpWidget(_scope(_router()));
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(UserAvatarTap)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byType(UserProfileBottomSheet), findsOneWidget);

      // In, so the avatar's own exit grace is cancelled by the popup's enter.
      await mouse.moveTo(tester.getCenter(find.byType(UserProfileBottomSheet)));
      await tester.pump();
      expect(find.byType(UserProfileBottomSheet), findsOneWidget);

      // Out again, onto empty page well clear of both the popup and the
      // avatar, so no re-hover re-arms anything and the grace is the only
      // thing that can close this.
      await mouse.moveTo(const Offset(1400, 880));
      await tester.pump();
      expect(
        find.byType(UserProfileBottomSheet),
        findsOneWidget,
        reason: 'a hover card must not vanish the instant the pointer leaves',
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byType(UserProfileBottomSheet),
        findsNothing,
        reason: 'the grace window ends, so the popup really does close',
      );
    },
  );

  platformTest(
    'both popup actions are pinned, so neither is lopsided',
    TargetPlatform.windows,
    (tester) async {
      _useDesktopWindow(tester);
      final router = _router();
      await tester.pumpWidget(_scope(router, profile: _tallProfile));
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(UserAvatarTap)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final popupRect = tester.getRect(find.byType(UserProfileBottomSheet));
      for (final action in [
        find.widgetWithText(ElevatedButton, 'Message'),
        find.widgetWithText(OutlinedButton, 'View profile'),
      ]) {
        expect(action, findsOneWidget);
        final rect = tester.getRect(action);
        expect(
          rect.bottom,
          lessThanOrEqualTo(popupRect.bottom),
          reason: 'a clipped action is a missing action',
        );
        expect(rect.top, greaterThanOrEqualTo(popupRect.top));
      }
    },
  );

  platformTest(
    'a short profile does not stretch the popup out to the height cap',
    TargetPlatform.windows,
    (tester) async {
      _useDesktopWindow(tester);
      final router = _router();
      await tester.pumpWidget(_scope(router));
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(UserAvatarTap)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final popupRect = tester.getRect(find.byType(UserProfileBottomSheet));
      // The pinned bar costs its own height and nothing else: the popup is
      // still the content it would have been, so it never grows.
      expect(
        popupRect.height,
        lessThan(520),
        reason: 'a short profile must keep a short popup',
      );
      expect(
        find.widgetWithText(OutlinedButton, 'View profile').hitTestable(),
        findsOneWidget,
      );
    },
  );

  platformTest(
    'a failed profile fetch renders an error instead of throwing',
    TargetPlatform.android,
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPublicProfileProvider(_userId).overrideWith(
              (ref) async => throw Exception('offline'),
            ),
          ],
          child: _app(_router()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(UserAvatarTap));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Unable to load user profile'), findsOneWidget);
    },
  );

  test('profile route keeps club context and encodes identifiers', () {
    expect(
      NavigationHelper.getUserProfileRoute('user-42', communityId: 'club-7'),
      '/user/user-42?communityId=club-7',
    );
    expect(NavigationHelper.getUserProfileRoute('user-42'), '/user/user-42');
    expect(
      NavigationHelper.getUserProfileRoute(' user 1 ', communityId: '  '),
      '/user/user%201',
    );
  });
}
