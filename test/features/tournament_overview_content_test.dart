import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/overview_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _UnauthenticatedNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _multiDivisionTournament() => Tournament.fromJson({
  'name': 'Overview content regression',
  'sport': 'badminton',
  'format': 'SINGLES',
  'bracketType': 'single_elimination',
  'status': 'in_progress',
  'creatorId': 'creator-1',
  'maxTeams': 16,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-01T00:00:00.000Z',
  'entryFee': 200001,
  'divisions': [
    {
      'id': 'division-men',
      'name': 'Regression Men Division',
      'matchType': 'SINGLES',
      'maxParticipants': 16,
    },
    {
      'id': 'division-women',
      'name': 'Regression Women Division',
      'matchType': 'SINGLES',
      'maxParticipants': 16,
    },
  ],
}, 'tournament-1');

void main() {
  testWidgets(
    'overview omits division cards while keeping schedule and fee details',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith(_UnauthenticatedNotifier.new)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: Scaffold(
              body: OverviewTab(
                tournament: _multiDivisionTournament(),
                teamCount: 0,
                resolveImageUrl: (_) => '',
                onNavigateToMatches: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('NỘI DUNG THI ĐẤU'), findsNothing);
      expect(find.text('Regression Men Division'), findsNothing);
      expect(find.text('Regression Women Division'), findsNothing);
      expect(find.text('Lịch thi đấu'), findsOneWidget);
      expect(find.text('THỜI GIAN ĐĂNG KÝ & LỆ PHÍ'), findsOneWidget);
      expect(find.text('Lệ phí tham gia:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
