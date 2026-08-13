import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/lite_tournament_create_result.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';

void main() {
  group('Tournament entity — Lite detection', () {
    test('isLite=true when tournamentConfig.isLite is true', () {
      final t = Tournament.fromJson({
        'name': 'Lite Test',
        'tournamentConfig': {'isLite': true},
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      }, 'id-1');
      expect(t.isLite, true);
    });

    test('isLite=true when top-level isLite is true', () {
      final t = Tournament.fromJson({
        'name': 'Lite Test 2',
        'isLite': true,
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      }, 'id-1b');
      expect(t.isLite, true);
    });

    test('isLite=false when tournamentConfig.mode is LITE but no isLite flag (scoring, NOT type)', () {
      // mode='LITE' là CÁCH TÍNH ĐIỂM, không phải loại giải → isLite phải false.
      final t = Tournament.fromJson({
        'name': 'Advanced Scoring Lite',
        'tournamentConfig': {'mode': 'LITE'},
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      }, 'id-2');
      expect(t.isLite, false);
    });

    test('isLite=false when tournamentConfig is absent', () {
      final t = Tournament.fromJson({
        'name': 'No Config',
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      }, 'id-3');
      expect(t.isLite, false);
    });

    test('inviteCode is parsed from JSON', () {
      final t = Tournament.fromJson({
        'name': 'Invite Test',
        'inviteCode': 'abc-123',
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      }, 'id-4');
      expect(t.inviteCode, 'abc-123');
    });

    test('inviteCode is null when absent', () {
      final t = Tournament.fromJson({
        'name': 'No Invite',
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-01-01T00:00:00Z',
      }, 'id-5');
      expect(t.inviteCode, isNull);
    });
  });

  group('CommunityTournamentModel — Lite detection', () {
    test('isLite=true from tournamentConfig.isLite true', () {
      final model = CommunityTournamentModel.fromJson({
        'id': 'c-1',
        'name': 'CLB Lite',
        'tournamentConfig': {'isLite': true},
      });
      expect(model.isLite, true);
    });

    test('isLite=true from top-level isLite true', () {
      final model = CommunityTournamentModel.fromJson({
        'id': 'c-1b',
        'name': 'CLB Lite Top',
        'isLite': true,
      });
      expect(model.isLite, true);
    });

    test('isLite=false when mode=LITE only (scoring, NOT type)', () {
      final model = CommunityTournamentModel.fromJson({
        'id': 'c-2',
        'name': 'CLB Advanced',
        'tournamentConfig': {'mode': 'LITE'},
      });
      expect(model.isLite, false);
    });

    test('isLite=false when tournamentConfig is absent', () {
      final model = CommunityTournamentModel.fromJson({
        'id': 'c-3',
        'name': 'CLB No Config',
        'tournamentConfig': {'maxTeams': 16},
      });
      expect(model.isLite, false);
    });

    test('isLite=false when type field is LITE (no fallback)', () {
      // Backward compat: type field should NOT trigger Lite detection
      final model = CommunityTournamentModel.fromJson({
        'id': 'c-4',
        'name': 'CLB Type Field',
        'type': 'LITE',
      });
      expect(model.isLite, false);
    });

    test('isLite=true for legacy lite (mode=LITE + hideAdvancedSettings)', () {
      // Fallback an toàn cho giải lite cũ trước migration.
      final model = CommunityTournamentModel.fromJson({
        'id': 'c-5',
        'name': 'CLB Legacy Lite',
        'tournamentConfig': {'mode': 'LITE', 'hideAdvancedSettings': true},
      });
      expect(model.isLite, true);
    });
  });

  group('LiteTournamentCreateResult — URL resolution', () {
    test('resolveUrl returns absolute URL as-is', () {
      final result = LiteTournamentCreateResult.fromJson({
        'id': 't-1',
        'name': 'Test',
        'status': 'draft',
        'joinUrl': 'https://giaidau.vnvar.com/lite/tournaments/join/abc',
      });
      expect(
        result.resolvedJoinUrl,
        'https://giaidau.vnvar.com/lite/tournaments/join/abc',
      );
    });

    test('resolveUrl prepends base for relative URL', () {
      final result = LiteTournamentCreateResult.fromJson({
        'id': 't-2',
        'name': 'Test',
        'status': 'draft',
        'joinUrl': '/lite/tournaments/join/def',
      });
      expect(
        result.resolvedJoinUrl,
        'https://sporto.asia/lite/tournaments/join/def',
      );
    });

    test('resolvedJoinUrl falls back to inviteCode when joinUrl missing', () {
      final result = LiteTournamentCreateResult.fromJson({
        'id': 't-3',
        'name': 'Test',
        'status': 'draft',
        'inviteCode': 'xyz-789',
      });
      expect(
        result.resolvedJoinUrl,
        'https://sporto.asia/lite/tournaments/join/xyz-789',
      );
    });

    test('resolvedJoinUrl returns empty when nothing available', () {
      final result = LiteTournamentCreateResult.fromJson({
        'id': 't-4',
        'name': 'Test',
        'status': 'draft',
      });
      expect(result.resolvedJoinUrl, '');
    });

    test('resolvedQrPayload prefers qrPayload over joinUrl', () {
      final result = LiteTournamentCreateResult.fromJson({
        'id': 't-5',
        'name': 'Test',
        'status': 'draft',
        'qrPayload': 'https://giaidau.vnvar.com/lite/tournaments/join/qr-code',
        'joinUrl': '/lite/tournaments/join/fallback',
      });
      expect(
        result.resolvedQrPayload,
        'https://giaidau.vnvar.com/lite/tournaments/join/qr-code',
      );
    });

    test(
      'resolvedQrPayload falls back to resolvedJoinUrl when qrPayload missing',
      () {
        final result = LiteTournamentCreateResult.fromJson({
          'id': 't-6',
          'name': 'Test',
          'status': 'draft',
          'inviteCode': 'code-123',
        });
        expect(
          result.resolvedQrPayload,
          'https://sporto.asia/lite/tournaments/join/code-123',
        );
      },
    );

    test('resolveUrl with custom baseUrl', () {
      const url = '/custom/path';
      final resolved = LiteTournamentCreateResult.resolveUrl(
        url,
        baseUrl: 'https://custom.example.com',
      );
      expect(resolved, 'https://custom.example.com/custom/path');
    });

    test('resolveUrl returns empty for null/empty input', () {
      expect(LiteTournamentCreateResult.resolveUrl(null), '');
      expect(LiteTournamentCreateResult.resolveUrl(''), '');
    });
  });
}
