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
}
