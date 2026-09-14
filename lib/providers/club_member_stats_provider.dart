import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/utils/match_visibility.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';

class ClubMemberStat {
  final String userId;
  int wins;
  int losses;

  ClubMemberStat({
    required this.userId,
    this.wins = 0,
    this.losses = 0,
  });

  int get totalMatches => wins + losses;

  double get winRate =>
      totalMatches == 0 ? 0.0 : (wins / totalMatches) * 100.0;
}

final clubMemberStatsProvider =
    FutureProvider.family<Map<String, ClubMemberStat>, String>((
      ref,
      communityId,
    ) async {
      final dio = ref.watch(dioClientProvider).dio;
      final matchRepo = ref.watch(matchRepositoryProvider);
      final sessionRepo = ref.watch(clubMatchSessionRepositoryProvider);

      final memberStatsMap = <String, ClubMemberStat>{};

      void recordResult(String? userId, bool won, bool isMock) {
        if (isMock) return;
        final uId = userId?.trim() ?? '';
        if (uId.isEmpty) return;
        final stat = memberStatsMap.putIfAbsent(
          uId,
          () => ClubMemberStat(userId: uId),
        );
        if (won) {
          stat.wins++;
        } else {
          stat.losses++;
        }
      }

      // 1. Tải danh sách giải đấu CLB
      final tourFetchFuture = () async {
        try {
          final tourRes = await dio.get('/communities/$communityId/tournaments');
          final rawTours =
              tourRes.data is Map
                  ? (tourRes.data['data'] ?? tourRes.data)
                  : tourRes.data;
          final tours =
              (rawTours is List ? rawTours : const <dynamic>[])
                  .whereType<Map>()
                  .map((t) => Map<String, dynamic>.from(t))
                  .take(6)
                  .toList(growable: false);

          await Future.wait(
            tours.map((tour) async {
              final tourId = tour['id']?.toString();
              if (tourId == null || tourId.isEmpty) return;
              try {
                final page = await matchRepo.getTournamentMatchesPaged(
                  tournamentId: tourId,
                  limit: 50,
                );
                for (final m in page.matches.where(isRenderablePublicMatch)) {
                  if (!m.isCompleted) continue;
                  if (m.score1 == m.score2) continue;
                  final side1Won = m.score1 > m.score2;
                  for (final info in m.team1MemberInfos) {
                    recordResult(info.userId, side1Won, info.isMock);
                  }
                  for (final info in m.team2MemberInfos) {
                    recordResult(info.userId, !side1Won, info.isMock);
                  }
                }
              } catch (_) {}
            }),
          );
        } catch (_) {}
      }();

      // 2. Tải danh sách buổi giao lưu
      final sessionFetchFuture = () async {
        try {
          final sessionPage = await sessionRepo.listPage(
            communityId,
            limit: 20,
          );

          await Future.wait(
            sessionPage.data.map((session) async {
              if (session.id.isEmpty) return;
              try {
                final matchPage = await sessionRepo.matchesPage(
                  session.id,
                  limit: 50,
                );
                for (final m in matchPage.data) {
                  final isCompleted =
                      m.status.trim().toUpperCase() == 'COMPLETED';
                  if (!isCompleted || m.sideAScore == m.sideBScore) continue;
                  final sideAWon = m.sideAScore > m.sideBScore;
                  for (final mem in m.sideAMembers) {
                    recordResult(mem.userId, sideAWon, mem.isMock);
                  }
                  for (final mem in m.sideBMembers) {
                    recordResult(mem.userId, !sideAWon, mem.isMock);
                  }
                }
              } catch (_) {}
            }),
          );
        } catch (_) {}
      }();

      // 3. Tải danh sách trận riêng (standalone)
      final standaloneFetchFuture = () async {
        try {
          final standalonePage = await sessionRepo.standaloneMatchesPage(
            communityId,
            limit: 50,
          );
          for (final m in standalonePage.data) {
            final isCompleted =
                m.status.trim().toUpperCase() == 'COMPLETED';
            if (!isCompleted || m.sideAScore == m.sideBScore) continue;
            final sideAWon = m.sideAScore > m.sideBScore;
            for (final mem in m.sideAMembers) {
              recordResult(mem.userId, sideAWon, mem.isMock);
            }
            for (final mem in m.sideBMembers) {
              recordResult(mem.userId, !sideAWon, mem.isMock);
            }
          }
        } catch (_) {}
      }();

      await Future.wait([
        tourFetchFuture,
        sessionFetchFuture,
        standaloneFetchFuture,
      ]);

      return memberStatsMap;
    });
