import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_quanly_giaidau/core/di/di.dart';

class MyTournamentWorkspaceNotifier extends AsyncNotifier<TournamentWorkspace> {
  static const _log = AppLogger('MyTournamentWorkspaceNotifier');

  @override
  Future<TournamentWorkspace> build() async {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      return TournamentWorkspace.empty;
    }

    final repository = ref.read(tournamentRepositoryProvider);
    return repository.getMyWorkspace();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(tournamentRepositoryProvider);
      return repository.getMyWorkspace();
    });
  }

  /// Đang tải trang tiếp theo — khoá để không bấm hai lần là gọi trùng.
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  /// Lấy trang kế tiếp bằng cursor rồi nối vào dữ liệu hiện có.
  ///
  /// Không đụng `state` khi đang tải, đã hết trang, hoặc workspace rỗng — gọi
  /// lại không gây hại.
  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.nextCursor == null) {
      return;
    }
    if (_isLoadingMore) return;

    _isLoadingMore = true;
    try {
      final repository = ref.read(tournamentRepositoryProvider);
      final next = await repository.getMyWorkspace(cursor: current.nextCursor);
      state = AsyncValue.data(current.mergePage(next));
    } catch (e, stack) {
      // Giữ nguyên dữ liệu cũ: cuộn tới đáy thấy lỗi rồi thử lại, không mất
      // những gì đã tải được.
      _log.error('Không tải được trang giải tiếp theo', e, stack);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> respondToRefereeInvite({
    required String tournamentId,
    required String refereeId,
    required String action,
  }) async {
    final previous = state.asData?.value ?? TournamentWorkspace.empty;
    final repository = ref.read(tournamentRepositoryProvider);

    state = AsyncValue.data(
      _optimisticWorkspace(
        previous,
        tournamentId: tournamentId,
        refereeId: refereeId,
        action: action,
      ),
    );

    try {
      await repository.respondToRefereeInvite(
        tournamentId: tournamentId,
        refereeId: refereeId,
        action: action,
      );
      await refresh();
      _log.success('Phản hồi lời mời trọng tài thành công');
    } catch (e, stack) {
      _log.error('Lỗi phản hồi lời mời trọng tài', e, stack);
      state = AsyncValue.data(previous);
      rethrow;
    }
  }

  TournamentWorkspace _optimisticWorkspace(
    TournamentWorkspace workspace, {
    required String tournamentId,
    required String refereeId,
    required String action,
  }) {
    final nextStatus = action.toUpperCase() == 'ACCEPT' ? 'ACCEPTED' : 'DECLINED';
    final remainingInvites = workspace.refereeInvites.where((invite) {
      return !(invite.tournamentId == tournamentId && invite.refereeId == refereeId);
    }).toList();

    final acceptedInvites = [...workspace.refereeTournaments];
    if (nextStatus == 'ACCEPTED') {
      final accepted = workspace.refereeInvites.where((invite) {
        return invite.tournamentId == tournamentId && invite.refereeId == refereeId;
      }).map((invite) {
        return TournamentRefereeInvite(
          refereeId: invite.refereeId,
          tournamentId: invite.tournamentId,
          tournamentName: invite.tournamentName,
          tournamentStatus: invite.tournamentStatus,
          categoryName: invite.categoryName,
          assignedAt: invite.assignedAt,
          status: nextStatus,
        );
      });
      acceptedInvites.insertAll(0, accepted);
    }

    return TournamentWorkspace(
      organizedTournaments: workspace.organizedTournaments,
      participatingTournaments: workspace.participatingTournaments,
      coOrganizerTournaments: workspace.coOrganizerTournaments,
      refereeInvites: remainingInvites,
      refereeTournaments: acceptedInvites,
      refereeMatches: workspace.refereeMatches,
    );
  }
}

final myTournamentWorkspaceProvider =
    AsyncNotifierProvider<MyTournamentWorkspaceNotifier, TournamentWorkspace>(
  MyTournamentWorkspaceNotifier.new,
);

final myRefereeInvitesProvider = Provider<AsyncValue<List<TournamentRefereeInvite>>>((ref) {
  final workspaceAsync = ref.watch(myTournamentWorkspaceProvider);
  return workspaceAsync.whenData((workspace) => workspace.refereeInvites);
});
