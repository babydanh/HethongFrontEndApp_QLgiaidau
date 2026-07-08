import 'package:app_quanly_giaidau/core/utils/date_parser.dart';

class Team {
  final String id;
  final String name;
  final List<String> members;
  final int seed;
  final String group;
  final String photoUrl;
  final String qrCode;
  final String approvalStatus;
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
    this.approvalStatus = 'PENDING_APPROVAL',
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
      approvalStatus: json['approvalStatus']?.toString().toUpperCase() ??
          json['teamStatus']?.toString().toUpperCase() ??
          json['status']?.toString().toUpperCase() ??
          'PENDING_APPROVAL',
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
      'approvalStatus': approvalStatus,
      'contactEmail': contactEmail,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Team copyWith({
    String? id,
    String? name,
    List<String>? members,
    int? seed,
    String? group,
    String? photoUrl,
    String? qrCode,
    String? approvalStatus,
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
      approvalStatus: approvalStatus ?? this.approvalStatus,
      contactEmail: contactEmail ?? this.contactEmail,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isApproved => approvalStatus == 'APPROVED' || approvalStatus == 'COMPLETE';
  bool get isPendingApproval =>
      approvalStatus == 'PENDING_APPROVAL' || approvalStatus == 'PENDING';
  bool get isPendingPartner => approvalStatus == 'PENDING_PARTNER';
  bool get isWaitlisted => approvalStatus == 'WAITLISTED';
  bool get isComplete => approvalStatus == 'COMPLETE';

  String get approvalLabel {
    switch (approvalStatus) {
      case 'COMPLETE':
        return 'Đã duyệt';
      case 'APPROVED':
        return 'Đã duyệt';
      case 'PENDING_PARTNER':
        return 'Chờ đồng đội';
      case 'PENDING_APPROVAL':
      case 'PENDING':
        return 'Đang duyệt';
      case 'WAITLISTED':
        return 'Hàng chờ';
      case 'REJECTED':
        return 'Bị từ chối';
      case 'WITHDRAWN':
        return 'Đã rút lui';
      case 'KICKED':
        return 'Đã bị loại';
      default:
        return 'Đang duyệt';
    }
  }

  @override
  String toString() => 'Team(id: $id, name: $name, seed: $seed)';
}
