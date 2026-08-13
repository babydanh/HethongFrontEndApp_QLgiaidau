/// Model cho giải đấu trong CLB — từ API response
class CommunityTournamentModel {
  final String id;
  final String name;
  final String sport;
  final String format;
  final String status;
  final int maxTeams;
  final int teamCount;
  final String? startDate;
  final String? locationAddress;
  final String? bannerUrl;
  final bool isLite;
  final String tournamentType;
  final bool isRanked;
  final String? parentId;
  final String categoryName;
  final int entryFee;
  final String? endDate;

  const CommunityTournamentModel({
    required this.id,
    required this.name,
    this.sport = '',
    this.format = '',
    this.status = 'draft',
    this.maxTeams = 16,
    this.teamCount = 0,
    this.startDate,
    this.locationAddress,
    this.bannerUrl,
    this.isLite = false,
    this.tournamentType = 'PUBLIC',
    this.isRanked = false,
    this.parentId,
    this.categoryName = '',
    this.entryFee = 0,
    this.endDate,
  });

  factory CommunityTournamentModel.fromJson(Map<String, dynamic> json) {
    // Sport từ category object hoặc trực tiếp
    String sport = json['sport']?.toString() ?? '';
    if (sport.isEmpty && json['category'] is Map) {
      sport = (json['category'] as Map)['slug']?.toString() ?? '';
    }
    final categoryName = json['category'] is Map
        ? ((json['category'] as Map)['name']?.toString() ?? sport)
        : sport;

    // maxTeams từ tournamentConfig hoặc trực tiếp
    int maxTeams = 16;
    if (json['maxParticipants'] != null) {
      maxTeams = int.tryParse(json['maxParticipants'].toString()) ?? 16;
    } else if (json['tournamentConfig'] is Map) {
      maxTeams =
          int.tryParse(
            (json['tournamentConfig'] as Map)['maxTeams']?.toString() ?? '16',
          ) ??
          16;
    }

    // teamCount từ _count
    int teamCount = 0;
    if (json['_count'] is Map) {
      var count = (json['_count'] as Map)['participants'];
      if (count != null) teamCount = int.tryParse(count.toString()) ?? 0;
    }

    // isLite = LOẠI GIẢI lite (nhanh). KHÔNG suy từ mode (cách tính điểm LITE/STRICT).
    bool isLite = false;
    if (json['tournamentConfig'] is Map) {
      final config = json['tournamentConfig'] as Map;
      isLite = config['isLite'] == true;
    }

    final entryFee = int.tryParse(
          (json['entryFee'] ?? json['registrationFee'] ?? json['fee'] ?? 0)
              .toString(),
        ) ??
        0;

    return CommunityTournamentModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      sport: sport,
      format: json['format']?.toString() ?? json['matchType']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      maxTeams: maxTeams,
      teamCount: teamCount,
      startDate: json['startDate']?.toString(),
      locationAddress:
          json['locationAddress']?.toString() ??
          json['venue']?['locationAddress']?.toString(),
      bannerUrl: json['bannerUrl']?.toString(),
      isLite: isLite,
      tournamentType: (json['tournamentType'] ?? json['type'] ?? 'PUBLIC')
          .toString()
          .toUpperCase(),
      isRanked: json['isRanked'] == true || json['is_ranked'] == true,
      parentId: json['parentId']?.toString() ?? json['parentTournamentId']?.toString(),
      categoryName: categoryName,
      entryFee: entryFee,
      endDate: json['endDate']?.toString(),
    );
  }
}
