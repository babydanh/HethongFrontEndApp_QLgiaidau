import 'package:app_quanly_giaidau/data/models/home_projection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('completed projection excludes every other tournament status', () {
    const projection = HomeProjection(
      featuredTournaments: [
        HomeFeaturedTournament(id: 'done', name: 'Done', status: 'COMPLETED'),
        HomeFeaturedTournament(
          id: 'open',
          name: 'Open',
          status: 'REGISTRATION_OPEN',
        ),
      ],
      tournaments: [
        HomeTournamentFinals(
          id: 'done',
          name: 'Done',
          status: 'COMPLETED',
          matches: [],
        ),
        HomeTournamentFinals(
          id: 'closed',
          name: 'Closed',
          status: 'REGISTRATION_CLOSED',
          matches: [],
        ),
        HomeTournamentFinals(id: 'unknown', name: 'Unknown', matches: []),
      ],
    );

    expect(projection.completedOnly.featuredTournaments.map((t) => t.id), [
      'done',
    ]);
    expect(projection.completedOnly.tournaments.map((t) => t.id), ['done']);
  });
}
