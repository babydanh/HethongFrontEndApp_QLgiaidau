import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/presence_service.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/domain/repositories/token_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/firebase/firebase_token_repository.dart';
import 'package:app_quanly_giaidau/providers/saved_tournaments_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);
  PresenceService get _presence => ref.read(presenceServiceProvider);

  /// Khởi tạo: Kiểm tra token đã lưu
  Future<void> init() async {
    // Luôn đảm bảo người dùng có một tài khoản ẩn danh để có quyền đọc Firestore public
    if (_auth.currentUser == null) {
      _log.debug('Khởi tạo: Gọi signInAnonymously()');
      await _auth.signInAnonymously();
    }

    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);

    if (savedToken != null && savedToken.isNotEmpty) {
      await validateToken(savedToken);
    }
  }

  /// Xác thực token
  Future<bool> validateToken(String tokenCode) async {
    _log.info('Bắt đầu xác thực token: ${tokenCode.substring(0, 3)}***');
    state = state.copyWith(status: AuthStatus.validating);

    try {
      // Đăng nhập anonymous nếu chưa
      if (_auth.currentUser == null) {
        _log.debug('Gọi signInAnonymously()');
        await _auth.signInAnonymously();
        _log.success('signInAnonymously() thành công');
      } else {
        _log.debug('Đã đăng nhập anonymous');
      }

      _log.debug('Đang truy vấn token từ Firestore...');
      // Query token từ Firestore
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

      // Lưu device vào authorized_users
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await ref.read(firestoreProvider)
              .collection(AppConstants.collectionTournaments)
              .doc(token.tournamentId)
              .collection('authorized_users')
              .doc(user.uid)
              .set({
            'role': role.name,
            'tokenCode': tokenCode.toUpperCase().trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          _log.warning('Không thể ghi authorized_users (có thể do quyền Firestore hoặc offline): $e');
        }
      }

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
      _presence.goOnline(tournamentId: token.tournamentId, role: role.name);
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

    // Lưu device vào authorized_users
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await ref.read(firestoreProvider)
            .collection(AppConstants.collectionTournaments)
            .doc(tournamentId)
            .collection('authorized_users')
            .doc(user.uid)
            .set({
          'role': role.name,
          'tokenCode': tokenCode.toUpperCase().trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        _log.warning('Không thể ghi authorized_users (có thể offline): $e');
      }
    }

    state = AuthState(
      status: AuthStatus.authenticated,
      role: role,
      tournamentId: tournamentId,
      tokenCode: tokenCode,
    );

    _startTokenListener(tokenCode);
    _presence.goOnline(tournamentId: tournamentId, role: role.name);
  }

  void _startTokenListener(String tokenCode) {
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
    await _presence.goOffline();
    _tokenSubscription?.cancel();
    _tokenSubscription = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    state = AuthState(status: AuthStatus.unauthenticated, errorMessage: reason);
  }
}

// ─── Providers ───

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final tokenRepositoryProvider = Provider<ITokenRepository>((ref) {
  return FirebaseTokenRepository(ref.watch(firestoreProvider));
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
