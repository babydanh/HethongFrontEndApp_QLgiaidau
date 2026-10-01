import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/match/widgets/match_discussion_message.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_avatar_tap.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_profile_bottom_sheet.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';

const _userId = 'user-7';
const _name = 'Nguyen Van A';
const _profile = UserPublicProfile(id: _userId, fullName: _name);

Widget _message({String userId = _userId}) => Scaffold(
  body: MatchDiscussionMessage(
    userId: userId,
    name: _name,
    text: 'Nice rally!',
    timeLabel: '20:15',
  ),
);

/// The discussion row is the only subject under test, so the harness is a bare
/// app shell whose home route renders it and whose router records where the
/// profile flow ends up.
GoRouter _router({String userId = _userId}) => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => _message(userId: userId),
    ),
    GoRoute(path: '/user/:id', builder: (context, state) => const Scaffold()),
  ],
);

Widget _app(GoRouter router) => ProviderScope(
  overrides: [
    userPublicProfileProvider(_userId).overrideWith((ref) async => _profile),
  ],
  child: MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: const [Locale('en')],
  ),
);

/// The widget branches on `defaultTargetPlatform`, and the test binding
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

/// Every semantics node currently mounted, in tree order.
List<SemanticsNode> _nodes(WidgetTester tester) {
  final root = tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode;
  final collected = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    collected.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root!);
  return collected;
}

void main() {
  platformTest(
    'tapping the display name opens the author preview on a touch device',
    TargetPlatform.android,
    (tester) async {
      await tester.pumpWidget(_app(_router()));
      await tester.pumpAndSettle();
      expect(find.byType(UserProfileBottomSheet), findsNothing);

      // The name itself, not just the artwork beside it.
      await tester.tap(find.text(_name));
      await tester.pumpAndSettle();

      expect(find.byType(UserProfileBottomSheet), findsOneWidget);
    },
  );

  platformTest(
    'tapping the avatar reaches the profile page on a pointer device',
    TargetPlatform.windows,
    (tester) async {
      final router = _router();
      await tester.pumpWidget(_app(router));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RankAvatar));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/user/$_userId');
    },
  );

  platformTest(
    'hovering the discussion row previews the author and auto-hides',
    TargetPlatform.windows,
    (tester) async {
      await tester.pumpWidget(_app(_router()));
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(UserProfileTapTarget)));

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(UserProfileBottomSheet), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(UserProfileBottomSheet), findsNothing);
    },
  );

  platformTest(
    'the row is announced as one control, not a button plus loose text',
    TargetPlatform.android,
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(_router()));
      await tester.pumpAndSettle();

      final nodes = _nodes(tester);
      final buttons = nodes
          .where((n) => n.hasFlag(SemanticsFlag.isButton))
          .toList();

      // Exactly one control, and it carries the name — so the avatar and the
      // display name are announced as the same thing rather than as a button
      // with loose text floating next to it.
      expect(buttons, hasLength(1));
      expect(buttons.single.label, "View $_name's profile");
      expect(
        nodes.where((n) => n.label == _name),
        isEmpty,
        reason: 'the name must not leak as its own text node',
      );
      handle.dispose();
    },
  );

  platformTest(
    'a message with no resolvable author stays inert',
    TargetPlatform.android,
    (tester) async {
      final router = _router(userId: '');
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text(_name));
      await tester.pumpAndSettle();

      expect(find.byType(UserProfileBottomSheet), findsNothing);
      expect(router.state.uri.toString(), '/home');
      expect(
        _nodes(tester).where((n) => n.hasFlag(SemanticsFlag.isButton)),
        isEmpty,
        reason: 'an unresolved author must not be advertised as a control',
      );
      handle.dispose();
    },
  );
}
