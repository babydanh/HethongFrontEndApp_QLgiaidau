import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/firestore_helpers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/match_event_model.dart';
import 'package:app_quanly_giaidau/data/models/penalty_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';

class FirebaseMatchRepository
    with FirestoreHelpers
    implements IMatchRepository {
  static const _log = AppLogger('MatchRepo');
  final FirebaseFirestore _firestore;

  FirebaseMatchRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _matchesRef(String tournamentId) =>
      _firestore
          .collection(AppConstants.collectionTournaments)
          .doc(tournamentId)
          .collection(AppConstants.collectionMatches);

  /// Chuẩn bị data trước khi ghi lên Firestore (DateTime → Timestamp)
  Map<String, dynamic> _prepareForFirestore(MatchModel match) {
    final data = match.toJson();
    return convertDateTimesToTimestamps(
      data,
      fields: ['updatedAt'],
      optionalFields: ['scheduledTime', 'startedAt', 'completedAt'],
    );
  }

  /// Parse Firestore document thành MatchModel (Timestamp → DateTime)
  MatchModel _parseFromFirestore(Map<String, dynamic> data, String id) {
    final converted = convertTimestampsToDateTimes(
      data,
      fields: ['updatedAt'],
      optionalFields: ['scheduledTime', 'startedAt', 'completedAt'],
    );
    return MatchModel.fromJson(converted, id);
  }

  @override
  Future<MatchModel> create(String tournamentId, MatchModel match) async {
    _log.info('Tạo trận đấu: V${match.round}-T${match.matchNumber} trong giải $tournamentId');
    try {
      final doc = _matchesRef(tournamentId).doc(match.id);
      await doc.set(_prepareForFirestore(match));
      _log.success('Tạo trận đấu thành công: ${match.id}');
      return match;
    } catch (e, stack) {
      _log.error('Lỗi tạo trận đấu: ${match.id}', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> createBatch(String tournamentId, List<MatchModel> matches) async {
    _log.info('Tạo batch ${matches.length} trận đấu cho giải $tournamentId');
    try {
      final batch = _firestore.batch();
      for (final match in matches) {
        final doc = _matchesRef(tournamentId).doc(match.id);
        batch.set(doc, _prepareForFirestore(match));
      }
      await batch.commit();
      _log.success('Tạo batch ${matches.length} trận đấu thành công');
    } catch (e, stack) {
      _log.error('Lỗi tạo batch trận đấu cho giải $tournamentId', e, stack);
      rethrow;
    }
  }

  @override
  Stream<List<MatchModel>> watchByTournament(String tournamentId) {
    _log.debug('Watch trận đấu trong giải: $tournamentId');
    return _matchesRef(tournamentId)
        .snapshots()
        .map((snapshot) {
      final matches = snapshot.docs
          .map((doc) => _parseFromFirestore(doc.data(), doc.id))
          .toList();
      matches.sort((a, b) {
        final roundComp = a.round.compareTo(b.round);
        if (roundComp != 0) return roundComp;
        return a.matchNumber.compareTo(b.matchNumber);
      });
      return matches;
    });
  }

  @override
  Stream<List<MatchModel>> watchLive(String tournamentId) {
    _log.debug('Watch trận đấu live trong giải: $tournamentId');
    return _matchesRef(tournamentId)
        .where('status', isEqualTo: AppConstants.matchLive)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _parseFromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<MatchModel?> watchMatch(String tournamentId, String matchId) {
    _log.debug('Watch trận đấu: $matchId');
    return _matchesRef(tournamentId)
        .doc(matchId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return _parseFromFirestore(doc.data()!, doc.id);
    });
  }

  @override
  Future<void> updateScore(
    String tournamentId,
    String matchId, {
    required int score1,
    required int score2,
  }) async {
    _log.info('Cập nhật điểm: $matchId → $score1-$score2');
    try {
      await _matchesRef(tournamentId).doc(matchId).update({
        'score1': score1,
        'score2': score2,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _log.success('Cập nhật điểm thành công: $matchId');
    } catch (e, stack) {
      _log.error('Lỗi cập nhật điểm: $matchId', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> updateLiveState(
    String tournamentId,
    String matchId, {
    int? score1,
    int? score2,
    List<MatchEvent>? events,
    String? status,
    int? maxScore,
    bool? winByTwo,
    int? timeLimitMinutes,
    String? refereeName,
    List<Penalty>? penalties,
  }) async {
    _log.info('Cập nhật LiveState cho trận: $matchId');
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (score1 != null) updates['score1'] = score1;
      if (score2 != null) updates['score2'] = score2;
      if (events != null) updates['events'] = events.map((e) => e.toJson()).toList();
      if (status != null) updates['status'] = status;
      if (maxScore != null) updates['maxScore'] = maxScore;
      if (winByTwo != null) updates['winByTwo'] = winByTwo;
      if (timeLimitMinutes != null) updates['timeLimitMinutes'] = timeLimitMinutes;
      if (refereeName != null) updates['refereeName'] = refereeName;
      if (penalties != null) updates['penalties'] = penalties.map((p) => p.toJson()).toList();

      await _matchesRef(tournamentId).doc(matchId).update(updates);
      _log.success('Cập nhật LiveState thành công: $matchId');
    } catch (e, stack) {
      _log.error('Lỗi cập nhật LiveState: $matchId', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> startMatch(
    String tournamentId,
    String matchId, {
    int? maxScore,
    int? timeLimitMinutes,
    String? refereeName,
  }) async {
    _log.info('Bắt đầu trận đấu: $matchId');
    try {
      final updates = <String, dynamic>{
        'status': AppConstants.matchLive,
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (maxScore != null) updates['maxScore'] = maxScore;
      if (timeLimitMinutes != null) updates['timeLimitMinutes'] = timeLimitMinutes;
      if (refereeName != null) updates['refereeName'] = refereeName;

      await _matchesRef(tournamentId).doc(matchId).update(updates);
      _log.success('Bắt đầu trận đấu thành công: $matchId');
    } catch (e, stack) {
      _log.error('Lỗi bắt đầu trận đấu: $matchId', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> completeMatch(
    String tournamentId,
    String matchId, {
    required String winnerId,
    required String loserId,
    required int finalScore1,
    required int finalScore2,
  }) async {
    _log.info('Kết thúc trận đấu: $matchId, winner: $winnerId, score: $finalScore1-$finalScore2');
    try {
      final docRef = _matchesRef(tournamentId).doc(matchId);
      
      // Update this match
      await docRef.update({
        'status': AppConstants.matchCompleted,
        'winnerId': winnerId,
        'loserId': loserId,
        'score1': finalScore1,
        'score2': finalScore2,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Tự động đẩy nhánh (Auto-advancement)
      final matchDoc = await docRef.get();
      if (matchDoc.exists) {
        final matchData = matchDoc.data()!;
        final nextMatchId = matchData['nextMatchId'] as String? ?? '';
        final loserNextMatchId = matchData['loserNextMatchId'] as String? ?? '';
        
        final winnerName = winnerId == matchData['team1Id'] ? matchData['team1Name'] : matchData['team2Name'];
        final loserName = loserId == matchData['team1Id'] ? matchData['team1Name'] : matchData['team2Name'];
        final matchNumber = matchData['matchNumber'] as int? ?? 1;
        final bracketPos = matchData['bracketPosition'] as Map<String, dynamic>?;

        // Xử lý riêng cho Chung kết tổng (Grand Final)
        if (bracketPos != null && bracketPos['bracket'] == 'grand_final') {
          if (winnerId == matchData['team1Id']) {
            // Nhánh thắng win -> Vô địch luôn. Không cần trận GF_1. Hủy bỏ GF_1.
            if (nextMatchId.isNotEmpty) {
              await _matchesRef(tournamentId).doc(nextMatchId).update({
                'status': 'cancelled',
              });
            }
          } else {
            // Nhánh thua win -> Kích hoạt trận Grand Final Reset (GF_1)
            if (nextMatchId.isNotEmpty) {
              // Đẩy Loser của GF_0 (nhánh thắng cũ) vào làm team1 của GF_1
              await advanceWinner(
                tournamentId, nextMatchId,
                winnerId: loserId,
                winnerName: loserName as String? ?? 'Loser',
                isTeam1: true,
              );
              // Đẩy Winner của GF_0 (nhánh thua cũ) vào làm team2 của GF_1
              await advanceWinner(
                tournamentId, nextMatchId,
                winnerId: winnerId,
                winnerName: winnerName as String? ?? 'Winner',
                isTeam1: false,
              );
              // Cập nhật trạng thái trận GF_1 thành scheduled
              await _matchesRef(tournamentId).doc(nextMatchId).update({
                'status': 'scheduled',
              });
            }
          }
        } 
        // Các trận đấu bình thường
        else {
          if (nextMatchId.isNotEmpty && winnerId.isNotEmpty && winnerId != 'BYE') {
            bool isTeam1 = matchNumber.isOdd;
            
            // Xử lý nhánh thua nội bộ
            if (bracketPos != null && bracketPos['bracket'] == 'losers') {
              final round = matchData['round'] as int? ?? 1;
              if (round % 2 != 0) {
                isTeam1 = false;
              }
            }

            // Đảm bảo chính xác slot khi đẩy vào Grand Final
            final nextMatchDoc = await _matchesRef(tournamentId).doc(nextMatchId).get();
            if (nextMatchDoc.exists) {
              final nextBracketPos = nextMatchDoc.data()!['bracketPosition'] as Map<String, dynamic>?;
              if (nextBracketPos != null && nextBracketPos['bracket'] == 'grand_final') {
                if (bracketPos != null && bracketPos['bracket'] == 'losers') {
                  isTeam1 = false; // Winner nhánh thua LUÔN LÀ TEAM 2 của Chung Kết Tổng
                } else if (bracketPos != null && bracketPos['bracket'] == 'winners') {
                  isTeam1 = true;  // Winner nhánh thắng LUÔN LÀ TEAM 1 của Chung Kết Tổng
                }
              }
            }

            await advanceWinner(
              tournamentId, 
              nextMatchId, 
              winnerId: winnerId, 
              winnerName: winnerName as String? ?? 'Winner', 
              isTeam1: isTeam1,
            );
          }
          
          if (loserNextMatchId.isNotEmpty && loserId.isNotEmpty && loserId != 'BYE') {
            // Logic cho nhánh thua đôi (double elimination losers drop)
            final round = matchData['round'] as int? ?? 1;
            bool isLoserTeam1 = matchNumber.isOdd;
            if (round > 1) isLoserTeam1 = true;
            
            await advanceWinner(
              tournamentId,
              loserNextMatchId,
              winnerId: loserId,
              winnerName: loserName as String? ?? 'Loser',
              isTeam1: isLoserTeam1,
            );
          }
        }
      }

      _log.success('Kết thúc trận đấu thành công: $matchId');
    } catch (e, stack) {
      _log.error('Lỗi kết thúc trận đấu: $matchId', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> updateSets(
    String tournamentId,
    String matchId,
    List<SetScore> sets,
  ) async {
    _log.info('Cập nhật sets trận: $matchId (${sets.length} sets)');
    try {
      await _matchesRef(tournamentId).doc(matchId).update({
        'sets': sets.map((s) => s.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _log.success('Cập nhật sets thành công: $matchId');
    } catch (e, stack) {
      _log.error('Lỗi cập nhật sets: $matchId', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> advanceWinner(
    String tournamentId,
    String nextMatchId, {
    required String winnerId,
    required String winnerName,
    required bool isTeam1,
  }) async {
    _log.info('Advance winner $winnerName vào trận: $nextMatchId (team${isTeam1 ? 1 : 2})');
    try {
      final docRef = _matchesRef(tournamentId).doc(nextMatchId);

      final field = isTeam1 ? 'team1' : 'team2';
      await docRef.update({
        '${field}Id': winnerId,
        '${field}Name': winnerName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _log.success('Advance winner thành công: $nextMatchId');

      // Tự động xử thắng (walkover) nếu có trường hợp gặp BYE
      final matchDoc = await docRef.get();
      if (!matchDoc.exists) return;

      final matchData = matchDoc.data()!;
      final t1Id = matchData['team1Id'] as String? ?? '';
      final t2Id = matchData['team2Id'] as String? ?? '';

      bool t1Bye = t1Id == 'BYE';
      bool t2Bye = t2Id == 'BYE';
      bool t1Real = t1Id.isNotEmpty && t1Id != 'BYE' && t1Id != 'TBD';
      bool t2Real = t2Id.isNotEmpty && t2Id != 'BYE' && t2Id != 'TBD';

      String? autoWinnerId;
      if (t1Bye && t2Real) autoWinnerId = t2Id;
      else if (t2Bye && t1Real) autoWinnerId = t1Id;
      else if (t1Bye && t2Bye) autoWinnerId = 'BYE';

      if (autoWinnerId != null) {
        _log.info('Phát hiện đối thủ là BYE trong trận $nextMatchId. Tự động walkover cho $autoWinnerId');
        await walkover(
          tournamentId,
          nextMatchId,
          winnerId: autoWinnerId,
          loserId: 'BYE',
        );
        // Gọi completeMatch để tiếp tục đẩy nhánh
        await completeMatch(
          tournamentId,
          nextMatchId,
          winnerId: autoWinnerId,
          loserId: 'BYE',
          finalScore1: 0,
          finalScore2: 0,
        );
      }
    } catch (e, stack) {
      _log.error('Lỗi advance winner vào trận: $nextMatchId', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> walkover(
    String tournamentId,
    String matchId, {
    required String winnerId,
    required String loserId,
  }) async {
    _log.info('Walkover trận: $matchId, winner: $winnerId');
    try {
      await _matchesRef(tournamentId).doc(matchId).update({
        'status': AppConstants.matchWalkover,
        'winnerId': winnerId,
        'loserId': loserId,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _log.success('Walkover thành công: $matchId');
    } catch (e, stack) {
      _log.error('Lỗi walkover trận: $matchId', e, stack);
      rethrow;
    }
  }

  @override
  Future<List<MatchModel>> getAllByTournament(String tournamentId) async {
    _log.debug('Lấy tất cả trận đấu trong giải: $tournamentId');
    try {
      final snapshot = await _matchesRef(tournamentId).get();
      final matches = snapshot.docs
          .map((doc) => _parseFromFirestore(doc.data(), doc.id))
          .toList();
      matches.sort((a, b) {
        final roundComp = a.round.compareTo(b.round);
        if (roundComp != 0) return roundComp;
        return a.matchNumber.compareTo(b.matchNumber);
      });
      _log.debug('Lấy được ${matches.length} trận đấu');
      return matches;
    } catch (e, stack) {
      _log.error('Lỗi lấy trận đấu trong giải $tournamentId', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> deleteAll(String tournamentId) async {
    _log.info('Xóa tất cả trận đấu trong giải: $tournamentId');
    try {
      final snapshot = await _matchesRef(tournamentId).get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
      }
      _log.success('Xóa ${snapshot.docs.length} trận đấu thành công');
    } catch (e, stack) {
      _log.error('Lỗi xóa trận đấu trong giải $tournamentId', e, stack);
      rethrow;
    }
  }
}
