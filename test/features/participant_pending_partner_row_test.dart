import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_people_section.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ParticipantsRepository implements ITournamentRepository {
  _ParticipantsRepository(this.participants);

  final List<OrganizerOpsParticipant> participants;

  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async => participants;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Tournament _tournament() => Tournament.fromJson({
  'name': 'Community Doubles Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'REGISTRATION_OPEN',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

Future<void> _pump(WidgetTester tester, {required bool isPaid}) async {
  final repo = _ParticipantsRepository([
    OrganizerOpsParticipant(
      id: 'p-lone',
      teamName: 'Giang',
      teamStatus: 'PENDING_PARTNER',
      isPaid: isPaid,
      entryFee: 1000000,
      members: const [OrganizerOpsMember(userId: 'u-giang', fullName: 'Giang')],
      divisionId: 'div-1',
    ),
  ]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tournamentRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: TournamentManagementPeopleSection(
            tournament: _tournament(),
            showRegistration: true,
            divisionId: 'div-1',
            embedded: true,
            pairFormat: true,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'TC-APP-PAY-PENDING-01: dòng chờ ghép cặp không có nhãn "Chờ" trùng, vẫn hiện chưa đóng phí',
    (tester) async {
      await _pump(tester, isPaid: false);

      expect(find.text('Chờ'), findsNothing);
      expect(find.text('Chưa đóng phí'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-APP-PAY-PENDING-02: dòng chờ ghép cặp đã đóng phí thì hiện đã đóng phí',
    (tester) async {
      await _pump(tester, isPaid: true);

      expect(find.text('Chờ'), findsNothing);
      expect(find.text('Đã đóng phí'), findsOneWidget);
    },
  );
}
