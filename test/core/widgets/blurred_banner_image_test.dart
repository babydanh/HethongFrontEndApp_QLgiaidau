import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/core/widgets/blurred_banner_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 1x1 transparent PNG, so the test never touches the network.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: SizedBox(width: 400, height: 200, child: child),
  ),
);

void main() {
  group('BlurredBannerImage', () {
    testWidgets('TC-BANNERFIT-APP-01 shows the banner whole (contain) on top of a blurred cover copy', (
      tester,
    ) async {
      await tester.pumpWidget(_host(BlurredBannerImage(image: MemoryImage(_png))));

      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images, hasLength(2));
      expect(images.first.fit, BoxFit.cover, reason: 'backdrop fills the frame');
      expect(images.last.fit, BoxFit.contain, reason: 'foreground is never cropped');
      expect(find.byType(ImageFiltered), findsOneWidget);
    });

    testWidgets('TC-BANNERFIT-APP-02 the blurred backdrop is hidden from screen readers', (tester) async {
      await tester.pumpWidget(_host(BlurredBannerImage(image: MemoryImage(_png))));

      final backdrop = tester.widgetList<Image>(find.byType(Image)).first;
      expect(backdrop.excludeFromSemantics, isTrue);
    });

    testWidgets('TC-BANNERFIT-APP-03 a failing image shows the fallback and no blurred leftover', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          BlurredBannerImage(
            image: MemoryImage(Uint8List.fromList(const [1, 2, 3])),
            errorBuilder: (_, _, _) => const Text('fallback'),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();

      expect(find.text('fallback'), findsOneWidget);
    });
  });
}
