import 'package:app_quanly_giaidau/domain/entities/user.dart';

abstract class IUserRepository {
  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile(Map<String, dynamic> data);
  Future<UserProfile> uploadAvatar(List<int> bytes, String fileName);
  Future<UserProfile> uploadCover(List<int> bytes, String fileName);
  Future<void> changePassword(String oldPassword, String newPassword);

  /// Lấy hồ sơ công khai của người dùng khác.
  /// GET /users/:id/public
  Future<UserPublicProfile> getPublicProfile(String userId);

  /// Tìm kiếm người dùng (để mời vào CLB).
  /// GET /users/search?q=
  Future<List<UserSearchResult>> searchUsers(String query);
}
