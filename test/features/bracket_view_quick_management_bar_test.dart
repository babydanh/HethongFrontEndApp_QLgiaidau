import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_management_bar.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/standings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// TC-BRACKET-MGMT-06: quick (Lite-family) tournaments still get Create bracket in the hub.
const _tournamentId = 'quick-bracket-fixture';
const _divisionId = 'division-a';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _tournament({required bool isLite}) => Tournament(
  id: _tournamentId,
  name: 'Quick bracket fixture',
  sport: 'pickleball',
  format: 'DOUBLES',
  bracketType: 'single_elimination',
  status: 'registration_closed',
  visibility: 'PUBLIC',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'fixture-owner',
  maxTeams: 16,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  isLite: isLite,
  divisions: [
    TournamentDivision(
      id: _divisionId,
      name: 'Đôi Nam Nữ',
      matchType: 'DOUBLES',
      bracketType: 'single_elimination',
      maxParticipants: 16,
      participantCount: 6,
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  required bool tournamentIsLite,
  bool screenIsLite = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentProvider.overrideWith(
          (ref, id) => Stream.value(_tournament(isLite: tournamentIsLite)),
        ),
        bracketMatchesWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(const []),
        ),
        standingsWithDivisionProvider.overrideWith(
          (ref, params) => Stream.value(const []),
        ),
        authProvider.overrideWith(_GuestAuthNotifier.new),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: BracketViewScreen(
                  tournamentId: _tournamentId,
                  divisionId: _divisionId,
                  isEmbedded: true,
                  isLite: screenIsLite,
                  canEditBracket: true,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'giải quick (isLite) mở trong hub: chủ giải thấy thanh Tạo bracket',
    (tester) async {
      await _pump(tester, tournamentIsLite: true);

      expect(find.byType(BracketManagementBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'màn quản lý Lite riêng (isLite của màn hình) giữ luồng ghép cặp, không có thanh',
    (tester) async {
      await _pump(tester, tournamentIsLite: true, screenIsLite: true);

      expect(find.byType(BracketManagementBar), findsNothing);
    },
  );

  testWidgets('giải thường: chủ giải vẫn thấy thanh', (tester) async {
    await _pump(tester, tournamentIsLite: false);

    expect(find.byType(BracketManagementBar), findsOneWidget);
  });
}
