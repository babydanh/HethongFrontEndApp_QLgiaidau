class AuthSession {
  final String accessToken;
  final String refreshToken;
  final List<String> roles;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.roles = const [],
  });
}
