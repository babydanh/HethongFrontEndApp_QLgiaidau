import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_h2h_overlay.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_side_avatars.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({String round = 'ROUND 1', double width = 360}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          key: const ValueKey('host'),
          width: width,
          child: LiveH2hOverlay(
            title: 'ĐỐI ĐẦU',
            roundLabel: round,
            left: const LiveH2hSideData(
              name: 'son bao b',
              ringColor: LiveH2hOverlay.leftRing,
            ),
            right: const LiveH2hSideData(
              name: 'Sơn Bảo Phan / Tiến Minh',
              ringColor: LiveH2hOverlay.rightRing,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('TC-LIVEOVL-01 shows title, round pill, both names and VS', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.textContaining('ĐỐI', findRichText: true), findsOneWidget);
    expect(find.text('ROUND 1'), findsOneWidget);
    expect(find.text('son bao b'), findsOneWidget);
    expect(find.text('Sơn Bảo Phan / Tiến Minh'), findsOneWidget);
    expect(find.text('VS'), findsOneWidget);
    // Initials ring when there is no photo.
    expect(find.text('SB'), findsOneWidget);
  });

  testWidgets('TC-LIVEOVL-02 an empty round label hides the pill', (
    tester,
  ) async {
    await tester.pumpWidget(_app(round: ''));

    expect(find.byKey(const ValueKey('live-h2h-round')), findsNothing);
  });

  testWidgets('TC-LIVEOVL-03 narrow video with long names does not overflow', (
    tester,
  ) async {
    await tester.pumpWidget(_app(width: 240));

    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-LIVEOVL-04 singles show one avatar, a pair shows two', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveH2hOverlay(
            title: 'ĐỐI ĐẦU',
            roundLabel: '',
            left: const LiveH2hSideData(
              name: 'odi695',
              ringColor: LiveH2hOverlay.leftRing,
              avatars: [LiveAvatarData(name: 'odi695')],
            ),
            right: const LiveH2hSideData(
              name: 'An Nguyễn / Bình Trần',
              ringColor: LiveH2hOverlay.rightRing,
              avatars: [
                LiveAvatarData(name: 'An Nguyễn'),
                LiveAvatarData(name: 'Bình Trần'),
              ],
            ),
          ),
        ),
      ),
    );

    // Single-word username: one initial; the pair: two overlapped avatars.
    expect(find.text('O'), findsOneWidget);
    expect(find.text('AN'), findsOneWidget);
    expect(find.text('BT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-LIVEOVL-05 exposes one spoken summary when labelled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveH2hOverlay(
            title: 'ĐỐI ĐẦU',
            roundLabel: 'ROUND 1',
            semanticsLabel: 'son bao b vs Sơn Bảo Phan',
            left: const LiveH2hSideData(
              name: 'son bao b',
              ringColor: LiveH2hOverlay.leftRing,
            ),
            right: const LiveH2hSideData(
              name: 'Sơn Bảo Phan',
              ringColor: LiveH2hOverlay.rightRing,
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('son bao b vs Sơn Bảo Phan'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('TC-LIVEOVL-06 glass panel: blur backdrop, no fading Opacity', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    final inOverlay = find.descendant(
      of: find.byType(LiveH2hOverlay),
      matching: find.byType(Opacity),
    );
    for (final opacity in tester.widgetList<Opacity>(inOverlay)) {
      expect(opacity.opacity, 1);
    }
    expect(
      find.descendant(
        of: find.byType(LiveH2hOverlay),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
  });

  testWidgets('TC-LIVEOVL-07 panel is at most 70% of the video and centred', (
    tester,
  ) async {
    await tester.pumpWidget(_app(width: 400));

    final host = tester.getRect(find.byKey(const ValueKey('host')));
    final panel = tester.getRect(find.byKey(const ValueKey('live-h2h-panel')));
    expect(panel.width, lessThanOrEqualTo(host.width * 0.7 + 0.5));
    expect(panel.width, greaterThanOrEqualTo(220));
    expect(panel.center.dx, closeTo(host.center.dx, 0.5));
  });

  testWidgets('TC-LIVEOVL-08 height follows the video width, no overflow', (
    tester,
  ) async {
    double panelHeight() =>
        tester.getSize(find.byKey(const ValueKey('live-h2h-panel'))).height;

    await tester.pumpWidget(_app(width: 400));
    final wide = panelHeight();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_app(width: 280));
    final narrow = panelHeight();
    expect(tester.takeException(), isNull);

    // Scale is 0.7 at 400dp and 0.49 at 280dp: the narrow panel is about 70%
    // as tall (hairline borders keep a 1dp floor, hence the slack).
    expect(narrow, inInclusiveRange(wide * 0.6, wide * 0.8));
    // Smaller than the old fixed layout (28 + 38 + 16 = 82dp).
    expect(wide, lessThan(82 * 0.75));
  });

  testWidgets('TC-LIVEOVL-09 the header carries the Sporto logo', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(
      find.descendant(
        of: find.byType(LiveH2hOverlay),
        matching: find.byType(SvgPicture),
      ),
      findsOneWidget,
    );
  });

  testWidgets('TC-LIVEOVL-11 small round close button hangs off the corner', (
    tester,
  ) async {
    var closed = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              key: const ValueKey('host'),
              width: 400,
              child: LiveH2hOverlay(
                title: 'ĐỐI ĐẦU',
                roundLabel: 'ROUND 1',
                onClose: () => closed++,
                left: const LiveH2hSideData(
                  name: 'son bao b',
                  ringColor: LiveH2hOverlay.leftRing,
                ),
                right: const LiveH2hSideData(
                  name: 'Sơn Bảo Phan',
                  ringColor: LiveH2hOverlay.rightRing,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final dot = tester.getRect(
      find.byKey(const ValueKey('live-overlay-close-dot')),
    );
    final panel = tester.getRect(find.byKey(const ValueKey('live-h2h-panel')));
    final pill = tester.getRect(find.byKey(const ValueKey('live-h2h-round')));
    final touch = tester.getRect(find.byType(IconButton));
    final host = tester.getRect(find.byKey(const ValueKey('host')));
    expect(dot.width, greaterThanOrEqualTo(24));
    expect(touch.shortestSide, greaterThanOrEqualTo(40));
    // Sits on the panel's top-right corner, partly outside it.
    expect(dot.top, lessThan(panel.top));
    expect(dot.right, greaterThan(panel.right));
    // Never covers the round pill, and the panel stays centred on the video.
    expect(pill.right, lessThanOrEqualTo(dot.left));
    expect(panel.center.dx, closeTo(host.center.dx, 0.5));

    await tester.tap(find.byTooltip('Đóng'));
    expect(closed, 1);
    expect(tester.takeException(), isNull);
  });
}
