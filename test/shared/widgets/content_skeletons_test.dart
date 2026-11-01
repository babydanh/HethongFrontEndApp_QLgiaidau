import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/shared/widgets/content_skeletons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _sizes = [Size(360, 640), Size(412, 915), Size(820, 1180)];

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme,
  home: Scaffold(body: Column(children: [Expanded(child: child)])),
);

void main() {
  final builders = <String, Widget Function()>{
    'ScrollFreeSkeleton': () =>
        const ScrollFreeSkeleton(child: ChatMessagesSkeleton()),
    'ChatMessagesSkeleton': () => const ChatMessagesSkeleton(),
    'FormSkeleton': () => const FormSkeleton(),
    'ProfileSummarySkeleton': () => const ProfileSummarySkeleton(),
    'RowTileSkeleton': () => const RowTileSkeleton(),
    'BlockSkeleton': () => const BlockSkeleton(height: 80),
  };

  for (final entry in builders.entries) {
    for (final size in _sizes) {
      testWidgets('${entry.key} renders without overflow at $size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_host(entry.value()));
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    }
  }
}
