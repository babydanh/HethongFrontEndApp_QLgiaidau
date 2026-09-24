import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_sponsor.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:dio/dio.dart';

class ApiTournamentManagementRepository
    implements TournamentManagementRepository {
  ApiTournamentManagementRepository(this._dioClient);

  final DioClient _dioClient;
  Dio get _dio => _dioClient.dio;

  dynamic _data(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return body['data'];
    }
    throw const FormatException('Expected API response data envelope.');
  }

  Map<String, dynamic> _map(Response<dynamic> response) {
    final value = _data(response);
    if (value is Map<String, dynamic>) return value;
    throw const FormatException('Expected an object in API response data.');
  }

  List<dynamic> _list(Response<dynamic> response) {
    final value = _data(response);
    if (value is List<dynamic>) return value;
    throw const FormatException('Expected a list in API response data.');
  }

  List<Map<String, dynamic>> _mapList(Response<dynamic> response) =>
      _list(response)
          .map((row) {
            if (row is Map<String, dynamic>) return row;
            throw const FormatException(
              'Expected object rows in API response.',
            );
          })
          .toList(growable: false);

  TournamentSponsor _sponsor(Response<dynamic> response) =>
      TournamentSponsor.fromJson(_map(response));

  List<Map<String, dynamic>> _payoutList(Response<dynamic> response) =>
      _mapList(response)
          .map((row) {
            final payout = row['payout'];
            if (payout is Map<String, dynamic>) {
              return <String, dynamic>{
                ...payout,
                if (row.containsKey('tournament'))
                  'tournament': row['tournament'],
              };
            }
            return row;
          })
          .toList(growable: false);

  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async =>
      _mapList(await _dio.get('/tournaments/$id/venues'));

  @override
  Future<Map<String, dynamic>> createVenue(
    String id, {
    required String name,
    required String locationAddress,
    String? venueId,
    bool? isDefault,
    int? initialCourtCount,
    String? courtPrefix,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'locationAddress': locationAddress,
      if (venueId != null) 'venueId': venueId,
      if (isDefault != null) 'isDefault': isDefault,
      if (initialCourtCount != null) 'initialCourtCount': initialCourtCount,
      if (courtPrefix != null) 'courtPrefix': courtPrefix,
    };
    return _map(await _dio.post('/tournaments/$id/venues', data: payload));
  }

  @override
  Future<Map<String, dynamic>> updateVenue(
    String id,
    String venueId, {
    String? name,
    String? locationAddress,
  }) async => _map(
    await _dio.patch(
      '/tournaments/$id/venues/$venueId',
      data: {
        if (name != null) 'name': name,
        if (locationAddress != null) 'locationAddress': locationAddress,
      },
    ),
  );

  @override
  Future<void> setDefaultVenue(String id, String venueId) async {
    await _dio.patch('/tournaments/$id/venues/$venueId/default');
  }

  @override
  Future<Map<String, dynamic>> removeVenue(String id, String venueId) async =>
      _map(await _dio.delete('/tournaments/$id/venues/$venueId'));

  @override
  Future<void> addCourt(
    String id,
    String venueId, {
    required String courtName,
    String? status,
  }) async {
    await _dio.post(
      '/tournaments/$id/venues/$venueId/courts',
      data: {'courtName': courtName, if (status != null) 'status': status},
    );
  }

  @override
  Future<void> removeCourt(String id, String venueId, String courtId) async {
    await _dio.delete('/tournaments/$id/venues/$venueId/courts/$courtId');
  }

  @override
  Future<List<TournamentSponsor>> getSponsors(String id) async =>
      _list(await _dio.get('/tournaments/$id/sponsors/manage'))
          .map((row) => TournamentSponsor.fromJson(row as Map<String, dynamic>))
          .toList(growable: false);

  @override
  Future<TournamentSponsor> createSponsor(
    String id,
    Map<String, dynamic> payload,
  ) async =>
      _sponsor(await _dio.post('/tournaments/$id/sponsors', data: payload));

  @override
  Future<TournamentSponsor> updateSponsor(
    String id,
    String sponsorId,
    Map<String, dynamic> payload,
  ) async => _sponsor(
    await _dio.patch('/tournaments/$id/sponsors/$sponsorId', data: payload),
  );

  @override
  Future<TournamentSponsor> archiveSponsor(String id, String sponsorId) async =>
      _sponsor(await _dio.delete('/tournaments/$id/sponsors/$sponsorId'));

  @override
  Future<List<Map<String, dynamic>>> getStaff(String id) async =>
      _mapList(await _dio.get('/tournaments/$id/staff'));

  @override
  Future<Map<String, dynamic>> addStaff(
    String id,
    String email,
    String role,
  ) async => _map(
    await _dio.post(
      '/tournaments/$id/staff',
      data: {'email': email, 'role': role},
    ),
  );

  @override
  Future<void> removeStaff(String id, String userId) async {
    await _dio.delete('/tournaments/$id/staff/$userId');
  }

  @override
  Future<List<Map<String, dynamic>>> getReferees(String id) async =>
      _mapList(await _dio.get('/tournaments/$id/referees'));

  @override
  Future<void> addReferee(String id, String email) async {
    await _dio.post('/tournaments/$id/referees', data: {'email': email});
  }

  @override
  Future<void> removeReferee(String id, String refereeId) async {
    await _dio.delete('/tournaments/$id/referees/$refereeId');
  }

  @override
  Future<Map<String, dynamic>> getFeesConfig() async =>
      _map(await _dio.get('/tournaments/fees'));

  @override
  Future<void> requestPayout({
    required String tournamentId,
    required String bankName,
    required String bankAccountNumber,
    required String bankAccountName,
    required num amountRequested,
  }) async {
    await _dio.post(
      '/payments/payout',
      data: {
        'tournamentId': tournamentId,
        'bankName': bankName,
        'bankAccountNumber': bankAccountNumber,
        'bankAccountName': bankAccountName,
        'amountRequested': amountRequested,
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getMyPayouts() async =>
      _payoutList(await _dio.get('/payments/payouts'));

  @override
  Future<void> updateParticipantStatus(
    String id,
    String participantId,
    String status,
  ) async {
    await _dio.patch(
      '/tournaments/$id/participants/$participantId',
      data: {'status': status},
    );
  }

  @override
  Future<List<String>> getGallery(String id) async => _list(
    await _dio.get('/tournaments/$id/gallery'),
  ).map((url) => url as String).toList(growable: false);

  @override
  Future<void> addGalleryImage(String id, String url) async {
    await _dio.post('/tournaments/$id/gallery', data: {'url': url});
  }

  @override
  Future<void> removeGalleryImage(String id, int index) async {
    await _dio.delete('/tournaments/$id/gallery/$index');
  }

  @override
  Future<List<Map<String, dynamic>>> getManageDivisions(String id) async =>
      _mapList(await _dio.get('/tournaments/$id/divisions'));

  @override
  Future<Map<String, dynamic>> createDivision(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final body = Map<String, dynamic>.of(payload)..remove('endDate');
    return _map(await _dio.post('/tournaments/$id/divisions', data: body));
  }

  @override
  Future<Map<String, dynamic>> updateDivision(
    String divisionId,
    Map<String, dynamic> payload,
  ) async => _map(
    await _dio.patch('/tournaments/divisions/$divisionId', data: payload),
  );

  @override
  Future<Map<String, dynamic>> updateDivisionConfig(
    String id,
    String divisionId,
    Map<String, dynamic> payload,
  ) async => _map(
    await _dio.patch(
      '/tournaments/$id/divisions/$divisionId/config',
      data: payload,
    ),
  );

  @override
  Future<void> deleteDivision(String divisionId) async {
    await _dio.delete('/tournaments/divisions/$divisionId');
  }

  @override
  Future<void> updateTournamentSeeds(
    String id,
    List<Map<String, dynamic>> seeds,
  ) async {
    await _dio.patch('/tournaments/$id/seeds', data: {'seeds': seeds});
  }

  @override
  Future<List<Map<String, dynamic>>> autoSeedParticipants(
    String id, {
    String? divisionId,
  }) async => _mapList(
    await _dio.post(
      '/tournaments/$id/auto-seed',
      data: {if (divisionId != null) 'divisionId': divisionId},
    ),
  );

  @override
  Future<Map<String, dynamic>> publishTournament(String id) async =>
      _map(await _dio.post('/tournaments/$id/publish'));

  @override
  Future<Map<String, dynamic>> reopenRegistration(String id) async =>
      _map(await _dio.post('/tournaments/$id/reopen-registration'));

  @override
  Future<Map<String, dynamic>> lockTournament(String id) async =>
      _map(await _dio.post('/tournaments/$id/lock'));

  @override
  Future<Map<String, dynamic>> regenerateInviteCode(String id) async =>
      _map(await _dio.post('/tournaments/$id/regenerate-invite'));
}
