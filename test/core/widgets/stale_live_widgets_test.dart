import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/stale_live_widgets.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme,
  locale: const Locale('vi'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SizedBox(width: 320, child: Center(child: child)),
  ),
);

MatchModel _match({DateTime? lastActivityAt}) => MatchModel(
  id: 'm',
  round: 1,
  matchNumber: 1,
  status: 'ONGOING',
  isStaleLive: true,
  lastActivityAt: lastActivityAt,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime(2026, 11, 1),
);

void main() {
  testWidgets('TC-SLM-APP-04 badge says Tạm dừng, not LIVE', (tester) async {
    await tester.pumpWidget(_harness(const StaleLiveBadge()));

    expect(find.text('Tạm dừng'), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
  });

  testWidgets('TC-SLM-APP-05 reminder shows the hours since last activity', (
    tester,
  ) async {
    final now = DateTime(2026, 11, 8, 12);
    await tester.pumpWidget(
      _harness(
        StaleLiveReminder(
          match: _match(
            lastActivityAt: now.subtract(const Duration(hours: 14)),
          ),
          now: now,
        ),
      ),
    );

    expect(
      find.text('Chưa cập nhật 14 giờ. Hãy kết thúc hoặc hủy trận.'),
      findsOneWidget,
    );
  });

  testWidgets('TC-SLM-APP-05b reminder without lastActivityAt omits hours', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(StaleLiveReminder(match: _match())));

    expect(
      find.text('Trận chưa được cập nhật gần đây. Hãy kết thúc hoặc hủy trận.'),
      findsOneWidget,
    );
  });

  testWidgets('TC-SLM-APP-05c reminder is empty for a normal live match', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(StaleLiveReminder(match: _match().copyWith(isStaleLive: false))),
    );

    expect(find.byIcon(Icons.hourglass_bottom_rounded), findsNothing);
  });
}
