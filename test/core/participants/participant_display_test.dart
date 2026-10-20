import 'package:flutter_test/flutter_test.dart';

import 'package:app_quanly_giaidau/core/participants/participant_display.dart';

void main() {
  group('abbreviateName (bảng ca hợp đồng §2)', () {
    const cases = <String, String>{
      'Nguyễn Văn An': 'N. V. An',
      'Nguyễn Thị Minh Khai': 'N. T. M. Khai',
      'Đỗ Mỹ': 'Đ. Mỹ',
      'An': 'An',
      '  trần   văn  bình ': 'T. V. bình',
      '': '',
      'Ánh Dương': 'Á. Dương',
    };
    cases.forEach((input, expected) {
      test('"$input" → "$expected"', () {
        expect(abbreviateName(input), expected);
      });
    });
  });

  group('resolveParticipantDisplay', () {
    const an = ParticipantPlayer(slot: 1, fullName: 'Nguyễn Văn An');
    const binh = ParticipantPlayer(slot: 2, fullName: 'Trần Văn Bình');

    test('đội có tên riêng khác tên VĐV → TEAM', () {
      final display = resolveParticipantDisplay(
        teamName: 'Đội Ánh Dương',
        players: const [an],
      );
      expect(display.mode, ParticipantDisplayMode.team);
      expect(display.teamName, 'Đội Ánh Dương');
    });

    test(
      'tên đội trùng tên VĐV (khác hoa thường, khác khoảng trắng) → PLAYERS',
      () {
        final display = resolveParticipantDisplay(
          teamName: '  nguyễn   văn an ',
          players: const [an, binh],
        );
        expect(display.mode, ParticipantDisplayMode.players);
        expect(display.teamName, isNull);
        expect(display.players.map((p) => p.fullName), [
          'Nguyễn Văn An',
          'Trần Văn Bình',
        ]);
      },
    );

    test('teamName null hoặc chỉ khoảng trắng → PLAYERS', () {
      expect(
        resolveParticipantDisplay(
          teamName: null,
          players: const [an, binh],
        ).mode,
        ParticipantDisplayMode.players,
      );
      expect(
        resolveParticipantDisplay(
          teamName: '   ',
          players: const [an, binh],
        ).mode,
        ParticipantDisplayMode.players,
      );
    });

    test('đơn có tên riêng → TEAM (không phải tên VĐV)', () {
      final display = resolveParticipantDisplay(
        teamName: 'CLB Cầu Lông Sao Mai',
        players: const [an],
      );
      expect(display.isTeam, isTrue);
      expect(display.teamName, 'CLB Cầu Lông Sao Mai');
    });

    test('bóng đá luôn TEAM khi có tên, kể cả trùng tên VĐV', () {
      final display = resolveParticipantDisplay(
        teamName: 'Nguyễn Văn An',
        players: const [an],
        teamOnly: true,
      );
      expect(display.isTeam, isTrue);
      expect(display.teamName, 'Nguyễn Văn An');
    });

    test('tên đội có ký tự phân cách KHÔNG bị tách để đoán VĐV', () {
      final display = resolveParticipantDisplay(
        teamName: 'Nguyễn Văn An / Trần Văn Bình',
        players: const [],
      );
      expect(display.isTeam, isTrue);
      expect(display.teamName, 'Nguyễn Văn An / Trần Văn Bình');
    });

    test('VĐV rỗng tên bị lọc khỏi PLAYERS', () {
      final display = resolveParticipantDisplay(
        teamName: null,
        players: const [
          ParticipantPlayer(slot: 1, fullName: '   '),
          binh,
        ],
      );
      expect(display.players, hasLength(1));
      expect(display.players.single.fullName, 'Trần Văn Bình');
    });
  });

  group('toParticipantPlayers', () {
    test('ưu tiên players[] khi có', () {
      final players = toParticipantPlayers({
        'teamName': null,
        'players': [
          {
            'slot': 1,
            'userId': 'u1',
            'fullName': 'Nguyễn Văn An',
            'avatarUrl': 'https://img/an.png',
            'isGuest': false,
          },
          {
            'slot': 2,
            'userId': null,
            'fullName': 'Trần Văn Bình',
            'avatarUrl': null,
            'isGuest': true,
          },
        ],
        'members': [
          {'userId': 'x', 'fullName': 'Người Khác'},
        ],
      });
      expect(players.map((p) => p.fullName), [
        'Nguyễn Văn An',
        'Trần Văn Bình',
      ]);
      expect(players.first.userId, 'u1');
      expect(players.first.avatarUrl, 'https://img/an.png');
      expect(players.last.isGuest, isTrue);
    });

    test(
      'thiếu players[] thì dựng từ members và guestNames (khách avatar null)',
      () {
        final players = toParticipantPlayers({
          'members': [
            {
              'userId': 'u1',
              'user': {'fullName': 'Nguyễn Văn An', 'avatarUrl': 'https://a'},
            },
          ],
          'guestNames': ['Khách Mời'],
        });
        expect(players, hasLength(2));
        expect(players[0].fullName, 'Nguyễn Văn An');
        expect(players[0].userId, 'u1');
        expect(players[0].avatarUrl, 'https://a');
        expect(players[0].isGuest, isFalse);
        expect(players[1].fullName, 'Khách Mời');
        expect(players[1].isGuest, isTrue);
        expect(players[1].avatarUrl, isNull);
        expect(players[1].userId, isNull);
      },
    );

    test('players[] rỗng thì vẫn dựng từ members', () {
      final players = toParticipantPlayers({
        'players': <Object>[],
        'rosters': [
          {'fullName': 'Trần Văn Bình', 'userId': 'u2'},
        ],
      });
      expect(players.single.fullName, 'Trần Văn Bình');
    });

    test('không có dữ liệu VĐV → rỗng, không suy từ teamName', () {
      final players = toParticipantPlayers({
        'teamName': 'Nguyễn Văn An / Trần Văn Bình',
      });
      expect(players, isEmpty);
    });
  });

  group('participantLabel', () {
    const players = [
      ParticipantPlayer(slot: 1, fullName: 'Nguyễn Văn An'),
      ParticipantPlayer(slot: 2, fullName: 'Trần Văn Bình'),
    ];

    test('TEAM trả tên đội nguyên văn, không viết tắt', () {
      expect(
        participantLabel(
          teamName: 'Đội Ánh Dương',
          players: players,
          abbreviated: true,
        ),
        'Đội Ánh Dương',
      );
    });

    test('PLAYERS nối tên đầy đủ bằng " / "', () {
      expect(
        participantLabel(teamName: null, players: players),
        'Nguyễn Văn An / Trần Văn Bình',
      );
    });

    test('PLAYERS viết tắt khi abbreviated', () {
      expect(
        participantLabel(teamName: '', players: players, abbreviated: true),
        'N. V. An / T. V. Bình',
      );
    });

    test('không có tên và không có VĐV → chuỗi rỗng', () {
      expect(participantLabel(teamName: null, players: const []), '');
    });
  });

  group('participantPlayersFromNames', () {
    test('bỏ tên rỗng và đánh số slot liên tục', () {
      final players = participantPlayersFromNames(['An', '   ', 'Bình']);
      expect(players.map((p) => p.slot), [1, 2]);
      expect(players.map((p) => p.fullName), ['An', 'Bình']);
      expect(players.every((p) => p.isGuest), isTrue);
    });
  });
}
