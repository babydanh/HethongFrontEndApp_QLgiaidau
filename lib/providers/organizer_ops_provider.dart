import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizerOpsReadModel {
  const OrganizerOpsReadModel({
    required this.participants,
    required this.referees,
    required this.auditEntries,
  });

  final List<OrganizerOpsParticipant> participants;
  final List<OrganizerOpsReferee> referees;
  final List<OrganizerOpsAuditEntry> auditEntries;
}

final organizerOpsReadModelProvider = FutureProvider.autoDispose
    .family<OrganizerOpsReadModel, ({String tournamentId, String divisionId})>((
      ref,
      params,
    ) async {
      final tournamentRepo = ref.watch(tournamentRepositoryProvider);
      final results = await Future.wait<Object?>([
        tournamentRepo.getOrganizerParticipants(
          params.tournamentId,
          divisionId: params.divisionId,
        ),
        tournamentRepo
            .getTournamentReferees(params.tournamentId)
            .catchError((_) => const <OrganizerOpsReferee>[]),
        tournamentRepo
            .getOpsAuditLogs(params.tournamentId, divisionId: params.divisionId)
            .catchError((_) => const <OrganizerOpsAuditEntry>[]),
      ]);

      return OrganizerOpsReadModel(
        participants: results[0] as List<OrganizerOpsParticipant>,
        referees: results[1] as List<OrganizerOpsReferee>,
        auditEntries: results[2] as List<OrganizerOpsAuditEntry>,
      );
    });
