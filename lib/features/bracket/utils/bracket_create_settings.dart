import 'dart:math' as math;

import 'package:app_quanly_giaidau/features/bracket/utils/bracket_quick_suggestion.dart';

/// Values of the "create bracket" popup for a Round Robin / group-stage division.
class BracketCreateSettings {
  const BracketCreateSettings({
    required this.numGroups,
    required this.teamsPerGroup,
    required this.teamsAdvancing,
    required this.roundsToPlay,
    required this.playoffType,
    required this.seedingType,
  });

  final int numGroups;
  final int teamsPerGroup;
  final int teamsAdvancing;
  final int roundsToPlay;

  /// `SINGLE_ELIMINATION` or `DOUBLE_ELIMINATION`.
  final String playoffType;

  /// `SEEDED` (by ELO) or `RANDOM`.
  final String seedingType;

  BracketCreateSettings copyWith({
    int? numGroups,
    int? teamsPerGroup,
    int? teamsAdvancing,
    int? roundsToPlay,
    String? playoffType,
    String? seedingType,
  }) => BracketCreateSettings(
    numGroups: numGroups ?? this.numGroups,
    teamsPerGroup: teamsPerGroup ?? this.teamsPerGroup,
    teamsAdvancing: teamsAdvancing ?? this.teamsAdvancing,
    roundsToPlay: roundsToPlay ?? this.roundsToPlay,
    playoffType: playoffType ?? this.playoffType,
    seedingType: seedingType ?? this.seedingType,
  );
}

bool _isRoundRobin(String bracketType) =>
    bracketType.toUpperCase() == 'ROUND_ROBIN';

Map<String, dynamic>? _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

int? _asInt(Object? value) => value is num ? value.toInt() : null;

/// Saved division config first, then the suggestion for the registered teams,
/// then the same defaults as the division editor.
BracketCreateSettings initialBracketCreateSettings({
  required String bracketType,
  required int participantCount,
  required Map<String, dynamic>? roundConfig,
}) {
  final roundRobin = _isRoundRobin(bracketType);
  final groups = _asMap(roundConfig?['groupsConfig']);
  final advancement = _asMap(roundConfig?['advancementConfig']);
  final playoff = _asMap(roundConfig?['playoffConfig']);
  final suggestion = bracketQuickSuggestion(
    bracketType: bracketType,
    participantCount: participantCount,
  );
  final legs = _asInt(groups?['roundsToPlay']) ?? suggestion?.roundsToPlay ?? 1;
  final teamsPerGroup =
      _asInt(groups?['teamsPerGroup']) ?? suggestion?.teamsPerGroup ?? 4;
  return BracketCreateSettings(
    numGroups: roundRobin
        ? 1
        : _asInt(groups?['numGroups']) ?? suggestion?.groups ?? 4,
    teamsPerGroup: teamsPerGroup,
    teamsAdvancing:
        _asInt(advancement?['teamsAdvancing']) ??
        suggestion?.teamsAdvancing ??
        2,
    roundsToPlay: legs.clamp(1, roundRobin ? 4 : 20).toInt(),
    playoffType: playoff?['type'] == 'DOUBLE_ELIMINATION'
        ? 'DOUBLE_ELIMINATION'
        : 'SINGLE_ELIMINATION',
    seedingType: playoff?['seedingType'] == 'RANDOM' ? 'RANDOM' : 'SEEDED',
  );
}

/// Merges the popup values into the saved `roundConfig`, keeping every other
/// key. Saved group assignments are dropped when the group count changes.
Map<String, dynamic> buildBracketCreateRoundConfig({
  required String bracketType,
  required Map<String, dynamic>? existing,
  required BracketCreateSettings settings,
}) {
  final roundRobin = _isRoundRobin(bracketType);
  final previousGroups = _asMap(existing?['groupsConfig']);
  final numGroups = roundRobin ? 1 : settings.numGroups.clamp(2, 32).toInt();
  final groupsConfig = <String, dynamic>{
    ...?previousGroups,
    'numGroups': numGroups,
    if (!roundRobin)
      'teamsPerGroup': settings.teamsPerGroup.clamp(2, 128).toInt(),
    'roundsToPlay': settings.roundsToPlay.clamp(1, roundRobin ? 4 : 20).toInt(),
  };
  final savedList = previousGroups?['groups'];
  if (savedList is List && savedList.length != numGroups) {
    groupsConfig.remove('groups');
  }
  final merged = <String, dynamic>{...?existing, 'groupsConfig': groupsConfig};
  if (roundRobin) return merged;
  merged['advancementConfig'] = {
    ...?_asMap(existing?['advancementConfig']),
    'teamsAdvancing': settings.teamsAdvancing
        .clamp(1, math.max(1, settings.teamsPerGroup - 1))
        .toInt(),
  };
  merged['playoffConfig'] = {
    ...?_asMap(existing?['playoffConfig']),
    'type': settings.playoffType,
    'seedingType': settings.seedingType,
  };
  return merged;
}
