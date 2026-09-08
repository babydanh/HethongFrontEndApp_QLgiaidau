import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/features/community/providers/user_club_rank_provider.dart';

void main() {
  group('userClubRankInfoFromResponse', () {
    test(
      'reads the requested user community rank from the wrapped response',
      () {
        final info = userClubRankInfoFromResponse({
          'data': {
            'publicRanks': const [],
            'communityRanks': [
              {
                'id': 'club-rank',
                'communityId': 'club-1',
                'categoryName': 'Tennis',
                'eloPoints': 1240,
                'tierName': 'Bạc',
                'matchesPlayed': 6,
                'matchesWon': 4,
              },
              {
                'id': 'other-club-rank',
                'communityId': 'club-2',
                'eloPoints': 1800,
                'matchesPlayed': 20,
                'matchesWon': 20,
              },
            ],
          },
        }, communityId: 'club-1');

        expect(info.ranking?.id, 'club-rank');
        expect(info.categoryName, 'Tennis');
        expect(info.eloPoints, 1240);
        expect(info.matchesPlayed, 6);
        expect(info.matchesWon, 4);
      },
    );

    test(
      'selects the most-played rank when a club has multiple categories',
      () {
        final info = userClubRankInfoFromResponse({
          'communityRanks': [
            {
              'id': 'doubles-rank',
              'communityId': 'club-1',
              'categoryName': 'Tennis',
              'eloPoints': 1500,
              'matchesPlayed': 2,
              'matchesWon': 2,
            },
            {
              'id': 'singles-rank',
              'communityId': 'club-1',
              'categoryName': 'Tennis',
              'eloPoints': 1300,
              'matchesPlayed': 7,
              'matchesWon': 4,
            },
          ],
        }, communityId: 'club-1');

        expect(info.ranking?.id, 'singles-rank');
        expect(info.matchesPlayed, 7);
        expect(info.matchesWon, 4);
      },
    );

    test('returns unranked defaults for another club', () {
      final info = userClubRankInfoFromResponse({
        'communityRanks': [
          {
            'id': 'club-rank',
            'communityId': 'club-1',
            'matchesPlayed': 3,
            'matchesWon': 1,
          },
        ],
      }, communityId: 'club-2');

      expect(info.ranking, isNull);
      expect(info.matchesPlayed, 0);
      expect(info.eloPoints, 1000);
    });
  });
}
