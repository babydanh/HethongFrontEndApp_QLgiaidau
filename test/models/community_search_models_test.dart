import 'package:app_quanly_giaidau/data/models/community_search_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the central search filter contract stable', () {
    expect(CommunitySearchType.all.apiValue, 'ALL');
    expect(CommunitySearchType.posts.apiValue, 'POSTS');
    expect(CommunitySearchType.members.apiValue, 'MEMBERS');
    expect(CommunitySearchType.matches.apiValue, 'MATCHES');
    expect(CommunitySearchType.tournaments.apiValue, 'TOURNAMENTS');
  });

  test('parses API results without losing the match source', () {
    final results = CommunitySearchResults.fromJson({
      'query': 'Trang Hưng',
      'posts': [],
      'members': [],
      'matches': [
        {
          'id': 'match-1',
          'source': 'SESSION',
          'sessionId': 'session-1',
          'title': 'Buổi giao lưu CLB',
          'status': 'COMPLETED',
        },
      ],
      'tournaments': [],
    });

    expect(results.query, 'Trang Hưng');
    expect(results.matches, hasLength(1));
    expect(results.matches.single.source, 'SESSION');
    expect(results.matches.single.sessionId, 'session-1');
    expect(results.matches.single.tournamentId, isNull);
  });
}
