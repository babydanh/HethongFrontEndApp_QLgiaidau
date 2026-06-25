import 'package:app_quanly_giaidau/domain/repositories/session_repository.dart';

class RestoreSavedInviteTokenUseCase {
  final ISessionRepository _sessionRepository;

  RestoreSavedInviteTokenUseCase(this._sessionRepository);

  Future<String?> call() {
    return _sessionRepository.getSavedInviteToken();
  }
}
