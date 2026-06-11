extension RoleExtension on String {
  /// Full display name with emoji
  String toRoleDisplayName() {
    return switch (this) {
      'admin' => '👑 Ban Tổ Chức (Admin)',
      'referee' => '⚖️ Trọng Tài (Referee)',
      'viewer' => '👀 Khán Giả (Viewer)',
      _ => this,
    };
  }

  /// Short name without emoji
  String toRoleShortName() {
    return switch (this) {
      'admin' => 'Admin',
      'referee' => 'Trọng Tài',
      'viewer' => 'Viewer',
      _ => this,
    };
  }
}
