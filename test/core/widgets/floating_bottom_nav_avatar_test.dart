import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(this.initialState);

  final AuthState initialState;

  @override
  AuthState build() => initialState;
}

const _signedIn = AuthState(
  status: AuthStatus.authenticated,
  role: UserRole.viewer,
);
const _withPhoto = UserProfile(
  id: 'u1',
  fullName: 'Alex',
  avatarUrl: 'https://example.test/a.png',
);

Future<void> _pumpNav(
  WidgetTester tester, {
  required AuthState authState,
  required UserProfile profile,
  List<PlayerRanking> rankings = const [],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => _TestAuthNotifier(authState)),
        userProfileProvider.overrideWith((ref) async => profile),
        userRankingsProvider.overrideWith((ref) async => rankings),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          bottomNavigationBar: FloatingBottomNav(
            currentIndex: 0,
            onTabSelected: (_) {},
            onMenuTap: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color? _ringColor(WidgetTester tester) {
  final outer = find
      .descendant(of: find.byType(RankAvatar), matching: find.byType(Container))
      .first;
  final decoration =
      tester.widget<Container>(outer).decoration! as BoxDecoration;
  return decoration.color;
}

void main() {
  testWidgets('fifth tab keeps the person icon for guests', (tester) async {
    await _pumpNav(tester, authState: const AuthState(), profile: _withPhoto);
    expect(find.byType(RankAvatar), findsNothing);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
  });

  testWidgets('fifth tab ring uses the best rank tier color from the web', (
    tester,
  ) async {
    await _pumpNav(
      tester,
      authState: _signedIn,
      profile: _withPhoto,
      rankings: [
        const PlayerRanking(
          id: 'r1',
          userId: 'u1',
          fullName: 'Alex',
          eloPoints: 1250,
          tierName: 'Low Tier C',
          matchesPlayed: 4,
        ),
        const PlayerRanking(
          id: 'r2',
          userId: 'u1',
          fullName: 'Alex',
          eloPoints: 1850,
          tierName: 'Tier S',
          matchesPlayed: 9,
        ),
      ],
    );
    expect(find.byType(RankAvatar), findsOneWidget);
    expect(_ringColor(tester), const Color(0xFFFBBF24));
  });

  testWidgets('fifth tab ring is neutral when the user has no rank yet', (
    tester,
  ) async {
    await _pumpNav(tester, authState: _signedIn, profile: _withPhoto);
    expect(find.byType(RankAvatar), findsOneWidget);
    expect(_ringColor(tester), const Color(0xFFCBD5E1));
  });

  testWidgets(
    'fifth tab keeps the person icon when signed in without a photo',
    (tester) async {
      await _pumpNav(
        tester,
        authState: _signedIn,
        profile: const UserProfile(id: 'u1', fullName: 'Alex'),
      );
      expect(find.byType(RankAvatar), findsNothing);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    },
  );
}
