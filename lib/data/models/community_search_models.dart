import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';

enum CommunitySearchType { all, posts, members, matches, tournaments }

extension CommunitySearchTypeApi on CommunitySearchType {
  String get apiValue => switch (this) {
    CommunitySearchType.all => 'ALL',
    CommunitySearchType.posts => 'POSTS',
    CommunitySearchType.members => 'MEMBERS',
    CommunitySearchType.matches => 'MATCHES',
    CommunitySearchType.tournaments => 'TOURNAMENTS',
  };
}

class CommunitySearchMatchModel {
  final String id;
  final String source;
  final String? tournamentId;
  final String? sessionId;
  final String title;
  final String? tournamentName;
  final String status;
  final DateTime? scheduledAt;

  const CommunitySearchMatchModel({
    required this.id,
    required this.source,
    this.tournamentId,
    this.sessionId,
    this.title = '',
    this.tournamentName,
    this.status = 'SCHEDULED',
    this.scheduledAt,
  });

  factory CommunitySearchMatchModel.fromJson(Map<String, dynamic> json) {
    return CommunitySearchMatchModel(
      id: json['id']?.toString() ?? '',
      source: json['source']?.toString() ?? 'TOURNAMENT',
      tournamentId: json['tournamentId']?.toString(),
      sessionId: json['sessionId']?.toString(),
      title: json['title']?.toString() ?? '',
      tournamentName: json['tournamentName']?.toString(),
      status: json['status']?.toString() ?? 'SCHEDULED',
      scheduledAt: DateTime.tryParse(json['scheduledAt']?.toString() ?? ''),
    );
  }
}

class CommunitySearchResults {
  final String query;
  final List<CommunityPostModel> posts;
  final List<CommunityMemberModel> members;
  final List<CommunitySearchMatchModel> matches;
  final List<CommunityTournamentModel> tournaments;

  const CommunitySearchResults({
    required this.query,
    this.posts = const [],
    this.members = const [],
    this.matches = const [],
    this.tournaments = const [],
  });

  factory CommunitySearchResults.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> maps(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }

    return CommunitySearchResults(
      query: json['query']?.toString() ?? '',
      posts: maps(
        'posts',
      ).map(CommunityPostModel.fromJson).toList(growable: false),
      members: maps(
        'members',
      ).map(CommunityMemberModel.fromJson).toList(growable: false),
      matches: maps(
        'matches',
      ).map(CommunitySearchMatchModel.fromJson).toList(growable: false),
      tournaments: maps(
        'tournaments',
      ).map(CommunityTournamentModel.fromJson).toList(growable: false),
    );
  }
}
