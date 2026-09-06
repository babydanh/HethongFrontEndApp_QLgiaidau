import 'dart:async';

import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/locale_provider.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/data/models/tournament_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tournamentsProvider = StreamProvider<List<Tournament>>((ref) {
  return ref.watch(tournamentRepositoryProvider).watchAll().map((list) {
    return list
        .where(
          (t) => t.status != 'PENDING_DELETE' && t.status != 'pending_delete',
        )
        .toList();
  });
});

final myTournamentsProvider = Provider<AsyncValue<List<Tournament>>>((ref) {
  final allTournamentsAsync = ref.watch(tournamentsProvider);

  return allTournamentsAsync.when(
    data: (allTournaments) => AsyncValue.data(allTournaments),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.data(const <Tournament>[]),
  );
});

final followedTournamentsProvider = FutureProvider<List<Tournament>>((
  ref,
) async {
  return ref.watch(tournamentRepositoryProvider).getFollowedTournaments();
});

final tournamentProvider = StreamProvider.family<Tournament?, String>((
  ref,
  id,
) {
  final repo = ref.watch(tournamentRepositoryProvider);
  final l10n = lookupAppLocalizations(ref.read(localeProvider));
  return repo
      .watch(id)
      .timeout(
        const Duration(seconds: 8),
        onTimeout: (sink) {
          sink.addError(TimeoutException(l10n.tournamentInfoTimeout));
        },
      );
});

final tournamentIntroProvider = FutureProvider.family<Tournament?, String>((
  ref,
  id,
) async {
  return ref
      .watch(tournamentRepositoryProvider)
      .getById(id)
      .timeout(const Duration(seconds: 8));
});

final tournamentIntroWithInviteProvider =
    FutureProvider.family<Tournament?, ({String id, String? invite})>((
      ref,
      params,
    ) async {
      return ref
          .watch(tournamentRepositoryProvider)
          .getById(params.id, inviteCode: params.invite)
          .timeout(const Duration(seconds: 8));
    });

/// Tải thông tin giải cho màn hình đăng ký, kèm mã mời (nếu có).
/// Mã mời được truyền qua `?invite=` để backend cho phép đọc giải PRIVATE.
/// Key đổi khi `invite` đổi → tự refetch sau khi người dùng nhập mã mời.
final registerTournamentProvider =
    FutureProvider.family<Tournament?, ({String id, String? invite})>((
      ref,
      params,
    ) async {
      return ref
          .watch(tournamentRepositoryProvider)
          .getById(params.id, inviteCode: params.invite)
          .timeout(const Duration(seconds: 8));
    });

final presenceCountProvider =
    StreamProvider.family<int, ({String tournamentId, String role})>((
      ref,
      params,
    ) {
      return Stream.value(0);
    });

final teamsProvider = StreamProvider.family<List<Team>, String>((
  ref,
  tournamentId,
) {
  return ref.watch(teamRepositoryProvider).watchByTournament(tournamentId);
});

final introTeamsProvider = FutureProvider.family<List<Team>, String>((
  ref,
  tournamentId,
) async {
  return ref
      .watch(teamRepositoryProvider)
      .getAllByTournament(tournamentId)
      .timeout(const Duration(seconds: 8));
});

final matchesProvider = StreamProvider.family<List<MatchModel>, String>((
  ref,
  tournamentId,
) {
  return ref.watch(matchRepositoryProvider).watchByTournament(tournamentId);
});

final tournamentDivisionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      tournamentId,
    ) async {
      final dio = ref.watch(dioClientProvider).dio;
      final response = await dio.get('/tournaments/$tournamentId/divisions');
      if (response.statusCode == 200) {
        final list = response.data['data'] as List<dynamic>;
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    });

final matchesWithDivisionProvider =
    StreamProvider.family<
      List<MatchModel>,
      ({String tournamentId, String? divisionId})
    >((ref, params) {
      return ref
          .watch(matchRepositoryProvider)
          .watchByTournament(
            params.tournamentId,
            divisionId: params.divisionId,
          );
    });

final liveMatchesProvider = StreamProvider.family<List<MatchModel>, String>((
  ref,
  tournamentId,
) {
  return ref.watch(matchRepositoryProvider).watchLive(tournamentId);
});

final bracketMatchesProvider = StreamProvider.family<List<MatchModel>, String>((
  ref,
  tournamentId,
) async* {
  final repo = ref.watch(tournamentRepositoryProvider);
  final bracketMatches = await repo.getBracketMatches(tournamentId);
  if (bracketMatches.isNotEmpty) {
    yield bracketMatches;
    yield* repo.watchBracketMatches(tournamentId);
  } else {
    yield* ref.watch(matchRepositoryProvider).watchByTournament(tournamentId);
  }
});

/// Lite tournaments are rendered from the bracket projection. The public flat
/// `/matches?publicOnly=true` feed intentionally excludes Lite records, so a
/// Lite screen must never fall back to that feed after a bracket read fails.
/// Keep the first paint bounded and retry the authoritative projection in the
/// background so a transient API failure does not leave the screen spinning.
final liteBracketMatchesProvider =
    StreamProvider.family<List<MatchModel>, String>((ref, tournamentId) async* {
      final repo = ref.watch(tournamentRepositoryProvider);

      Future<List<MatchModel>> loadSnapshot() async {
        try {
          return await repo
              .getBracketMatches(tournamentId)
              .timeout(const Duration(seconds: 8), onTimeout: () => const []);
        } catch (_) {
          return const [];
        }
      }

      yield await loadSnapshot();
      yield* Stream.periodic(const Duration(seconds: 15))
          .asyncMap((_) => loadSnapshot())
          .handleError((_) => const <MatchModel>[]);
    });

/// Division-scoped Lite projection for the live tournament screen. Keep it
/// separate from the generic provider so normal tournaments retain their
/// existing flat-feed fallback and Lite never gets filtered out by
/// `publicOnly=true`.
final liteBracketMatchesWithDivisionProvider =
    StreamProvider.family<
      List<MatchModel>,
      ({String tournamentId, String? divisionId})
    >((ref, params) async* {
      final repo = ref.watch(tournamentRepositoryProvider);

      Future<List<MatchModel>> loadSnapshot() async {
        try {
          return await repo
              .getBracketMatches(
                params.tournamentId,
                divisionId: params.divisionId,
              )
              .timeout(const Duration(seconds: 8), onTimeout: () => const []);
        } catch (_) {
          return const [];
        }
      }

      yield await loadSnapshot();
      yield* Stream.periodic(const Duration(seconds: 15))
          .asyncMap((_) => loadSnapshot())
          .handleError((_) => const <MatchModel>[]);
    });

final bracketMatchesWithDivisionProvider =
    StreamProvider.family<
      List<MatchModel>,
      ({String tournamentId, String? divisionId})
    >((ref, params) async* {
      final tournamentRepo = ref.watch(tournamentRepositoryProvider);
      final matchRepo = ref.watch(matchRepositoryProvider);

      List<MatchModel> bracketMatches = const [];
      List<MatchModel> flatMatches = const [];

      try {
        // `/bracket` is authoritative for the diagram/table and is the common
        // path for Lite management. Do not start the expensive paginated matches
        // request in parallel; use it only as a fallback when no bracket exists.
        bracketMatches = await tournamentRepo
            .getBracketMatches(
              params.tournamentId,
              divisionId: params.divisionId,
            )
            .catchError((_) => <MatchModel>[]);
        if (bracketMatches.isEmpty) {
          flatMatches = await matchRepo
              .getAllByTournament(
                params.tournamentId,
                divisionId: params.divisionId,
              )
              .catchError((_) => <MatchModel>[]);
        }
      } catch (_) {}

      // /bracket is the authoritative source and matches what the web renders.
      // Use ONLY bracket matches when available, falling back to flat list if not.
      final snapshot = bracketMatches.isNotEmpty ? bracketMatches : flatMatches;

      // Yield the snapshot immediately (even if empty `[]`) so Riverpod transitions out
      // of loading state instantly instead of hanging the UI on division change.
      yield snapshot;

      if (snapshot.isNotEmpty) {
        yield* tournamentRepo
            .watchBracketMatches(
              params.tournamentId,
              divisionId: params.divisionId,
            )
            .handleError((_) {});
      } else {
        yield* matchRepo.watchByTournament(
          params.tournamentId,
          divisionId: params.divisionId,
        );
      }
    });

final singleMatchProvider = StreamProvider.autoDispose
    .family<MatchModel?, ({String tournamentId, String matchId})>((
      ref,
      params,
    ) {
      return ref
          .watch(matchRepositoryProvider)
          .watchMatch(params.tournamentId, params.matchId);
    });

final viewerCountProvider = StreamProvider.autoDispose.family<int, String>((
  ref,
  matchId,
) {
  final socketService = ref.watch(matchSocketServiceProvider);
  socketService.connect(matchId);

  ref.onDispose(() {
    socketService.leave(matchId);
  });

  return socketService.onViewerCount
      .where((data) => data['matchId'] == matchId)
      .map((data) => (data['viewerCount'] as num?)?.toInt() ?? 1);
});
