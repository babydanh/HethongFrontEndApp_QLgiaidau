import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/rank_avatar.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/permission_rows.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _avatar = 'https://cdn.example.test/staff.png';
const _creatorAvatar = 'https://cdn.example.test/creator.png';

class _Repo implements TournamentManagementRepository {
  _Repo(this.staff);

  final List<Map<String, dynamic>> staff;

  @override
  Future<List<Map<String, dynamic>>> getStaff(String id) async => staff;

  @override
  Future<List<Map<String, dynamic>>> getReferees(String id) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament({Map<String, dynamic>? creator}) => Tournament.fromJson({
  'name': 'Permissions Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'registration',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'registrationMode': 'APPROVAL',
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
  'creator': ?creator,
}, 'tournament-1');

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  required List<Map<String, dynamic>> staff,
  Map<String, dynamic>? creator,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentManagementRepositoryProvider.overrideWithValue(_Repo(staff)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: TournamentManagementPeopleSection(
            tournament: _tournament(creator: creator),
            showRegistration: false,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
}

Map<String, dynamic> _staff(String userId, String name, {String? avatarUrl}) =>
    {
      'userId': userId,
      'role': 'CO_ORGANIZER',
      'fullName': name,
      'email': '$userId@example.test',
      'avatarUrl': avatarUrl,
    };

void main() {
  test('TC-PERM-CREATOR-01 permission row keeps the staff avatarUrl', () {
    final rows = buildPermissionRows([_staff('u1', 'An', avatarUrl: _avatar)], [
      {'id': 'r1', 'userId': 'u2', 'status': 'INVITED', 'avatarUrl': _avatar},
    ]);

    expect(rows[0].avatarUrl, _avatar);
    expect(rows[1].avatarUrl, _avatar);
  });

  testWidgets('TC-PERM-CREATOR-02 staff row draws the photo, not a letter', (
    tester,
  ) async {
    await _pump(tester, staff: [_staff('u1', 'An', avatarUrl: _avatar)]);

    final avatar = tester.widget<RankAvatar>(find.byType(RankAvatar));
    expect(avatar.imageUrl, _avatar);
  });

  testWidgets('TC-PERM-CREATOR-03 the creator is listed with their photo', (
    tester,
  ) async {
    final l10n = await _pump(
      tester,
      staff: [_staff('u1', 'An')],
      creator: {
        'id': 'u-creator',
        'fullName': 'Chu Giai',
        'avatarUrl': _creatorAvatar,
      },
    );

    expect(find.text('Chu Giai'), findsOneWidget);
    expect(find.text(l10n.tournamentManagementRoleCreator), findsOneWidget);
    final urls = tester
        .widgetList<RankAvatar>(find.byType(RankAvatar))
        .map((a) => a.imageUrl);
    expect(urls, contains(_creatorAvatar));
  });

  testWidgets('TC-PERM-CREATOR-04 a creator who is also staff shows once', (
    tester,
  ) async {
    await _pump(
      tester,
      staff: [_staff('u-creator', 'Chu Giai')],
      creator: {'id': 'u-creator', 'fullName': 'Chu Giai'},
    );

    expect(find.text('Chu Giai'), findsOneWidget);
  });
}
