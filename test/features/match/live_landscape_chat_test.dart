import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_landscape_chat.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({
  required List<LiveChatLine> lines,
  required bool canPost,
  VoidCallback? onSend,
  VoidCallback? onCheer,
  VoidCallback? onLogin,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Stack(
        children: [
          LiveLandscapeChat(
            lines: lines,
            canPost: canPost,
            controller: TextEditingController(),
            sending: false,
            onSend: onSend ?? () {},
            onCheer: onCheer ?? () {},
            onLogin: onLogin ?? () {},
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('TC-LIVEFS-07 shows chat lines newest at the bottom', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        lines: const [
          LiveChatLine(id: '2', name: 'Bob', text: 'second'),
          LiveChatLine(id: '1', name: 'Ann', text: 'first'),
        ],
        canPost: true,
      ),
    );

    expect(find.textContaining('first', findRichText: true), findsOneWidget);
    expect(find.textContaining('second', findRichText: true), findsOneWidget);
    expect(
      tester.getTopLeft(find.textContaining('first', findRichText: true)).dy,
      lessThan(tester.getTopLeft(find.textContaining('second', findRichText: true)).dy),
    );
  });

  testWidgets('TC-LIVEFS-08 posting needs login; send and cheer fire', (
    tester,
  ) async {
    var logins = 0, sends = 0, cheers = 0;
    await tester.pumpWidget(
      _app(
        lines: const [],
        canPost: false,
        onLogin: () => logins++,
        onSend: () => sends++,
        onCheer: () => cheers++,
      ),
    );
    await tester.tap(find.text('Log in'));
    expect(logins, 1);
    expect(find.byIcon(Icons.send_rounded), findsNothing);

    await tester.pumpWidget(
      _app(
        lines: const [],
        canPost: true,
        onLogin: () => logins++,
        onSend: () => sends++,
        onCheer: () => cheers++,
      ),
    );
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.tap(find.byIcon(Icons.favorite_rounded));
    expect([sends, cheers], [1, 1]);
  });

  testWidgets('TC-LIVEFS-12 comment box draws no outline even when focused', (
    tester,
  ) async {
    await tester.pumpWidget(_app(lines: const [], canPost: true));
    await tester.tap(find.byType(TextField));
    await tester.pump();

    final decoration = tester.widget<TextField>(find.byType(TextField)).decoration!;
    for (final border in [
      decoration.border,
      decoration.enabledBorder,
      decoration.focusedBorder,
      decoration.disabledBorder,
    ]) {
      expect((border! as OutlineInputBorder).borderSide, BorderSide.none);
    }
  });
}
