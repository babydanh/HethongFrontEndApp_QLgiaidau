import 'dart:async';

import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/tournament_step_summary.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every participant of a tournament as the organiser sees them (same source
/// as the athletes tab). Auto-disposed, so it is only fetched while the
/// progress popup needs it.
final organizerParticipantsProvider = FutureProvider.autoDispose
    .family<List<OrganizerOpsParticipant>, String>(
      (ref, tournamentId) => ref
          .watch(tournamentRepositoryProvider)
          .getOrganizerParticipants(tournamentId),
    );

/// How long the popup waits for slow data before it opens with "Đang tải".
const stepSummaryWait = Duration(seconds: 3);

Future<(SummaryLoad, T)> _settle<T>(Future<T> source, T empty) async {
  try {
    return (SummaryLoad.ready, await source.timeout(stepSummaryWait));
  } on TimeoutException {
    return (SummaryLoad.loading, empty);
  } on Object {
    return (SummaryLoad.error, empty);
  }
}

/// Reads the participants and the managed matches of [tournament] and builds
/// its [StepSummary]. A source that fails maps to [SummaryLoad.error], one
/// that is still slow after [stepSummaryWait] to [SummaryLoad.loading]; this
/// function itself never throws and never writes.
Future<StepSummary> loadStepSummary(
  WidgetRef ref,
  Tournament tournament, {
  DateTime? now,
}) async {
  final id = tournament.id;
  final participantsProvider = organizerParticipantsProvider(id);
  final matchesProvider = managedMatchesWithDivisionProvider((
    tournamentId: id,
    divisionId: null,
  ));
  // A provider nobody listens to is paused (a stream never emits) or disposed
  // (auto-dispose), so hold both until the reads finish.
  final holds = [
    ref.listenManual(participantsProvider, (_, _) {}),
    ref.listenManual(matchesProvider, (_, _) {}),
  ];
  try {
    final (participantsLoad, participants) = await _settle(
      ref.read(participantsProvider.future),
      const <OrganizerOpsParticipant>[],
    );
    final (matchesLoad, matches) = await _settle(
      ref.read(matchesProvider.future),
      const <MatchModel>[],
    );
    return buildStepSummary(
      tournament: tournament,
      divisions: tournament.divisions,
      participants: participants,
      participantsLoad: participantsLoad,
      matches: matches,
      matchesLoad: matchesLoad,
      now: now ?? DateTime.now(),
    );
  } finally {
    for (final hold in holds) {
      hold.close();
    }
  }
}
