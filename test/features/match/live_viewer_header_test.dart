import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_viewer_header.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TC-LIVEVIEW-01 shows title, subtitle and cheer count', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        LiveViewerHeader(
          title: 'Alpha vs Beta',
          subtitle: '12 watching · Cup · Round 1',
          cheerCount: 1234,
          onCheer: () {},
          onShare: () {},
          onMore: () {},
        ),
      ),
    );

    expect(find.text('Alpha vs Beta'), findsOneWidget);
    expect(find.text('12 watching · Cup · Round 1'), findsOneWidget);
    expect(find.text('1234'), findsOneWidget);
  });

  testWidgets('TC-LIVEVIEW-02 chips and "more" fire their callbacks', (
    tester,
  ) async {
    var cheers = 0, shares = 0, mores = 0, tournaments = 0;
    await tester.pumpWidget(
      _app(
        LiveViewerHeader(
          title: 'A vs B',
          subtitle: 'sub',
          cheerCount: 0,
          onCheer: () => cheers++,
          onShare: () => shares++,
          onMore: () => mores++,
          tournamentLabel: 'Cup ABC',
          onOpenTournament: () => tournaments++,
        ),
      ),
    );

    await tester.tap(find.text('Cheer'));
    await tester.tap(find.text('Share'));
    await tester.tap(find.text('Cup ABC'));
    await tester.tap(find.text('More'));

    expect([cheers, shares, tournaments, mores], [1, 1, 1, 1]);
  });

  testWidgets('TC-LIVEVIEW-03 hides the tournament chip when there is none', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        LiveViewerHeader(
          title: 'A vs B',
          subtitle: 'sub',
          cheerCount: 0,
          onCheer: () {},
          onShare: () {},
          onMore: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.emoji_events_outlined), findsNothing);
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme,
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);
