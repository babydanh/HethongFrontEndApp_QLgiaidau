import 'package:app_quanly_giaidau/core/utils/date_parser.dart';

class Team {
  final String id;
  final String name;
  final List<String> members;
  final int seed;
  final String group;
  final String photoUrl;
  final String qrCode;
  final bool isCheckedIn;
  final String contactEmail;
  final DateTime createdAt;

  const Team({
    required this.id,
    required this.name,
    this.members = const [],
    this.seed = 0,
    this.group = '',
    this.photoUrl = '',
    this.qrCode = '',
    this.isCheckedIn = false,
    this.contactEmail = '',
    required this.createdAt,
  });

  factory Team.fromJson(Map<String, dynamic> json, String id) {
    return Team(
      id: id,
      name: json['name'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      seed: json['seed'] ?? 0,
      group: json['group'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      qrCode: json['qrCode'] ?? '',
      isCheckedIn: json['isCheckedIn'] ?? false,
      contactEmail: json['contactEmail'] ?? '',
      createdAt: DateParser.parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'members': members,
      'seed': seed,
      'group': group,
      'photoUrl': photoUrl,
      'qrCode': qrCode,
      'isCheckedIn': isCheckedIn,
      'contactEmail': contactEmail,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // _parseDate() đã được thay bằng DateParser.parseDate() — DRY principle

  Team copyWith({
    String? id,
    String? name,
    List<String>? members,
    int? seed,
    String? group,
    String? photoUrl,
    String? qrCode,
    bool? isCheckedIn,
    String? contactEmail,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      seed: seed ?? this.seed,
      group: group ?? this.group,
      photoUrl: photoUrl ?? this.photoUrl,
      qrCode: qrCode ?? this.qrCode,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      contactEmail: contactEmail ?? this.contactEmail,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Team(id: $id, name: $name, seed: $seed)';
}
