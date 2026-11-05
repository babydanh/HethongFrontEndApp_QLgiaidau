import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_stage_operations_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/stage_operations_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final stageOperationsRepositoryProvider = Provider<IStageOperationsRepository>(
  (ref) => ApiStageOperationsRepository(ref.watch(dioClientProvider)),
);

/// Stages (with match counts) of one division, loaded when the stage
/// operations screen opens; invalidate it after a mutation.
final divisionStageOpsProvider = FutureProvider.autoDispose
    .family<List<StageOpsStage>, ({String tournamentId, String divisionId})>(
      (ref, params) => ref
          .watch(stageOperationsRepositoryProvider)
          .getStages(params.tournamentId, divisionId: params.divisionId),
    );
