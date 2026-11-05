import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/repositories/pair_move_repository.dart';
import 'package:dio/dio.dart';

class ApiPairMoveRepository implements PairMoveRepository {
  ApiPairMoveRepository(this._dioClient);

  final DioClient _dioClient;
  Dio get _dio => _dioClient.dio;

  Map<String, dynamic> _dataMap(Response<dynamic> response) {
    final body = response.data;
    final data = body is Map<String, dynamic> ? body['data'] : null;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Expected an object in API response data.');
  }

  @override
  Future<List<String>> movePairMember(
    String tournamentId,
    PairMoveRequest request,
  ) async {
    final response = await _dio.post(
      '/tournaments/$tournamentId/pairing/move',
      data: request.toJson(),
    );
    final ids = _dataMap(response)['participantIds'];
    return ids is List ? ids.map((id) => id.toString()).toList() : const [];
  }

  @override
  Future<PairRemoveResult> removePairMember(
    String tournamentId, {
    required String participantId,
    required int slot,
    required String expectedKey,
  }) async {
    final response = await _dio.post(
      '/tournaments/$tournamentId/pairing/$participantId/remove-member',
      data: <String, dynamic>{'slot': slot, 'expectedKey': expectedKey},
    );
    final data = _dataMap(response);
    return PairRemoveResult(
      remainingParticipantId: data['remainingParticipantId']?.toString() ?? '',
      removedParticipantId: data['removedParticipantId']?.toString() ?? '',
    );
  }
}
