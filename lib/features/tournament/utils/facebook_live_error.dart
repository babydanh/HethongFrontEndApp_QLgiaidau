import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:dio/dio.dart';

enum FacebookLiveError {
  notConnected,
  expired,
  permission,
  network,
  unavailable,
  forbidden,
  browser,
  generic,
}

/// Map lỗi tạo/kết nối live Facebook như Web `facebookLiveErrorKey`.
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
      FacebookLiveError.network => l10n.tournamentCameraFbErrorNetwork,
      FacebookLiveError.unavailable => l10n.tournamentCameraFbErrorUnavailable,
      FacebookLiveError.forbidden => l10n.tournamentCameraFbErrorForbidden,
      FacebookLiveError.browser => l10n.tournamentCameraFbErrorBrowser,
      FacebookLiveError.generic => l10n.tournamentCameraFbErrorGeneric,
    };
