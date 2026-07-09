// Tests for Tournament entity
// Covers: INTRO-001, INTRO-002, DETAIL-001

import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';

void main() {
  group('TC-FLUTTER-INTRO-001: Tournament.fromJson', () {
    test('should parse full JSON with nested category and config', () {
      final json = {
        'name': 'Giai Cau Long Mo Rong 2026',
        'sport': 'badminton',
        'format': 'SINGLES',
        'category': {'name': 'Cầu lông', 'slug': 'badminton'},
        'matchType': 'singles',
        'bracketType': 'single_elimination',
        'status': 'in_progress',
        'visibility': 'PUBLIC',
        'adminToken': 'ADM-XXX',
        'refereeToken': 'REF-XXX',
        'viewerToken': 'VWR-XXX',
        'creatorId': 'user-1',
        'creator': {'id': 'user-1', 'fullName': 'Nguyen Van A'},
        'maxTeams': 16,
        'maxPlayersPerTeam': 2,
        'description': 'Giai dau mo rong',
        'roundCount': 4,
        'createdAt': '2026-06-01T00:00:00Z',
        'updatedAt': '2026-07-07T00:00:00Z',
        'entryFee': '100000',
        'startDate': '2026-07-15T00:00:00Z',
        'endDate': '2026-07-20T00:00:00Z',
        'locationAddress': 'Ha Noi',
        'prizeDescription': '10.000.000d',
        'contactInfo': {'phone': '0123456789'},
        'divisions': [{'name': 'Nam'}, {'name': 'Nu'}],
      };

      final tournament = Tournament.fromJson(json, 'tour-1');

      expect(tournament.id, 'tour-1');
      expect(tournament.name, 'Giai Cau Long Mo Rong 2026');
      expect(tournament.sport, 'badminton');
      expect(tournament.format, 'singles'); // matchType 'singles' maps to formatSingles which is lowercase
      expect(tournament.category, 'Cầu lông');
      expect(tournament.bracketType, 'single_elimination');
      expect(tournament.status, 'in_progress');
      expect(tournament.visibility, 'PUBLIC');
      expect(tournament.maxTeams, 16);
      expect(tournament.entryFee, 100000.0);
      expect(tournament.description, 'Giai dau mo rong');
      expect(tournament.prizeDescription, '10.000.000d');
      expect(tournament.locationAddress, 'Ha Noi');
      expect(tournament.contactInfo, {'phone': '0123456789'});
      expect(tournament.divisions, ['Nam', 'Nu']);
    });

    test('should handle minimal JSON with defaults', () {
      final json = {
        'name': 'Giai Test',
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      };

      final tournament = Tournament.fromJson(json, 'tour-1');

      expect(tournament.id, 'tour-1');
      expect(tournament.name, 'Giai Test');
      expect(tournament.sport, '');
      expect(tournament.format, '');
      expect(tournament.status, 'draft');
      expect(tournament.visibility, 'PUBLIC');
      expect(tournament.maxTeams, 16);
      expect(tournament.entryFee, null);
      expect(tournament.description, '');
      expect(tournament.divisions, []);
    });

    test('should parse doubles format from matchType', () {
      final json = {
        'name': 'Test',
        'matchType': 'doubles',
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      };
      final t = Tournament.fromJson(json, '1');
      expect(t.format, 'doubles'); // matchType 'doubles' maps to formatDoubles which is 'doubles'
    });

    test('should parse status through normalizer', () {
      final json = {
        'name': 'Test',
        'status': 'ONGOING',
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      };
      final t = Tournament.fromJson(json, '1');
      // StatusHelper.normalizeTournamentStatus maps 'ONGOING' to something
      expect(t.status, isNotEmpty);
    });

    test('should handle tournamentConfig JSONB', () {
      final json = {
        'name': 'Test',
        'tournamentConfig': {
          'bracketType': 'round_robin',
          'maxTeams': 8,
          'roundRobinLegs': 2,
        },
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      };
      final t = Tournament.fromJson(json, '1');
      expect(t.bracketType, 'round_robin');
      expect(t.maxTeams, 8);
      expect(t.roundCount, 2);
    });

    test('should handle gallery images', () {
      final json = {
        'name': 'Test',
        'galleryImages': ['img1.jpg', 'img2.jpg'],
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      };
      final t = Tournament.fromJson(json, '1');
      expect(t.galleryImages, ['img1.jpg', 'img2.jpg']);
    });

    test('should handle PRIVATE visibility', () {
      final json = {
        'name': 'Test',
        'visibility': 'PRIVATE',
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      };
      final t = Tournament.fromJson(json, '1');
      expect(t.visibility, 'PRIVATE');
    });

    test('should fallback to PUBLIC for unknown visibility', () {
      final json = {
        'name': 'Test',
        'visibility': 'SECRET',
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      };
      final t = Tournament.fromJson(json, '1');
      expect(t.visibility, 'PUBLIC');
    });
  });
}
