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
  });

  factory CommunityTournamentModel.fromJson(Map<String, dynamic> json) {
    // Lấy sport từ category object hoặc từ sportRules/tournamentConfig
    String sport = json['sport']?.toString() ?? '';
    if (sport.isEmpty && json['category'] is Map) {
      sport = (json['category'] as Map)['slug']?.toString() ?? '';
    }

    // Lấy maxTeams từ tournamentConfig hoặc trực tiếp
    int maxTeams = 16;
    if (json['maxParticipants'] != null) {
      maxTeams = int.tryParse(json['maxParticipants'].toString()) ?? 16;
    } else if (json['tournamentConfig'] is Map) {
      maxTeams = int.tryParse((json['tournamentConfig'] as Map)['maxTeams']?.toString() ?? '16') ?? 16;
    }

    // Lấy teamCount từ _count
    int teamCount = 0;
    if (json['_count'] is Map) {
      var count = (json['_count'] as Map)['participants'];
      if (count != null) teamCount = int.tryParse(count.toString()) ?? 0;
    }

    return CommunityTournamentModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      sport: sport,
      format: json['format']?.toString() ?? json['matchType']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      maxTeams: maxTeams,
      teamCount: teamCount,
      startDate: json['startDate']?.toString(),
      locationAddress: json['locationAddress']?.toString() ?? json['venue']?['locationAddress']?.toString(),
      bannerUrl: json['bannerUrl']?.toString(),
    );
  }
}
