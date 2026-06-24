import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/repositories/token_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_token_repository.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
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
  static const _tokenKey = 'saved_token';

  StreamSubscription? _tokenSubscription;

  @override
  AuthState build() {
    ref.onDispose(() {
      _tokenSubscription?.cancel();
    });
    return const AuthState();
  }

  ITokenRepository get _tokenRepository => ref.read(tokenRepositoryProvider);

  /// Khởi tạo: Kiểm tra token đã lưu
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);

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
      final token = await _tokenRepository.validateToken(tokenCode);
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

      // Lưu token vào local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, tokenCode);
      
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, tokenCode);
    
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

  /// Phân tích thông báo lỗi từ NestJS (có thể là String hoặc List)
  String _parseNestJsError(dynamic responseData, String fallback) {
    if (responseData == null) return fallback;
    final rawMessage = responseData['message'];
    String msg;
    if (rawMessage is List && rawMessage.isNotEmpty) {
      msg = rawMessage.first.toString();
    } else if (rawMessage is String) {
      msg = rawMessage;
    } else {
      return fallback;
    }
    // Map một số thông báo tiếng Anh sang tiếng Việt
    const viMap = {
      'Email already exists': 'Email này đã được đăng ký. Vui lòng dùng email khác hoặc đăng nhập.',
      'email should not be empty': 'Vui lòng nhập địa chỉ email.',
      'email must be an email': 'Địa chỉ email không hợp lệ.',
      'password must be longer than or equal to 6 characters': 'Mật khẩu phải có ít nhất 6 ký tự.',
      'password should not be empty': 'Vui lòng nhập mật khẩu.',
      'fullName should not be empty': 'Vui lòng nhập họ và tên.',
      'Invalid credentials': 'Email hoặc mật khẩu không đúng.',
      'Tài khoản này được đăng ký qua Google. Vui lòng đăng nhập bằng Google.': 'Tài khoản này đã đăng ký qua Google. Vui lòng đăng nhập bằng Google.',
    };
    return viMap[msg] ?? msg;
  }

  /// Đăng nhập bằng Email & Mật khẩu
  Future<bool> loginWithEmailPassword(String email, String password) async {
    _log.info('Đăng nhập bằng email: $email via NestJS Mobile API');
    state = state.copyWith(status: AuthStatus.validating);

    try {
      final response = await ref.read(dioClientProvider).dio.post(
        '/auth/mobile/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        // NestJS trả về { statusCode, message, data: { accessToken, refreshToken, user } }
        final innerData = data['data'] as Map<String, dynamic>? ?? data as Map<String, dynamic>;
        final accessToken = innerData['accessToken'] as String?;
        final refreshToken = innerData['refreshToken'] as String?;
        
        if (accessToken != null && refreshToken != null) {
          await ref.read(tokenManagerProvider).saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );

          // Lấy roles từ user data
          final userMap = innerData['user'] as Map<String, dynamic>?;
          final userRolesList = userMap?['roles'] as List<dynamic>? ?? [];
          UserRole role = UserRole.viewer;
          if (userRolesList.contains('ADMIN') || userRolesList.contains('admin')) {
            role = UserRole.admin;
          } else if (userRolesList.contains('REFEREE') || userRolesList.contains('referee')) {
            role = UserRole.referee;
          }
          // PLAYER, USER, hoặc bất kỳ role khác → viewer (mặc định)

          state = AuthState(
            status: AuthStatus.authenticated,
            role: role,
            tokenCode: 'SESSION',
          );
          return true;
        }
      }
      
      state = const AuthState(
        status: AuthStatus.invalid,
        errorMessage: 'Không tìm thấy thông tin xác thực trong phản hồi',
      );
      return false;
    } catch (e, stack) {
      _log.error('Lỗi đăng nhập', e, stack);
      String errMsg = 'Lỗi kết nối đến máy chủ';
      if (e is DioException) {
        errMsg = _parseNestJsError(e.response?.data, e.message ?? errMsg);
      }
      state = AuthState(
        status: AuthStatus.invalid,
        errorMessage: errMsg,
      );
      return false;
    }
  }

  /// Đăng ký tài khoản mới bằng Email & Mật khẩu
  Future<bool> registerWithEmailPassword(String email, String password, String fullName) async {
    _log.info('Đăng ký bằng email: $email via NestJS Mobile API');
    state = state.copyWith(status: AuthStatus.validating);

    try {
      final response = await ref.read(dioClientProvider).dio.post(
        '/auth/mobile/register',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Tự động đăng nhập sau khi đăng ký thành công
        return await loginWithEmailPassword(email, password);
      }
      
      state = const AuthState(
        status: AuthStatus.invalid,
        errorMessage: 'Đăng ký không thành công. Vui lòng thử lại.',
      );
      return false;
    } catch (e, stack) {
      _log.error('Lỗi đăng ký', e, stack);
      String errMsg = 'Lỗi kết nối đến máy chủ';
      if (e is DioException) {
        errMsg = _parseNestJsError(e.response?.data, e.message ?? errMsg);
      }
      state = AuthState(
        status: AuthStatus.invalid,
        errorMessage: errMsg,
      );
      return false;
    }
  }

  void _startTokenListener(String tokenCode) {
    if (tokenCode == 'SESSION') return; // Không cần listen token của email session
    _tokenSubscription?.cancel();
    _tokenSubscription = _tokenRepository.watchToken(tokenCode).listen((token) {
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await ref.read(tokenManagerProvider).clearTokens();
    state = AuthState(status: AuthStatus.unauthenticated, errorMessage: reason);
  }
}

// ─── Token Repository Provider kết nối tới API ───

final tokenRepositoryProvider = Provider<ITokenRepository>((ref) {
  return ApiTokenRepository(ref.watch(dioClientProvider));
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
