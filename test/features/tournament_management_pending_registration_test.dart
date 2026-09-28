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
  'status': 'registration',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'registrationMode': 'APPROVAL',
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

void main() {
  testWidgets('organizer sees pending applicant and review actions', (
    tester,
  ) async {
    final participants = _ParticipantsRepository([
      const OrganizerOpsParticipant(
        id: 'participant-1',
        teamName: 'Waiting Pair',
        teamStatus: 'PENDING_APPROVAL',
        isPaid: false,
        members: [],
        registeredByUserId: 'user-1',
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tournamentRepositoryProvider.overrideWithValue(participants),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(
            body: TournamentManagementPeopleSection(
              tournament: _tournament(),
              showRegistration: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    expect(find.text('Waiting Pair'), findsOneWidget);
    expect(
      find.text(l10n.tournamentManagementParticipantPending),
      findsOneWidget,
    );
    expect(find.text(l10n.tournamentManagementApprove), findsOneWidget);
    expect(find.text(l10n.tournamentManagementReject), findsOneWidget);
  });
}
