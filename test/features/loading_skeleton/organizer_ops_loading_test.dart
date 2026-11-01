import 'dart:async';

import 'package:app_quanly_giaidau/core/widgets/skeleton/skeleton_scope.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/organizer_ops_screen.dart';
import 'package:app_quanly_giaidau/providers/organizer_ops_provider.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'loading_harness.dart';

const _tournamentId = 't-1';
const _divisionId = 'd-1';

Tournament _tournament() => Tournament.fromJson({
  'name': 'Ops loading fixture',
  'sport': 'pickleball',
  'format': 'doubles',
  'status': 'in_progress',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, _tournamentId);

void main() {
  for (final view in [OrganizerOpsView.matches, OrganizerOpsView.activity]) {
    testWidgets('OrganizerOpsScreen ${view.name} shows skeleton while loading', (
      tester,
    ) async {
      await pumpLoading(
        tester,
        OrganizerOpsScreen(
          tournamentId: _tournamentId,
          initialDivisionId: _divisionId,
          view: view,
        ),
        size: const Size(720, 1200),
        overrides: [
          tournamentProvider(
            _tournamentId,
          ).overrideWith((ref) => Stream<Tournament?>.value(_tournament())),
          tournamentDivisionsProvider(_tournamentId).overrideWith(
            (ref) async => [
              {'id': _divisionId, 'name': 'Open', 'matchType': 'DOUBLES'},
            ],
          ),
          managedMatchesWithDivisionProvider((
            tournamentId: _tournamentId,
            divisionId: _divisionId,
          )).overrideWith((ref) => StreamController<List<MatchModel>>().stream),
          organizerOpsReadModelProvider((
            tournamentId: _tournamentId,
            divisionId: _divisionId,
          )).overrideWith(
            (ref) => Completer<OrganizerOpsReadModel>().future,
          ),
        ],
      );

      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(SkeletonScope), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
