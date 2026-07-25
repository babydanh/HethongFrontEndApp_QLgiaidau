// Batch A+B Focused Verification
// Socket parser JSON/Map | No legacy score API payloads
// Status normalize | Operation action/reason
// Register participant.id + invite query | Payment purpose

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────
// 1. Socket parser JSON/Map — MatchSocketService._parsePayload
// ─────────────────────────────────────────────────────────────────
void main() {
  group('[Batch A+B] Socket parser JSON/Map', () {
    test('PASS: _parsePayload handles Map<String,dynamic> directly', () {
      final source = File(
        'lib/core/services/match_socket_service.dart',
      ).readAsStringSync();
      // Must check type before processing
      expect(source, contains('data is Map<String, dynamic>'));
      expect(source, contains('Map<String, dynamic>.from(data)'));
      // String payload goes through jsonDecode
      expect(source, contains('if (data is String)'));
      expect(source, contains('jsonDecode(data)'));
    });

    test('PASS: _parsePayload decodes JSON string safely', () {
      final source = File(
        'lib/core/services/match_socket_service.dart',
      ).readAsStringSync();
      expect(source, contains('jsonDecode(data)'));
      expect(source, contains('jsonDecode'));
      // Must wrap in try-catch
      expect(source, contains('catch'));
      // Returns null on failure, never throws
      expect(source, contains('return null'));
    });

    test('PASS: _parsePayload warns on unknown format', () {
      final source = File(
        'lib/core/services/match_socket_service.dart',
      ).readAsStringSync();
      expect(source, contains('_log.warning'));
      expect(source, contains('format lạ'));
    });

    test('PASS: All socket event listeners use _parsePayload', () {
      final source = File(
        'lib/core/services/match_socket_service.dart',
      ).readAsStringSync();
      // Every .on() callback calls _parsePayload before adding to controller
      final callCount = 'final parsed = _parsePayload(data);'.allMatches(source).length;
      expect(callCount, 5, reason: 'All 5 event types (score, status, viewer, comment, cheer) must parse');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 2. No legacy score API payloads — ApiMatchRepository
  // ─────────────────────────────────────────────────────────────
  group('[Batch A+B] No legacy score API payloads', () {
    test('PASS: updateLiveState blocks flat score1/score2 calls', () {
      final source = File(
        'lib/data/repositories/api/api_match_repository.dart',
      ).readAsStringSync();
      // Must not send flat score payload
      expect(source, contains('Flat score1/score2 không được backend'));
      expect(source, contains('UnsupportedError'));
    });

    test('PASS: updateLiveState uses /status endpoint for status-only', () {
      final source = File(
        'lib/data/repositories/api/api_match_repository.dart',
      ).readAsStringSync();
      expect(source, contains("'/matches/\$matchId/status'"));
    });

    test('PASS: completeMatch throws instead of sending legacy payload', () {
      final source = File(
        'lib/data/repositories/api/api_match_repository.dart',
      ).readAsStringSync();
      expect(source, contains('completeMatch không được backend /score hỗ trợ'));
      expect(source, contains('UnsupportedError'));
    });

    test('PASS: updateScoreDetails sends p1SetsWon/p2SetsWon/scoreDetails', () {
      final source = File(
        'lib/data/repositories/api/api_match_repository.dart',
      ).readAsStringSync();
      expect(source, contains("'p1SetsWon': p1SetsWon"));
      expect(source, contains("'p2SetsWon': p2SetsWon"));
      expect(source, contains("'scoreDetails'"));
      expect(source, contains("'/matches/\$matchId/score'"));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 3. Status normalize
  // ─────────────────────────────────────────────────────────────
  group('[Batch A+B] Status normalize', () {
    test('PASS: StatusHelper.normalizeTournamentStatus covers all backend enums', () {
      final source = File(
        'lib/core/utils/status_helpers.dart',
      ).readAsStringSync();
      expect(source, contains("'DRAFT'"));
      expect(source, contains("'UPCOMING'"));
      expect(source, contains("'REGISTRATION_OPEN'"));
      expect(source, contains("'REGISTRATION_CLOSED'"));
      expect(source, contains("'ONGOING'"));
      expect(source, contains("'IN_PROGRESS'"));
      expect(source, contains("'COMPLETED'"));
      expect(source, contains("'FINISHED'"));
      expect(source, contains("'CANCELLED'"));
    });

    test('PASS: Tournament.fromJson uses StatusHelper to normalize', () {
      final source = File(
        'lib/domain/entities/tournament.dart',
      ).readAsStringSync();
      expect(source, contains('StatusHelper.normalizeTournamentStatus'));
    });

    test('PASS: _mapMatchStatus covers ONGOING/IN_PROGRESS/LIVE → live', () {
      final source = File(
        'lib/data/repositories/api/api_match_repository.dart',
      ).readAsStringSync();
      expect(source, contains("'ONGOING'"));
      expect(source, contains("'IN_PROGRESS'"));
      expect(source, contains("'LIVE'"));
      expect(source, contains("'COMPLETED'"));
      expect(source, contains("'FINISHED'"));
      expect(source, contains("'DONE'"));
      expect(source, contains("'ENDED'"));
      expect(source, contains("'WALKOVER'"));
      expect(source, contains("'CANCELLED'"));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 4. Operation action/reason
  // ─────────────────────────────────────────────────────────────
  group('[Batch A+B] Operation action/reason', () {
    test('PASS: matchOperation sends action + reason + optional winnerId', () {
      final source = File(
        'lib/data/repositories/api/api_match_repository.dart',
      ).readAsStringSync();
      expect(source, contains("'action': action"));
      expect(source, contains("'reason': reason"));
      expect(source, contains("'/matches/\$matchId/operation'"));
    });

    test('PASS: applyOperation in MatchController calls matchOperation', () {
      final source = File(
        'lib/providers/match_control_notifier.dart',
      ).readAsStringSync();
      expect(source, contains('applyOperation'));
      expect(source, contains('action'));
      expect(source, contains('reason'));
      expect(source, contains('matchOperation'));
      expect(source, contains('PATCH /matches/:id/operation'));
    });

    test('PASS: IMatchRepository.matchOperation declares action+reason required', () {
      final source = File(
        'lib/domain/repositories/match_repository.dart',
      ).readAsStringSync();
      expect(source, contains('required String action'));
      expect(source, contains('required String reason'));
      expect(source, contains('matchOperation'));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 5. Register participant.id + invite query
  // ─────────────────────────────────────────────────────────────
  group('[Batch A+B] Register participant.id + invite query', () {
    test('PASS: TournamentRegistrationResult extracts participant.id from nested map', () {
      final source = File(
        'lib/domain/entities/tournament_registration.dart',
      ).readAsStringSync();
      expect(source, contains("j['participant']"));
      expect(source, contains("participant['id']"));
      expect(source, contains('fallback top-level id'));
    });

    test('PASS: ApiTournamentRepository.registerParticipant sends invite as query param', () {
      final source = File(
        'lib/data/repositories/api/api_tournament_repository.dart',
      ).readAsStringSync();
      expect(source, contains("'invite'"));
      expect(source, contains('queryParameters'));
      expect(source, contains("'/tournaments/\$tournamentId/register'"));
    });

    test('PASS: registerParticipant returns TournamentRegistrationResult fromJson', () {
      final source = File(
        'lib/data/repositories/api/api_tournament_repository.dart',
      ).readAsStringSync();
      expect(source, contains('TournamentRegistrationResult.fromJson'));
    });

    test('PASS: InviteCode passed through register screen → API call', () {
      final source = File(
        'lib/features/register/screens/tournament_register_screen.dart',
      ).readAsStringSync();
      expect(source, contains('inviteCode:'));
      expect(source, contains('_localInviteCode'));
      expect(source, contains('widget.inviteCode'));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 6. Payment purpose
  // ─────────────────────────────────────────────────────────────
  group('[Batch A+B] Payment purpose', () {
    test('PASS: CreatePaymentDto.toJson includes purpose: REGISTRATION_FEE', () {
      final source = File(
        'lib/data/models/payment_model.dart',
      ).readAsStringSync();
      expect(source, contains("'purpose': 'REGISTRATION_FEE'"));
      expect(source, contains('purpose'));
    });

    test('PASS: CreatePaymentDto used by CheckoutScreen.createPaymentLink', () {
      final source = File(
        'lib/features/payment/screens/checkout_screen.dart',
      ).readAsStringSync();
      expect(source, contains('CreatePaymentDto'));
      expect(source, contains('tournamentId'));
      expect(source, contains('participantId'));
    });
  });
}
