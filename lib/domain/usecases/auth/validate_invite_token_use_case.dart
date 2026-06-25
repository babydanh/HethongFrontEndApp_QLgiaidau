import 'package:app_quanly_giaidau/domain/entities/token.dart';
import 'package:app_quanly_giaidau/domain/repositories/token_repository.dart';

class ValidateInviteTokenUseCase {
  final ITokenRepository _tokenRepository;

  ValidateInviteTokenUseCase(this._tokenRepository);

  Future<TokenModel?> call(String tokenCode) {
    return _tokenRepository.validateToken(tokenCode);
  }
}
