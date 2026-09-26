import 'package:app_quanly_giaidau/providers/lite_management_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _participant(
  String id, {
  String status = 'PENDING_PARTNER',
  String? inviteToken,
  int rosterCount = 1,
}) => {
  'id': id,
  'teamStatus': status,
  'teamName': id,
  if (inviteToken != null) 'teamInviteToken': inviteToken,
  'rosters': List.generate(
    rosterCount,
    (index) => {
      'userId': '$id-player-$index',
      'role': index == 0 ? 'MAIN' : 'SUB',
      'profile': {'fullName': '$id player $index'},
    },
  ),
};

void main() {
  test('Lite BTC pairing list excludes approval, invite, and paired rows', () {
    final state = LiteManagementState(
      participants: [
        LiteParticipant.fromJson(_participant('eligible')),
        LiteParticipant.fromJson(
          _participant('approval', status: 'PENDING_APPROVAL'),
        ),
        LiteParticipant.fromJson(
          _participant('self-invite', inviteToken: 'INVITE-TOKEN'),
        ),
        LiteParticipant.fromJson(
          _participant('already-paired', status: 'COMPLETE', rosterCount: 2),
        ),
        LiteParticipant.fromJson(
          _participant(
            'approved-team',
            status: 'PENDING_APPROVAL',
            rosterCount: 2,
          ),
        ),
      ],
    );

    expect(state.pendingParticipants.map((participant) => participant.id), [
      'eligible',
    ]);
    expect(state.completeParticipants.map((participant) => participant.id), [
      'already-paired',
      'approved-team',
    ]);
  });
}
