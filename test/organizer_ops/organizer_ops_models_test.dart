import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:test/test.dart';

void main() {
  group('OrganizerOpsParticipant', () {
    test('parses public roster payload with nested members', () {
      final participant = OrganizerOpsParticipant.fromJson({
        'id': 'participant-1',
        'teamName': 'Team A',
        'teamStatus': 'COMPLETE',
        'isPaid': true,
        'tournamentDivisionId': 'division-1',
        'seed': '4',
        'members': [
          {
            'userId': 'user-1',
            'fullName': 'Nguyen Van A',
            'role': 'MAIN',
            'isMock': false,
          },
        ],
      });

      expect(participant.id, 'participant-1');
      expect(participant.teamName, 'Team A');
      expect(participant.teamStatus, 'COMPLETE');
      expect(participant.isPaid, isTrue);
      expect(participant.divisionId, 'division-1');
      expect(participant.seed, 4);
      expect(participant.members.single.fullName, 'Nguyen Van A');
      expect(participant.isKicked, isFalse);
    });

    test('recognizes kicked and disqualified states', () {
      final kicked = OrganizerOpsParticipant.fromJson({
        'id': 'kicked',
        'teamName': 'Kicked',
        'teamStatus': 'KICKED',
        'isPaid': false,
      });
      final disqualified = OrganizerOpsParticipant.fromJson({
        'id': 'dq',
        'teamName': 'DQ',
        'team_status': 'DISQUALIFIED',
        'is_paid': false,
      });

      expect(kicked.isKicked, isTrue);
      expect(kicked.isDisciplined, isFalse);
      expect(disqualified.isDisciplined, isTrue);
    });
  });

  test('parses snake_case audit payload and actor fallback', () {
    final entry = OrganizerOpsAuditEntry.fromJson({
      'id': 'audit-1',
      'table_name': 'matches',
      'record_id': 'match-1',
      'action': 'UPDATE_SCORE',
      'created_at': '2026-08-27T02:00:00.000Z',
      'user': {'email': 'operator@example.com'},
    });

    expect(entry.id, 'audit-1');
    expect(entry.tableName, 'matches');
    expect(entry.recordId, 'match-1');
    expect(entry.action, 'UPDATE_SCORE');
    expect(entry.actorName, 'operator@example.com');
    expect(entry.createdAt.toUtc().year, 2026);
  });
}
