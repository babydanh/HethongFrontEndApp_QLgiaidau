/// One round-one slot of the playoff, same shape as an entry of the Backend
/// `advanceMapping.slotOrder`: 0-based group index plus 1-based rank, or a
/// best-third wildcard.
class AdvanceSlot {
  const AdvanceSlot.rank(int this.groupIndex, this.rank) : wildcard = false;
  const AdvanceSlot.wildcard() : groupIndex = null, rank = 0, wildcard = true;

  final int? groupIndex;
  final int rank;
  final bool wildcard;

  Map<String, dynamic> toJson() =>
      wildcard ? {'wildcard': true} : {'groupIndex': groupIndex, 'rank': rank};

  String get _key => wildcard ? 'W' : '$groupIndex:$rank';

  /// Null when [raw] is not a valid slot entry.
  static AdvanceSlot? tryParse(Object? raw) {
    if (raw is! Map) return null;
    if (raw['wildcard'] == true) return const AdvanceSlot.wildcard();
    final groupIndex = raw['groupIndex'];
    final rank = raw['rank'];
    if (groupIndex is! num || rank is! num) return null;
    return AdvanceSlot.rank(groupIndex.toInt(), rank.toInt());
  }

  @override
  bool operator ==(Object other) => other is AdvanceSlot && other._key == _key;

  @override
  int get hashCode => _key.hashCode;
}

int _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

/// Slot order of round one, mirroring the Backend `advanceStandings` seeding:
/// with 1 or 2 advancing per group neighbouring groups are crossed (A1-B2,
/// B1-A2, ...); otherwise teams go group by group; wildcards come last.
List<AdvanceSlot> defaultSlotOrder({
  required int numGroups,
  required int teamsAdvancing,
  required bool allowWildcard,
  required int wildcardTeams,
}) {
  final groupCount = numGroups < 0 ? 0 : numGroups;
  // The Backend reads a missing or zero value as "1 advancing".
  final advancing = teamsAdvancing >= 1 ? teamsAdvancing : 1;
  AdvanceSlot rank(int position, int group) =>
      AdvanceSlot.rank(group, position);
  List<AdvanceSlot> allRanks(int group) => [
    for (var position = 1; position <= advancing; position++)
      rank(position, group),
  ];

  final order = <AdvanceSlot>[];
  if (advancing == 1 || advancing == 2) {
    for (var group = 0; group < groupCount; group += 2) {
      final partner = group + 1;
      if (partner >= groupCount) {
        order.addAll(allRanks(group));
      } else if (advancing == 1) {
        order.addAll([rank(1, group), rank(1, partner)]);
      } else {
        order.addAll([
          rank(1, group),
          rank(2, partner),
          rank(1, partner),
          rank(2, group),
        ]);
      }
    }
  } else {
    for (var group = 0; group < groupCount; group++) {
      order.addAll(allRanks(group));
    }
  }
  if (allowWildcard && wildcardTeams > 0) {
    order.addAll(List.filled(wildcardTeams, const AdvanceSlot.wildcard()));
  }
  return order;
}

/// A saved order is usable only when it holds exactly the default slots.
bool _isPermutationOf(List<AdvanceSlot> saved, List<AdvanceSlot> defaults) {
  if (saved.length != defaults.length) return false;
  final expected = defaults.map((slot) => slot._key).toList()..sort();
  final actual = saved.map((slot) => slot._key).toList()..sort();
  for (var i = 0; i < actual.length; i++) {
    if (actual[i] != expected[i]) return false;
  }
  return true;
}

/// Who each round-one slot of the playoff waits for, built from the stages of
/// `GET /tournaments/:id/bracket`. Slots `2k` and `2k + 1` of [slotOrder]
/// belong to the k-th winners round-one match (by `matchOrder`).
class KnockoutSeedPlan {
  const KnockoutSeedPlan({
    required this.stageId,
    required this.slotOrder,
    required this.groupNames,
    required this.roundOneMatchIds,
  });

  final String stageId;
  final List<AdvanceSlot> slotOrder;
  final List<String> groupNames;
  final List<String> roundOneMatchIds;

  /// Group name the Backend falls back to (A, B, ...) when a group has none.
  String groupName(int groupIndex) =>
      groupIndex >= 0 &&
          groupIndex < groupNames.length &&
          groupNames[groupIndex].isNotEmpty
      ? groupNames[groupIndex]
      : String.fromCharCode(65 + groupIndex);

  /// Index into [slotOrder] of one round-one slot ([side] 1 or 2), or null
  /// when the match is not a winners round-one match or has no slot.
  int? slotIndex(String matchId, int side) {
    final match = roundOneMatchIds.indexOf(matchId);
    if (match < 0) return null;
    final index = match * 2 + (side == 1 ? 0 : 1);
    return index < slotOrder.length ? index : null;
  }

  /// Copy with two slots exchanged; an invalid pair returns the same order.
  KnockoutSeedPlan withSwapped(int a, int b) {
    final valid = a != b && a >= 0 && b >= 0;
    if (!valid || a >= slotOrder.length || b >= slotOrder.length) return this;
    final next = List<AdvanceSlot>.of(slotOrder);
    next[a] = slotOrder[b];
    next[b] = slotOrder[a];
    return KnockoutSeedPlan(
      stageId: stageId,
      slotOrder: List.unmodifiable(next),
      groupNames: groupNames,
      roundOneMatchIds: roundOneMatchIds,
    );
  }

  /// Null when the bracket has no group stage followed by a playoff stage that
  /// carries a group-stage advance mapping.
  static KnockoutSeedPlan? fromStages(List<Map<String, dynamic>> stages) {
    final groupStage = stages
        .where((stage) => stage['type'] == 'ROUND_ROBIN')
        .firstOrNull;
    final knockout = stages.where(_hasGroupMapping).firstOrNull;
    if (groupStage == null || knockout == null) return null;
    final mapping = Map<String, dynamic>.from(
      (knockout['roundConfig'] as Map)['advanceMapping'] as Map,
    );
    final defaults = defaultSlotOrder(
      numGroups: _asInt(mapping['numGroups']),
      teamsAdvancing: _asInt(mapping['teamsAdvancing']),
      allowWildcard: mapping['allowWildcard'] == true,
      wildcardTeams: _asInt(mapping['wildcardTeams']),
    );
    final saved = mapping['slotOrder'] is List
        ? [
            for (final raw in mapping['slotOrder'] as List)
              ?AdvanceSlot.tryParse(raw),
          ]
        : const <AdvanceSlot>[];
    return KnockoutSeedPlan(
      stageId: knockout['id']?.toString() ?? '',
      slotOrder: List.unmodifiable(
        _isPermutationOf(saved, defaults) ? saved : defaults,
      ),
      groupNames: [
        for (final group in (groupStage['groups'] as List? ?? const []))
          if (group is Map) group['name']?.toString() ?? '',
      ],
      roundOneMatchIds: _winnersRoundOne(knockout),
    );
  }

  static bool _hasGroupMapping(Map<String, dynamic> stage) {
    if (stage['type'] == 'ROUND_ROBIN') return false;
    final config = stage['roundConfig'];
    final mapping = config is Map ? config['advanceMapping'] : null;
    return mapping is Map && mapping['source'] != 'SWISS';
  }

  /// Winners-bracket round-one match ids in `matchOrder`.
  static List<String> _winnersRoundOne(Map<String, dynamic> knockout) {
    final matches =
        [
          for (final group in (knockout['groups'] as List? ?? const []))
            if (group is Map)
              for (final match in (group['matches'] as List? ?? const []))
                if (match is Map && _isWinnersRoundOne(match))
                  Map<String, dynamic>.from(match),
        ]..sort(
          (a, b) => _asInt(a['matchOrder']).compareTo(_asInt(b['matchOrder'])),
        );
    return [for (final match in matches) match['id'].toString()];
  }

  static bool _isWinnersRoundOne(Map match) {
    final branch = (match['bracketBranch'] ?? '').toString().toUpperCase();
    return _asInt(match['roundNumber']) == 1 &&
        branch != 'LOSERS' &&
        branch != 'GRAND_FINALS';
  }
}
