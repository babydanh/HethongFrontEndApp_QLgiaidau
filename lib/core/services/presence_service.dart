import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';

class PresenceService {
  static const _log = AppLogger('PresenceService');
  final FirebaseDatabase _db;
  
  // Tạo 1 ID ngẫu nhiên cho mỗi phiên bật app
  final String _sessionId = const Uuid().v4();
  DatabaseReference? _currentPresenceRef;

  PresenceService(this._db);

  /// Báo cáo thiết bị đang online vào Realtime Database
  Future<void> goOnline({
    required String tournamentId,
    required String role,
  }) async {
    try {
      // Hủy cái cũ nếu có
      await goOffline();

      // Đường dẫn lưu trữ: /tournaments_presence/tournamentId/role/sessionId
      _currentPresenceRef = _db.ref('tournaments_presence/$tournamentId/$role/$_sessionId');
      
      // Đăng ký hành động tự động xóa node này khi mất kết nối internet / app crash
      await _currentPresenceRef!.onDisconnect().remove();
      
      // Set giá trị thành true
      await _currentPresenceRef!.set(true);
      _log.info('Thiết lập Online Presence thành công (Session: $_sessionId, Role: $role)');
    } catch (e, stack) {
      _log.error('Lỗi thiết lập Online Presence', e, stack);
    }
  }

  /// Gọi khi user chủ động đăng xuất hoặc đổi giải
  Future<void> goOffline() async {
    try {
      if (_currentPresenceRef != null) {
        // Hủy onDisconnect hook
        await _currentPresenceRef!.onDisconnect().cancel();
        // Xóa data hiện tại
        await _currentPresenceRef!.remove();
        _currentPresenceRef = null;
        _log.info('Đã set Offline thành công');
      }
    } catch (e, stack) {
      _log.error('Lỗi thiết lập Offline', e, stack);
    }
  }

  /// Lắng nghe số lượng người đang online theo role
  Stream<int> watchOnlineCount(String tournamentId, String role) {
    final ref = _db.ref('tournaments_presence/$tournamentId/$role');
    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return 0;
      if (data is Map) return data.length;
      return 0;
    });
  }
}

// ─── Providers ───
final firebaseDatabaseProvider = Provider<FirebaseDatabase>((ref) {
  return FirebaseDatabase.instance;
});

final presenceServiceProvider = Provider<PresenceService>((ref) {
  return PresenceService(ref.watch(firebaseDatabaseProvider));
});
