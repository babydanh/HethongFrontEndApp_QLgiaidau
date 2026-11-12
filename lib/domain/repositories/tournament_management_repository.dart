import 'package:app_quanly_giaidau/domain/entities/tournament_sponsor.dart';
import 'package:app_quanly_giaidau/domain/entities/add_athlete_candidate.dart';
import 'package:app_quanly_giaidau/domain/entities/pairing.dart';
import 'package:app_quanly_giaidau/domain/entities/roster_import.dart';

abstract interface class TournamentManagementRepository {
  Future<List<Map<String, dynamic>>> getVenues(String id);
  Future<Map<String, dynamic>> createVenue(
    String id, {
    required String name,
    required String locationAddress,
    String? venueId,
    bool? isDefault,
    int? initialCourtCount,
    String? courtPrefix,
  });
  Future<Map<String, dynamic>> updateVenue(
    String id,
    String venueId, {
    String? name,
    String? locationAddress,
  });
  Future<void> setDefaultVenue(String id, String venueId);
  Future<Map<String, dynamic>> removeVenue(String id, String venueId);
  Future<void> addCourt(
    String id,
    String venueId, {
    required String courtName,
    String? status,
  });
  Future<void> removeCourt(String id, String venueId, String courtId);

  Future<List<TournamentSponsor>> getSponsors(String id);
  Future<TournamentSponsor> createSponsor(
    String id,
    Map<String, dynamic> payload,
  );
  Future<TournamentSponsor> updateSponsor(
    String id,
    String sponsorId,
    Map<String, dynamic> payload,
  );
  Future<TournamentSponsor> archiveSponsor(String id, String sponsorId);

  Future<List<Map<String, dynamic>>> getStaff(String id);
  Future<Map<String, dynamic>> addStaff(String id, String email, String role);
  Future<void> removeStaff(String id, String userId);
  Future<List<Map<String, dynamic>>> getReferees(String id);
  Future<void> addReferee(String id, String email);
  Future<void> removeReferee(String id, String refereeId);

  Future<Map<String, dynamic>> getFeesConfig();
  Future<void> requestPayout({
    required String tournamentId,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
    required num amountRequested,
  });
  Future<List<Map<String, dynamic>>> getMyPayouts();
  Future<void> updateParticipantStatus(
    String id,
    String participantId,
    String status,
  );

  /// Ghi chú nội bộ BTC (`PATCH /tournaments/:id/participants/:pid/note`,
  /// body `{ note }` — lưu vào `customResponses.notes`, VĐV không thấy).
  Future<void> updateParticipantNote(
    String id,
    String participantId,
    String note,
  );

  /// Day-of-event check-in mark (`PATCH .../participants/:pid/presence`,
  /// body `{ present }`); a note for organizers only.
  Future<void> setParticipantPresent(
    String id,
    String participantId,
    bool present,
  );

  /// Entry-fee paid flag (`PATCH .../participants/:pid/fee-payment`, body
  /// `{ paid }`); the Backend may open a refund request when it is cleared.
  Future<void> setParticipantFeePaid(
    String id,
    String participantId,
    bool paid,
  );

  /// Sửa liên hệ hồ sơ do BTC tạo (`PATCH .../participants/:pid/entry`):
  /// payload `{ members: [{ slot, name, email, phone, expectedKey }] }`
  /// (chỉ thành viên khách, giống Web `updateOrganizerEntry`).
  Future<void> updateOrganizerEntry(
    String id,
    String participantId,
    Map<String, dynamic> payload,
  );

  /// Khoá/mở roster đội bóng (`POST .../participants/:pid/lock-roster`
  /// / `unlock-roster`, không body).
  Future<void> lockParticipantRoster(String id, String participantId);
  Future<void> unlockParticipantRoster(String id, String participantId);

  /// Xoá một VĐV ảo (`DELETE /tournaments/:id/participants/:pid/mock`,
  /// route Web `deleteMockParticipant`).
  Future<void> deleteMockParticipant(String id, String participantId);

  /// Sinh VĐV ảo (`POST /tournaments/:id/mock-participants`, body
  /// `{ names, divisionId?, pairingMode? }` — Web `seedMockParticipants`).
  /// [pairingMode] chỉ có ý nghĩa với nội dung đôi: `'AUTO'` ghép 2 dòng
  /// liên tiếp thành 1 cặp, `'INDIVIDUAL_WAITING'` sinh VĐV lẻ chờ BTC ghép.
  Future<void> seedMockParticipants(
    String id,
    List<String> names, {
    String? divisionId,
    String? pairingMode,
  });

  /// Xoá VĐV ảo của một hạng mục (`DELETE /tournaments/:id/mock-participants`,
  /// query `divisionId` — Web `clearMockParticipants`); bỏ [divisionId] thì
  /// xoá ở cấp giải.
  Future<void> clearMockParticipants(String id, {String? divisionId});

  /// Gán suất đặc cách (`POST /tournaments/:id/reserve-slots`, body
  /// `{ userEmailOrPhone, teamName, partnerEmailOrPhone?, divisionId? }` —
  /// Web `assignReservedSlot`).
  Future<void> reserveSlots(
    String id, {
    required String userEmailOrPhone,
    required String teamName,
    String? partnerEmailOrPhone,
    String? divisionId,
  });

  /// Tách một cặp đã ghép (`POST /tournaments/:id/pairing/:pid/unpair`).
  Future<void> unpairParticipant(String id, String participantId);

  /// Danh sách VĐV đang chờ ghép cặp
  /// (`GET /tournaments/:id/pairing/participants` — Web
  /// `getTournamentPairingParticipants`).
  Future<List<PairingCandidate>> getPairingParticipants(String id);

  /// Ghép nhiều cặp trong một lần (`POST /tournaments/:id/pairing/batch`,
  /// body `{ pairs: [{ participant1Id, participant2Id, teamName? }] }` — Web
  /// `pairTournamentParticipantsBatch`).
  Future<void> pairBatch(String id, List<PairInput> pairs);

  /// Ghép tự động theo chiến lược (`POST /tournaments/:id/pairing/generate`,
  /// body `{ strategy, divisionId? }` — Web `generateTournamentPairs`).
  Future<PairGenerateResult> pairGenerate(
    String id, {
    required PairingStrategy strategy,
    String? divisionId,
  });
  Future<List<AddAthleteCandidate>> listAddAthleteCandidates(
    String id, {
    required AddAthleteSource source,
    String? query,
    String? participantId,
  });
  Future<String> addAthleteCandidate(
    String id, {
    required AddAthleteSource source,
    required String userId,
    String? tournamentDivisionId,
    String? participantId,
    FootballRosterRole? role,
  });
  Future<String> addAthleteDirect(
    String id, {
    required String name,
    String? email,
    String? phone,
    String? notes,
    double? elo,
    String? eloSource,
    String? tournamentDivisionId,
  });
  Future<List<AddAthleteSearchCandidate>> searchAddAthleteCandidates(
    String id, {
    String? name,
    String? email,
    String? participantId,
  });
  Future<List<AddedAthletePair>> addAthletePairs(
    String id, {
    required AddAthleteSource source,
    required String tournamentDivisionId,
    required List<String> userIds,
  });
  Future<RosterImportBatchPreview> previewRosterImportBatch(
    String id,
    RosterImportBatchRequest request,
  );

  /// Ghi các dòng đủ điều kiện. Idempotency-Key được tính từ nội dung request,
  /// nên gửi lại đúng payload không tạo bản ghi trùng.
  Future<RosterImportBatchResult> importRosterBatch(
    String id,
    RosterImportBatchRequest request,
  );

  Future<List<String>> getGallery(String id);
  Future<void> addGalleryImage(String id, String url);
  Future<void> removeGalleryImage(String id, int index);

  Future<List<Map<String, dynamic>>> getManageDivisions(String id);
  Future<Map<String, dynamic>> createDivision(
    String id,
    Map<String, dynamic> payload,
  );
  Future<Map<String, dynamic>> updateDivision(
    String divisionId,
    Map<String, dynamic> payload,
  );
  Future<Map<String, dynamic>> updateDivisionConfig(
    String id,
    String divisionId,
    Map<String, dynamic> payload,
  );
  Future<void> deleteDivision(String divisionId);

  Future<Map<String, dynamic>> publishTournament(String id);

  /// Hạn cấp giải đã qua thì phải gửi [registrationEndDate] mới (server từ chối
  /// nếu thiếu); server tự dời ngày giải khi hạn mới vượt ngày bắt đầu.
  /// [divisionIds] chỉ mở lại đúng các nội dung đó (ReopenRegistrationDto),
  /// bỏ trống thì mở lại mọi nội dung như trước.
  Future<Map<String, dynamic>> reopenRegistration(
    String id, {
    DateTime? registrationEndDate,
    List<String>? divisionIds,
  });

  /// Đóng đăng ký mọi nội dung (không tạo sơ đồ). Nội dung riêng thì khoá qua
  /// `updateDivisionConfig` với `isRegistrationLocked`.
  Future<Map<String, dynamic>> closeRegistration(String id);

  /// Đóng đăng ký đúng các nội dung trong [divisionIds] (body `divisionIds`,
  /// đối chiếu Web `tournamentsApi.closeRegistration`). Backend từ chối mảng
  /// rỗng nên danh sách phải có ít nhất một id.
  Future<Map<String, dynamic>> closeDivisionRegistrations(
    String id,
    List<String> divisionIds,
  );
  Future<Map<String, dynamic>> regenerateInviteCode(String id);
}

/// Cập nhật giải (Web `tournamentsApi.updateTournament`): PATCH
/// `/tournaments/:id`. Sheet cài đặt khung giờ (task 4.3) dùng để lưu
/// `tournamentConfig` — payload là object `tournamentConfig` GỐC của giải đã
/// merge các trường đổi, vì server ghi đè toàn bộ JSONB này.
///
/// Tách interface riêng theo pattern [TournamentLifecycleRepository] để các
/// repository/fake không dùng PATCH giải không phải khai báo đủ.
abstract interface class TournamentSettingsRepository {
  Future<void> updateTournament(String id, Map<String, dynamic> payload);
}

extension TournamentSettingsRepositoryAccess on TournamentManagementRepository {
  Future<void> updateTournament(String id, Map<String, dynamic> payload) =>
      (this as TournamentSettingsRepository).updateTournament(id, payload);
}

abstract interface class TournamentLifecycleRepository {
  Future<Map<String, dynamic>> startTournament(String id);
  Future<Map<String, dynamic>> completeTournament(String id);

  /// `POST /tournaments/:id/results/confirm`: the organizer confirms the
  /// results again after the bracket was edited (clears `needsReconfirm`).
  Future<void> confirmTournamentResults(String id);
}

extension TournamentLifecycleRepositoryAccess
    on TournamentManagementRepository {
  Future<Map<String, dynamic>> startTournament(String id) =>
      (this as TournamentLifecycleRepository).startTournament(id);

  Future<Map<String, dynamic>> completeTournament(String id) =>
      (this as TournamentLifecycleRepository).completeTournament(id);

  Future<void> confirmTournamentResults(String id) =>
      (this as TournamentLifecycleRepository).confirmTournamentResults(id);
}
