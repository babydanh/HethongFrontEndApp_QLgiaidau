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
    return CommunityTournamentModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      sport: json['sport']?.toString() ?? json['category']?['slug']?.toString() ?? '',
      format: json['format']?.toString() ?? json['matchType']?.toString() ?? '',
      status: json['status']?.toString() ?? 'draft',
      maxTeams: int.tryParse(json['maxTeams']?.toString() ?? '16') ?? 16,
      teamCount: int.tryParse(json['teamCount']?.toString() ?? json['_count']?['teams']?.toString() ?? '0') ?? 0,
      startDate: json['startDate']?.toString(),
      locationAddress: json['locationAddress']?.toString(),
      bannerUrl: json['bannerUrl']?.toString(),
    );
  }
}
