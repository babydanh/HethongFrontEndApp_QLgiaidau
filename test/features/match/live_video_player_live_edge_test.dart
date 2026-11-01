import 'package:app_quanly_giaidau/features/match/widgets/live_video_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TC-LIVEFS-05 behind live only past the threshold', () {
    expect(
      isBehindLive(
        position: const Duration(seconds: 88),
        duration: const Duration(seconds: 100),
      ),
      isTrue,
    );
    expect(
      isBehindLive(
        position: const Duration(seconds: 96),
        duration: const Duration(seconds: 100),
      ),
      isFalse,
    );
  });

  test('TC-LIVEFS-06 unknown duration is never behind live', () {
    expect(
      isBehindLive(position: const Duration(seconds: 5), duration: Duration.zero),
      isFalse,
    );
  });
}
