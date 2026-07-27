import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String screenSource;
  late String repositorySource;

  setUpAll(() {
    screenSource = File(
      'lib/features/tournament/screens/tournament_intro_screen.dart',
    ).readAsStringSync();
    repositorySource = File(
      'lib/data/repositories/api/api_team_repository.dart',
    ).readAsStringSync();
  });

  test('screen delegates business rules to typed registration gate', () {
    expect(screenSource, contains('RegistrationGateResult _registrationGate'));
    expect(screenSource, contains('evaluateRegistrationGate('));
    expect(screenSource, contains('identityCheckPending'));
    expect(screenSource, contains('gate.canContinue'));
    expect(screenSource, contains('gate.label'));
  });

  test('duplicate detection uses active roster userId only', () {
    expect(screenSource, contains("'WITHDRAWN', 'REJECTED', 'KICKED'"));
    expect(screenSource, contains('member.userId == currentUserId'));
    expect(screenSource, isNot(contains('member.fullName ==')));
    expect(screenSource, isNot(contains('members.contains(currentUserId)')));
  });

  test('repository preserves roster identities', () {
    expect(repositorySource, contains('MatchMemberInfo.fromJson'));
    expect(repositorySource, contains('memberInfos: memberInfos'));
    expect(repositorySource, contains("json['rosters']"));
    expect(repositorySource, contains("json['members']"));
  });

  test(
    'screen does not invent Lite routing or tournament full from maxTeams',
    () {
      expect(screenSource, isNot(contains("context.push('/lite")));
      expect(screenSource, isNot(contains('tournament.maxTeams')));
    },
  );
}
