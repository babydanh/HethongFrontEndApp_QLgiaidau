import 'package:app_quanly_giaidau/core/utils/date_parser.dart';

class Tournament {
  final String id;
  final String name;
  final String sport;
  final String format;
  final String? category;
  final String bracketType;
  final String status;
  final String adminToken;
  final String refereeToken;
  final String viewerToken;
  final String creatorId;
  final int maxTeams;
  final int? maxPlayersPerTeam;
  final String description;
  final int roundCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tournament({
    required this.id,
    required this.name,
    required this.sport,
    required this.format,
    this.category,
    required this.bracketType,
    this.status = 'draft',
    required this.adminToken,
    required this.refereeToken,
    required this.viewerToken,
    required this.creatorId,
    this.maxTeams = 16,
    this.maxPlayersPerTeam,
    this.description = '',
    this.roundCount = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tournament.fromJson(Map<String, dynamic> json, String id) {
    return Tournament(
      id: id,
      name: json['name'] ?? '',
      sport: json['sport'] ?? '',
      format: json['format'] ?? '',
      category: json['category'],
      bracketType: json['bracketType'] ?? '',
      status: json['status'] ?? 'draft',
      adminToken: json['adminToken'] ?? '',
      refereeToken: json['refereeToken'] ?? '',
      viewerToken: json['viewerToken'] ?? '',
      creatorId: json['creatorId'] ?? '',
      maxTeams: json['maxTeams'] ?? 16,
      maxPlayersPerTeam: json['maxPlayersPerTeam'],
      description: json['description'] ?? '',
      roundCount: json['roundCount'] ?? 1,
      createdAt: DateParser.parseDate(json['createdAt']),
      updatedAt: DateParser.parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sport': sport,
      'format': format,
      if (category != null) 'category': category,
      'bracketType': bracketType,
      'status': status,
      'adminToken': adminToken,
      'refereeToken': refereeToken,
      'viewerToken': viewerToken,
      'creatorId': creatorId,
      'maxTeams': maxTeams,
      if (maxPlayersPerTeam != null) 'maxPlayersPerTeam': maxPlayersPerTeam,
      'description': description,
      'roundCount': roundCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // _parseDate() đã được thay bằng DateParser.parseDate() — DRY principle

  Tournament copyWith({
    String? id,
    String? name,
    String? sport,
    String? format,
    String? category,
    String? bracketType,
    String? status,
    String? adminToken,
    String? refereeToken,
    String? viewerToken,
    String? creatorId,
    int? maxTeams,
    int? maxPlayersPerTeam,
    String? description,
    int? roundCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      sport: sport ?? this.sport,
      format: format ?? this.format,
      category: category ?? this.category,
      bracketType: bracketType ?? this.bracketType,
      status: status ?? this.status,
      adminToken: adminToken ?? this.adminToken,
      refereeToken: refereeToken ?? this.refereeToken,
      viewerToken: viewerToken ?? this.viewerToken,
      creatorId: creatorId ?? this.creatorId,
      maxTeams: maxTeams ?? this.maxTeams,
      maxPlayersPerTeam: maxPlayersPerTeam ?? this.maxPlayersPerTeam,
      description: description ?? this.description,
      roundCount: roundCount ?? this.roundCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Tournament(id: $id, name: $name, status: $status)';
}
