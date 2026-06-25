import 'package:app_quanly_giaidau/domain/repositories/session_repository.dart';

class SaveInviteTokenUseCase {
  final ISessionRepository _sessionRepository;

  SaveInviteTokenUseCase(this._sessionRepository);

  Future<void> call(String tokenCode) {
    return _sessionRepository.saveInviteToken(tokenCode);
  }
}
