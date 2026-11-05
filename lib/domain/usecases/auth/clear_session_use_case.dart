import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/repositories/auth_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/session_repository.dart';

/// Đăng xuất: huỷ device token và thu hồi refresh token phía server (best
/// effort, timeout ngắn) TRƯỚC khi xoá phiên cục bộ. Lỗi mạng không chặn đăng
/// xuất.
class ClearSessionUseCase {
  static const _log = AppLogger('ClearSession');
  static const _remoteTimeout = Duration(seconds: 5);

  final ISessionRepository _sessionRepository;
  final IAuthRepository? _authRepository;
  final Future<String?> Function()? _readRefreshToken;
  final Future<void> Function()? _unregisterDevice;

  ClearSessionUseCase(
    this._sessionRepository, {
    IAuthRepository? authRepository,
    Future<String?> Function()? readRefreshToken,
    Future<void> Function()? unregisterDevice,
  })  : _authRepository = authRepository,
        _readRefreshToken = readRefreshToken,
        _unregisterDevice = unregisterDevice;

  Future<void> call() async {
    // Song song để tối đa ~5s thay vì ~10s; cả hai xong mới xoá phiên cục bộ.
    await Future.wait([
      _bestEffort('unregisterDevice', () async => _unregisterDevice?.call()),
      _bestEffort('revokeRefreshToken', _revokeRefreshToken),
    ]);
    await _sessionRepository.clearInviteToken();
    await _sessionRepository.clearAuthTokens();
  }

  Future<void> _revokeRefreshToken() async {
    final token = await _readRefreshToken?.call();
    if (token == null || token.isEmpty) return;
    await _authRepository?.logout(refreshToken: token);
  }

  Future<void> _bestEffort(
    String name,
    Future<void> Function() action,
  ) async {
    try {
      await action().timeout(_remoteTimeout);
    } catch (e, stack) {
      // Server không tới được thì vẫn xoá phiên cục bộ.
      _log.error('Logout bước $name lỗi, bỏ qua', e, stack);
    }
  }
}
