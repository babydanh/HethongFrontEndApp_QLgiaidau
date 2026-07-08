import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/token_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/token_repository.dart';

class ApiTokenRepository implements ITokenRepository {
  static const _log = AppLogger('ApiTokenRepo');
  final DioClient _dioClient;

  ApiTokenRepository(this._dioClient);

  @override
  Future<TokenModel> createToken({
    required String code,
    required String role,
    required String tournamentId,
  }) async {
    // Mobile không trực tiếp tạo token, vai trò này thuộc về Web.
    throw UnimplementedError('Mobile app cannot create tokens directly.');
  }

  @override
  Future<void> createTokensForTournament({
    required String tournamentId,
    required String adminToken,
    required String refereeToken,
    required String viewerToken,
  }) async {
    throw UnimplementedError('Mobile app cannot create tournament tokens directly.');
  }

  @override
  Future<TokenModel?> validateToken(String code) async {
    _log.info('Validating token via API: $code');
    try {
      String cleanCode = code.toUpperCase().trim();
      String requestedRole = 'viewer';
      if (cleanCode.startsWith('ADM-')) {
        requestedRole = 'admin';
        cleanCode = cleanCode.replaceFirst('ADM-', '');
      } else if (cleanCode.startsWith('REF-')) {
        requestedRole = 'referee';
        cleanCode = cleanCode.replaceFirst('REF-', '');
      }

      final response = await _dioClient.dio.get('/tournaments/join/$cleanCode');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          // Giao diện API trả về thông tin giải đấu.
          // Để map tương thích với cấu trúc TokenModel cũ, ta xác định vai trò của code.
          final String tournamentId = data['id'];
          String role = requestedRole;
          if (role == 'viewer') {
            if (code.toUpperCase().startsWith('ADM') || code == data['adminToken']) {
              role = 'admin';
            } else if (code.toUpperCase().startsWith('REF') || code == data['refereeToken']) {
              role = 'referee';
            }
          }
          
          return TokenModel(
            id: code.toUpperCase().trim(),
            code: code.toUpperCase().trim(),
            role: role,
            tournamentId: tournamentId,
            isActive: true,
            createdAt: DateTime.now(),
          );
        }
      }
      return null;
    } catch (e, stack) {
      _log.error('Error validating token via API', e, stack);
      rethrow;
    }
  }

  @override
  Stream<TokenModel?> watchToken(String code) {
    // Mobile app currently polls token state through the backend flow.
    // Nếu token bị hủy hoặc thay đổi, interceptor 401 của Dio sẽ bắt và xử lý logout.
    return Stream.value(TokenModel(
      id: code,
      code: code,
      role: code.toUpperCase().startsWith('ADM') ? 'admin' : (code.toUpperCase().startsWith('REF') ? 'referee' : 'viewer'),
      tournamentId: '',
      isActive: true,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<List<TokenModel>> getTokensByTournament(String tournamentId) async {
    try {
      final response = await _dioClient.dio.get('/tournaments/$tournamentId');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          return [
            TokenModel(
              id: data['adminToken'] ?? 'ADM-$tournamentId',
              code: data['adminToken'] ?? 'ADM-$tournamentId',
              role: 'admin',
              tournamentId: tournamentId,
              isActive: true,
              createdAt: DateTime.now(),
            ),
            TokenModel(
              id: data['refereeToken'] ?? 'REF-$tournamentId',
              code: data['refereeToken'] ?? 'REF-$tournamentId',
              role: 'referee',
              tournamentId: tournamentId,
              isActive: true,
              createdAt: DateTime.now(),
            ),
            TokenModel(
              id: data['viewerToken'] ?? 'VWR-$tournamentId',
              code: data['viewerToken'] ?? 'VWR-$tournamentId',
              role: 'viewer',
              tournamentId: tournamentId,
              isActive: true,
              createdAt: DateTime.now(),
            ),
          ];
        }
      }
      return [];
    } catch (e, stack) {
      _log.error('Error getting tokens by tournament via API', e, stack);
      return [];
    }
  }

  @override
  Future<void> deactivateToken(String tokenId) async {
    throw UnimplementedError('Mobile app cannot deactivate tokens.');
  }

  @override
  Future<String> regenerateToken({
    required String tournamentId,
    required String role,
    required String newCode,
  }) async {
    _log.info('Requesting token regeneration for role: $role');
    final response = await _dioClient.dio.post('/tournaments/$tournamentId/regenerate-invite');
    if (response.statusCode == 200) {
      final data = response.data['data'];
      if (role == 'admin') return data['adminToken'] ?? newCode;
      if (role == 'referee') return data['refereeToken'] ?? newCode;
      return data['viewerToken'] ?? newCode;
    }
    throw Exception('Failed to regenerate token via API');
  }

  @override
  Future<void> deleteTokensByTournament(String tournamentId) async {
    _log.info('Backend mới không có token riêng — bỏ qua');
  }
}
