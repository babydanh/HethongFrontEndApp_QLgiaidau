import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_comment_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TC-LIVEVIEW-14 signed-in input is one pill with send inside', (
    tester,
  ) async {
    var sent = 0;
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        LiveCommentInput(
          controller: controller,
          hint: 'Write a comment...',
          canPost: true,
          sending: false,
          onSend: () => sent++,
          onLogin: () {},
          loginLabel: 'Log in',
        ),
      ),
    );

    expect(find.text('Write a comment...'), findsOneWidget);
    // One block: a single text field, no standalone heart, send inside.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    await tester.tap(find.byIcon(Icons.send_rounded));
    expect(sent, 1);
  });

  testWidgets('TC-LIVEVIEW-15 guest sees a login button and cannot type', (
    tester,
  ) async {
    var logins = 0;
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        LiveCommentInput(
          controller: controller,
          hint: 'Log in to comment',
          canPost: false,
          sending: false,
          onSend: () {},
          onLogin: () => logins++,
          loginLabel: 'Log in',
        ),
      ),
    );

    expect(find.byIcon(Icons.send_rounded), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester.tap(find.text('Log in'));
    expect(logins, 1);
  });

  testWidgets('TC-LIVEVIEW-16 sending shows progress and blocks double send', (
    tester,
  ) async {
    var sent = 0;
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        LiveCommentInput(
          controller: controller,
          hint: 'x',
          canPost: true,
          sending: true,
          onSend: () => sent++,
          onLogin: () {},
          loginLabel: 'Log in',
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    expect(sent, 0);
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme,
  home: Scaffold(body: Center(child: child)),
);
