import 'package:app_quanly_giaidau/core/utils/pair_generation_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pairGeneratedLabels', () {
    test('joins each pair member names with " & " from envelope body', () {
      final raw = {
        'status': 'OK',
        'data': {
          'paired': [
            {'participantId': 'p1', 'memberNames': ['An', 'Bình']},
            {'participantId': 'p2', 'memberNames': ['Cường', 'Dũng']},
          ],
        },
      };
      expect(pairGeneratedLabels(raw), ['An & Bình', 'Cường & Dũng']);
    });

    test('reads flat body and skips missing or blank members', () {
      expect(
        pairGeneratedLabels({
          'paired': [
            {
              'memberNames': ['An', '  '],
            },
            {'memberNames': <String>[]},
          ],
        }),
        ['An'],
      );
      expect(pairGeneratedLabels({'message': 'ok'}), isEmpty);
      expect(pairGeneratedLabels(null), isEmpty);
    });
  });

  group('pairUnpairedNames', () {
    test('prefers unpairedNames sent by the server', () {
      expect(
        pairUnpairedNames(
          {
            'unpairedNames': ['Eva'],
            'unpairedParticipantIds': ['p9'],
          },
          {'p9': 'Khác'},
        ),
        ['Eva'],
      );
    });

    test('maps unpairedParticipantIds to names when names are absent', () {
      expect(
        pairUnpairedNames(
          {
            'data': {
              'unpairedParticipantIds': ['a', 'b'],
            },
          },
          {'a': 'An'},
        ),
        ['An', '#b'],
      );
    });

    test('is empty when nobody is left unpaired', () {
      expect(
        pairUnpairedNames(
          {'unpairedParticipantIds': [], 'unpairedNames': []},
          {},
        ),
        isEmpty,
      );
    });
  });
}
