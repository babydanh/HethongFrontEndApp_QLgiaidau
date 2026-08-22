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
  final bool? allowStrangerMessages;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? role;
  final int? eloPoints;
  final String? tierName;
  final String? createdAt;

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
    this.allowStrangerMessages,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.role,
    this.eloPoints,
    this.tierName,
    this.createdAt,
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
      allowStrangerMessages: _parseBool(p['allowStrangerMessages']),
      bankName: p['bankName']?.toString(),
      bankAccountNumber: p['bankAccountNumber']?.toString(),
      bankAccountName: p['bankAccountName']?.toString(),
      role: p['role']?.toString(),
      eloPoints: _parseInt(p['eloPoints']),
      tierName: p['tierName']?.toString(),
      createdAt: p['createdAt']?.toString(),
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
      if (allowStrangerMessages != null)
        'allowStrangerMessages': allowStrangerMessages,
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
    bool? allowStrangerMessages,
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
      allowStrangerMessages:
          allowStrangerMessages ?? this.allowStrangerMessages,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      role: role ?? this.role,
      eloPoints: eloPoints ?? this.eloPoints,
      tierName: tierName ?? this.tierName,
    );
  }

  @override
  String toString() =>
      'UserProfile(id: $id, fullName: $fullName, email: $email)';

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
  final List<UserPublicAchievement> achievements;

  const UserPublicProfile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.coverUrl,
    this.gender,
    this.bio,
    this.isVerified = false,
    this.ranks = const [],
    this.achievements = const [],
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
      ranks: [
        ...((json['ranks'] as List<dynamic>?)
                ?.map((e) => UserPublicRank.fromJson(e as Map<String, dynamic>))
                .toList() ??
            []),
        ...((json['pairRanks'] as List<dynamic>?)
                ?.map(
                  (e) => UserPublicRank.fromJson({
                    ...(e as Map<String, dynamic>),
                    'matchType': e['matchType'] ?? 'DOUBLES',
                  }),
                )
                .toList() ??
            []),
      ],
      achievements:
          (json['achievements'] as List<dynamic>?)
              ?.map(
                (e) =>
                    UserPublicAchievement.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class UserPublicAchievement {
  final String tournamentId;
  final String tournamentName;
  final int rank;
  final String? completedAt;
  final String? tournamentDate;

  const UserPublicAchievement({
    required this.tournamentId,
    required this.tournamentName,
    required this.rank,
    this.completedAt,
    this.tournamentDate,
  });

  factory UserPublicAchievement.fromJson(Map<String, dynamic> json) {
    return UserPublicAchievement(
      tournamentId: json['tournamentId'] as String? ?? '',
      tournamentName: json['tournamentName'] as String? ?? 'Giải đấu',
      rank: ((json['rank'] ?? 0) as num).toInt(),
      completedAt: json['completedAt'] as String?,
      tournamentDate: json['tournamentDate'] as String?,
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
  final String? matchType;
  final String? genderRestriction;
  final String? partnerId;
  final String? partnerName;
  final String? partnerAvatarUrl;
  final int? peakElo;
  final bool? shieldActive;
  final String? currentStreakType;
  final int currentStreakCount;

  const UserPublicRank({
    required this.categoryId,
    required this.categoryName,
    this.eloPoints = 0,
    this.tierName,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.matchType,
    this.genderRestriction,
    this.partnerId,
    this.partnerName,
    this.partnerAvatarUrl,
    this.peakElo,
    this.shieldActive,
    this.currentStreakType,
    this.currentStreakCount = 0,
  });

  factory UserPublicRank.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, [int fallback = 0]) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    String? asString(dynamic value) => value?.toString();

    final category = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : null;
    final tier = json['tier'] is Map
        ? Map<String, dynamic>.from(json['tier'] as Map)
        : null;
    final streakType = asString(
      json['currentStreakType'] ?? json['current_streak_type'],
    )?.toUpperCase();

    return UserPublicRank(
      categoryId: asString(json['categoryId'] ?? category?['id']) ?? '',
      categoryName: asString(json['categoryName'] ?? category?['name']) ?? '',
      eloPoints: asInt(json['eloPoints'] ?? json['elo_points']),
      tierName: asString(tier?['name'] ?? json['tierName']),
      matchesPlayed: asInt(json['matchesPlayed'] ?? json['totalMatches']),
      matchesWon: asInt(json['matchesWon'] ?? json['wins']),
      matchType: asString(
        json['matchType'] ?? json['match_type'],
      )?.toUpperCase(),
      genderRestriction: asString(
        json['genderRestriction'] ?? json['gender_restriction'],
      )?.toUpperCase(),
      partnerId: asString(json['partnerId'] ?? json['partner_id']),
      partnerName: asString(json['partnerName'] ?? json['partner_name']),
      partnerAvatarUrl: asString(
        json['partnerAvatarUrl'] ?? json['partner_avatar_url'],
      ),
      peakElo: json['peakElo'] == null && json['peak_elo'] == null
          ? null
          : asInt(json['peakElo'] ?? json['peak_elo']),
      shieldActive:
          json['shieldActive'] as bool? ?? json['shield_active'] as bool?,
      currentStreakType: streakType,
      currentStreakCount: asInt(
        json['currentStreakCount'] ?? json['current_streak_count'],
      ),
    );
  }

  bool get isDoubles => matchType == 'DOUBLES' || matchType == 'MIXED_DOUBLES';

  bool get hasPlayed => matchesPlayed > 0;
}

/// Kết quả tìm kiếm người dùng (GET /users/search).
class UserSearchResult {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? email;

  const UserSearchResult({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.email,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String? ?? json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      email: json['email'] as String?,
    );
  }
}
