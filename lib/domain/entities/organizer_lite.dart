class OrganizerLiteReferee {
  final String id;
  final String userId;
  final String status;
  final String fullName;

  /// Null when the referee has no email (phone-only account); may be masked.
  final String? email;
  final String avatarUrl;

  const OrganizerLiteReferee({
    required this.id,
    required this.userId,
    required this.status,
    required this.fullName,
    this.email,
    required this.avatarUrl,
  });

  factory OrganizerLiteReferee.fromJson(Map<String, dynamic> json) {
    return OrganizerLiteReferee(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Trọng tài',
      email: _nonBlank(json['email']),
      avatarUrl: json['avatarUrl']?.toString() ?? '',
    );
  }

  bool get isAccepted => status.toUpperCase() == 'ACCEPTED';
  bool get isInvited => status.toUpperCase() == 'INVITED';
}

String? _nonBlank(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
