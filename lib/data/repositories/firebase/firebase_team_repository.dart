import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/firestore_helpers.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/team_repository.dart';

class FirebaseTeamRepository
    with FirestoreHelpers
    implements ITeamRepository {
  static const _log = AppLogger('TeamRepo');
  final FirebaseFirestore _firestore;

  FirebaseTeamRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _teamsRef(String tournamentId) =>
      _firestore
          .collection(AppConstants.collectionTournaments)
          .doc(tournamentId)
          .collection(AppConstants.collectionTeams);

  /// Chuẩn bị data trước khi ghi lên Firestore (DateTime → Timestamp)
  Map<String, dynamic> _prepareForFirestore(Team team) {
    final data = team.toJson();
    return convertDateTimesToTimestamps(data, fields: ['createdAt']);
  }

  /// Parse Firestore document thành Team model (Timestamp → DateTime)
  Team _parseFromFirestore(Map<String, dynamic> data, String id) {
    final converted = convertTimestampsToDateTimes(data, fields: ['createdAt']);
    return Team.fromJson(converted, id);
  }

  @override
  Future<Team> create(String tournamentId, Team team) async {
    _log.info('Tạo đội: ${team.name} trong giải $tournamentId');
    try {
      final doc = _teamsRef(tournamentId).doc(team.id);
      await doc.set(_prepareForFirestore(team));
      _log.success('Tạo đội thành công: ${team.id}');
      return team;
    } catch (e, stack) {
      _log.error('Lỗi tạo đội: ${team.name}', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> importTeams(String tournamentId, List<Team> teams) async {
    _log.info('Import ${teams.length} đội vào giải $tournamentId');
    try {
      final batch = _firestore.batch();
      for (final team in teams) {
        final doc = _teamsRef(tournamentId).doc(team.id);
        batch.set(doc, _prepareForFirestore(team));
      }
      await batch.commit();
      _log.success('Import ${teams.length} đội thành công');
    } catch (e, stack) {
      _log.error('Lỗi import đội vào giải $tournamentId', e, stack);
      rethrow;
    }
  }

  @override
  Future<Team?> getById(String tournamentId, String teamId) async {
    _log.debug('Lấy đội: $teamId trong giải $tournamentId');
    try {
      final doc = await _teamsRef(tournamentId).doc(teamId).get();
      if (!doc.exists) {
        _log.warning('Đội không tồn tại: $teamId');
        return null;
      }
      return _parseFromFirestore(doc.data()!, doc.id);
    } catch (e, stack) {
      _log.error('Lỗi lấy đội: $teamId', e, stack);
      rethrow;
    }
  }

  @override
  Stream<List<Team>> watchByTournament(String tournamentId) {
    _log.debug('Watch đội trong giải: $tournamentId');
    return _teamsRef(tournamentId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _parseFromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<List<Team>> getAllByTournament(String tournamentId) async {
    _log.debug('Lấy tất cả đội trong giải: $tournamentId');
    try {
      final snapshot =
          await _teamsRef(tournamentId).orderBy('createdAt').get();
      final teams = snapshot.docs
          .map((doc) => _parseFromFirestore(doc.data(), doc.id))
          .toList();
      _log.debug('Lấy được ${teams.length} đội');
      return teams;
    } catch (e, stack) {
      _log.error('Lỗi lấy đội trong giải $tournamentId', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> update(
      String tournamentId, String teamId, Map<String, dynamic> data) async {
    _log.info('Cập nhật đội: $teamId, fields: ${data.keys.toList()}');
    try {
      await _teamsRef(tournamentId).doc(teamId).update(data);
      _log.success('Cập nhật đội thành công: $teamId');
    } catch (e, stack) {
      _log.error('Lỗi cập nhật đội: $teamId', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> checkIn(String tournamentId, String teamId) async {
    _log.info('Check-in đội: $teamId');
    try {
      await _teamsRef(tournamentId).doc(teamId).update({
        'isCheckedIn': true,
      });
      _log.success('Check-in thành công: $teamId');
    } catch (e, stack) {
      _log.error('Lỗi check-in đội: $teamId', e, stack);
      rethrow;
    }
  }

  @override
  Future<Team?> findByQrCode(String tournamentId, String qrCode) async {
    _log.info('Tìm đội theo QR: $qrCode');
    try {
      final snapshot = await _teamsRef(tournamentId)
          .where('qrCode', isEqualTo: qrCode)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        _log.warning('Không tìm thấy đội với QR: $qrCode');
        return null;
      }
      return _parseFromFirestore(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e, stack) {
      _log.error('Lỗi tìm đội theo QR: $qrCode', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> delete(String tournamentId, String teamId) async {
    _log.info('Xóa đội: $teamId');
    try {
      await _teamsRef(tournamentId).doc(teamId).delete();
      _log.success('Xóa đội thành công: $teamId');
    } catch (e, stack) {
      _log.error('Lỗi xóa đội: $teamId', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> deleteAll(String tournamentId) async {
    _log.info('Xóa tất cả đội trong giải: $tournamentId');
    try {
      final snapshot = await _teamsRef(tournamentId).get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
      }
      _log.success('Xóa ${snapshot.docs.length} đội thành công');
    } catch (e, stack) {
      _log.error('Lỗi xóa tất cả đội trong giải $tournamentId', e, stack);
      rethrow;
    }
  }

  @override
  Future<int> count(String tournamentId) async {
    _log.debug('Đếm số đội trong giải: $tournamentId');
    try {
      final snapshot = await _teamsRef(tournamentId).count().get();
      return snapshot.count ?? 0;
    } catch (e, stack) {
      _log.error('Lỗi đếm đội trong giải $tournamentId', e, stack);
      rethrow;
    }
  }
}
