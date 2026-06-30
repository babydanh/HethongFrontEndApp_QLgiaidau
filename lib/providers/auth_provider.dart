import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/entities/auth_session.dart';
import 'package:app_quanly_giaidau/providers/saved_tournaments_provider.dart';

// ─── Enums ───

enum AuthStatus { unauthenticated, validating, authenticated, invalid }

enum UserRole { admin, referee, viewer }

// ─── Auth State ───

class AuthState {
  final AuthStatus status;
  final UserRole? role;
  final String? tournamentId;
  final String? tokenCode;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.role,
    this.tournamentId,
    this.tokenCode,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserRole? role,
    String? tournamentId,
    String? tokenCode,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      role: role ?? this.role,
      tournamentId: tournamentId ?? this.tournamentId,
      tokenCode: tokenCode ?? this.tokenCode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isAdmin => role == UserRole.admin;
  bool get isReferee => role == UserRole.referee;
  bool get isViewer => role == UserRole.viewer;
  bool get canScore => isAdmin || isReferee;
}

// ─── Auth Notifier ───

class AuthNotifier extends Notifier<AuthState> {
  static const _log = AppLogger('AuthNotifier');

  StreamSubscription? _tokenSubscription;
  bool _initialized = false;

  @override
  AuthState build() {
    ref.onDispose(() {
      _tokenSubscription?.cancel();
    });
    if (!_initialized && ref.exists(tokenManagerProvider)) {
      _initialized = true;
      Future.microtask(() => init());
    }
    return const AuthState();
  }

  /// Khởi tạo: Kiểm tra JWT token hoặc token đã lưu
  Future<void> init() async {
    final tokenManager = ref.read(tokenManagerProvider);
    final hasJwt = await tokenManager.hasValidToken();
    if (hasJwt) {
      final roleStr = await tokenManager.getRole();
      final restoredRole = UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.viewer,
      );
      _log.success("Khôi phục phiên đăng nhập từ JWT token. Role: ${restoredRole.name}");
      state = AuthState(
        status: AuthStatus.authenticated,
        role: restoredRole,
        tokenCode: "SESSION",
      );
      return;
    }

    final savedToken = await ref.read(restoreSavedInviteTokenUseCaseProvider).call();
    if (savedToken != null && savedToken.isNotEmpty) {
      await validateToken(savedToken);
    }
  }

  /// Xác thực token
  Future<bool> validateToken(String tokenCode) async {
    _log.info('Bắt đầu xác thực token: ${tokenCode.substring(0, 3)}*** via NestJS API');
    state = state.copyWith(status: AuthStatus.validating);

    try {
      _log.debug('Đang truy vấn token từ API...');
      final token = await ref.read(validateInviteTokenUseCaseProvider).call(tokenCode);
      _log.debug('Truy vấn token hoàn tất. Kết quả: ${token?.id}');

      if (token == null) {
        state = AuthState(
          status: AuthStatus.invalid,
          errorMessage: 'Token không hợp lệ hoặc đã hết hạn',
        );
        return false;
      }

      // Xác định role
      final role = switch (token.role) {
        'admin' => UserRole.admin,
        'referee' => UserRole.referee,
        'viewer' => UserRole.viewer,
        _ => null,
      };

      if (role == null) {
        state = AuthState(
          status: AuthStatus.invalid,
          errorMessage: 'Vai trò không xác định',
        );
        return false;
      }

      await ref.read(saveInviteTokenUseCaseProvider).call(tokenCode);
      
      // Ghi nhớ giải đấu này vào session danh sách giải đấu của bạn
      await ref.read(savedTournamentsProvider.notifier).saveTournament(token.tournamentId, tokenCode, role.name);

      _log.success(
        'Xác thực thành công. Role: ${role.name}, Tournament: ${token.tournamentId}',
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        role: role,
        tournamentId: token.tournamentId,
        tokenCode: tokenCode,
      );

      _startTokenListener(tokenCode);
      return true;
    } catch (e, stack) {
      _log.error('Lỗi xác thực token', e, stack);
      state = AuthState(
        status: AuthStatus.invalid,
        errorMessage: 'Lỗi xác thực: ${e.toString()}',
      );
      return false;
    }
  }

  /// Đăng nhập trực tiếp (Dùng khi vừa tạo giải đấu xong)
  Future<void> loginLocally({
    required String tokenCode,
    required UserRole role,
    required String tournamentId,
  }) async {
    await ref.read(saveInviteTokenUseCaseProvider).call(tokenCode);
    
    // Lưu vào danh sách các giải đấu của mình
    await ref.read(savedTournamentsProvider.notifier).saveTournament(tournamentId, tokenCode, role.name);

    state = AuthState(
      status: AuthStatus.authenticated,
      role: role,
      tournamentId: tournamentId,
      tokenCode: tokenCode,
    );

    _startTokenListener(tokenCode);
  }

  Future<void> _saveJwtSession(AuthSession session, UserRole role) async {
    try {
      final tokenManager = ref.read(tokenManagerProvider);
      await tokenManager.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        role: role.name,
      );
      _log.success("JWT session saved to secure storage");
    } catch (e, stack) {
      _log.error("Failed to save JWT session", e, stack);
    }
  }

  /// Đăng nhập bằng Email & Mật khẩu
  Future<bool> loginWithEmailPassword(String email, String password) async {
    _log.info('Đăng nhập bằng email: $email via NestJS Mobile API');
    state = state.copyWith(status: AuthStatus.validating);

    try {
      final session = await ref.read(loginWithEmailUseCaseProvider).call(
            email: email,
            password: password,
          );
      final role = _mapSessionRole(session);
      await _saveJwtSession(session, role);
      state = AuthState(
        status: AuthStatus.authenticated,
        role: role,
        tokenCode: 'SESSION',
      );
      return true;
    } catch (e, stack) {
      _log.error('Lỗi đăng nhập', e, stack);
      state = AuthState(
        status: AuthStatus.invalid,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Đăng nhập bằng Google
  Future<bool> loginWithGoogle(String idToken) async {
    _log.info('Đăng nhập bằng Google via NestJS Mobile API');
    state = state.copyWith(status: AuthStatus.validating);

    try {
      final session = await ref.read(loginWithGoogleUseCaseProvider).call(
            idToken: idToken,
          );
      final role = _mapSessionRole(session);
      await _saveJwtSession(session, role);
      state = AuthState(
        status: AuthStatus.authenticated,
        role: role,
        tokenCode: 'SESSION',
      );
      return true;
    } catch (e, stack) {
      _log.error('Lỗi đăng nhập Google', e, stack);
      state = AuthState(
        status: AuthStatus.invalid,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Đăng ký tài khoản mới bằng Email & Mật khẩu
  Future<bool> registerWithEmailPassword(String email, String password, String fullName) async {
    _log.info('Đăng ký bằng email: $email via NestJS Mobile API');
    state = state.copyWith(status: AuthStatus.validating);

    try {
      final session = await ref.read(registerWithEmailUseCaseProvider).call(
            email: email,
            password: password,
            fullName: fullName,
          );
      final role = _mapSessionRole(session);
      await _saveJwtSession(session, role);
      state = AuthState(
        status: AuthStatus.authenticated,
        role: role,
        tokenCode: 'SESSION',
      );
      return true;
    } catch (e, stack) {
      _log.error('Lỗi đăng ký', e, stack);
      state = AuthState(
        status: AuthStatus.invalid,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  UserRole _mapSessionRole(AuthSession session) {
    if (session.roles.contains('ADMIN') || session.roles.contains('admin')) {
      return UserRole.admin;
    }
    if (session.roles.contains('REFEREE') ||
        session.roles.contains('referee')) {
      return UserRole.referee;
    }
    return UserRole.viewer;
  }

  void _startTokenListener(String tokenCode) {
    if (tokenCode == 'SESSION') return; // Không cần listen token của email session
    _tokenSubscription?.cancel();
    _tokenSubscription = ref.read(tokenRepositoryProvider).watchToken(tokenCode).listen((token) {
      if (token == null && state.isAuthenticated) {
        _log.warning(
          'Token $tokenCode đã bị vô hiệu hóa hoặc xóa. Tiến hành đăng xuất tự động.',
        );
        signOut(
          reason: 'Phiên đăng nhập đã hết hạn hoặc mã truy cập đã được đổi.',
        );
      }
    });
  }

  /// Đăng xuất
  Future<void> signOut({String? reason}) async {
    _tokenSubscription?.cancel();
    _tokenSubscription = null;
    await ref.read(clearSessionUseCaseProvider).call();
    state = AuthState(status: AuthStatus.unauthenticated, errorMessage: reason);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
