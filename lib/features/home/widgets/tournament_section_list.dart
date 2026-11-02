import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/match_status_filter.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/home_skeletons.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/explore/widgets/live_tournament_with_matches_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/home_match_feed_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Số card skeleton hiển thị khi feed đang quét mà chưa có card nào.
const _skeletonCards = 3;

/// Feed trận của tab Khám phá. Dữ liệu đến từ [homeMatchFeedProvider] (một
/// nguồn, có trần request); widget này chỉ chọn hiển thị: skeleton khi đang
/// quét, danh sách card, thông báo rỗng, hoặc lỗi kèm nút thử lại.
class TournamentSectionList extends ConsumerStatefulWidget {
  final List<Tournament> tournaments;
  final MatchStatusFilter filter;
  final String emptyMessage;
  final VoidCallback? onNoLiveMatches;

  const TournamentSectionList({
    super.key,
    required this.tournaments,
    required this.filter,
    required this.emptyMessage,
    this.onNoLiveMatches,
  });

  @override
  ConsumerState<TournamentSectionList> createState() =>
      _TournamentSectionListState();
}

class _TournamentSectionListState extends ConsumerState<TournamentSectionList>
    with WidgetsBindingObserver {
  HomeMatchFeedNotifier? _feed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _feed?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final tournaments = widget.tournaments;
    final filter = widget.filter;
    final emptyMessage = widget.emptyMessage;
    final onNoLiveMatches = widget.onNoLiveMatches;
    if (tournaments.isEmpty) {
      _feed = null;
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final query = HomeMatchFeedQuery(
      status: filter,
      tournamentIds: [for (final t in tournaments) t.id],
    );
    final provider = homeMatchFeedProvider(query);
    final feed = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    _feed = notifier;

    ref.listen(provider, (_, next) {
      final nothingLive =
          filter == MatchStatusFilter.live &&
          !next.isScanning &&
          !next.hasVisible &&
          !next.hasError;
      if (nothingLive) onNoLiveMatches?.call();
    });

    final byId = {for (final t in tournaments) t.id: t};
    final cards = [
      for (final id in feed.revealedIds)
        if (byId[id] != null) (tournament: byId[id]!, page: feed.pages[id]!),
    ];
    final variant = switch (filter) {
      MatchStatusFilter.live => SkeletonCardVariant.live,
      MatchStatusFilter.scheduled => SkeletonCardVariant.schedule,
      _ => SkeletonCardVariant.result,
    };

    if (cards.isEmpty) {
      if (feed.isScanning) {
        return SliverToBoxAdapter(
          child: Column(
            children: [
              for (var i = 0; i < _skeletonCards; i++)
                TournamentMatchesCardSkeleton(variant: variant),
            ],
          ),
        );
      }
      return SliverToBoxAdapter(
        child: _StatusMessage(
          message: feed.hasError
              ? AppLocalizations.of(context)!.homeMatchesLoadError
              : emptyMessage,
          action: feed.hasError
              ? _FeedAction(
                  icon: Icons.refresh_rounded,
                  label: AppLocalizations.of(context)!.homeGlobalSearchRetry,
                  onPressed: () {
                    for (final id in feed.opened) {
                      if (feed.pages[id]?.status == FeedPageStatus.error) {
                        notifier.retry(id);
                      }
                    }
                  },
                )
              : null,
        ),
      );
    }

    final showTail = feed.hasMore || feed.isScanning;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < cards.length) {
            final card = cards[index];
            return LiveTournamentWithMatchesCard(
              key: ValueKey(card.tournament.id),
              tournament: card.tournament,
              filter: filter,
              initialPage: card.page,
            );
          }
          return _LoadMoreTail(
            variant: variant,
            scanning: feed.isScanning,
            onVisible: notifier.loadMore,
          );
        },
        childCount: cards.length + (showTail ? 1 : 0),
      ),
    );
  }
}

class _FeedAction {
  final IconData? icon;
  final String label;
  final VoidCallback onPressed;

  const _FeedAction({this.icon, required this.label, required this.onPressed});
}

class _StatusMessage extends StatelessWidget {
  final String message;
  final _FeedAction? action;

  const _StatusMessage({required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final action = this.action;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (action != null)
            action.icon == null
                ? TextButton(
                    onPressed: action.onPressed,
                    child: Text(action.label),
                  )
                : TextButton.icon(
                    onPressed: action.onPressed,
                    icon: Icon(action.icon),
                    label: Text(action.label),
                  ),
        ],
      ),
    );
  }
}

/// Dòng cuối danh sách: luôn là một skeleton đứng yên, không có nút. Mở thêm
/// một đợt giải khi được dựng (tức là người dùng đã cuộn tới cuối) và mở tiếp
/// mỗi khi dựng lại thấy không còn đợt nào đang chạy, nên không
/// chớp giữa skeleton và nút. Cuộn đi chỗ khác thì dòng này không được dựng và
/// việc quét dừng lại.
class _LoadMoreTail extends StatefulWidget {
  final SkeletonCardVariant variant;
  final bool scanning;
  final VoidCallback onVisible;

  const _LoadMoreTail({
    required this.variant,
    required this.scanning,
    required this.onVisible,
  });

  @override
  State<_LoadMoreTail> createState() => _LoadMoreTailState();
}

class _LoadMoreTailState extends State<_LoadMoreTail> {
  @override
  void initState() {
    super.initState();
    _loadNextBatch();
  }

  @override
  void didUpdateWidget(_LoadMoreTail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A batch can finish between two frames, so ask whenever a rebuild finds
    // the feed idle instead of waiting to see the scanning flag flip.
    if (!widget.scanning) _loadNextBatch();
  }

  void _loadNextBatch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onVisible();
    });
  }

  @override
  Widget build(BuildContext context) =>
      TournamentMatchesCardSkeleton(variant: widget.variant);
}
