import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

/// Backend trả `role` = phần tử đầu của danh sách vai trò theo thứ tự hàng DB
/// (`users.repository.ts`: `role: rolesList[0] || 'PLAYER'`), nên một BTC có thể
/// có `role = PLAYER` còn `roles` chứa ORGANIZER. Kiểm quyền phải dùng `hasRole`.
void main() {
  group('UserProfile.hasRole (F2: không kiểm riêng trường role)', () {
    test('BTC có role=PLAYER nhưng roles chứa ORGANIZER vẫn có quyền BTC', () {
      final profile = UserProfile.fromJson({
        'id': 'organizer-1',
        'role': 'PLAYER',
        'roles': ['PLAYER', 'ORGANIZER'],
      });

      expect(profile.hasRole('ORGANIZER'), isTrue);
      expect(profile.hasRole('ADMIN'), isFalse);
    });

    test('VĐV chỉ có PLAYER không được coi là BTC', () {
      final profile = UserProfile.fromJson({
        'id': 'player-1',
        'role': 'PLAYER',
        'roles': ['PLAYER'],
      });

      expect(profile.hasRole('ORGANIZER'), isFalse);
    });

    test('so khớp không phân biệt hoa thường và khoảng trắng', () {
      final profile = UserProfile.fromJson({
        'id': 'admin-1',
        'role': ' admin ',
        'roles': <String>[],
      });

      expect(profile.hasRole('ADMIN'), isTrue);
    });
  });
}
