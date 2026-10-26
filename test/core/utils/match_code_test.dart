import 'dart:ui';

import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/core/utils/match_code.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match({
  String? matchCode,
  List<ParticipantPlayer> team1Players = const [],
  List<ParticipantPlayer> team2Players = const [],
  String? clubMatchSessionId,
  bool isStandaloneMatch = false,
  int matchNumber = 7,
}) => MatchModel(
  id: 'm1',
  round: 1,
  matchNumber: matchNumber,
  matchCode: matchCode,
  team1Name: 'TBD',
  team2Name: 'TBD',
  team1Players: team1Players,
  team2Players: team2Players,
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

  group('buildMatchCode', () {
    test('returns the trimmed backend code', () {
      expect(buildMatchCode(' DNTB-K1-T3 '), 'DNTB-K1-T3');
    });

    test('returns null when backend code is missing or blank', () {
      expect(buildMatchCode(null), isNull);
      expect(buildMatchCode('  '), isNull);
    });
  });

  group('formatMatchCode', () {
    test('TC-FEAT-01: uses the backend code without athlete initials', () {
      final match = _match(
        matchCode: 'DNTB-K1-T3',
        team1Players: [_player('Nguyễn Văn An')],
        team2Players: [_player('Trần Thị Bình')],
      );
      expect(matchCodeOrNull(match), 'DNTB-K1-T3');
      expect(formatMatchCode(match, l10n: vi), '#DNTB-K1-T3');
    });

    test('TC-FEAT-02: prefixes a doubles code before opponents are known', () {
      expect(
        formatMatchCode(_match(matchCode: 'DDNTB-K1-T3'), l10n: vi),
        '#DDNTB-K1-T3',
      );
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
          _match(matchCode: 'DNTB-K1-T3', clubMatchSessionId: 's1'),
          l10n: vi,
        ),
        'Trận 7',
      );
      expect(
        matchCodeOrNull(
          _match(matchCode: 'DNTB-K1-T3', isStandaloneMatch: true),
        ),
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
        MatchModel.fromJson(json(matchCode: 'DNTB-K1-T3'), 'm1').matchCode,
        'DNTB-K1-T3',
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
      final match = _match(matchCode: 'DNTB-K1-T3');
      expect(match.copyWith(round: 2).matchCode, 'DNTB-K1-T3');
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
        assignedJson(matchCode: 'DDNTB-K1-T3'),
      );
      expect(withCode.matchCode, 'DDNTB-K1-T3');
      expect(withCode.localizedMatchLabel(vi), '#DDNTB-K1-T3');

      final legacy = TournamentAssignedMatch.fromJson(assignedJson());
      expect(legacy.matchCode, isNull);
      expect(legacy.localizedMatchLabel(vi), 'Trận 4');
    });
  });
}
