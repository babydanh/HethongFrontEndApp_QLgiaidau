import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'shot.dart';

/// Empty dotenv so code reading `dotenv.env` works without a real `.env`.
void initXem() => dotenv.loadFromString(isOptional: true);

/// Real app theme + Vietnamese l10n around [home], with fake providers.
/// No network and no Backend: every repository must be overridden.
Widget xemApp({required Widget home, List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: home,
      ),
    );

/// Pumps until idle but never hangs on a looping animation (LIVE pulse, etc.).
Future<void> settle(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  } on FlutterError {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// First vertical scrollable on screen (the page body in these tests).
final _pageScrollable = find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

/// Scrolls the page by [dy] logical pixels (positive = further down).
Future<void> scrollBy(WidgetTester tester, double dy) async {
  await tester.drag(_pageScrollable, Offset(0, -dy));
  await settle(tester);
}

/// Scrolls the page until [target] is visible.
Future<void> scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 200, scrollable: _pageScrollable);
  await settle(tester);
}

/// Pumps [app], then takes named screenshots with [snap]. The surface is
/// converted to an image once, lazily, on the first [snap] of the test.
class XemShooter {
  XemShooter(this.tester, this.binding);

  final WidgetTester tester;
  final IntegrationTestWidgetsFlutterBinding binding;
  bool _converted = false;

  Future<void> pump(Widget app) async {
    await tester.pumpWidget(app);
    await settle(tester);
  }

  Future<void> snap(String name) async {
    await settle(tester);
    if (!_converted) {
      await binding.convertFlutterSurfaceToImage();
      _converted = true;
    }
    await tester.pump();
    await shot(binding, name);
  }
}
