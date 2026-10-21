import 'dart:ui';

import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/bracket_stage_utils.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _swissMatch(int round, {String stageType = 'SWISS'}) => MatchModel(
  id: 'm-$round',
  round: round,
  matchNumber: 1,
  bracketPosition: BracketPosition(round: round, position: 1),
  stageType: stageType,
  stageName: 'Thụy Sĩ',
  groupName: 'Thụy Sĩ',
  updatedAt: DateTime.utc(2026, 1, 1),
);

void main() {
  final vi = lookupAppLocalizations(const Locale('vi'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('bracketSwiss constant is lower-case like the other bracket types', () {
    expect(AppConstants.bracketSwiss, 'swiss');
    expect(AppConstants.supportsSeeding('swiss'), isFalse);
  });

  test('bracketDisplayName and bracketDescription know swiss', () {
    expect(vi.bracketDisplayName('swiss'), 'Thụy Sĩ');
    expect(en.bracketDisplayName('SWISS'), 'Swiss');
    expect(vi.bracketDescription('swiss'), isNotEmpty);
    // Unknown values keep the old behaviour.
    expect(vi.bracketDisplayName('mystery_type'), 'mystery type');
    expect(vi.bracketDescription('mystery_type'), isEmpty);
  });

  group('isSwissMatch and stage helpers', () {
    test('SWISS stage is detected case-insensitively', () {
      expect(isSwissMatch(_swissMatch(1)), isTrue);
      expect(isSwissMatch(_swissMatch(1, stageType: 'swiss')), isTrue);
      expect(isSwissMatch(_swissMatch(1, stageType: 'ROUND_ROBIN')), isFalse);
    });

    test('SWISS is neither knockout nor group even with group-like names', () {
      final m = _swissMatch(2);
      expect(isKnockoutMatch(m), isFalse);
      expect(isGroupStageMatch(m), isFalse);
      expect(isDoubleEliminationMatch(m), isFalse);
    });
  });

  group('formatRound for swiss', () {
    test('labels the round as "Vòng N" / "Round N"', () {
      final matches = [_swissMatch(1), _swissMatch(2), _swissMatch(3)];
      expect(
        MatchRoundLabel.formatRound(
          match: matches[2],
          allMatches: matches,
          l10n: vi,
        ),
        'Vòng 3',
      );
      expect(
        MatchRoundLabel.formatRound(
          match: matches[0],
          allMatches: matches,
          l10n: en,
        ),
        'Round 1',
      );
    });

    test('never produces knockout names, even for the last round', () {
      final matches = [_swissMatch(1), _swissMatch(2)];
      final label = MatchRoundLabel.formatRound(
        match: matches.last,
        allMatches: matches,
        l10n: vi,
      );
      expect(label, 'Vòng 2');
      expect(label, isNot(vi.matchTableRoundFinal));
    });
  });
}
