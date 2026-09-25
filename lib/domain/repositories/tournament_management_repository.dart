import 'package:app_quanly_giaidau/domain/entities/tournament_sponsor.dart';

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
  Future<void> updateTournamentSeeds(
    String id,
    List<Map<String, dynamic>> seeds,
  );
  Future<List<Map<String, dynamic>>> autoSeedParticipants(
    String id, {
    String? divisionId,
  });

  Future<Map<String, dynamic>> publishTournament(String id);
  Future<Map<String, dynamic>> reopenRegistration(String id);
  Future<Map<String, dynamic>> lockTournament(String id);
  Future<Map<String, dynamic>> regenerateInviteCode(String id);
}
