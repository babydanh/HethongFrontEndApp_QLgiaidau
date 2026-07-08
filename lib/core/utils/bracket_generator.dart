import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';

abstract class IBracketGenerator {
  List<MatchModel> generate(String tournamentId, List<Team> teams, {int roundCount = 1});
}

class BracketFactory {
  static IBracketGenerator getGenerator(String bracketType) {
    switch (bracketType) {
      case AppConstants.bracketDoubleElimination:
        return DoubleEliminationGenerator();
      case AppConstants.bracketRoundRobin:
        return RoundRobinGenerator();
      case AppConstants.bracketSingleElimination:
      default:
        return SingleEliminationGenerator();
    }
  }
}

class SingleEliminationGenerator implements IBracketGenerator {
  static const _uuid = Uuid();

  @override
  List<MatchModel> generate(String tournamentId, List<Team> teams, {int roundCount = 1}) {
    if (teams.isEmpty) return [];

    // 1. Tính toán số vòng và số trận
    int p = 1;
    while (p < teams.length) {
      p *= 2;
    }

    final totalRounds = (log(p) / log(2)).round();
    if (totalRounds == 0) return [];

    // 2. Xáo trộn danh sách đội (Random bốc thăm)
    final shuffledTeams = List<Team>.from(teams)..shuffle();

    // 3. Tạo các slot (rải đều để tránh 2 BYE gặp nhau)
    List<Team?> slots = List.generate(p, (index) => null);
    int teamIndex = 0;
    // Rải team1 cho tất cả các trận
    for (int i = 0; i < p ~/ 2; i++) {
      if (teamIndex < shuffledTeams.length) {
        slots[i * 2] = shuffledTeams[teamIndex++];
      }
    }
    // Rải team2 cho các trận còn lại
    for (int i = 0; i < p ~/ 2; i++) {
      if (teamIndex < shuffledTeams.length) {
        slots[i * 2 + 1] = shuffledTeams[teamIndex++];
      }
    }

    List<MatchModel> allMatches = [];
    Map<String, String> matchIds = {};

    // Khởi tạo trước các ID để có thể link nextMatchId
    for (int r = 1; r <= totalRounds; r++) {
      int matchesInRound = p ~/ pow(2, r);
      for (int pos = 0; pos < matchesInRound; pos++) {
        matchIds['${r}_$pos'] = _uuid.v4();
      }
    }

    // 4. Sinh các trận đấu
    for (int r = 1; r <= totalRounds; r++) {
      int matchesInRound = p ~/ pow(2, r);

      for (int pos = 0; pos < matchesInRound; pos++) {
        final matchId = matchIds['${r}_$pos']!;
        
        // Trận đấu tiếp theo (trừ chung kết)
        String nextMatchId = '';
        if (r < totalRounds) {
          int nextPos = pos ~/ 2;
          nextMatchId = matchIds['${r + 1}_$nextPos']!;
        }

        if (r == 1) {
          // Vòng 1 lấy dữ liệu từ mảng slots
          final t1 = slots[pos * 2];
          final t2 = slots[pos * 2 + 1];

          bool isBye = t2 == null || t1 == null;
          String status = isBye ? 'walkover' : 'scheduled';
          String winnerId = '';
          
          if (isBye) {
             if (t1 != null) winnerId = t1.id;
             if (t2 != null) winnerId = t2.id;
          }

          allMatches.add(
            MatchModel(
              id: matchId,
              round: r,
              matchNumber: pos + 1,
              team1Id: t1?.id ?? 'BYE',
              team2Id: t2?.id ?? 'BYE',
              team1Name: t1?.name ?? 'BYE',
              team2Name: t2?.name ?? 'BYE',
              score1: 0,
              score2: 0,
              winnerId: winnerId,
              status: status,
              bracketPosition: BracketPosition(round: r, position: pos),
              nextMatchId: nextMatchId,
              updatedAt: DateTime.now(),
            ),
          );
        } else {
          // Các vòng sau: team trống, đợi vòng trước đánh xong
          allMatches.add(
            MatchModel(
              id: matchId,
              round: r,
              matchNumber: pos + 1,
              team1Id: '',
              team2Id: '',
              team1Name: 'TBD',
              team2Name: 'TBD',
              score1: 0,
              score2: 0,
              winnerId: '',
              status: 'scheduled',
              bracketPosition: BracketPosition(round: r, position: pos),
              nextMatchId: nextMatchId,
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
    }

    // Tự động đẩy đội thắng ở các trận walkover (BYE) lên vòng tiếp theo
    for (int i = 0; i < allMatches.length; i++) {
      final match = allMatches[i];
      if (StatusHelper.isWalkover(match.status) &&
          match.winnerId.isNotEmpty &&
          match.nextMatchId.isNotEmpty) {
        final winnerId = match.winnerId;
        final winnerName =
            winnerId == match.team1Id ? match.team1Name : match.team2Name;
        final isTeam1 = match.matchNumber.isOdd;

        final nextIndex =
            allMatches.indexWhere((m) => m.id == match.nextMatchId);
        if (nextIndex != -1) {
          final nextMatch = allMatches[nextIndex];
          allMatches[nextIndex] = nextMatch.copyWith(
            team1Id: isTeam1 ? winnerId : nextMatch.team1Id,
            team1Name: isTeam1 ? winnerName : nextMatch.team1Name,
            team2Id: !isTeam1 ? winnerId : nextMatch.team2Id,
            team2Name: !isTeam1 ? winnerName : nextMatch.team2Name,
          );
        }
      }
    }
    return allMatches;
  }
}

class DoubleEliminationGenerator implements IBracketGenerator {
  static const _uuid = Uuid();

  @override
  List<MatchModel> generate(String tournamentId, List<Team> teams, {int roundCount = 1}) {
    if (teams.isEmpty) return [];

    int p = 1;
    while (p < teams.length) {
      p *= 2;
    }

    final totalWBRounds = (log(p) / log(2)).round();
    if (totalWBRounds == 0) return [];
    
    final lbRounds = 2 * (totalWBRounds - 1);

    final shuffledTeams = List<Team>.from(teams)..shuffle();
    List<Team?> slots = List.generate(p, (index) => null);
    int teamIndex = 0;
    for (int i = 0; i < p ~/ 2; i++) {
      if (teamIndex < shuffledTeams.length) {
        slots[i * 2] = shuffledTeams[teamIndex++];
      }
    }
    for (int i = 0; i < p ~/ 2; i++) {
      if (teamIndex < shuffledTeams.length) {
        slots[i * 2 + 1] = shuffledTeams[teamIndex++];
      }
    }

    List<MatchModel> allMatches = [];
    Map<String, String> matchIds = {};

    // 1. Tạo Match IDs
    for (int r = 1; r <= totalWBRounds; r++) {
      int matchesInRound = p ~/ pow(2, r);
      for (int pos = 0; pos < matchesInRound; pos++) {
        matchIds['W_${r}_$pos'] = _uuid.v4();
      }
    }
    for (int j = 1; j <= lbRounds; j++) {
      int matchesInRound = p ~/ pow(2, ((j - 1) ~/ 2) + 2);
      for (int pos = 0; pos < matchesInRound; pos++) {
        matchIds['L_${j}_$pos'] = _uuid.v4();
      }
    }
    matchIds['GF_0'] = _uuid.v4();
    matchIds['GF_1'] = _uuid.v4(); // Bracket reset

    // 2. Tạo trận đấu Nhánh Thắng (WB)
    for (int r = 1; r <= totalWBRounds; r++) {
      int matchesInRound = p ~/ pow(2, r);

      for (int pos = 0; pos < matchesInRound; pos++) {
        final matchId = matchIds['W_${r}_$pos']!;
        
        String nextMatchId = r < totalWBRounds ? matchIds['W_${r + 1}_${pos ~/ 2}']! : matchIds['GF_0']!;
        String loserNextMatchId = '';
        if (r == 1) {
          loserNextMatchId = matchIds['L_1_${pos ~/ 2}']!;
        } else {
          int dropPos = (r % 2 == 0) ? (matchesInRound - 1 - pos) : pos;
          loserNextMatchId = matchIds['L_${2 * (r - 1)}_$dropPos']!;
        }

        if (r == 1) {
          final t1 = slots[pos * 2];
          final t2 = slots[pos * 2 + 1];

          bool isBye = t2 == null || t1 == null;
          String status = isBye ? 'walkover' : 'scheduled';
          String winnerId = '';
          String loserId = '';
          
          if (isBye) {
             if (t1 != null) { winnerId = t1.id; loserId = 'BYE'; }
             if (t2 != null) { winnerId = t2.id; loserId = 'BYE'; }
          }

          allMatches.add(
            MatchModel(
              id: matchId,
              round: r,
              matchNumber: pos + 1,
              team1Id: t1?.id ?? 'BYE',
              team2Id: t2?.id ?? 'BYE',
              team1Name: t1?.name ?? 'BYE',
              team2Name: t2?.name ?? 'BYE',
              score1: 0,
              score2: 0,
              winnerId: winnerId,
              loserId: loserId,
              status: status,
              bracketPosition: BracketPosition(bracket: 'winners', round: r, position: pos),
              nextMatchId: nextMatchId,
              loserNextMatchId: loserNextMatchId,
              updatedAt: DateTime.now(),
            ),
          );
        } else {
          allMatches.add(
            MatchModel(
              id: matchId,
              round: r,
              matchNumber: pos + 1,
              team1Id: '',
              team2Id: '',
              team1Name: 'TBD',
              team2Name: 'TBD',
              score1: 0,
              score2: 0,
              winnerId: '',
              status: 'scheduled',
              bracketPosition: BracketPosition(bracket: 'winners', round: r, position: pos),
              nextMatchId: nextMatchId,
              loserNextMatchId: loserNextMatchId,
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
    }

    // 3. Tạo trận đấu Nhánh Thua (LB)
    for (int j = 1; j <= lbRounds; j++) {
      int matchesInRound = p ~/ pow(2, ((j - 1) ~/ 2) + 2);
      for (int pos = 0; pos < matchesInRound; pos++) {
        final matchId = matchIds['L_${j}_$pos']!;
        String nextMatchId = '';
        if (j == lbRounds) {
          nextMatchId = matchIds['GF_0']!;
        } else if (j % 2 != 0) {
          nextMatchId = matchIds['L_${j + 1}_$pos']!;
        } else {
          nextMatchId = matchIds['L_${j + 1}_${pos ~/ 2}']!;
        }

        allMatches.add(
          MatchModel(
            id: matchId,
            round: j,
            matchNumber: pos + 1,
            team1Id: '',
            team2Id: '',
            team1Name: 'TBD',
            team2Name: 'TBD',
            score1: 0,
            score2: 0,
            winnerId: '',
            status: 'scheduled',
            bracketPosition: BracketPosition(bracket: 'losers', round: j, position: pos),
            nextMatchId: nextMatchId,
            loserNextMatchId: '',
            updatedAt: DateTime.now(),
          ),
        );
      }
    }

    // 4. Tạo Grand Final
    allMatches.add(
      MatchModel(
        id: matchIds['GF_0']!,
        round: totalWBRounds + 1,
        matchNumber: 1,
        team1Id: '',
        team2Id: '',
        team1Name: 'TBD',
        team2Name: 'TBD',
        score1: 0,
        score2: 0,
        winnerId: '',
        status: 'scheduled',
        bracketPosition: BracketPosition(bracket: 'grand_final', round: 1, position: 0),
        nextMatchId: matchIds['GF_1']!,
        loserNextMatchId: '',
        updatedAt: DateTime.now(),
      ),
    );
    
    // Bracket reset match
    allMatches.add(
      MatchModel(
        id: matchIds['GF_1']!,
        round: totalWBRounds + 2,
        matchNumber: 1,
        team1Id: '',
        team2Id: '',
        team1Name: 'TBD',
        team2Name: 'TBD',
        score1: 0,
        score2: 0,
        winnerId: '',
        status: 'pending_if_necessary',
        bracketPosition: BracketPosition(bracket: 'grand_final_reset', round: 1, position: 0),
        nextMatchId: '',
        loserNextMatchId: '',
        updatedAt: DateTime.now(),
      ),
    );

    // 5. Đẩy đội BYE lên các vòng tiếp theo (Quét đệ quy cho cả nhánh Thắng & Thua)
    bool changed = true;
    while (changed) {
      changed = false;
      for (int i = 0; i < allMatches.length; i++) {
        final match = allMatches[i];
        
        // 5.1. Nhận diện trận đấu có thể walkover (nhận BYE từ vòng trước)
        if (!StatusHelper.isWalkover(match.status) && match.status != 'completed') {
          bool isT1Bye = match.team1Id == 'BYE';
          bool isT2Bye = match.team2Id == 'BYE';
          bool isT1Real = match.team1Id.isNotEmpty && match.team1Id != 'BYE' && match.team1Id != 'TBD';
          bool isT2Real = match.team2Id.isNotEmpty && match.team2Id != 'BYE' && match.team2Id != 'TBD';
          
          if (isT1Bye && isT2Bye) {
            allMatches[i] = match.copyWith(status: 'walkover', winnerId: 'BYE', loserId: 'BYE');
            changed = true;
          } else if (isT1Bye && isT2Real) {
            allMatches[i] = match.copyWith(status: 'walkover', winnerId: match.team2Id, loserId: 'BYE');
            changed = true;
          } else if (isT2Bye && isT1Real) {
            allMatches[i] = match.copyWith(status: 'walkover', winnerId: match.team1Id, loserId: 'BYE');
            changed = true;
          }
        }
        
        // 5.2. Nếu đã là walkover, đẩy Winner và Loser đi tiếp
        if (StatusHelper.isWalkover(allMatches[i].status) && allMatches[i].winnerId.isNotEmpty) {
          final currentMatch = allMatches[i];
          final winnerId = currentMatch.winnerId;
          final loserId = currentMatch.loserId;
          final winnerName = winnerId == currentMatch.team1Id ? currentMatch.team1Name : currentMatch.team2Name;
          final loserName = 'BYE';
          final isTeam1 = currentMatch.matchNumber.isOdd;
          
          if (currentMatch.nextMatchId.isNotEmpty) {
            final nextIndex = allMatches.indexWhere((m) => m.id == currentMatch.nextMatchId);
            if (nextIndex != -1) {
              final nextMatch = allMatches[nextIndex];
              bool forwardIsTeam1 = isTeam1;
              if (currentMatch.bracketPosition.bracket == 'losers' && currentMatch.round % 2 != 0) {
                forwardIsTeam1 = false;
              }
              
              String newT1Id = forwardIsTeam1 ? winnerId : nextMatch.team1Id;
              String newT2Id = !forwardIsTeam1 ? winnerId : nextMatch.team2Id;
              
              if (newT1Id != nextMatch.team1Id || newT2Id != nextMatch.team2Id) {
                allMatches[nextIndex] = nextMatch.copyWith(
                  team1Id: newT1Id,
                  team1Name: forwardIsTeam1 ? winnerName : nextMatch.team1Name,
                  team2Id: newT2Id,
                  team2Name: !forwardIsTeam1 ? winnerName : nextMatch.team2Name,
                );
                changed = true;
              }
            }
          }
          
          if (currentMatch.loserNextMatchId.isNotEmpty) {
             final loserNextIndex = allMatches.indexWhere((m) => m.id == currentMatch.loserNextMatchId);
             if (loserNextIndex != -1) {
               final loserNextMatch = allMatches[loserNextIndex];
               bool isLoserTeam1 = currentMatch.matchNumber % 2 != 0;
               if (currentMatch.round > 1) {
                  isLoserTeam1 = true; 
               }
               
               String newT1Id = isLoserTeam1 ? loserId : loserNextMatch.team1Id;
               String newT2Id = !isLoserTeam1 ? loserId : loserNextMatch.team2Id;
               
               if (newT1Id != loserNextMatch.team1Id || newT2Id != loserNextMatch.team2Id) {
                 allMatches[loserNextIndex] = loserNextMatch.copyWith(
                   team1Id: newT1Id,
                   team1Name: isLoserTeam1 ? loserName : loserNextMatch.team1Name,
                   team2Id: newT2Id,
                   team2Name: !isLoserTeam1 ? loserName : loserNextMatch.team2Name,
                 );
                 changed = true;
               }
             }
          }
        }
      }
    }

    return allMatches;
  }
}

class RoundRobinGenerator implements IBracketGenerator {
  static const _uuid = Uuid();

  @override
  List<MatchModel> generate(String tournamentId, List<Team> teams, {int roundCount = 1}) {
    if (teams.length < 2) return [];

    List<MatchModel> allMatches = [];
    List<Team> currentTeams = List.from(teams);

    if (currentTeams.length % 2 != 0) {
      currentTeams.add(
        Team(
          id: 'BYE',
          name: 'BYE',
          qrCode: '',
          members: const [],
          group: '',
          photoUrl: '',
          approvalStatus: 'COMPLETE',
          contactEmail: '',
          createdAt: DateTime.now(),
          seed: 0,
        ),
      );
    }

    int numTeams = currentTeams.length;
    int matchesPerRound = numTeams ~/ 2;

    int matchCounter = 1;

    for (int round = 1; round <= roundCount; round++) {
      for (int i = 0; i < matchesPerRound; i++) {
        Team t1 = currentTeams[i];
        Team t2 = currentTeams[numTeams - 1 - i];

        if (t1.id != 'BYE' && t2.id != 'BYE') {
          allMatches.add(
            MatchModel(
              id: _uuid.v4(),
              round: round,
              matchNumber: matchCounter++,
              team1Id: t1.id,
              team2Id: t2.id,
              team1Name: t1.name,
              team2Name: t2.name,
              score1: 0,
              score2: 0,
              status: 'scheduled',
              bracketPosition: BracketPosition(round: round, position: i),
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
      // Dịch chuyển vòng tròn: Đội ở vị trí index 0 giữ nguyên, các đội còn lại xoay vòng
      currentTeams.insert(1, currentTeams.removeLast());
    }

    return allMatches;
  }
}
