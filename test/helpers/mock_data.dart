/// Test data factories cho tất cả modules
/// Dùng chung cho unit test & widget test

import 'package:app_quanly_giaidau/domain/entities/app_notification.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/entities/standing.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/entities/team.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/entities/token.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/data/models/payment_model.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';

// ============================================================
// AUTH
// ============================================================
Map<String, dynamic> mockLoginJson({
  String email = 'test@example.com',
  String password = 'password123',
}) {
  return {
    'accessToken': 'access_token_123',
    'refreshToken': 'refresh_token_456',
    'roles': ['ADMIN'],
    'user': {'id': 'user-1', 'fullName': 'Nguyen Van A', 'email': email},
  };
}

Map<String, dynamic> mockRegisterJson({
  String email = 'newuser@example.com',
  String password = 'password123',
  String fullName = 'Tran Van B',
}) {
  return {
    'accessToken': 'access_token_789',
    'refreshToken': 'refresh_token_012',
    'roles': ['VIEWER'],
    'user': {'id': 'user-2', 'fullName': fullName, 'email': email},
  };
}

// ============================================================
// TOURNAMENT
// ============================================================
Map<String, dynamic> mockTournamentJson({
  String id = 'tour-1',
  String name = 'Giai Cau Long Mo Rong 2026',
  String status = 'in_progress',
}) {
  return {
    'name': name,
    'sport': 'badminton',
    'format': 'SINGLES',
    'category': {'name': 'Cầu lông', 'slug': 'badminton'},
    'matchType': 'singles',
    'bracketType': 'single_elimination',
    'status': status,
    'visibility': 'PUBLIC',
    'adminToken': 'ADM-XXX',
    'refereeToken': 'REF-XXX',
    'viewerToken': 'VWR-XXX',
    'creatorId': 'user-1',
    'creator': {'id': 'user-1', 'fullName': 'Nguyen Van A'},
    'maxTeams': 16,
    'maxPlayersPerTeam': 1,
    'description': 'Giai dau mo rong danh cho moi nguoi',
    'roundCount': 4,
    'createdAt': '2026-06-01T00:00:00Z',
    'updatedAt': '2026-07-07T00:00:00Z',
    'entryFee': 100000,
    'startDate': '2026-07-15T00:00:00Z',
    'endDate': '2026-07-20T00:00:00Z',
    'registrationStartDate': '2026-06-01T00:00:00Z',
    'registrationEndDate': '2026-07-14T00:00:00Z',
    'locationAddress': 'Nha Thien Dau Ha Noi',
    'prizeDescription': 'Giai nhat: 10.000.000d',
    'contactInfo': {'phone': '0123456789', 'email': 'contact@example.com'},
    'divisions': [
      {'name': 'Nam'},
      {'name': 'Nu'},
    ],
  };
}

Tournament createMockTournament({
  String id = 'tour-1',
  String name = 'Giai Cau Long Mo Rong 2026',
  String status = 'in_progress',
}) {
  return Tournament.fromJson(mockTournamentJson(id: id, name: name, status: status), id);
}

// ============================================================
// RANKING
// ============================================================
Map<String, dynamic> mockPlayerRankingJson({
  String userId = 'user-1',
  String fullName = 'Nguyen Van A',
  int eloPoints = 1500,
  int rank = 1,
}) {
  return {
    'id': 'rank-$userId',
    'userId': userId,
    'user': {'id': userId, 'fullName': fullName, 'avatarUrl': null},
    'fullName': fullName,
    'eloPoints': eloPoints,
    'elo_points': eloPoints,
    'tier': {'id': 'tier-1', 'name': 'Vang'},
    'tierName': 'Vang',
    'rank': rank,
    'matchesPlayed': 20,
    'totalMatches': 20,
    'matchesWon': 15,
    'wins': 15,
    'categoryId': 'cat-1',
    'category': {'id': 'cat-1', 'name': 'Cau Long'},
  };
}

PlayerRanking createMockPlayerRanking({
  String userId = 'user-1',
  String fullName = 'Nguyen Van A',
  int eloPoints = 1500,
  int rank = 1,
}) {
  return PlayerRanking.fromJson(mockPlayerRankingJson(
    userId: userId, fullName: fullName, eloPoints: eloPoints, rank: rank,
  ));
}

// ============================================================
// STANDING
// ============================================================
Map<String, dynamic> mockStandingJson({
  String id = 'standing-1',
  String teamName = 'Doi A',
  int totalPoints = 9,
}) {
  return {
    'teamName': teamName,
    'group': 'Bang A',
    'played': 3,
    'won': 3,
    'lost': 0,
    'drawn': 0,
    'pointsFor': 15,
    'pointsAgainst': 5,
    'pointDifference': 10,
    'totalPoints': totalPoints,
  };
}

Standing createMockStanding({
  String id = 'standing-1',
  String teamName = 'Doi A',
  int totalPoints = 9,
}) {
  return Standing.fromJson(mockStandingJson(id: id, teamName: teamName, totalPoints: totalPoints), id);
}

// ============================================================
// NOTIFICATION
// ============================================================
Map<String, dynamic> mockNotificationJson({
  String id = 'notif-1',
  String type = 'MATCH',
  String title = 'Tran dau sap dien ra',
  bool isRead = false,
}) {
  return {
    'id': id,
    'type': type,
    'title': title,
    'content': 'Noi dung thong bao',
    'body': 'Noi dung thong bao',
    'isRead': isRead,
    'is_read': isRead,
    'redirectUrl': '/intro/tour-1',
    'createdAt': '2026-07-07T10:00:00Z',
    'created_at': '2026-07-07T10:00:00Z',
  };
}

AppNotification createMockNotification({
  String id = 'notif-1',
  String type = 'MATCH',
  String title = 'Tran dau sap dien ra',
  bool isRead = false,
}) {
  return AppNotification.fromJson(mockNotificationJson(
    id: id, type: type, title: title, isRead: isRead,
  ));
}

// ============================================================
// TEAM
// ============================================================
Map<String, dynamic> mockTeamJson({
  String id = 'team-1',
  String name = 'Doi A',
}) {
  return {
    'id': id,
    'name': name,
    'members': ['Nguyen Van A', 'Tran Van B'],
    'playerNames': 'Nguyen Van A',
    'division': 'Bang A',
    'seed': 1,
  };
}

Team createMockTeam({
  String id = 'team-1',
  String name = 'Doi A',
}) {
  return Team.fromJson(mockTeamJson(id: id, name: name), id);
}

// ============================================================
// MATCH
// ============================================================
Map<String, dynamic> mockMatchJson({
  String id = 'match-1',
  String status = 'scheduled',
}) {
  return {
    'id': id,
    'tournamentId': 'tour-1',
    'round': 1,
    'roundName': 'Vong 1',
    'team1Id': 'team-1',
    'team1Name': 'Doi A',
    'team2Id': 'team-2',
    'team2Name': 'Doi B',
    'score1': 0,
    'score2': 0,
    'status': status,
    'scheduledTime': '2026-07-15T08:00:00Z',
    'court': 'San 1',
    'refereeName': 'Trong tai A',
    'winnerId': status == 'completed' ? 'team-1' : null,
    'nextMatchId': status == 'completed' ? 'match-2' : null,
    'bracketPosition': {'bracket': 'winners', 'row': 0, 'col': 0},
    'maxScore': 21,
    'winByTwo': true,
    'sets': [],
  };
}

// ============================================================
// PAYMENT
// ============================================================
Map<String, dynamic> mockPaymentJson({
  String id = 'pay-1',
  String status = 'completed',
}) {
  return {
    'id': id,
    'amount': 100000,
    'gateway': 'PAYOS',
    'status': status,
    'tournamentId': 'tour-1',
    'tournamentName': 'Giai Cau Long',
    'participantId': 'part-1',
    'transactionReference': 'GD-001',
    'createdAt': '2026-07-07T10:00:00Z',
    'updatedAt': '2026-07-07T10:05:00Z',
  };
}

// ============================================================
// WORKSPACE
// ============================================================
TournamentWorkspace createMockWorkspace({
  int organizedCount = 2,
  int participatingCount = 1,
  int refereeCount = 1,
}) {
  return TournamentWorkspace(
    organizedTournaments: List.generate(
      organizedCount,
      (i) => Tournament(
        id: 'org-$i',
        name: 'Giai To Chuc $i',
        sport: 'badminton',
        format: 'SINGLES',
        bracketType: 'single_elimination',
        creatorId: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        adminToken: 'ADM-ORG-$i',
        refereeToken: 'REF-ORG-$i',
        viewerToken: 'VWR-ORG-$i',
      ),
    ),
    participatingTournaments: List.generate(
      participatingCount,
      (i) => Tournament(
        id: 'part-$i',
        name: 'Giai Tham Gia $i',
        sport: 'tennis',
        format: 'DOUBLES',
        bracketType: 'round_robin',
        creatorId: 'other-user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        adminToken: 'ADM-PRT-$i',
        refereeToken: 'REF-PRT-$i',
        viewerToken: 'VWR-PRT-$i',
      ),
    ),
    coOrganizerTournaments: [],
    refereeInvites: List.generate(
      refereeCount,
      (i) => TournamentRefereeInvite(
        refereeId: 'ref-$i',
        tournamentId: 'tour-$i',
        tournamentName: 'Giai Trong Tai $i',
        tournamentStatus: 'IN_PROGRESS',
        categoryName: 'Cầu lông',
        assignedAt: DateTime.now(),
        status: 'PENDING',
      ),
    ),
    refereeMatches: [],
  );
}

// ============================================================
// COMMUNITY
// ============================================================
Map<String, dynamic> mockCommunityJson({
  String id = 'club-1',
  String name = 'CLB CAU LONG HA NOI',
}) {
  return {
    'id': id,
    'name': name,
    'description': 'Cau lac bo cau long hang dau Ha Noi',
    'sport': 'badminton',
    'sports': ['badminton'],
    'location': 'Ha Noi',
    'joinMode': 'OPEN',
    'memberCount': 50,
    'maxMembers': 100,
    'bannerUrl': null,
    'logoUrl': null,
    'status': 'ACTIVE',
    'createdAt': '2026-01-01T00:00:00Z',
    'owner': {'id': 'user-1', 'fullName': 'Nguyen Van A'},
  };
}

Map<String, dynamic> mockCommunityTournamentJson({
  String id = 'ct-1',
  String name = 'Giai CLB Noi Bo 2026',
}) {
  return {
    'id': id,
    'name': name,
    'sport': 'badminton',
    'format': 'SINGLES',
    'status': 'DRAFT',
    'maxParticipants': '16',
    '_count': {'participants': 3},
    'startDate': '2026-08-01',
  };
}

Map<String, dynamic> mockCommunityMemberJson({
  String userId = 'user-1',
  String role = 'OWNER',
  String status = 'JOINED',
}) {
  return {
    'id': 'mem-$userId',
    'userId': userId,
    'fullName': 'Nguyen Van A',
    'email': 'test@example.com',
    'role': role,
    'status': status,
    'avatarUrl': null,
  };
}

// ============================================================
// USER PROFILE
// ============================================================
Map<String, dynamic> mockUserProfileJson({
  String id = 'user-1',
  String fullName = 'Nguyen Van A',
}) {
  return {
    'id': id,
    'fullName': fullName,
    'email': 'test@example.com',
    'phone': '0912345678',
    'gender': 'Nam',
    'address': 'Ha Noi',
    'province': 'Ha Noi',
    'bio': 'VĐV cau long',
    'avatarUrl': null,
    'coverUrl': null,
    'isVerified': true,
    'bankName': 'Vietcombank',
    'bankAccount': '0123456789',
    'bankHolder': 'NGUYEN VAN A',
    'dateOfBirth': '1990-01-01',
    'createdAt': '2026-01-01T00:00:00Z',
  };
}

// ============================================================
// BRACKET GENERATOR HELPERS
// ============================================================
List<Map<String, dynamic>> mockTeamsForDraw(int count) {
  return List.generate(count, (i) => {
    'id': 'team-$i',
    'name': 'Doi ${String.fromCharCode(65 + i)}',
    'members': ['Thanh vien $i'],
  });
}
