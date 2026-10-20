import 'package:app_quanly_giaidau/data/models/match_playback_model.dart';
import 'package:app_quanly_giaidau/features/match/widgets/match_replay_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _segment({
  required String name,
  required String url,
  required int offset,
  required int duration,
  int clipStart = 0,
}) => <String, Object?>{
  'name': name,
  'url': url,
  'startAt': '2026-10-20T14:49:08+07:00',
  'offsetSec': offset,
  'clipStartSec': clipStart,
  'durationSec': duration,
};

void main() {
  group('MatchReplay.fromJson', () {
    test(
      'parse safely, drop invalid URLs and order valid segments by offset',
      () {
        final replay = MatchReplay.fromJson(<String, Object?>{
          'matchId': 'match-1',
          'available': true,
          'reason': null,
          'startedAt': '2026-10-20T14:49:08+07:00',
          'endedAt': null,
          'durationSec': 90,
          'segments': <Object?>[
            _segment(
              name: 'second.mp4',
              url: 'https://media.example.test/second.mp4',
              offset: 60,
              duration: 30,
            ),
            _segment(name: 'missing.mp4', url: '', offset: 0, duration: 60),
            _segment(
              name: 'first.mp4',
              url: 'https://media.example.test/first.mp4',
              offset: 0,
              duration: 60,
            ),
            _segment(
              name: 'insecure.mp4',
              url: 'http://media.example.test/insecure.mp4',
              offset: 0,
              duration: 60,
            ),
            'not-a-map',
          ],
        });

        expect(replay.available, isTrue);
        expect(replay.segments.map((segment) => segment.name), [
          'first.mp4',
          'second.mp4',
        ]);
        expect(replay.durationSec, 90);
        expect(() => replay.segments.clear(), throwsUnsupportedError);
      },
    );

    test('empty or malformed segments make replay unavailable safely', () {
      final replay = MatchReplay.fromJson(<String, Object?>{
        'available': true,
        'durationSec': 'invalid',
        'segments': <Object?>[
          <String, Object?>{'name': 'no-url.mp4', 'durationSec': 12},
        ],
      });

      expect(replay.available, isFalse);
      expect(replay.durationSec, 0);
      expect(replay.segments, isEmpty);
    });
  });

  group('matchReplayPositionAt', () {
    final segments = <MatchReplaySegment>[
      MatchReplaySegment.tryParse(
        _segment(
          name: 'a.mp4',
          url: 'https://media.example.test/a.mp4',
          offset: 0,
          duration: 120,
        ),
      )!,
      MatchReplaySegment.tryParse(
        _segment(
          name: 'b.mp4',
          url: 'https://media.example.test/b.mp4',
          offset: 120,
          duration: 90,
        ),
      )!,
    ];

    test('maps start, exact boundary, interior, and end boundary', () {
      expect(
        matchReplayPositionAt(segments, 0),
        const MatchReplayPosition(segmentIndex: 0, offsetSec: 0),
      );
      expect(
        matchReplayPositionAt(segments, 119),
        const MatchReplayPosition(segmentIndex: 0, offsetSec: 119),
      );
      expect(
        matchReplayPositionAt(segments, 120),
        const MatchReplayPosition(segmentIndex: 1, offsetSec: 0),
      );
      expect(
        matchReplayPositionAt(segments, 160),
        const MatchReplayPosition(segmentIndex: 1, offsetSec: 40),
      );
      expect(
        matchReplayPositionAt(segments, 210),
        const MatchReplayPosition(segmentIndex: 1, offsetSec: 90),
      );
      expect(
        matchReplayPositionAt(segments, -10),
        const MatchReplayPosition(segmentIndex: 0, offsetSec: 0),
      );
    });

    test('maps a segment offset back to the global timeline', () {
      final position = matchReplayPositionAt(segments, 145)!;
      expect(position.segmentIndex, 1);
      expect(matchReplayGlobalSeconds(position, segments), 145);
    });

    test('seeks past leading clip footage and stops at the estimated end', () {
      final clipSegments = <MatchReplaySegment>[
        MatchReplaySegment.tryParse(
          _segment(
            name: 'first.mp4',
            url: 'https://media.example.test/first.mp4',
            offset: 0,
            clipStart: 8,
            duration: 120,
          ),
        )!,
        MatchReplaySegment.tryParse(
          _segment(
            name: 'last.mp4',
            url: 'https://media.example.test/last.mp4',
            offset: 120,
            clipStart: 15,
            duration: 30,
          ),
        )!,
      ];
      final first = clipSegments.first;
      final last = clipSegments.last;
      final start = matchReplayPositionAt(clipSegments, 0)!;
      final lastEnd = matchReplayPositionAt(clipSegments, 150)!;

      expect(matchReplayMediaSeconds(first, start.offsetSec), 8);
      expect(matchReplayGlobalSeconds(start, clipSegments), 0);
      expect(matchReplaySegmentReachedEnd(last, 44), isFalse);
      expect(matchReplaySegmentReachedEnd(last, 45), isTrue);
      expect(matchReplayGlobalSeconds(lastEnd, clipSegments), 150);
    });

    test('returns null when there are no segments', () {
      expect(matchReplayPositionAt(const [], 10), isNull);
    });
  });
}
