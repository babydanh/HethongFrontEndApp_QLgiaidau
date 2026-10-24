import 'dart:ui';

import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match(int round, int number) => MatchModel(
  id: 'm-$round-$number',
  round: round,
  matchNumber: number,
  team1Name: 'A$number',
  team2Name: 'B$number',
  status: 'scheduled',
  bracketPosition: BracketPosition(round: round, position: number),
  updatedAt: DateTime.utc(2026, 1, 1),
);

void main() {
  final vi = lookupAppLocalizations(const Locale('vi'));
  final en = lookupAppLocalizations(const Locale('en'));

  // Quy ước như web: vòng có N trận = "Vòng 1/N" (16 VĐV → 8 trận → Vòng 1/8).
  group('knockout round names follow the 1/N-matches convention', () {
    test('knockoutRoundName counts matches from the final', () {
      expect(MatchRoundLabel.knockoutRoundName(1, 4, l10n: vi), 'Vòng 1/8');
      expect(MatchRoundLabel.knockoutRoundName(1, 5, l10n: vi), 'Vòng 1/16');
      expect(MatchRoundLabel.knockoutRoundName(2, 4, l10n: vi), 'Tứ kết');
      // Tiếng Anh dùng số VĐV theo quy ước quốc tế.
      expect(MatchRoundLabel.knockoutRoundName(1, 4, l10n: en), 'Round of 16');
    });

    test('same-round match count: 8 matches is Vòng 1/8', () {
      final round1 = [for (var n = 1; n <= 8; n++) _match(1, n)];
      expect(
        MatchRoundLabel.formatRound(
          match: round1.first,
          allMatches: round1,
          l10n: vi,
        ),
        'Vòng 1/8',
      );
    });

    test('irregular round falls back to distance from the final', () {
      // Vòng 1 thiếu trận (BYE) nên không đủ 8 trận; nhánh có 4 vòng.
      final matches = [
        for (var n = 1; n <= 6; n++) _match(1, n),
        for (var n = 1; n <= 4; n++) _match(2, n),
        for (var n = 1; n <= 2; n++) _match(3, n),
        _match(4, 1),
      ];
      expect(
        MatchRoundLabel.formatRound(
          match: matches.first,
          allMatches: matches,
          l10n: vi,
        ),
        'Vòng 1/8',
      );
    });

    test('bracket size fallback: 16 slots in round 1 is Vòng 1/8', () {
      expect(
        MatchRoundLabel.formatRound(
          match: _match(1, 1),
          bracketSize: 16,
          l10n: vi,
        ),
        'Vòng 1/8',
      );
      expect(
        MatchRoundLabel.formatRound(
          match: _match(1, 1),
          bracketSize: 32,
          l10n: vi,
        ),
        'Vòng 1/16',
      );
      expect(
        MatchRoundLabel.formatRound(
          match: _match(2, 1),
          bracketSize: 16,
          l10n: vi,
        ),
        'Tứ kết',
      );
    });
  });

  test('swiss stage is labelled "Vòng N", not a knockout round', () {
    final match = MatchModel(
      id: 'swiss-1',
      round: 3,
      matchNumber: 1,
      stageType: 'SWISS',
      bracketPosition: const BracketPosition(round: 3, position: 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    expect(
      MatchRoundLabel.formatRound(match: match, bracketSize: 4, l10n: vi),
      'Vòng 3',
    );
    expect(MatchRoundLabel.isGroupOrRoundRobin(match, 'round_robin'), isFalse);
  });
  // Như Web: bảng chỉ có ký hiệu thì ghi "Bảng X • Lượt n"; thẻ hẹp "Bảng X".
  group('group stage label matches the web', () {
    MatchModel groupMatch(String groupName, {int? leg}) => _match(3, 12)
        .copyWith(
          groupName: groupName,
          stageName: 'Vòng bảng',
          stageType: 'ROUND_ROBIN',
          leg: leg,
        );

    test('a bare letter becomes Bảng B with its leg', () {
      expect(
        MatchRoundLabel.formatRound(match: groupMatch('B'), l10n: vi),
        'Bảng B • Lượt 1',
      );
      expect(
        MatchRoundLabel.formatRound(
          match: groupMatch('B'),
          l10n: vi,
          short: true,
        ),
        'Bảng B',
      );
      expect(
        MatchRoundLabel.formatRound(match: groupMatch('B'), l10n: en),
        'Group B • Leg 1',
      );
    });

    test('a name that already says Bảng is not doubled', () {
      expect(
        MatchRoundLabel.formatRound(match: groupMatch('Bảng a'), l10n: vi),
        'Bảng A • Lượt 1',
      );
    });

    test('the return leg keeps its number', () {
      expect(
        MatchRoundLabel.formatRound(match: groupMatch('B', leg: 2), l10n: vi),
        'Bảng B • Lượt 2',
      );
    });
  });
}
