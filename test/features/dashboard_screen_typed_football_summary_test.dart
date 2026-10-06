import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_team_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/dashboard/screens/dashboard_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _AuthenticatedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, role: UserRole.viewer);
}

class _PreviewWorkspaceNotifier extends MyTournamentWorkspaceNotifier {
  @override
  Future<TournamentWorkspace> build() async => TournamentWorkspace.empty;
}

ThemeData _lightPreviewTheme() {
  return ThemeData.light().copyWith(
    extensions: const [
      AppColorsExtension(
        bgDark: Color(0xFFFFFFFF),
        bgCard: Color(0xFFFFFFFF),
        bgSurface: Color(0xFFF8FAFC),
        bgElevated: Color(0xFFFFFFFF),
        textPrimary: Color(0xFF0F172A),
        textSecondary: Color(0xFF334155),
        textMuted: Color(0xFF64748B),
        border: Color(0xFFE2E8F0),
        borderLight: Color(0xFFF1F5F9),
        success: Color(0xFF22C55E),
        warning: Color(0xFFF59E0B),
        error: Color(0xFFEF4444),
        info: Color(0xFF3B82F6),
        chipBackground: Color(0xFF3A3B3C),
      ),
    ],
  );
}

void main() {
  testWidgets(
    'dashboard shows the highest-ELO typed football team without errors',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(_AuthenticatedAuthNotifier.new),
            userProfileProvider.overrideWith(
              (ref) async => const UserProfile(
                id: 'fixture-player',
                fullName: 'Nguyen An',
              ),
            ),
            userRankingsProvider.overrideWith(
              (ref) async => const [
                PlayerRanking(
                  id: 'rank-badminton',
                  userId: 'fixture-player',
                  fullName: 'Nguyen An',
                  eloPoints: 1360,
                  tierName: 'Gold',
                  rank: 2,
                  matchesPlayed: 8,
                  matchesWon: 6,
                  categoryId: 'badminton',
                  categoryName: 'Badminton',
                  peakElo: 1410,
                ),
              ],
            ),
            myFootballTeamsProvider.overrideWith(
              (ref) async => const [
                FootballTeamSummary(
                  id: 'team-low',
                  name: 'River Cats',
                  categoryId: 'football',
                  eloPoints: 1080,
                ),
                FootballTeamSummary(
                  id: 'team-high',
                  name: 'North Stars',
                  categoryId: 'football',
                  eloPoints: 1460,
                ),
              ],
            ),
            categoriesProvider.overrideWith((ref) async => const []),
            followedTournamentsProvider.overrideWith((ref) async => const []),
            myTournamentWorkspaceProvider.overrideWith(
              _PreviewWorkspaceNotifier.new,
            ),
          ],
          child: MaterialApp(
            theme: _lightPreviewTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('vi'),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('North Stars'), findsOneWidget);
      expect(find.textContaining('River Cats'), findsNothing);
      expect(find.text('1360 ELO'), findsOneWidget);
      expect(find.text('1460 ELO'), findsOneWidget);
      expect(find.text('Hoạt động theo môn'), findsOneWidget);
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(360, 800);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
