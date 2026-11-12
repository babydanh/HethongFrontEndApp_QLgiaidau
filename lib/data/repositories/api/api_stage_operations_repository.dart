import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/repositories/stage_operations_repository.dart';

class ApiStageOperationsRepository implements IStageOperationsRepository {
  ApiStageOperationsRepository(this._dioClient);

  final DioClient _dioClient;

  /// `response.data['data']` as a map; empty when the envelope has no body.
  Map<String, dynamic> _data(Object? raw) {
    final data = raw is Map ? raw['data'] : null;
    return data is Map ? Map<String, dynamic>.from(data) : const {};
  }

  @override
  Future<List<StageOpsStage>> getStages(
    String tournamentId, {
    required String divisionId,
  }) async {
    final response = await _dioClient.dio.get(
      '/tournaments/$tournamentId/bracket',
      queryParameters: {'divisionId': divisionId},
    );
    final stages = _data(response.data)['stages'];
    return [
      for (final stage in stages is List ? stages : const [])
        if (stage is Map)
          StageOpsStage.fromJson(Map<String, dynamic>.from(stage)),
    ]..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Future<void> finalizeStage(String tournamentId, String stageId) async {
    await _dioClient.dio.post(
      '/tournaments/$tournamentId/stages/$stageId/finalize',
    );
  }

  @override
  Future<StageOpsAdvanceResult> advanceStandings(
    String tournamentId, {
    required String divisionId,
    required String stageId,
  }) async {
    final response = await _dioClient.dio.post(
      '/tournaments/$tournamentId/advance-standings',
      data: {'divisionId': divisionId, 'stageId': stageId},
    );
    final data = _data(response.data);
    final stageIds = data['stageIds'];
    final pendingTies = data['pendingTies'];
    return StageOpsAdvanceResult(
      stageCount: stageIds is List ? stageIds.length : 0,
      totalMatches: (data['totalMatches'] as num?)?.toInt() ?? 0,
      pendingTieCount: pendingTies is List ? pendingTies.length : 0,
    );
  }

  @override
  Future<void> createPlayoffMatch(
    String tournamentId, {
    required String stageId,
    required String participant1Id,
    required String participant2Id,
  }) async {
    await _dioClient.dio.post(
      '/tournaments/$tournamentId/playoff',
      data: {
        'stageId': stageId,
        'participant1Id': participant1Id,
        'participant2Id': participant2Id,
      },
    );
  }

  @override
  Future<StageOpsCancelResult> cancelDivisionBracket(
    String tournamentId,
    String divisionId,
  ) async {
    final response = await _dioClient.dio.delete(
      '/tournaments/$tournamentId/bracket/divisions/$divisionId',
    );
    final data = _data(response.data);
    return StageOpsCancelResult(
      cancelledStages: (data['cancelledStages'] as num?)?.toInt() ?? 0,
      cancelledMatches: (data['cancelledMatches'] as num?)?.toInt() ?? 0,
    );
  }
}
