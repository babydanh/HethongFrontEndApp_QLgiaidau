import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/firestore_helpers.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';

class FirebaseTournamentRepository
    with FirestoreHelpers
    implements ITournamentRepository {
  static const _log = AppLogger('TournamentRepo');
  final FirebaseFirestore _firestore;

  FirebaseTournamentRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _tournamentsRef =>
      _firestore.collection(AppConstants.collectionTournaments);

  /// Chuẩn bị data trước khi ghi lên Firestore (DateTime → Timestamp)
  Map<String, dynamic> _prepareForFirestore(Tournament tournament) {
    final data = tournament.toJson();
    return convertDateTimesToTimestamps(
      data,
      fields: ['createdAt', 'updatedAt'],
    );
  }

  /// Parse Firestore document thành Tournament model (Timestamp → DateTime)
  Tournament _parseFromFirestore(Map<String, dynamic> data, String id) {
    final converted = convertTimestampsToDateTimes(
      data,
      fields: ['createdAt', 'updatedAt'],
    );
    return Tournament.fromJson(converted, id);
  }

  @override
  Future<Tournament> create(Tournament tournament) async {
    _log.info('Tạo giải đấu: ${tournament.name}');
    try {
      final doc = _tournamentsRef.doc(tournament.id);
      await doc.set(_prepareForFirestore(tournament));
      _log.success('Tạo giải đấu thành công: ${tournament.id}');
      return tournament;
    } catch (e, stack) {
      _log.error('Lỗi tạo giải đấu: ${tournament.name}', e, stack);
      rethrow;
    }
  }

  @override
  Future<Tournament?> getById(String id) async {
    _log.debug('Lấy giải đấu theo ID: $id');
    try {
      final doc = await _tournamentsRef.doc(id).get();
      if (!doc.exists) {
        _log.warning('Giải đấu không tồn tại: $id');
        return null;
      }
      return _parseFromFirestore(doc.data()!, doc.id);
    } catch (e, stack) {
      _log.error('Lỗi lấy giải đấu: $id', e, stack);
      rethrow;
    }
  }

  @override
  Stream<Tournament?> watch(String id) {
    _log.debug('Watch giải đấu: $id');
    return _tournamentsRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return _parseFromFirestore(doc.data()!, doc.id);
    });
  }

  @override
  Stream<List<Tournament>> watchAll() {
    _log.debug('Watch tất cả giải đấu');
    return _tournamentsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _parseFromFirestore(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    _log.info('Cập nhật giải đấu: $id, fields: ${data.keys.toList()}');
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _tournamentsRef.doc(id).update(data);
      _log.success('Cập nhật giải đấu thành công: $id');
    } catch (e, stack) {
      _log.error('Lỗi cập nhật giải đấu: $id', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> updateStatus(String id, String status) async {
    _log.info('Cập nhật trạng thái giải: $id → $status');
    try {
      await update(id, {'status': status});
      _log.success('Cập nhật trạng thái thành công: $id → $status');
    } catch (e, stack) {
      _log.error('Lỗi cập nhật trạng thái: $id', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> updateToken(String id, String role, String newToken) async {
    _log.info('Cập nhật token giải: $id, role: $role');
    try {
      final field = switch (role) {
        AppConstants.roleAdmin => 'adminToken',
        AppConstants.roleReferee => 'refereeToken',
        AppConstants.roleViewer => 'viewerToken',
        _ => throw ArgumentError('Invalid role: $role'),
      };
      await update(id, {field: newToken});
      _log.success('Cập nhật token thành công: $id, role: $role');
    } catch (e, stack) {
      _log.error('Lỗi cập nhật token: $id, role: $role', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    _log.info('Xóa giải đấu: $id');
    try {
      // Delete subcollections first
      await _deleteSubcollection('$id/${AppConstants.collectionTeams}');
      await _deleteSubcollection('$id/${AppConstants.collectionMatches}');
      await _deleteSubcollection('$id/${AppConstants.collectionStandings}');

      // Delete main document
      await _tournamentsRef.doc(id).delete();
      _log.success('Xóa giải đấu thành công: $id');
    } catch (e, stack) {
      _log.error('Lỗi xóa giải đấu: $id', e, stack);
      rethrow;
    }
  }

  Future<void> _deleteSubcollection(String path) async {
    final parts = path.split('/');
    if (parts.length < 2) return;

    final collectionName = parts.last;
    final parentDocId = parts.first;

    final snapshot = await _tournamentsRef
        .doc(parentDocId)
        .collection(collectionName)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }
}
