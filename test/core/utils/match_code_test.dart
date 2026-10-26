import 'dart:ui';

import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/core/utils/match_code.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match({
  String? matchCode,
  String team1Name = 'TBD',
  String team2Name = 'TBD',
  List<ParticipantPlayer> team1Players = const [],
  List<ParticipantPlayer> team2Players = const [],
  String? sportKey,
  String? clubMatchSessionId,
  bool isStandaloneMatch = false,
  int matchNumber = 7,
}) => MatchModel(
  id: 'm1',
  round: 1,
  matchNumber: matchNumber,
  matchCode: matchCode,
  team1Name: team1Name,
  team2Name: team2Name,
  team1Players: team1Players,
  team2Players: team2Players,
  sportKey: sportKey,
  clubMatchSessionId: clubMatchSessionId,
  isStandaloneMatch: isStandaloneMatch,
  bracketPosition: BracketPosition(round: 1, position: matchNumber),
  updatedAt: DateTime.utc(2026, 1, 1),
);

ParticipantPlayer _player(String name, [int slot = 1]) =>
    ParticipantPlayer(slot: slot, fullName: name);

const _absent = Object();

void main() {
  final vi = lookupAppLocalizations(const Locale('vi'));

  group('abbreviateNameForCode (same vectors as Web)', () {
    const vectors = <String?, String>{
      'Nguyễn Văn An': 'VA',
      'Trần Thị Bình': 'TB',
      'Đặng Thị Mỹ Hạnh': 'MH',
      'Hùng': 'H',
      'Lê Văn': 'LV',
      '  trần   thị  bình ': 'TB',
      'Đỗ': 'D',
      '': '',
      null: '',
      "O'Brien John": 'OJ',
      '   ': '',
    };
    vectors.forEach((input, expected) {
      test('${input == null ? 'null' : '"$input"'} -> "$expected"', () {
        expect(abbreviateNameForCode(input), expected);
      });
    });

    test('decomposed (NFD) Vietnamese input folds like precomposed', () {
      // "Đặng Thị" with combining marks: a + breve + dot below, i + dot below.
      expect(abbreviateNameForCode('Đặng Thị'), 'DT');
    });
  });

  group('buildMatchCode', () {
    test('both sides', () {
      expect(
        buildMatchCode('DN1W2T3', 'Nguyễn Văn An', 'Trần Thị Bình'),
        'DN1W2T3VATB',
      );
    });
    test('no side known', () {
      expect(buildMatchCode('DN1W2T3', null, null), 'DN1W2T3');
    });
    test('only side 1', () {
      expect(buildMatchCode('DN1W2T3', 'Nguyễn Văn An', null), 'DN1W2T3VA');
    });
    test('only side 2 (missing side is skipped)', () {
      expect(buildMatchCode('DN1W2T3', null, 'Trần Thị Bình'), 'DN1W2T3TB');
    });
  });

  group('formatMatchCode', () {
    test('singles take the first player of each side', () {
      final match = _match(
        matchCode: 'DN1W2T3',
        team1Players: [_player('Nguyễn Văn An')],
        team2Players: [_player('Trần Thị Bình')],
      );
      expect(formatMatchCode(match, l10n: vi), 'DN1W2T3VATB');
    });

    test('doubles take only the first player of each pair', () {
      final match = _match(
        matchCode: 'DN1W2T3',
        team1Players: [_player('Nguyễn Văn An'), _player('Lê Văn Cường', 2)],
        team2Players: [_player('Trần Thị Bình'), _player('Đỗ', 2)],
      );
      expect(formatMatchCode(match, l10n: vi), 'DN1W2T3VATB');
    });

    test('TBD sides are skipped', () {
      expect(
        formatMatchCode(_match(matchCode: 'DN1W2T3'), l10n: vi),
        'DN1W2T3',
      );
      expect(
        formatMatchCode(
          _match(
            matchCode: 'DN1W2T3',
            team1Players: [_player('Nguyễn Văn An')],
          ),
          l10n: vi,
        ),
        'DN1W2T3VA',
      );
    });

    test('team name is used when there are no players', () {
      final match = _match(
        matchCode: 'DN1W2T3',
        team1Name: 'Phượng Hoàng',
        team2Name: 'Sơn Ca',
      );
      expect(formatMatchCode(match, l10n: vi), 'DN1W2T3PHSC');
    });

    test('football always uses the team name, not a roster member', () {
      final match = _match(
        matchCode: 'DN1W2T3',
        sportKey: 'football',
        team1Name: 'Hà Nội FC',
        team2Name: 'Sài Gòn',
        team1Players: [_player('Nguyễn Văn An')],
        team2Players: [_player('Trần Thị Bình')],
      );
      expect(formatMatchCode(match, l10n: vi), 'DN1W2T3NFSG');
    });

    test('missing or blank matchCode falls back to the old label', () {
      final named = _match(
        team1Players: [_player('Nguyễn Văn An')],
        team2Players: [_player('Trần Thị Bình')],
      );
      expect(formatMatchCode(named, l10n: vi), 'Trận 7');
      expect(formatMatchCode(_match(matchCode: '  '), l10n: vi), 'Trận 7');
      expect(matchCodeOrNull(named), isNull);
    });

    test('club matches never show a code', () {
      expect(
        formatMatchCode(
          _match(matchCode: 'DN1W2T3', clubMatchSessionId: 's1'),
          l10n: vi,
        ),
        'Trận 7',
      );
      expect(
        matchCodeOrNull(_match(matchCode: 'DN1W2T3', isStandaloneMatch: true)),
        isNull,
      );
    });
  });

  group('JSON parsing', () {
    Map<String, dynamic> json({Object? matchCode = _absent}) => {
      'roundNumber': 1,
      'matchNumber': 3,
      'status': 'SCHEDULED',
      if (!identical(matchCode, _absent)) 'matchCode': matchCode,
    };

    test('MatchModel.fromJson reads matchCode', () {
      expect(
        MatchModel.fromJson(json(matchCode: 'DN1W2T3'), 'm1').matchCode,
        'DN1W2T3',
      );
    });

    test('MatchModel.fromJson tolerates a missing or null matchCode', () {
      expect(MatchModel.fromJson(json(), 'm1').matchCode, isNull);
      expect(
        MatchModel.fromJson(json(matchCode: null), 'm1').matchCode,
        isNull,
      );
    });

    test('MatchModel copyWith keeps matchCode', () {
      final match = _match(matchCode: 'DN1W2T3');
      expect(match.copyWith(round: 2).matchCode, 'DN1W2T3');
      expect(match.copyWith(matchCode: 'X1').matchCode, 'X1');
    });

    Map<String, dynamic> assignedJson({Object? matchCode = _absent}) => {
      'id': 'a1',
      'tournamentId': 't1',
      'tournamentName': 'Giải',
      'matchOrder': 4,
      'participant1Name': 'Nguyễn Văn An / Lê Văn Cường',
      'participant2Name': 'Trần Thị Bình',
      if (!identical(matchCode, _absent)) 'matchCode': matchCode,
    };

    test('TournamentAssignedMatch shows the code or the old label', () {
      final withCode = TournamentAssignedMatch.fromJson(
        assignedJson(matchCode: 'DN1W2T3'),
      );
      expect(withCode.matchCode, 'DN1W2T3');
      expect(withCode.localizedMatchLabel(vi), 'DN1W2T3VATB');

      final legacy = TournamentAssignedMatch.fromJson(assignedJson());
      expect(legacy.matchCode, isNull);
      expect(legacy.localizedMatchLabel(vi), 'Trận 4');
    });
  });
}
