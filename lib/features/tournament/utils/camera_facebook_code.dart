import 'package:app_quanly_giaidau/data/models/camera_patch.dart';
import 'package:app_quanly_giaidau/data/models/court_camera_model.dart';
import 'package:app_quanly_giaidau/features/match/utils/live_embed.dart';
import 'package:dio/dio.dart';

/// Backend error code of `GET /livestream/cameras/:id/facebook-live` once the
/// stored code is older than its retention window.
const facebookLiveCodeExpiredCode = 'FACEBOOK_LIVE_CODE_EXPIRED';

/// "Xem mã phát" is only offered for a camera whose playback URL is a
/// Facebook live link (same parser the camera editor uses).
bool canViewFacebookCode(TournamentCameraModel camera) =>
    LiveEmbed.parse(camera.playbackUrl).platform == LiveEmbedPlatform.facebook;

/// A fresh code replaces the playback URL, which the backend refuses while the
/// camera is LIVE or when the URL is not editable.
bool canRegenerateFacebookCode(TournamentCameraModel camera) =>
    camera.playbackUrlEditable && camera.status != 'LIVE';

bool isFacebookLiveCodeExpired(Object error) {
  if (error is! DioException) return false;
  final data = error.response?.data;
  return data is Map && data['code'] == facebookLiveCodeExpiredCode;
}

/// Mirrors Web `buildCameraPatch`: blank or unchanged fields are left out, and
/// the URL is left out when the backend does not allow editing it.
CameraPatch buildCameraPatch(
  TournamentCameraModel original, {
  required String name,
  required String playbackUrl,
}) {
  final newName = name.trim();
  final newUrl = playbackUrl.trim();
  return CameraPatch(
    name: newName.isNotEmpty && newName != original.name ? newName : null,
    playbackUrl:
        original.playbackUrlEditable &&
            newUrl.isNotEmpty &&
            newUrl != (original.playbackUrl ?? '')
        ? newUrl
        : null,
  );
}
