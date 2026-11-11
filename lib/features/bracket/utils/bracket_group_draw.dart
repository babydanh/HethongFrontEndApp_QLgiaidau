import 'dart:math';

import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/group_stage_config.dart';

/// Deals [teams] into [numGroups] balanced groups and returns the team ids per
/// group. By ELO the strongest team goes first and the groups are walked in
/// snake order (A B C C B A ...), so the strong teams are spread; otherwise the
/// teams are shuffled first.
List<List<String>> drawBracketGroups({
  required List<Team> teams,
  required int numGroups,
  required bool byElo,
  Random? random,
}) {
  final groups = [for (var i = 0; i < numGroups; i++) <String>[]];
  final ordered = List<Team>.of(teams);
  if (byElo) {
    ordered.sort(_strongestFirst);
  } else {
    ordered.shuffle(random);
  }
  for (var i = 0; i < ordered.length; i++) {
    final position = i % numGroups;
    final index = (i ~/ numGroups).isEven ? position : numGroups - 1 - position;
    groups[index].add(ordered[i].id);
  }
  return groups;
}

int _strongestFirst(Team a, Team b) {
  final byElo = (b.eloPoints ?? -1).compareTo(a.eloPoints ?? -1);
  if (byElo != 0) return byElo;
  final byName = a.name.compareTo(b.name);
  return byName != 0 ? byName : a.id.compareTo(b.id);
}

/// Copy of [roundConfig] whose `groupsConfig.groups` lists [groups], so the
/// backend creates the bracket with exactly these teams in each group. A group
/// name the organizer already chose is kept.
Map<String, dynamic> withDrawnGroups(
  Map<String, dynamic> roundConfig,
  List<List<String>> groups,
) {
  final rawGroupsConfig = roundConfig['groupsConfig'];
  final groupsConfig = rawGroupsConfig is Map
      ? Map<String, dynamic>.from(rawGroupsConfig)
      : <String, dynamic>{};
  final saved = groupsConfig['groups'];
  groupsConfig['groups'] = [
    for (var i = 0; i < groups.length; i++)
      {
        'name': _savedName(saved, i) ?? groupStageGroupName(i),
        'participantIds': List<String>.of(groups[i]),
      },
  ];
  return {...roundConfig, 'groupsConfig': groupsConfig};
}

String? _savedName(Object? saved, int index) {
  if (saved is! List || index >= saved.length) return null;
  final group = saved[index];
  final name = group is Map ? group['name']?.toString().trim() : null;
  return name == null || name.isEmpty ? null : name;
}
