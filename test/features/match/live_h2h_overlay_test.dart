import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_h2h_overlay.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_side_avatars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({String round = 'ROUND 1', double width = 360}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
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
}
