import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:app_quanly_giaidau/features/lite/screens/lite_join_screen.dart';
import 'package:app_quanly_giaidau/features/lite/screens/lite_management_screen.dart';
import 'package:app_quanly_giaidau/features/lite/screens/lite_pairing_screen.dart';
import 'package:app_quanly_giaidau/features/register/screens/football_team_register_screen.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'loading_harness.dart';

class _AuthenticatedUser extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

void _expectSkeletonNotSpinner(WidgetTester tester) {
  expect(find.byType(SkeletonScope), findsWidgets);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  testWidgets('LiteJoinScreen shows skeleton while loading the invite', (
    tester,
  ) async {
    await pumpLoading(
      tester,
      const LiteJoinScreen(inviteCode: 'CODE'),
      overrides: [
        pendingDioOverride,
        authProvider.overrideWith(_AuthenticatedUser.new),
      ],
    );
    _expectSkeletonNotSpinner(tester);
  });

  testWidgets('LiteManagementScreen shows skeleton under the tab bar', (
    tester,
  ) async {
    await pumpLoading(
      tester,
      const LiteManagementScreen(tournamentId: 't1'),
      overrides: [pendingDioOverride],
    );
    expect(find.byType(TabBar), findsOneWidget);
    _expectSkeletonNotSpinner(tester);
    // The notifier arms 12 s request timeouts; let them fire so no timer is
    // left pending when the test ends.
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 13));
    }
  });

  testWidgets('LitePairingScreen shows skeleton while loading', (tester) async {
    await pumpLoading(
      tester,
      const LitePairingScreen(tournamentId: 't1'),
      overrides: [pendingDioOverride],
    );
    _expectSkeletonNotSpinner(tester);
  });

  testWidgets('FootballTeamRegisterScreen shows skeleton while loading teams', (
    tester,
  ) async {
    await pumpLoading(
      tester,
      const FootballTeamRegisterScreen(tournamentId: 't1'),
      overrides: [pendingDioOverride],
    );
    expect(find.byType(SkeletonScope), findsWidgets);
    // The submit button may still hold a small in-button spinner; the content
    // area must not.
    expect(
      find.descendant(
        of: find.byType(Scrollable).first,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
