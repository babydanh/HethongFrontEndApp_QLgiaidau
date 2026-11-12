import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// First page and every following page hold this many tournaments.
const kOrganizedPageSize = 4;

class OrganizedTournamentsState {
  const OrganizedTournamentsState({
    this.items = const [],
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<Tournament> items;
  final String? nextCursor;
  final bool isLoadingMore;

  /// The last "Xem thêm" request failed; loaded rows are kept for a retry.
  final bool loadMoreFailed;

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  OrganizedTournamentsState copyWith({
    List<Tournament>? items,
    String? nextCursor,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) => OrganizedTournamentsState(
    items: items ?? this.items,
    nextCursor: nextCursor ?? this.nextCursor,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

/// Own tournaments for the profile: 4 per page via `workspace/me?role=ORGANIZER`.
class OrganizedTournamentsNotifier
    extends AsyncNotifier<OrganizedTournamentsState> {
  static const _log = AppLogger('OrganizedTournamentsNotifier');

  @override
  Future<OrganizedTournamentsState> build() async {
    final page = await ref
        .read(tournamentRepositoryProvider)
        .getMyWorkspace(limit: kOrganizedPageSize, role: 'ORGANIZER');
    return OrganizedTournamentsState(
      items: page.organizedTournaments,
      nextCursor: page.nextCursor,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    // The loading flag lives in state so a fast double tap is ignored too.
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final page = await ref
          .read(tournamentRepositoryProvider)
          .getMyWorkspace(
            cursor: current.nextCursor,
            limit: kOrganizedPageSize,
            role: 'ORGANIZER',
          );
      final seen = {for (final t in current.items) t.id};
      state = AsyncData(
        OrganizedTournamentsState(
          items: [
            ...current.items,
            ...page.organizedTournaments.where((t) => seen.add(t.id)),
          ],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (e, stack) {
      _log.error('Không tải được trang giải tổ chức tiếp theo', e, stack);
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreFailed: true),
      );
    }
  }
}

final organizedTournamentsProvider =
    AsyncNotifierProvider.autoDispose<
      OrganizedTournamentsNotifier,
      OrganizedTournamentsState
    >(OrganizedTournamentsNotifier.new);
