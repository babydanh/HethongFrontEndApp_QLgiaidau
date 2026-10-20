import 'package:app_quanly_giaidau/core/utils/bracket_generation_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bracket generation summary', () {
    test('reads unpaired names and auto pairs from envelope or flat body', () {
      final envelope = {
        'data': {
          'unpairedNames': ['An'],
          'autoPaired': [
            {
              'participantId': 'p1',
              'memberNames': ['Bình', 'Cường'],
            },
          ],
        },
      };
      expect(bracketUnpairedNames(envelope), ['An']);
      expect(bracketAutoPairedLabels(envelope), ['Bình / Cường']);

      final flat = {'unpairedNames': ['Dũng']};
      expect(bracketUnpairedNames(flat), ['Dũng']);
    });

    test('missing fields from an older server are empty, not an error', () {
      expect(bracketUnpairedNames(<String, dynamic>{}), isEmpty);
      expect(bracketAutoPairedLabels(null), isEmpty);
      expect(bracketAutoPairedLabels({'autoPaired': 'bad'}), isEmpty);
    });
  });
}
