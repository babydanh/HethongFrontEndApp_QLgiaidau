import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';

class GroupStageGroup {
  final String name;
  final List<String> participantIds;

  const GroupStageGroup({required this.name, required this.participantIds});
}

class GroupStageConfig {
  final List<GroupStageGroup> groups;
  final List<String> unassignedParticipantIds;
  final List<String> participantIds;
  final int teamsAdvancing;
  final int teamsPerGroup;

  const GroupStageConfig({
    required this.groups,
    required this.unassignedParticipantIds,
    required this.participantIds,
    required this.teamsAdvancing,
    required this.teamsPerGroup,
  });

  GroupStageConfig resizeGroupCount(int count) {
    final targetCount = count < 1 ? 1 : count;
    final nextGroups = groups.take(targetCount).toList();
    for (var index = nextGroups.length; index < targetCount; index++) {
      nextGroups.add(
        GroupStageGroup(name: _groupName(index), participantIds: const []),
      );
    }

    final unassigned = List<String>.of(unassignedParticipantIds);
    for (final removedGroup in groups.skip(targetCount)) {
      unassigned.addAll(removedGroup.participantIds);
    }

    return GroupStageConfig(
      groups: List.unmodifiable(nextGroups),
      unassignedParticipantIds: List.unmodifiable(unassigned),
      participantIds: participantIds,
      teamsAdvancing: teamsAdvancing,
      teamsPerGroup: _ceilDivide(participantIds.length, targetCount),
    );
  }

  GroupStageConfig moveParticipant(
    String participantId, {
    int? groupIndex,
    String? beforeParticipantId,
  }) {
    if (!participantIds.contains(participantId)) return this;
    if (groupIndex != null && (groupIndex < 0 || groupIndex >= groups.length)) {
      return this;
    }

    final nextGroups = groups
        .map(
          (group) => GroupStageGroup(
            name: group.name,
            participantIds: List<String>.of(group.participantIds)
              ..remove(participantId),
          ),
        )
        .toList();
    final unassigned = List<String>.of(unassignedParticipantIds)
      ..remove(participantId);

    if (groupIndex == null) {
      unassigned.add(participantId);
    } else {
      final target = nextGroups[groupIndex].participantIds;
      final insertAt = beforeParticipantId == null
          ? -1
          : target.indexOf(beforeParticipantId);
      if (insertAt < 0) {
        target.add(participantId);
      } else {
        target.insert(insertAt, participantId);
      }
    }

    return GroupStageConfig(
      groups: List.unmodifiable(
        nextGroups.map(
          (group) => GroupStageGroup(
            name: group.name,
            participantIds: List.unmodifiable(group.participantIds),
          ),
        ),
      ),
      unassignedParticipantIds: List.unmodifiable(unassigned),
      participantIds: participantIds,
      teamsAdvancing: teamsAdvancing,
      teamsPerGroup: teamsPerGroup,
    );
  }
}

GroupStageConfig resolveGroupStageConfig({
  required TournamentDivision division,
  required Map<String, dynamic> tournamentConfig,
  required List<Team> teams,
}) {
  final roundConfig = division.roundConfig ?? const <String, dynamic>{};
  final rawGroupsConfig = roundConfig['groupsConfig'];
  final groupsConfig = rawGroupsConfig is Map
      ? Map<String, dynamic>.from(rawGroupsConfig)
      : const <String, dynamic>{};
  final groupCount =
      _positiveInt(groupsConfig['numGroups']) ??
      _positiveInt(tournamentConfig['numberOfGroups']) ??
      1;
  final eligibleParticipantIds = teams
      .where((team) => team.divisionId == division.id && team.isApproved)
      .map((team) => team.id)
      .where((id) => id.isNotEmpty)
      .toList();
  final eligibleIds = eligibleParticipantIds.toSet();
  final savedGroups = groupsConfig['groups'];
  final groups = <GroupStageGroup>[];
  final assignedIds = <String>{};

  for (var index = 0; index < groupCount; index++) {
    final savedGroup = savedGroups is List && index < savedGroups.length
        ? savedGroups[index]
        : null;
    final savedMap = savedGroup is Map ? savedGroup : null;
    final rawName = savedMap?['name']?.toString().trim();
    final participantIds = <String>[];
    final rawParticipantIds = savedMap?['participantIds'];
    if (rawParticipantIds is List) {
      for (final rawId in rawParticipantIds) {
        final id = rawId?.toString() ?? '';
        if (id.isNotEmpty && eligibleIds.contains(id) && assignedIds.add(id)) {
          participantIds.add(id);
        }
      }
    }
    groups.add(
      GroupStageGroup(
        name: rawName == null || rawName.isEmpty ? _groupName(index) : rawName,
        participantIds: List.unmodifiable(participantIds),
      ),
    );
  }

  final advancementConfig = roundConfig['advancementConfig'];
  final advancementMap = advancementConfig is Map
      ? advancementConfig
      : const <String, dynamic>{};
  final teamsAdvancing =
      _positiveInt(advancementMap['teamsAdvancing']) ??
      _positiveInt(tournamentConfig['teamsAdvancingPerGroup']) ??
      2;

  return GroupStageConfig(
    groups: List.unmodifiable(groups),
    unassignedParticipantIds: List.unmodifiable(
      eligibleParticipantIds.where((id) => !assignedIds.contains(id)),
    ),
    participantIds: List.unmodifiable(eligibleParticipantIds),
    teamsAdvancing: teamsAdvancing,
    teamsPerGroup:
        _positiveInt(groupsConfig['teamsPerGroup']) ??
        _ceilDivide(eligibleParticipantIds.length, groupCount),
  );
}

List<int> groupCountOptions({
  required int participantCount,
  required int currentGroupCount,
}) {
  final maxGroupCount = participantCount ~/ 2;
  final upperBound = maxGroupCount < 1 ? 1 : maxGroupCount;
  return [
    for (var count = 1; count <= upperBound; count++) count,
    if (currentGroupCount > upperBound) currentGroupCount,
  ];
}

Map<String, dynamic> buildDivisionConfigPatchPayload({
  required Map<String, dynamic>? currentRoundConfig,
  required GroupStageConfig config,
}) {
  final roundConfig = Map<String, dynamic>.of(
    currentRoundConfig ?? const <String, dynamic>{},
  );
  final rawGroupsConfig = roundConfig['groupsConfig'];
  final groupsConfig = rawGroupsConfig is Map
      ? Map<String, dynamic>.from(rawGroupsConfig)
      : <String, dynamic>{};
  groupsConfig['numGroups'] = config.groups.length;
  groupsConfig['teamsPerGroup'] = config.teamsPerGroup;
  groupsConfig['groups'] = [
    for (final group in config.groups)
      {
        'name': group.name,
        'participantIds': List<String>.of(group.participantIds),
      },
  ];
  roundConfig['groupsConfig'] = groupsConfig;

  return {'isConfigOverride': true, 'roundConfig': roundConfig};
}

int? _positiveInt(Object? value) {
  final parsed = switch (value) {
    int integer => integer,
    num number when number.isFinite && number == number.roundToDouble() =>
      number.toInt(),
    String text => int.tryParse(text),
    _ => null,
  };
  return parsed != null && parsed > 0 ? parsed : null;
}

int _ceilDivide(int value, int divisor) => (value + divisor - 1) ~/ divisor;

String _groupName(int index) {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  if (index < letters.length) return letters[index];
  final previous = _groupName(index ~/ letters.length - 1);
  return '$previous${letters[index % letters.length]}';
}
