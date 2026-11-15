import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/providers/organizer_ops_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'loading_skeleton/loading_harness.dart';

const _tournamentId = 't-1';
const _divisionId = 'd-1';

Tournament _tournament() => Tournament.fromJson({
  'name': 'Ops roster fixture',
  'sport': 'pickleball',
  'format': 'singles',
  'status': 'registration',
  'maxTeams': 8,
  'maxPlayersPerTeam': 1,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _tournamentId);

OrganizerOpsParticipant _participant(String id, String name) =>
    OrganizerOpsParticipant(
      id: id,
      teamName: name,
      teamStatus: 'APPROVED',
      isPaid: false,
      members: [OrganizerOpsMember(userId: 'u-$id', fullName: name)],
    );

void main() {
  testWidgets('refresh shows a participant added on the server', (
    tester,
  ) async {
    final server = <OrganizerOpsParticipant>[_participant('p1', 'An Nguyen')];
    await pumpLoading(
      tester,
      const OrganizerOpsScreen(
        tournamentId: _tournamentId,
        initialDivisionId: _divisionId,
        view: OrganizerOpsView.roster,
      ),
      size: const Size(720, 1400),
      overrides: [
        tournamentProvider(
          _tournamentId,
        ).overrideWith((ref) => Stream<Tournament?>.value(_tournament())),
        tournamentDivisionsProvider(_tournamentId).overrideWith(
          (ref) async => [
            {'id': _divisionId, 'name': 'Open', 'matchType': 'SINGLES'},
          ],
        ),
        organizerOpsReadModelProvider((
          tournamentId: _tournamentId,
          divisionId: _divisionId,
        )).overrideWith(
          (ref) async => OrganizerOpsReadModel(
            participants: List.of(server),
            referees: const [],
            auditEntries: const [],
          ),
        ),
      ],
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('An Nguyen'), findsWidgets);
    expect(find.textContaining('Binh Tran'), findsNothing);

    server.add(_participant('p2', 'Binh Tran'));
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Binh Tran'), findsWidgets);
  });
}
