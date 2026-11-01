import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_bone_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sizes = [Size(360, 640), Size(412, 915), Size(820, 1180)];

final _widgets = <String, Widget Function()>{
  'list': () => const BoneListLoading(),
  'list no avatar': () => const BoneListLoading(leadingAvatar: false),
  'block': () => const BoneBlockLoading(),
  'matches': () => const BoneMatchListLoading(),
  'standings': () => const BoneStandingsLoading(),
  'detail': () => const BoneDetailLoading(),
  'podium': () => const BonePodiumLoading(),
  'bracket': () => const BoneBracketLoading(),
  'chips': () => const BoneChipsLoading(),
};

Future<void> _pump(WidgetTester tester, Size size, Widget body) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: body)));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  for (final entry in _widgets.entries) {
    for (final size in _sizes) {
      testWidgets('${entry.key} fits a bounded region at $size', (tester) async {
        await _pump(tester, size, SizedBox(height: 200, child: entry.value()));

        expect(tester.takeException(), isNull);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('${entry.key} fits a scrolling list at $size', (tester) async {
        await _pump(tester, size, ListView(children: [entry.value()]));

        expect(tester.takeException(), isNull);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    }
  }

  testWidgets('skeleton is static when animations are disabled', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: Scaffold(body: BoneListLoading())),
      ),
    );

    expect(tester.hasRunningAnimations, isFalse);
  });
}
