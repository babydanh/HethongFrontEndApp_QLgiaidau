import 'package:app_quanly_giaidau/core/utils/date_parser.dart';

class TokenModel {
  final String id;
  final String code;
  final String role;
  final String tournamentId;
  final bool isActive;
  final DateTime createdAt;

  const TokenModel({
    required this.id,
    required this.code,
    required this.role,
    required this.tournamentId,
    this.isActive = true,
    required this.createdAt,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json, String id) {
    return TokenModel(
      id: id,
      code: json['code'] ?? '',
      role: json['role'] ?? '',
      tournamentId: json['tournamentId'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: DateParser.parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'role': role,
      'tournamentId': tournamentId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TokenModel copyWith({
    String? id,
    String? code,
    String? role,
    String? tournamentId,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return TokenModel(
      id: id ?? this.id,
      code: code ?? this.code,
      role: role ?? this.role,
      tournamentId: tournamentId ?? this.tournamentId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isReferee => role == 'referee';
  bool get isViewer => role == 'viewer';

  @override
  String toString() =>
      'TokenModel(code: $code, role: $role, tournament: $tournamentId)';
}
