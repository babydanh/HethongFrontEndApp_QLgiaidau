import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  locale: const Locale('vi'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

const _lan = ParticipantPlayer(slot: 1, fullName: 'Pham Thi Lan');
const _nga = ParticipantPlayer(slot: 2, fullName: 'Vu Thi Nga');

void main() {
  testWidgets('TC-SIDE-01 named team shows one logo and one team-name line', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        const ParticipantSideLines(teamName: 'Sam Set', players: [_lan, _nga]),
      ),
    );

    expect(find.byKey(const ValueKey('side-lines-team-logo')), findsOneWidget);
    expect(find.text('Sam Set'), findsOneWidget);
    expect(find.text(abbreviateName('Pham Thi Lan')), findsNothing);
  });

  testWidgets('TC-SIDE-02 unnamed doubles shows one avatar line per player', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        const ParticipantSideLines(teamName: null, players: [_lan, _nga]),
      ),
    );

    expect(find.byKey(const ValueKey('side-lines-team-logo')), findsNothing);
    expect(find.byKey(const ValueKey('side-lines-player-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('side-lines-player-1')), findsOneWidget);
    expect(find.text(abbreviateName('Pham Thi Lan')), findsOneWidget);
    expect(find.text(abbreviateName('Vu Thi Nga')), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNWidgets(2));
  });

  testWidgets('TC-SIDE-03 singles shows a single avatar line', (tester) async {
    await tester.pumpWidget(
      _harness(const ParticipantSideLines(teamName: '', players: [_lan])),
    );

    expect(find.byKey(const ValueKey('side-lines-player-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('side-lines-player-1')), findsNothing);
  });

  testWidgets('TC-SIDE-04 the winning side is bold and ticked', (tester) async {
    await tester.pumpWidget(
      _harness(
        const ParticipantSideLines(teamName: null, players: [_lan], won: true),
      ),
    );

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    final text = tester.widget<Text>(find.text(abbreviateName('Pham Thi Lan')));
    expect(text.style?.fontWeight, FontWeight.w800);
  });

  testWidgets('TC-SIDE-05 a side without players says it is undetermined', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(const ParticipantSideLines(teamName: null, players: [])),
    );

    expect(find.text('Chưa xác định'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing);
  });

  testWidgets('TC-SIDE-06 a player without a photo shows the initial', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(const ParticipantSideLines(teamName: null, players: [_lan])),
    );

    expect(find.text('PL'), findsOneWidget);
  });

  testWidgets('TC-SIDE-07 avatar colour follows the name like the Web', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(const ParticipantSideLines(teamName: null, players: [_lan])),
    );

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.radius, 9);
    expect(avatar.backgroundColor, avatarFallbackColor('Pham Thi Lan'));
    expect(
      avatarFallbackColor('  PHAM  thi lan '),
      avatarFallbackColor('Pham Thi Lan'),
    );
    expect(avatarInitials('Nguyễn Hoàng Phong'), 'NP');
    expect(avatarInitials('Lan'), 'L');
    expect(avatarInitials(''), '?');
  });

  testWidgets('TC-SIDE-08 the tick of the winner is the Lavish blue', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        const ParticipantSideLines(teamName: null, players: [_lan], won: true),
      ),
    );

    final tick = tester.widget<Icon>(find.byIcon(Icons.check_rounded));
    expect(tick.color, const Color(0xFF2563EB));
    expect(tick.size, 12);
  });

  testWidgets('TC-SIDE-09 an empty side names the match it waits for', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        const ParticipantSideLines(
          teamName: null,
          players: [],
          waitingFor: 'V1601',
        ),
      ),
    );

    expect(find.text('Chờ đội thắng V1601'), findsOneWidget);
    expect(find.text('Chưa xác định'), findsNothing);
  });
}
