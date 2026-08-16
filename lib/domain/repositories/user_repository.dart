import 'package:app_quanly_giaidau/domain/entities/user.dart';

/// Tỉnh/thành phục vụ chọn khu vực tranh tài. GET /regions/provinces
class ProvinceOption {
  final String code;
  final String name;
  const ProvinceOption({required this.code, required this.name});
}

abstract class IUserRepository {
  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile(Map<String, dynamic> data);
  Future<UserProfile> uploadAvatar(List<int> bytes, String fileName);
  Future<UserProfile> uploadCover(List<int> bytes, String fileName);
  Future<void> changePassword(String oldPassword, String newPassword);

  /// Xóa tài khoản hiện tại. POST /users/delete-account
  Future<void> deleteAccount(String password);

  /// Gửi yêu cầu đổi dữ liệu bị khóa (VD: giới tính). POST /users/change-requests
  Future<void> createChangeRequest({required String requestType, required String newValue});

  /// Danh sách tỉnh/thành. GET /regions/provinces
  Future<List<ProvinceOption>> getProvinces();

  /// Lấy hồ sơ công khai của người dùng khác.
  /// GET /users/:id/public
  Future<UserPublicProfile> getPublicProfile(String userId);

  /// Tìm kiếm người dùng (để mời vào CLB).
  /// GET /users/search?q=
  Future<List<UserSearchResult>> searchUsers(String query);
}
