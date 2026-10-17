import 'package:app_quanly_giaidau/core/utils/pair_generation_summary.dart';
import 'package:app_quanly_giaidau/providers/lite_management_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

LiteParticipant _participant(Map<String, dynamic> json) =>
    LiteParticipant.fromJson(json);

void main() {
  group('LiteParticipant member count mirrors backend', () {
    test('BTC-added guest without roster is one athlete and waits for partner', () {
      final guest = _participant({
        'id': 'p1',
        'teamStatus': 'PENDING_PARTNER',
        'teamName': 'Nguyễn A',
        'customResponses': {
          'importedFrom': 'ORGANIZER_DIRECT',
          'player1Name': 'Nguyễn A',
        },
        'rosters': <Object>[],
      });
      expect(guest.memberCount, 1);
      expect(guest.isPending, isTrue);
      expect(guest.isComplete, isFalse);
    });

    test('organizer entry naming athlete 2 holds two athletes and is complete', () {
      final pair = _participant({
        'id': 'p2',
        'teamStatus': 'PENDING_APPROVAL',
        'customResponses': {
          'importedFrom': 'EXCEL',
          'player2Name': 'Trần B',
        },
        'rosters': <Object>[],
      });
      expect(pair.memberCount, 2);
      expect(pair.isComplete, isTrue);
      expect(pair.isPending, isFalse);
    });

    test('self-registered participant counts only its own rosters', () {
      final self = _participant({
        'id': 'p3',
        'teamStatus': 'PENDING_PARTNER',
        'customResponses': {'importedFrom': 'SELF'},
        'rosters': <Object>[],
      });
      expect(self.memberCount, 0);
      expect(self.isPending, isFalse);
    });

    test('participant with an invite token is never offered for organizer pairing', () {
      final invited = _participant({
        'id': 'p4',
        'teamStatus': 'PENDING_PARTNER',
        'teamInviteToken': 'tok',
        'customResponses': {'importedFrom': 'ORGANIZER_DIRECT'},
        'rosters': <Object>[],
      });
      expect(invited.isPending, isFalse);
    });
  });

  group('pairing messages', () {
    test('unpairedDisplayNames turns ids into names and keeps unknown ids visible', () {
      expect(unpairedDisplayNames(['a', 'b'], {'a': 'An'}), ['An', '#b']);
      expect(unpairedDisplayNames(['a'], {'a': '  '}), ['#a']);
      expect(unpairedDisplayNames([], {}), isEmpty);
    });

    test('participant keeps the division id the backend row carries', () {
      final participant = _participant({
        'id': 'p5',
        'teamStatus': 'PENDING_PARTNER',
        'tournamentDivisionId': 'd2',
        'customResponses': {'importedFrom': 'ORGANIZER_DIRECT'},
        'rosters': <Object>[],
      });
      expect(participant.tournamentDivisionId, 'd2');
    });
  });
}
