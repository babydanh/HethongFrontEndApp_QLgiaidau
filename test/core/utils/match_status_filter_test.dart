import 'package:app_quanly_giaidau/core/utils/match_status_filter.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match(String status, {DateTime? completedAt}) => MatchModel(
  id: 'm',
  round: 1,
  matchNumber: 1,
  status: status,
  completedAt: completedAt,
  bracketPosition: const BracketPosition(bracket: 'winners', round: 1, position: 0),
  updatedAt: DateTime(2026, 11, 1),
);

void main() {
  group('MatchStatusFilter.parse', () {
    test('maps the home tab keys', () {
      expect(MatchStatusFilter.parse('live'), MatchStatusFilter.live);
      expect(MatchStatusFilter.parse('scheduled'), MatchStatusFilter.scheduled);
      expect(MatchStatusFilter.parse('completed'), MatchStatusFilter.completed);
      expect(MatchStatusFilter.parse('all'), MatchStatusFilter.all);
    });

    test('falls back to all for an unknown key', () {
      expect(MatchStatusFilter.parse('registration'), MatchStatusFilter.all);
      expect(MatchStatusFilter.parse(''), MatchStatusFilter.all);
    });
  });

  group('MatchStatusFilter.toServerParam', () {
    test('sends the backend enum names and nothing for all', () {
      expect(MatchStatusFilter.live.toServerParam(), 'ONGOING');
      expect(MatchStatusFilter.scheduled.toServerParam(), 'SCHEDULED');
      expect(MatchStatusFilter.completed.toServerParam(), 'COMPLETED');
      expect(MatchStatusFilter.all.toServerParam(), isNull);
    });
  });

  group('MatchStatusFilter.accepts', () {
    test('live accepts only live matches', () {
      expect(MatchStatusFilter.live.accepts(_match('live')), isTrue);
      expect(MatchStatusFilter.live.accepts(_match('scheduled')), isFalse);
      expect(MatchStatusFilter.live.accepts(_match('completed')), isFalse);
    });

    test('completed accepts every ended alias and a match with completedAt', () {
      for (final s in ['completed', 'COMPLETED', 'FINISHED', 'DONE', 'ENDED']) {
        expect(MatchStatusFilter.completed.accepts(_match(s)), isTrue, reason: s);
      }
      expect(
        MatchStatusFilter.completed.accepts(
          _match('scheduled', completedAt: DateTime(2026, 11, 1)),
        ),
        isTrue,
      );
      expect(MatchStatusFilter.completed.accepts(_match('live')), isFalse);
    });

    test('scheduled rejects live and completed matches', () {
      expect(MatchStatusFilter.scheduled.accepts(_match('scheduled')), isTrue);
      expect(MatchStatusFilter.scheduled.accepts(_match('live')), isFalse);
      expect(MatchStatusFilter.scheduled.accepts(_match('completed')), isFalse);
    });

    test('all accepts any match', () {
      for (final s in ['live', 'scheduled', 'completed', 'walkover']) {
        expect(MatchStatusFilter.all.accepts(_match(s)), isTrue, reason: s);
      }
    });
  });
}
