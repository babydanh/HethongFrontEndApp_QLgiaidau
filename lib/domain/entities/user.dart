class UserProfile {
  final String id;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? provinceCode;
  final bool? isEmailVerified;
  final bool? isPhoneVerified;
  final bool? isGenderLocked;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? role;
  final int? eloPoints;
  final String? tierName;

  const UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.provinceCode,
    this.isEmailVerified,
    this.isPhoneVerified,
    this.isGenderLocked,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.role,
    this.eloPoints,
    this.tierName,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // NestJS BE trả profile fields trong `profile` object lồng nhau
    // Top-level: id, email, isEmailVerified, isPhoneVerified, role, roles, createdAt
    // Nested profile: fullName, avatarUrl, coverUrl, phoneNumber, dateOfBirth, gender, address, bio, provinceCode, etc.
    // Handle cả 2 cấu trúc (phẳng hoặc lồng) để linh hoạt
    final p = <String, dynamic>{};
    p.addAll(json);
    final nestedProfile = json['profile'];
    if (nestedProfile is Map<String, dynamic>) {
      // Merge fields từ profile lên cùng cấp (fields ở top-level giữ nguyên)
      nestedProfile.forEach((k, v) {
        p.putIfAbsent(k, () => v);
      });
    }

    return UserProfile(
      id: p['id']?.toString() ?? '',
      fullName: p['fullName']?.toString(),
      email: p['email']?.toString(),
      avatarUrl: p['avatarUrl']?.toString(),
      coverUrl: p['coverUrl']?.toString(),
      bio: p['bio']?.toString(),
      phoneNumber: p['phoneNumber']?.toString(),
      dateOfBirth: p['dateOfBirth']?.toString(),
      gender: p['gender']?.toString(),
      address: p['address']?.toString(),
      provinceCode: p['provinceCode']?.toString(),
      isEmailVerified: _parseBool(p['isEmailVerified']),
      isPhoneVerified: _parseBool(p['isPhoneVerified']),
      isGenderLocked: _parseBool(p['isGenderLocked']),
      bankName: p['bankName']?.toString(),
      bankAccountNumber: p['bankAccountNumber']?.toString(),
      bankAccountName: p['bankAccountName']?.toString(),
      role: p['role']?.toString(),
      eloPoints: _parseInt(p['eloPoints']),
      tierName: p['tierName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (bio != null) 'bio': bio,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (address != null) 'address': address,
      if (provinceCode != null) 'provinceCode': provinceCode,
      if (isEmailVerified != null) 'isEmailVerified': isEmailVerified,
      if (isPhoneVerified != null) 'isPhoneVerified': isPhoneVerified,
      if (isGenderLocked != null) 'isGenderLocked': isGenderLocked,
      if (bankName != null) 'bankName': bankName,
      if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
      if (bankAccountName != null) 'bankAccountName': bankAccountName,
      if (role != null) 'role': role,
      if (eloPoints != null) 'eloPoints': eloPoints,
      if (tierName != null) 'tierName': tierName,
    };
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? provinceCode,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isGenderLocked,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    String? role,
    int? eloPoints,
    String? tierName,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      provinceCode: provinceCode ?? this.provinceCode,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isGenderLocked: isGenderLocked ?? this.isGenderLocked,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      role: role ?? this.role,
      eloPoints: eloPoints ?? this.eloPoints,
      tierName: tierName ?? this.tierName,
    );
  }

  @override
  String toString() => 'UserProfile(id: $id, fullName: $fullName, email: $email)';

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// Hồ sơ công khai của người dùng (GET /users/:id/public).
class UserPublicProfile {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? coverUrl;
  final String? gender;
  final String? bio;
  final bool isVerified;
  final List<UserPublicRank> ranks;

  const UserPublicProfile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.coverUrl,
    this.gender,
    this.bio,
    this.isVerified = false,
    this.ranks = const [],
  });

  factory UserPublicProfile.fromJson(Map<String, dynamic> json) {
    return UserPublicProfile(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      isVerified: json['isVerified'] == true,
      ranks: (json['ranks'] as List<dynamic>?)
              ?.map((e) => UserPublicRank.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class UserPublicRank {
  final String categoryId;
  final String categoryName;
  final int eloPoints;
  final String? tierName;
  final int matchesPlayed;
  final int matchesWon;

  const UserPublicRank({
    required this.categoryId,
    required this.categoryName,
    this.eloPoints = 0,
    this.tierName,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
  });

  factory UserPublicRank.fromJson(Map<String, dynamic> json) {
    return UserPublicRank(
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      eloPoints: ((json['eloPoints'] ?? 0) as num).toInt(),
      tierName: json['tierName'] as String?,
      matchesPlayed: ((json['matchesPlayed'] ?? 0) as num).toInt(),
      matchesWon: ((json['matchesWon'] ?? 0) as num).toInt(),
    );
  }
}
