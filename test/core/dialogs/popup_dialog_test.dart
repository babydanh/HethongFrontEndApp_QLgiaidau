import 'package:app_quanly_giaidau/core/dialogs/popup_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const label = 'Popup body';
  bool? result;

  Future<void> pumpHost(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const ValueKey('open'),
                onPressed: () async {
                  result = await showPopupDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      content: const Text(label),
                      actions: [
                        TextButton(
                          key: const ValueKey('yes'),
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Lowest opacity found on the transitions wrapping the popup body.
  double bodyOpacity(WidgetTester tester) {
    final fades = tester.widgetList<FadeTransition>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(FadeTransition),
      ),
    );
    return fades
        .map((fade) => fade.opacity.value)
        .reduce((a, b) => a < b ? a : b);
  }

  testWidgets('TC-POPUP-01: popup fades and grows in, not appearing at once', (
    tester,
  ) async {
    await pumpHost(tester);
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text(label), findsOneWidget);
    expect(bodyOpacity(tester), lessThan(1));
    final scale = tester.widget<ScaleTransition>(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byType(ScaleTransition),
          )
          .first,
    );
    expect(scale.scale.value, lessThan(1));

    await tester.pumpAndSettle();
    expect(bodyOpacity(tester), 1);
  });

  testWidgets('TC-POPUP-02: popup is fully shown at once with reduced motion', (
    tester,
  ) async {
    await pumpHost(tester, reduceMotion: true);
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pump();
    await tester.pump();

    expect(find.text(label), findsOneWidget);
    expect(bodyOpacity(tester), 1);
  });

  testWidgets('TC-POPUP-03: the value popped by the popup is returned', (
    tester,
  ) async {
    await pumpHost(tester);
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('yes')));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text(label), findsNothing);
  });

  testWidgets('TC-POPUP-04: a tap on the barrier closes the popup with null', (
    tester,
  ) async {
    await pumpHost(tester);
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(find.text(label), findsNothing);
    expect(result, isNull);
  });
}
