import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_court_camera_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/court_camera_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final courtCameraRepositoryProvider = Provider<ICourtCameraRepository>((ref) {
  return ApiCourtCameraRepository(ref.watch(dioClientProvider));
});

/// Court cameras of one tournament.
///
/// Every mutation re-reads the list instead of patching it locally: the server
/// decides which camera a court ends up with (upsert on playback-url, automatic
/// reassignment when a match changes court), so a locally patched list would
/// drift from the truth.
class TournamentCamerasNotifier
    extends AsyncNotifier<List<TournamentCameraModel>> {
  final String tournamentId;
  TournamentCamerasNotifier(this.tournamentId);

  @override
  Future<List<TournamentCameraModel>> build() =>
      ref.read(courtCameraRepositoryProvider).listCameras(tournamentId);

  Future<void> refresh() async {
    // The previous list stays on screen until the re-read lands: blanking the
    // state first would make every saved court flash "no camera".
    state = await AsyncValue.guard(
      () => ref.read(courtCameraRepositoryProvider).listCameras(tournamentId),
    );
  }

  Future<String?> setCourtPlaybackUrl({
    required String courtId,
    required String playbackUrl,
  }) async {
    final cameraId = await ref
        .read(courtCameraRepositoryProvider)
        .setCourtPlaybackUrl(
          tournamentId: tournamentId,
          courtId: courtId,
          playbackUrl: playbackUrl,
        );
    await refresh();
    return cameraId;
  }

  Future<void> assignCamera({
    required String matchId,
    required String cameraId,
  }) async {
    await ref
        .read(courtCameraRepositoryProvider)
        .assignCamera(matchId: matchId, cameraId: cameraId);
    await refresh();
  }
}

final tournamentCamerasProvider =
    AsyncNotifierProvider.family<
      TournamentCamerasNotifier,
      List<TournamentCameraModel>,
      String
    >(TournamentCamerasNotifier.new);

/// Camera currently bound to [courtId], or null when the court has none.
TournamentCameraModel? cameraForCourt(
  List<TournamentCameraModel> cameras,
  String courtId,
) {
  for (final camera in cameras) {
    if (camera.courtId == courtId) return camera;
  }
  return null;
}
