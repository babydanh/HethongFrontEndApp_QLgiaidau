import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_intro_screen.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_state_views.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentId = 'club-tournament';
const _clubId = 'club-1';
const _tournamentName = 'Giải CLB thử nghiệm';

class _GuestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Tournament _clubTournament({required String visibility}) {
  final now = DateTime.now();
  return Tournament(
    id: _tournamentId,
    name: _tournamentName,
    sport: 'badminton',
    format: 'SINGLES',
    bracketType: 'single_elimination',
    status: 'REGISTRATION_OPEN',
    visibility: visibility,
    adminToken: '',
    refereeToken: '',
    viewerToken: '',
    creatorId: 'owner-1',
    creatorFullName: 'Tournament owner',
    communityId: _clubId,
    maxTeams: 8,
    createdAt: now,
    updatedAt: now,
    // Từ 2 nội dung trở lên, tab tổng quan không dựng lưới xác nhận của CLB
    // (lưới này có lỗi tràn layout sẵn có, nằm ngoài change này).
    divisions: const [
      TournamentDivision(
        id: 'division-1',
        name: 'Adults',
        matchType: 'SINGLES',
        maxParticipants: 8,
      ),
      TournamentDivision(
        id: 'division-2',
        name: 'Youth',
        matchType: 'SINGLES',
        maxParticipants: 8,
      ),
    ],
  );
}

ProviderScope _scope({
  required Tournament tournament,
  required CommunityMemberModel? membership,
}) => ProviderScope(
  overrides: [
    authProvider.overrideWith(_GuestAuthNotifier.new),
    userProfileProvider.overrideWith(
      (ref) async => UserProfile(
        id: 'viewer-1',
        fullName: 'Viewer',
        email: 'viewer@example.test',
      ),
    ),
    tournamentIntroWithInviteProvider((
      id: _tournamentId,
      invite: null,
    )).overrideWith((ref) async => tournament),
    myCommunityMembershipProvider(
      _clubId,
    ).overrideWith((ref) async => membership),
    tournamentDivisionsProvider(
      _tournamentId,
    ).overrideWith((ref) async => const <Map<String, dynamic>>[]),
    introTeamsProvider(_tournamentId).overrideWith((ref) async => const []),
    teamsProvider(_tournamentId).overrideWith((ref) => Stream.value(const [])),
    matchesProvider(
      _tournamentId,
    ).overrideWith((ref) => Stream.value(const [])),
    followedTournamentsProvider.overrideWith((ref) async => const []),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    home: const TournamentIntroScreen(tournamentId: _tournamentId),
  ),
);

const _joinedMember = CommunityMemberModel(
  id: 'member-1',
  userId: 'viewer-1',
  communityId: _clubId,
  status: 'JOINED',
);

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpIntro(
  WidgetTester tester, {
  required String visibility,
  required CommunityMemberModel? membership,
}) async {
  _setPhoneViewport(tester);
  await tester.pumpWidget(
    _scope(
      tournament: _clubTournament(visibility: visibility),
      membership: membership,
    ),
  );
  await tester.pump();
  // Màn giải tải nhiều provider nối tiếp: pump từng bước để future và timer kịp chạy.
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('giải CLB PUBLIC: khách xem được nội dung giải', (tester) async {
    await _pumpIntro(tester, visibility: 'PUBLIC', membership: null);

    expect(find.byType(PrivateTournamentAccessView), findsNothing);
    expect(find.byType(TabBarView), findsOneWidget);
  });

  testWidgets('giải CLB PRIVATE: khách thấy màn chặn', (tester) async {
    await _pumpIntro(tester, visibility: 'PRIVATE', membership: null);

    expect(find.byType(PrivateTournamentAccessView), findsOneWidget);
  });

  testWidgets('giải CLB PRIVATE: thành viên JOINED xem được nội dung', (
    tester,
  ) async {
    await _pumpIntro(tester, visibility: 'PRIVATE', membership: _joinedMember);

    expect(find.byType(PrivateTournamentAccessView), findsNothing);
    expect(find.byType(TabBarView), findsOneWidget);
  });
}
