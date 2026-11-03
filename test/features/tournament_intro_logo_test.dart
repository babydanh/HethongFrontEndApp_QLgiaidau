import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_intro_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _id = 'tournament-logo';

class _GuestAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _tournament({String? bannerUrl, String? logoUrl}) =>
    Tournament.fromJson({
      'name': 'Logo Cup',
      'sport': 'pickleball',
      'format': 'doubles',
      'bracketType': 'single_elimination',
      'status': 'REGISTRATION_OPEN',
      'visibility': 'PUBLIC',
      'maxTeams': 8,
      'bannerUrl': bannerUrl,
      'logoUrl': logoUrl,
      'createdAt': '2026-01-01T00:00:00Z',
      'updatedAt': '2026-01-01T00:00:00Z',
    }, _id);

Future<void> _pump(WidgetTester tester, Tournament tournament) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_GuestAuth.new),
        userProfileProvider.overrideWith(
          (ref) async => UserProfile(
            id: 'viewer-1',
            fullName: 'Viewer',
            email: 'viewer@example.test',
          ),
        ),
        tournamentIntroWithInviteProvider((
          id: _id,
          invite: null,
        )).overrideWith((ref) async => tournament),
        tournamentDivisionsProvider(
          _id,
        ).overrideWith((ref) async => const <Map<String, dynamic>>[]),
        introTeamsProvider(_id).overrideWith((ref) async => const []),
        teamsProvider(_id).overrideWith((ref) => Stream.value(const [])),
        matchesProvider(_id).overrideWith((ref) => Stream.value(const [])),
        followedTournamentsProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: const TournamentIntroScreen(tournamentId: _id),
      ),
    ),
  );
  await tester.pump();
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  const logoKey = ValueKey('tournament-intro-logo');

  testWidgets('TC-INTRO-LOGO-01 a tournament with banner and logo shows the logo', (
    tester,
  ) async {
    await _pump(
      tester,
      _tournament(
        bannerUrl: 'https://images.example/banner.jpg',
        logoUrl: 'https://images.example/logo.png',
      ),
    );

    expect(find.byKey(logoKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC-INTRO-LOGO-02 no logo means no logo badge on the banner', (
    tester,
  ) async {
    await _pump(
      tester,
      _tournament(bannerUrl: 'https://images.example/banner.jpg'),
    );

    expect(find.byKey(logoKey), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
