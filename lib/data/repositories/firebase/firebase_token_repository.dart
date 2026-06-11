import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/firestore_helpers.dart';
import 'package:app_quanly_giaidau/data/models/token_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/token_repository.dart';

class FirebaseTokenRepository
    with FirestoreHelpers
    implements ITokenRepository {
  static const _log = AppLogger('TokenRepo');
  final FirebaseFirestore _firestore;

  FirebaseTokenRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _tokensRef =>
      _firestore.collection(AppConstants.collectionTokens);

  /// Chuẩn bị data trước khi ghi lên Firestore (DateTime → Timestamp)
  Map<String, dynamic> _prepareForFirestore(TokenModel token) {
    final data = token.toJson();
    return convertDateTimesToTimestamps(data, fields: ['createdAt']);
  }

  /// Parse Firestore document thành TokenModel (Timestamp → DateTime)
  TokenModel _parseFromFirestore(Map<String, dynamic> data, String id) {
    final converted = convertTimestampsToDateTimes(data, fields: ['createdAt']);
    return TokenModel.fromJson(converted, id);
  }

  @override
  Future<TokenModel> createToken({
    required String code,
    required String role,
    required String tournamentId,
  }) async {
    _log.info('Tạo token: role=$role, tournament=$tournamentId');
    try {
      final codeUpper = code.toUpperCase().trim();
      final doc = _tokensRef.doc(codeUpper);
      final token = TokenModel(
        id: codeUpper,
        code: codeUpper,
        role: role,
        tournamentId: tournamentId,
        isActive: true,
        createdAt: DateTime.now(),
      );
      await doc.set(_prepareForFirestore(token));
      _log.success('Tạo token thành công: ${doc.id}');
      return token;
    } catch (e, stack) {
      _log.error('Lỗi tạo token: role=$role', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> createTokensForTournament({
    required String tournamentId,
    required String adminToken,
    required String refereeToken,
    required String viewerToken,
  }) async {
    _log.info('Tạo bộ 3 token cho giải: $tournamentId');
    try {
      final batch = _firestore.batch();

      final tokens = [
        TokenModel(
          id: adminToken.toUpperCase().trim(),
          code: adminToken.toUpperCase().trim(),
          role: AppConstants.roleAdmin,
          tournamentId: tournamentId,
          createdAt: DateTime.now(),
        ),
        TokenModel(
          id: refereeToken.toUpperCase().trim(),
          code: refereeToken.toUpperCase().trim(),
          role: AppConstants.roleReferee,
          tournamentId: tournamentId,
          createdAt: DateTime.now(),
        ),
        TokenModel(
          id: viewerToken.toUpperCase().trim(),
          code: viewerToken.toUpperCase().trim(),
          role: AppConstants.roleViewer,
          tournamentId: tournamentId,
          createdAt: DateTime.now(),
        ),
      ];

      for (final token in tokens) {
        final doc = _tokensRef.doc(token.id);
        batch.set(doc, _prepareForFirestore(token));
      }

      await batch.commit();
      _log.success('Tạo bộ 3 token thành công cho giải: $tournamentId');
    } catch (e, stack) {
      _log.error('Lỗi tạo bộ token cho giải: $tournamentId', e, stack);
      rethrow;
    }
  }

  @override
  Future<TokenModel?> validateToken(String code) async {
    final codeUpper = code.toUpperCase().trim();
    _log.info('Xác thực token: ${codeUpper.substring(0, 3)}***');
    try {
      final docSnapshot = await _tokensRef.doc(codeUpper).get();

      if (!docSnapshot.exists) {
        _log.warning('Token không tồn tại');
        return null;
      }

      final docData = docSnapshot.data()!;
      if (docData['isActive'] == false) {
         _log.warning('Token đã bị vô hiệu hóa');
         return null;
      }

      final token = _parseFromFirestore(docData, docSnapshot.id);
      _log.success('Token hợp lệ: role=${token.role}, tournament=${token.tournamentId}');
      return token;
    } catch (e, stack) {
      _log.error('Lỗi xác thực token', e, stack);
      rethrow;
    }
  }

  @override
  Stream<TokenModel?> watchToken(String code) {
    final codeUpper = code.toUpperCase().trim();
    return _tokensRef.doc(codeUpper).snapshots().map((docSnapshot) {
      if (!docSnapshot.exists || docSnapshot.data()?['isActive'] == false) {
        return null;
      }
      return _parseFromFirestore(docSnapshot.data()!, docSnapshot.id);
    });
  }

  @override
  Future<List<TokenModel>> getTokensByTournament(String tournamentId) async {
    _log.debug('Lấy tokens của giải: $tournamentId');
    try {
      final snapshot = await _tokensRef
          .where('tournamentId', isEqualTo: tournamentId)
          .get();

      final tokens = snapshot.docs
          .map((doc) => _parseFromFirestore(doc.data(), doc.id))
          .toList();
      _log.debug('Lấy được ${tokens.length} tokens');
      return tokens;
    } catch (e, stack) {
      _log.error('Lỗi lấy tokens của giải $tournamentId', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> deactivateToken(String tokenId) async {
    _log.info('Vô hiệu hóa token: $tokenId');
    try {
      await _tokensRef.doc(tokenId).update({'isActive': false});
      _log.success('Vô hiệu hóa token thành công: $tokenId');
    } catch (e, stack) {
      _log.error('Lỗi vô hiệu hóa token: $tokenId', e, stack);
      rethrow;
    }
  }

  @override
  Future<String> regenerateToken({
    required String tournamentId,
    required String role,
    required String newCode,
  }) async {
    _log.info('Regenerate token: role=$role, tournament=$tournamentId');
    try {
      // Vô hiệu hóa token cũ
      final oldTokens = await _tokensRef
          .where('tournamentId', isEqualTo: tournamentId)
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldTokens.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
      _log.debug('Vô hiệu hóa ${oldTokens.docs.length} token cũ');

      // Tạo token mới
      final newCodeUpper = newCode.toUpperCase().trim();
      final newDoc = _tokensRef.doc(newCodeUpper);
      batch.set(
          newDoc,
          _prepareForFirestore(TokenModel(
            id: newCodeUpper,
            code: newCodeUpper,
            role: role,
            tournamentId: tournamentId,
            createdAt: DateTime.now(),
          )));

      await batch.commit();
      _log.success('Regenerate token thành công: role=$role');
      return newCode;
    } catch (e, stack) {
      _log.error('Lỗi regenerate token: role=$role', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> deleteTokensByTournament(String tournamentId) async {
    _log.info('Xóa tất cả token của giải: $tournamentId');
    try {
      final snapshot = await _tokensRef
          .where('tournamentId', isEqualTo: tournamentId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      _log.success('Xóa ${snapshot.docs.length} token thành công');
    } catch (e, stack) {
      _log.error('Lỗi xóa token của giải $tournamentId', e, stack);
      rethrow;
    }
  }
}
