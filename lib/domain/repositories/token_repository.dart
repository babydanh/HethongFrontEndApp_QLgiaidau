import 'package:app_quanly_giaidau/data/models/token_model.dart';

abstract class ITokenRepository {
  Future<TokenModel> createToken({
    required String code,
    required String role,
    required String tournamentId,
  });

  Future<void> createTokensForTournament({
    required String tournamentId,
    required String adminToken,
    required String refereeToken,
    required String viewerToken,
  });

  Future<TokenModel?> validateToken(String code);

  /// Lắng nghe thay đổi của token (Realtime) để xử lý kick user
  Stream<TokenModel?> watchToken(String code);
  
  Future<List<TokenModel>> getTokensByTournament(String tournamentId);
  
  Future<void> deactivateToken(String tokenId);
  
  Future<String> regenerateToken({
    required String tournamentId,
    required String role,
    required String newCode,
  });

  Future<void> deleteTokensByTournament(String tournamentId);
}
