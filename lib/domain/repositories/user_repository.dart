import 'package:app_quanly_giaidau/domain/entities/user.dart';

abstract class IUserRepository {
  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile(Map<String, dynamic> data);
  Future<UserProfile> uploadAvatar(String filePath);
  Future<UserProfile> uploadCover(String filePath);
  Future<void> changePassword(String oldPassword, String newPassword);
}
