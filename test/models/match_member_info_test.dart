import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';

void main() {
  group('MatchModel member info', () {
    test(
      'parses roster member userId, ELO and tier from participant rosters',
      () {
        final match = MatchModel.fromJson({
          'round': 1,
          'matchNumber': 1,
          'updatedAt': '2026-07-19T10:00:00Z',
          'participant1': {
            'rosters': [
              {
                'userId': 'user-1',
                'fullName': 'Nguyễn Văn A',
                'eloPoints': 1450,
                'tierName': 'Vàng',
              },
            ],
          },
          'participant2': {
            'rosters': [
              {
                'user': {'id': 'user-2', 'fullName': 'Trần Thị B'},
                'ranking': {'eloPoints': 1320, 'tierName': 'Bạc'},
              },
            ],
          },
        }, 'match-1');

        expect(match.team1Members, ['Nguyễn Văn A']);
        expect(match.team2Members, ['Trần Thị B']);

        expect(match.team1MemberInfos, hasLength(1));
        expect(match.team1MemberInfos.first.userId, 'user-1');
        expect(match.team1MemberInfos.first.fullName, 'Nguyễn Văn A');
        expect(match.team1MemberInfos.first.eloPoints, 1450);
        expect(match.team1MemberInfos.first.tierName, 'Vàng');

        expect(match.team2MemberInfos, hasLength(1));
        expect(match.team2MemberInfos.first.userId, 'user-2');
        expect(match.team2MemberInfos.first.fullName, 'Trần Thị B');
        expect(match.team2MemberInfos.first.eloPoints, 1320);
        expect(match.team2MemberInfos.first.tierName, 'Bạc');
      },
    );

    test(
      'does not invent ELO when backend does not provide ranking fields',
      () {
        final match = MatchModel.fromJson({
          'round': 1,
          'matchNumber': 1,
          'updatedAt': '2026-07-19T10:00:00Z',
          'participant1': {
            'rosters': [
              {'userId': 'user-1', 'fullName': 'Người chơi chưa xếp hạng'},
            ],
          },
        }, 'match-1');

        expect(match.team1MemberInfos.single.eloPoints, isNull);
        expect(match.team1MemberInfos.single.tierName, isNull);
      },
    );
  });
}
