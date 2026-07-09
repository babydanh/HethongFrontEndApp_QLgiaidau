// Tests for Community and CommunityTournamentModel entities
// Covers: COMMUNITY-001, 003, 008, FLUTTER-05-08, FLUTTER-21, FLUTTER-26-27

import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/gallery_image_model.dart';

void main() {
  group('TC-FLUTTER-COMMUNITY-001: Community.fromJson', () {
    test('TC-FLUTTER-COMMUNITY-003: should parse full community JSON', () {
      final json = {
        'id': 'club-1',
        'name': 'CLB CAU LONG HA NOI',
        'description': 'Cau lac bo cau long',
        'sports': 'badminton',
        'communitySports': [
          {'category': {'name': 'Cau Long', 'slug': 'badminton'}, 'categoryId': 'cat-1'}
        ],
        'location': 'Ha Noi',
        'locationAddress': 'Ha Noi',
        'joinMode': 'OPEN',
        'memberCount': 50,
        'members': List.generate(50, (i) => {'id': 'm-$i'}),
        '_count': {'members': 50},
        'maxMembers': 100,
        'bannerUrl': 'https://example.com/banner.jpg',
        'logoUrl': 'https://example.com/logo.jpg',
        'status': 'ACTIVE',
        'createdAt': '2026-01-01T00:00:00Z',
        'owner': {'id': 'user-1', 'fullName': 'Nguyen Van A'},
      };

      final community = Community.fromJson(json);

      expect(community.id, 'club-1');
      expect(community.name, 'CLB CAU LONG HA NOI');
      expect(community.description, 'Cau lac bo cau long');
      expect(community.sports, ['Cau Long']);
      expect(community.locationAddress, 'Ha Noi');
      expect(community.memberCount, 50);
      expect(community.maxMembers, 100);
      expect(community.joinMode, 'OPEN');
      expect(community.status, 'ACTIVE');
    });

    test('TC-FLUTTER-COMMUNITY-001: should handle minimal JSON with defaults', () {
      final json = {'id': 'club-1', 'name': 'Test Club'};
      final community = Community.fromJson(json);

      expect(community.name, 'Test Club');
      expect(community.sports, []);
      expect(community.memberCount, 0);
      expect(community.joinMode, 'OPEN');
      expect(community.status, 'ACTIVE');
      expect(community.description, isNull);
    });

    test('TC-FLUTTER-COMMUNITY-001: should handle empty sports', () {
      final json = {'id': '1', 'name': 'C'};
      final c = Community.fromJson(json);
      expect(c.sports, []);
    });
  });

  group('TC-FLUTTER-26: CommunityTournamentModel.fromJson', () {
    test('should parse full JSON', () {
      final json = {
        'id': 'ct-1',
        'name': 'Giai CLB Noi Bo',
        'sport': 'badminton',
        'format': 'SINGLES',
        'status': 'DRAFT',
        'maxParticipants': '16',
        '_count': {'participants': 3},
        'startDate': '2026-08-01',
      };

      final model = CommunityTournamentModel.fromJson(json);
      expect(model.id, 'ct-1');
      expect(model.name, 'Giai CLB Noi Bo');
      expect(model.maxTeams, 16);
      expect(model.teamCount, 3);
      expect(model.startDate, '2026-08-01');
    });

    test('TC-FLUTTER-27: should handle missing fields with defaults', () {
      final json = {'id': '', 'name': ''};
      final model = CommunityTournamentModel.fromJson(json);
      expect(model.id, '');
      expect(model.name, '');
      expect(model.maxTeams, 16);
      expect(model.teamCount, 0);
      expect(model.status, 'draft');
    });
  });

  group('CommunityMemberModel.fromJson', () {
    test('should parse full JSON with nested member/user', () {
      final json = {
        'member': {'id': 'mem-1', 'userId': 'user-1', 'role': 'OWNER', 'status': 'JOINED', 'communityId': 'club-1', 'joinedAt': '2026-01-01'},
        'user': {'id': 'user-1', 'fullName': 'Nguyen Van A', 'avatarUrl': null, 'email': 'test@test.com'},
      };

      final model = CommunityMemberModel.fromJson(json);
      expect(model.id, 'mem-1');
      expect(model.userId, 'user-1');
      expect(model.role, 'OWNER');
      expect(model.status, 'JOINED');
      expect(model.userFullName, 'Nguyen Van A');
    });

    test('should handle flat JSON', () {
      final json = {'id': 'mem-1', 'userId': 'u1', 'role': 'MEMBER', 'status': 'JOINED'};
      final model = CommunityMemberModel.fromJson(json);
      expect(model.role, 'MEMBER');
      expect(model.userFullName, null);
    });
  });

  group('GalleryImageModel.fromJson', () {
    test('should parse with imageUrl', () {
      final g = GalleryImageModel.fromJson({'imageUrl': 'https://example.com/img.jpg'});
      expect(g.imageUrl, 'https://example.com/img.jpg');
    });

    test('should fallback to image_url', () {
      final g = GalleryImageModel.fromJson({'image_url': 'https://example.com/img2.jpg'});
      expect(g.imageUrl, 'https://example.com/img2.jpg');
    });

    test('should use empty default', () {
      final g = GalleryImageModel.fromJson({});
      expect(g.imageUrl, '');
    });
  });
}
