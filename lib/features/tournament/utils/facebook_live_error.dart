import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';

enum FacebookLiveError {
  notConnected,
  expired,
  permission,
  pageNotEligible,
  network,
  unavailable,
  forbidden,
  generic,
}

/// Map lỗi tạo live Facebook như Web `facebookLiveErrorKey`.
FacebookLiveError facebookLiveError(Object error) {
  if (error is! DioException) return FacebookLiveError.generic;
  final response = error.response;
  if (response == null) return FacebookLiveError.network;
  final data = response.data;
  final code = data is Map ? data['code'] : null;
  switch (code) {
    case 'FACEBOOK_NOT_CONNECTED':
      return FacebookLiveError.notConnected;
    case 'FACEBOOK_CONNECTION_EXPIRED':
      return FacebookLiveError.expired;
    case 'FACEBOOK_PERMISSION_MISSING':
      return FacebookLiveError.permission;
    case 'FACEBOOK_PAGE_NOT_ELIGIBLE':
      return FacebookLiveError.pageNotEligible;
    case 'PROVIDER_UNAVAILABLE':
      return FacebookLiveError.unavailable;
  }
  final status = response.statusCode ?? 0;
  if (status == 403) return FacebookLiveError.forbidden;
  if (status >= 500) return FacebookLiveError.unavailable;
  return FacebookLiveError.generic;
}

String facebookLiveErrorText(AppLocalizations l10n, FacebookLiveError error) =>
    switch (error) {
      FacebookLiveError.notConnected => l10n.tournamentCameraFbErrorNotConnected,
      FacebookLiveError.expired => l10n.tournamentCameraFbErrorExpired,
      FacebookLiveError.permission => l10n.tournamentCameraFbErrorPermission,
      FacebookLiveError.pageNotEligible =>
        l10n.tournamentCameraFbErrorPageNotEligible,
      FacebookLiveError.network => l10n.tournamentCameraFbErrorNetwork,
      FacebookLiveError.unavailable => l10n.tournamentCameraFbErrorUnavailable,
      FacebookLiveError.forbidden => l10n.tournamentCameraFbErrorForbidden,
      FacebookLiveError.generic => l10n.tournamentCameraFbErrorGeneric,
    };

/// Fallback camera name when the user leaves the name empty: `Live Facebook HH:mm`.
String facebookLiveDefaultCameraName(DateTime now) {
  String two(int value) => value.toString().padLeft(2, '0');
  return 'Live Facebook ${two(now.hour)}:${two(now.minute)}';
}
