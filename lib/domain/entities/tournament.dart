import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/date_parser.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';

class Tournament {
  final String id;
  final String name;
  final String sport;
  final String format;
  final String? category;
  final String bracketType;
  final String status;
  final String visibility;
  final String adminToken;
  final String refereeToken;
  final String viewerToken;
  final String creatorId;
  final String? creatorFullName;
  final String? creatorAvatarUrl;
  final int maxTeams;
  final int? maxPlayersPerTeam;
  final String description;
  final int roundCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Web parity fields
  final double? entryFee;
  final String? logoUrl;
  final String? bannerUrl;
  final List<String> galleryImages;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? registrationStartDate;
  final DateTime? registrationEndDate;
  final String? locationAddress;
  final String? prizeDescription;
  final Map<String, dynamic>? contactInfo;
  final List<String> divisions;
  final bool isRanked;

  const Tournament({
    required this.id,
    required this.name,
    required this.sport,
    required this.format,
    this.category,
    required this.bracketType,
    this.status = 'draft',
    this.visibility = 'PUBLIC',
    required this.adminToken,
    required this.refereeToken,
    required this.viewerToken,
    required this.creatorId,
    this.creatorFullName,
    this.creatorAvatarUrl,
    this.maxTeams = 16,
    this.maxPlayersPerTeam,
    this.description = '',
    this.roundCount = 1,
    required this.createdAt,
    required this.updatedAt,
    this.entryFee,
    this.logoUrl,
    this.bannerUrl,
    this.galleryImages = const [],
    this.startDate,
    this.endDate,
    this.registrationStartDate,
    this.registrationEndDate,
    this.locationAddress,
    this.prizeDescription,
    this.contactInfo,
    this.divisions = const [],
    this.isRanked = false,
  });

  factory Tournament.fromJson(Map<String, dynamic> json, String id) {
    // ─── Debug log ───
    // ignore: unused_local_variable
    final log = AppLogger('Tournament');
    log.info('fromJson id=$id keys=${json.keys.length}');

    // ─── Category / Sport ───
    String? parsedCategory;
    String sportVal = '';

    if (json['category'] != null && json['category'] is Map) {
      final cat = json['category'] as Map<String, dynamic>;
      parsedCategory = cat['name']?.toString();
      sportVal = cat['slug']?.toString() ?? '';
    } else if (json['sport'] != null) {
      sportVal = json['sport'].toString();
    }

    // ─── Format: từ matchType + genderRestriction ───
    String formatVal = '';
    if (json['matchType'] != null) {
      final mt = json['matchType'].toString().toLowerCase();
      final gender = json['genderRestriction']?.toString().toLowerCase() ?? '';
      if (mt == 'doubles' || mt == 'double') {
        if (gender == 'female') formatVal = AppConstants.categoryWomenDoubles;
        else if (gender == 'male') formatVal = AppConstants.categoryMenDoubles;
        else if (gender == 'mixed') formatVal = AppConstants.categoryMixedDoubles;
        else formatVal = AppConstants.formatDoubles;
      } else {
        if (gender == 'female') formatVal = AppConstants.categoryWomenSingles;
        else if (gender == 'male') formatVal = AppConstants.categoryMenSingles;
        else formatVal = AppConstants.formatSingles;
      }
    } else if (json['format'] != null) {
      formatVal = json['format'].toString();
    }

    // ─── tournamentConfig (JSONB) ───
    Map<String, dynamic> config = {};
    if (json['tournamentConfig'] != null && json['tournamentConfig'] is Map) {
      config = json['tournamentConfig'] as Map<String, dynamic>;
    }

    String bracketTypeVal = config['bracketType']?.toString() ?? json['bracketType']?.toString() ?? '';
    int maxTeamsVal = _toInt(config['maxTeams']) ?? json['maxTeams'] ?? 16;
    int roundCountVal = _toInt(config['roundRobinLegs']) ?? json['roundCount'] ?? 1;

    final mappedStatus =
        StatusHelper.normalizeTournamentStatus(json['status']?.toString());

    final parsedVisibility = (json['visibility'] ?? 'PUBLIC').toString().toUpperCase();

    double? parsedEntryFee;
    if (json['entryFee'] != null) {
      parsedEntryFee = double.tryParse(json['entryFee'].toString());
    }

    Map<String, dynamic>? parsedContactInfo;
    if (json['contactInfo'] != null && json['contactInfo'] is Map) {
      parsedContactInfo = Map<String, dynamic>.from(json['contactInfo'] as Map);
    }

    final List<String> parsedDivisions = [];
    if (json['divisions'] != null && json['divisions'] is List) {
      for (var div in json['divisions']) {
        if (div is Map && div['name'] != null) {
          parsedDivisions.add(div['name'].toString());
        }
      }
    }

    return Tournament(
      id: id,
      name: json['name'] ?? '',
      sport: sportVal,
      format: formatVal,
      category: parsedCategory,
      bracketType: bracketTypeVal,
      status: mappedStatus,
      visibility: parsedVisibility == 'PRIVATE' ? 'PRIVATE' : 'PUBLIC',
      adminToken: json['adminToken'] ?? json['inviteCode'] ?? '',
      refereeToken: json['refereeToken'] ?? json['inviteCode'] ?? '',
      viewerToken: json['viewerToken'] ?? json['inviteCode'] ?? '',
      creatorId: json['creatorId'] ?? json['createdBy'] ?? json['creator']?['id'] ?? json['organizer']?['id'] ?? '',
      creatorFullName: json['creator']?['fullName'] ?? json['organizer']?['fullName'],
      creatorAvatarUrl: json['creator']?['avatarUrl'] ?? json['organizer']?['avatarUrl'],
      maxTeams: maxTeamsVal,
      maxPlayersPerTeam: json['maxPlayersPerTeam'],
      description: json['description'] ?? '',
      roundCount: roundCountVal,
      createdAt: DateParser.parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: DateParser.parseDate(json['updatedAt'] ?? json['updated_at']),
      entryFee: parsedEntryFee,
      logoUrl: json['logoUrl'] ?? json['logo_url'],
      bannerUrl: json['bannerUrl'] ?? json['banner_url'],
      galleryImages: (json['galleryImages'] as List<dynamic>? ?? json['gallery_images'] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? [],
      startDate: json['startDate'] != null ? DateParser.parseDate(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateParser.parseDate(json['endDate']) : null,
      registrationStartDate: json['registrationStartDate'] != null ? DateParser.parseDate(json['registrationStartDate']) : null,
      registrationEndDate: json['registrationEndDate'] != null ? DateParser.parseDate(json['registrationEndDate']) : null,
      locationAddress: json['locationAddress'] ?? json['location_address'],
      prizeDescription: json['prizeDescription'] ?? json['prize_description'],
      contactInfo: parsedContactInfo,
      divisions: parsedDivisions,
      isRanked: json['isRanked'] == true || json['is_ranked'] == true,
    );
  }

  /// Helper parse value → int. Handles both int and numeric String from JSONB.
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sport': sport,
      'format': format,
      if (category != null) 'category': category,
      'bracketType': bracketType,
      'status': status,
      'visibility': visibility,
      'adminToken': adminToken,
      'refereeToken': refereeToken,
      'viewerToken': viewerToken,
      'creatorId': creatorId,
      if (creatorFullName != null) 'creatorFullName': creatorFullName,
      if (creatorAvatarUrl != null) 'creatorAvatarUrl': creatorAvatarUrl,
      'maxTeams': maxTeams,
      if (maxPlayersPerTeam != null) 'maxPlayersPerTeam': maxPlayersPerTeam,
      'description': description,
      'roundCount': roundCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (entryFee != null) 'entryFee': entryFee,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (bannerUrl != null) 'bannerUrl': bannerUrl,
      if (galleryImages.isNotEmpty) 'galleryImages': galleryImages,
      if (startDate != null) 'startDate': startDate?.toIso8601String(),
      if (endDate != null) 'endDate': endDate?.toIso8601String(),
      if (registrationStartDate != null) 'registrationStartDate': registrationStartDate?.toIso8601String(),
      if (registrationEndDate != null) 'registrationEndDate': registrationEndDate?.toIso8601String(),
      if (locationAddress != null) 'locationAddress': locationAddress,
      if (prizeDescription != null) 'prizeDescription': prizeDescription,
      if (contactInfo != null) 'contactInfo': contactInfo,
      'isRanked': isRanked,
    };
  }

  Tournament copyWith({
    String? id,
    String? name,
    String? sport,
    String? format,
    String? category,
    String? bracketType,
    String? status,
    String? visibility,
    String? adminToken,
    String? refereeToken,
    String? viewerToken,
    String? creatorId,
    String? creatorFullName,
    String? creatorAvatarUrl,
    int? maxTeams,
    int? maxPlayersPerTeam,
    String? description,
    int? roundCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? entryFee,
    String? logoUrl,
    String? bannerUrl,
    List<String>? galleryImages,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationStartDate,
    DateTime? registrationEndDate,
    String? locationAddress,
    String? prizeDescription,
    Map<String, dynamic>? contactInfo,
    List<String>? divisions,
    bool? isRanked,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      sport: sport ?? this.sport,
      format: format ?? this.format,
      category: category ?? this.category,
      bracketType: bracketType ?? this.bracketType,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      adminToken: adminToken ?? this.adminToken,
      refereeToken: refereeToken ?? this.refereeToken,
      viewerToken: viewerToken ?? this.viewerToken,
      creatorId: creatorId ?? this.creatorId,
      creatorFullName: creatorFullName ?? this.creatorFullName,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
      maxTeams: maxTeams ?? this.maxTeams,
      maxPlayersPerTeam: maxPlayersPerTeam ?? this.maxPlayersPerTeam,
      description: description ?? this.description,
      roundCount: roundCount ?? this.roundCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      entryFee: entryFee ?? this.entryFee,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationStartDate: registrationStartDate ?? this.registrationStartDate,
      registrationEndDate: registrationEndDate ?? this.registrationEndDate,
      locationAddress: locationAddress ?? this.locationAddress,
      prizeDescription: prizeDescription ?? this.prizeDescription,
      contactInfo: contactInfo ?? this.contactInfo,
      divisions: divisions ?? this.divisions,
      isRanked: isRanked ?? this.isRanked,
    );
  }

  @override
  String toString() => 'Tournament(id: $id, name: $name, status: $status)';
}
