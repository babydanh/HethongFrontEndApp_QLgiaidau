import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/home_skeletons.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/list_skeletons.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => MaterialApp(
  theme: AppTheme.darkTheme,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(body: child),
  ),
);

void main() {
  group('SkeletonScope', () {
    testWidgets('uses exactly one Shimmer for many boxes', (tester) async {
      await tester.pumpWidget(
        _host(
          const SkeletonScope(
            child: Column(
              children: [
                SkeletonBox(height: 20),
                SkeletonLine(),
                SkeletonCircle(size: 24),
                SkeletonBox(height: 20),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('renders static boxes when animations are disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SkeletonScope(child: SkeletonBox(height: 20)),
          disableAnimations: true,
        ),
      );

      expect(find.byType(Shimmer), findsNothing);
      expect(find.byType(SkeletonBox), findsOneWidget);
    });
  });

  group('composed skeletons', () {
    testWidgets('HomeBannerSkeleton is exactly the requested height', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const HomeBannerSkeleton(height: 188)));

      expect(tester.getSize(find.byType(HomeBannerSkeleton)).height, 188);
    });

    final builders = <String, Widget Function()>{
      'HomeBannerSkeleton': () => const HomeBannerSkeleton(height: 188),
      'HomeStatusTabsSkeleton': () => const HomeStatusTabsSkeleton(),
      'card live': () => const TournamentMatchesCardSkeleton(
        variant: SkeletonCardVariant.live,
      ),
      'card schedule': () => const TournamentMatchesCardSkeleton(
        variant: SkeletonCardVariant.schedule,
      ),
      'card result': () => const TournamentMatchesCardSkeleton(
        variant: SkeletonCardVariant.result,
      ),
      'rows live': () => const TournamentMatchRowsSkeleton(
        variant: SkeletonCardVariant.live,
      ),
      'rows schedule': () => const TournamentMatchRowsSkeleton(
        variant: SkeletonCardVariant.schedule,
      ),
      'TournamentBannerCardSkeleton': () => const TournamentBannerCardSkeleton(),
      'ListPageSkeleton': () => const ListPageSkeleton(),
      'ListPageSkeleton no avatar': () =>
          const ListPageSkeleton(itemCount: 3, leadingAvatar: false),
      'DetailPageSkeleton': () => const DetailPageSkeleton(),
      'TournamentListItemSkeleton': () => const TournamentListItemSkeleton(),
      'LeaderboardRowSkeleton': () => const LeaderboardRowSkeleton(),
      'SocialPostSkeleton': () => const SocialPostSkeleton(),
      'MatchRowSkeleton': () => const MatchRowSkeleton(),
    };
    const sizes = [Size(360, 640), Size(412, 915), Size(820, 1180)];

    for (final entry in builders.entries) {
      for (final size in sizes) {
        testWidgets('${entry.key} fits ${size.width}x${size.height}', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            _host(SingleChildScrollView(child: entry.value())),
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(Shimmer), findsOneWidget);
        });
      }
    }
  });
}
