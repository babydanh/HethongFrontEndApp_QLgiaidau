import 'package:app_quanly_giaidau/domain/repositories/auth_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/session_repository.dart';

/// Đăng xuất: huỷ device token và thu hồi refresh token phía server (best
/// effort, timeout ngắn) TRƯỚC khi xoá phiên cục bộ. Lỗi mạng không chặn đăng
/// xuất.
class ClearSessionUseCase {
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
    await _bestEffort(() async => _unregisterDevice?.call());
    await _bestEffort(_revokeRefreshToken);
    await _sessionRepository.clearInviteToken();
    await _sessionRepository.clearAuthTokens();
  }

  Future<void> _revokeRefreshToken() async {
    final token = await _readRefreshToken?.call();
    if (token == null || token.isEmpty) return;
    await _authRepository?.logout(refreshToken: token);
  }

  Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action().timeout(_remoteTimeout);
    } catch (_) {
      // Server không tới được thì vẫn xoá phiên cục bộ.
    }
  }
}
