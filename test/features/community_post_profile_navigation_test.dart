import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/features/community/social/widgets/community_post_card.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_avatar_tap.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/user_profile_bottom_sheet.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';

const _authorId = 'user-42';
const _authorName = 'Nguyen Van A';
const _communityId = 'club-7';

/// The feed card is the only subject under test, so the harness is a bare app
/// shell whose home route renders it and whose router records where the
/// profile flow ends up.
GoRouter _router({String authorId = _authorId}) => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => Scaffold(
        body: CommunityPostCard(
          post: CommunityPostModel(
            id: 'post-1',
            authorId: authorId,
            authorName: _authorName,
            text: 'Welcome to the club!',
          ),
          communityId: _communityId,
        ),
      ),
    ),
    GoRoute(path: '/user/:id', builder: (context, state) => const Scaffold()),
  ],
);

Widget _app(GoRouter router) => ProviderScope(
  overrides: [
    communityTagPresetsProvider(_communityId).overrideWith((ref) async => []),
    communityMemberDirectoryProvider(
      _communityId,
    ).overrideWith((ref) async => {}),
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

void main() {
  platformTest(
    'tapping the feed header avatar reaches the author profile on desktop',
    TargetPlatform.windows,
    (tester) async {
      final router = _router();
      await tester.pumpWidget(_app(router));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RankAvatar));
      await tester.pumpAndSettle();

      expect(
        router.state.uri.toString(),
        '/user/$_authorId?communityId=$_communityId',
      );
    },
  );

  platformTest(
    'tapping the feed header name previews the author on a phone',
    TargetPlatform.android,
    (tester) async {
      await tester.pumpWidget(_app(_router()));
      await tester.pumpAndSettle();
      expect(find.byType(UserProfileBottomSheet), findsNothing);

      await tester.tap(find.text(_authorName));
      await tester.pumpAndSettle();

      expect(find.byType(UserProfileBottomSheet), findsOneWidget);
    },
  );

  platformTest(
    'a post with no resolvable author exposes no profile control',
    TargetPlatform.windows,
    (tester) async {
      final router = _router(authorId: '');
      await tester.pumpWidget(_app(router));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RankAvatar));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), '/home');
      expect(
        find
            .byType(UserProfileTapTarget)
            .evaluate()
            .where((e) => (e.widget as UserProfileTapTarget).userId.isNotEmpty),
        isEmpty,
      );
    },
  );
}
