// Tests for Team entity
// Covers: TEAMS-001, TEAMS-004

import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';

void main() {
  group('TC-FLUTTER-TEAMS-001: Team.fromJson', () {
    test('TC-FLUTTER-TEAMS-001: should parse full team JSON correctly', () {
      final json = {
        'name': 'Doi A',
        'members': ['Nguyen Van A', 'Tran Van B'],
        'seed': 2,
        'group': 'Bang A',
        'photoUrl': 'https://example.com/photo.jpg',
        'qrCode': 'VDV-001',
        'approvalStatus': 'APPROVED',
        'contactEmail': 'contact@example.com',
        'createdAt': '2026-06-01T00:00:00Z',
      };

      final team = Team.fromJson(json, 'team-1');

      expect(team.id, 'team-1');
      expect(team.name, 'Doi A');
      expect(team.members, ['Nguyen Van A', 'Tran Van B']);
      expect(team.seed, 2);
      expect(team.group, 'Bang A');
      expect(team.photoUrl, 'https://example.com/photo.jpg');
      expect(team.qrCode, 'VDV-001');
      expect(team.approvalStatus, 'APPROVED');
      expect(team.contactEmail, 'contact@example.com');
    });

    test('TC-FLUTTER-TEAMS-001: should handle minimal JSON with defaults', () {
      final json = {'name': ''};
      final team = Team.fromJson(json, 'team-1');

      expect(team.id, 'team-1');
      expect(team.name, '');
      expect(team.members, []);
      expect(team.seed, 0);
      expect(team.group, '');
      expect(team.approvalStatus, 'PENDING_APPROVAL');
      expect(team.qrCode, '');
    });

    test('TC-FLUTTER-TEAMS-001: should fallback approvalStatus from teamStatus', () {
      final json = {'name': 'A', 'teamStatus': 'WAITLISTED'};
      final team = Team.fromJson(json, '1');
      expect(team.approvalStatus, 'WAITLISTED');
    });

    test('TC-FLUTTER-TEAMS-001: should fallback approvalStatus from status', () {
      final json = {'name': 'A', 'status': 'APPROVED'};
      final team = Team.fromJson(json, '1');
      expect(team.approvalStatus, 'APPROVED');
    });
  });

  group('TC-FLUTTER-TEAMS-004: Team getters', () {
    test('isApproved returns true for APPROVED', () {
      final t = Team(id: '1', name: 'A', approvalStatus: 'APPROVED', createdAt: DateTime.now());
      expect(t.isApproved, true);
      expect(t.isPendingApproval, false);
    });

    test('isPendingApproval returns true for PENDING_APPROVAL', () {
      final t = Team(id: '1', name: 'A', approvalStatus: 'PENDING_APPROVAL', createdAt: DateTime.now());
      expect(t.isPendingApproval, true);
      expect(t.isApproved, false);
    });

    test('isComplete returns true when approvalStatus is COMPLETE', () {
      final t = Team(id: '1', name: 'A', approvalStatus: 'COMPLETE', createdAt: DateTime.now());
      expect(t.isComplete, true);
    });

    test('isComplete returns false when approvalStatus is PENDING_APPROVAL', () {
      final t = Team(id: '1', name: '', approvalStatus: 'PENDING_APPROVAL', createdAt: DateTime.now());
      expect(t.isComplete, false);
    });
  });
}
