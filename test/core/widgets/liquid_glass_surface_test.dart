import 'package:app_quanly_giaidau/core/widgets/liquid_glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await LiquidGlassWidgets.initialize(
      warmUpMode: GlassWarmUpMode.never,
      enablePerformanceMonitor: false,
    );
  });
  testWidgets('normal contrast renders the standard Liquid Glass shader', (
    tester,
  ) async {
    await tester.pumpWidget(
      LiquidGlassWidgets.wrap(
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(highContrast: false),
            child: child!,
          ),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                height: 72,
                child: _SearchGlassHarness(),
              ),
            ),
          ),
        ),
        brightnessResolver: Theme.maybeBrightnessOf,
      ),
    );
    await tester.pump();

    final glass = tester.widget<GlassContainer>(find.byType(GlassContainer));
    expect(glass.quality, GlassQuality.standard);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'high contrast uses an opaque fallback and keeps the action labeled',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(highContrast: true),
            child: child!,
          ),
          home: Scaffold(
            body: ColoredBox(
              color: Colors.red,
              child: Center(
                child: SizedBox(
                  width: 160,
                  height: 72,
                  child: const _SearchGlassHarness(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GlassContainer), findsNothing);
      expect(find.byType(BackdropFilter), findsNothing);
      final decoration = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(LiquidGlassSurface),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((decoration.decoration as BoxDecoration).color, Colors.white);

      final action = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(LiquidGlassSurface),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Open tournament search',
          ),
        ),
      );
      expect(action.properties.label, 'Open tournament search');
      expect(action.properties.button, isTrue);
    },
  );
}

class _SearchGlassHarness extends StatelessWidget {
  const _SearchGlassHarness();

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      tintColor: Colors.white,
      fallbackColor: Colors.white,
      borderColor: Colors.white,
      borderRadius: BorderRadius.circular(16),
      opacity: 0.12,
      child: Semantics(
        button: true,
        label: 'Open tournament search',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
