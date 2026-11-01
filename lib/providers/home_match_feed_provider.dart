import 'dart:async';

import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/cursor_pagination.dart';
import 'package:app_quanly_giaidau/core/utils/match_status_filter.dart';
import 'package:app_quanly_giaidau/core/utils/match_visibility.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FeedPageStatus { loading, ready, empty, error }

/// Trang đầu (4 trận) của một giải trong feed trang chủ.
class FeedPage {
  final FeedPageStatus status;
  final List<MatchModel> items;
  final String? nextCursor;

  const FeedPage(this.status, {this.items = const [], this.nextCursor});
}

/// Khóa của feed: bộ lọc trạng thái và danh sách id giải (đã lọc môn) theo thứ
/// tự hiển thị. Hai khóa bằng nhau thì dùng chung dữ liệu đã tải.
class HomeMatchFeedQuery {
  final MatchStatusFilter status;
  final List<String> tournamentIds;

  const HomeMatchFeedQuery({required this.status, required this.tournamentIds});

  @override
  bool operator ==(Object other) =>
      other is HomeMatchFeedQuery &&
      other.status == status &&
      listEquals(other.tournamentIds, tournamentIds);

  @override
  int get hashCode => Object.hash(status, Object.hashAll(tournamentIds));
}

class HomeMatchFeedState {
  /// Id giải đã mở, theo thứ tự.
  final List<String> opened;
  final Map<String, FeedPage> pages;
  final int total;

  /// Đang có một bước quét chạy (kể cả bước tự nối tiếp).
  final bool isScanning;

  const HomeMatchFeedState({
    this.opened = const [],
    this.pages = const {},
    this.total = 0,
    this.isScanning = false,
  });

  bool get hasMore => opened.length < total;

  List<String> get visibleIds => [
    for (final id in opened)
      if (pages[id]?.status == FeedPageStatus.ready) id,
  ];

  bool get hasVisible => visibleIds.isNotEmpty;

  bool get hasError =>
      pages.values.any((page) => page.status == FeedPageStatus.error);

  HomeMatchFeedState copyWith({
    List<String>? opened,
    Map<String, FeedPage>? pages,
    bool? isScanning,
  }) => HomeMatchFeedState(
    opened: opened ?? this.opened,
    pages: pages ?? this.pages,
    total: total,
    isScanning: isScanning ?? this.isScanning,
  );
}

/// Nguồn dữ liệu duy nhất của tab Trận đấu ở trang chủ: mỗi giải đúng một lần
/// gọi lấy trang đầu, có trần số giải mỗi bước, số request cùng lúc và số bước
/// tự nối tiếp; không socket và không timer theo từng giải.
final homeMatchFeedProvider = NotifierProvider.autoDispose
    .family<HomeMatchFeedNotifier, HomeMatchFeedState, HomeMatchFeedQuery>(
      HomeMatchFeedNotifier.new,
    );

class HomeMatchFeedNotifier extends Notifier<HomeMatchFeedState> {
  static const _log = AppLogger('HomeMatchFeed');

  static const _batchSize = 6;
  static const _maxConcurrent = 3;
  static const _maxEmptySteps = 4;
  static const _firstPageSize = 4;

  /// Chờ một nhịp trước khi quét để đổi bộ lọc liên tục chỉ quét bộ lọc cuối.
  static const _startDelay = Duration(milliseconds: 120);
  static const _tick = Duration(seconds: 30);
  static const _idleTicksBeforeRefresh = 4;
  static const _refreshGate = Duration(milliseconds: 1500);
  static const _keepAfterLastListener = Duration(seconds: 60);

  final HomeMatchFeedQuery query;

  HomeMatchFeedNotifier(this.query);

  final _inFlight = <String>{};
  var _stepRunning = false;
  var _emptySteps = 0;
  var _started = false;
  var _idleTicks = 0;
  var _gated = false;
  Timer? _startTimer;
  Timer? _tickTimer;
  Timer? _gateTimer;
  Timer? _dropTimer;

  @override
  HomeMatchFeedState build() {
    final link = ref.keepAlive();
    ref.onCancel(() {
      _startTimer?.cancel();
      _startTimer = null;
      _tickTimer?.cancel();
      _dropTimer = Timer(_keepAfterLastListener, link.close);
    });
    ref.onResume(() {
      _dropTimer?.cancel();
      _startTicking();
      if (!_started) _scheduleStart();
    });
    ref.onDispose(() {
      _startTimer?.cancel();
      _tickTimer?.cancel();
      _gateTimer?.cancel();
      _dropTimer?.cancel();
    });

    final hasTournaments = query.tournamentIds.isNotEmpty;
    _startTicking();
    if (hasTournaments) _scheduleStart();
    return HomeMatchFeedState(
      total: query.tournamentIds.length,
      isScanning: hasTournaments,
    );
  }

  void _startTicking() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(_tick, (_) => _onTick());
  }

  void _scheduleStart() {
    _startTimer?.cancel();
    _startTimer = Timer(_startDelay, () {
      _startTimer = null;
      _started = true;
      unawaited(loadMore());
    });
  }

  void _onTick() {
    _idleTicks++;
    final liveCardShown =
        query.status == MatchStatusFilter.live && state.hasVisible;
    if (liveCardShown || _idleTicks >= _idleTicksBeforeRefresh) {
      unawaited(refresh());
    }
  }

  /// Mở thêm tối đa 6 giải. Khi chưa có card nào thì tự nối tiếp, tối đa 4 bước.
  Future<void> loadMore({bool auto = false}) async {
    if (_stepRunning || !state.hasMore) return;
    if (!auto) _emptySteps = 0;
    _stepRunning = true;
    final ids = query.tournamentIds
        .skip(state.opened.length)
        .take(_batchSize)
        .toList();
    state = state.copyWith(
      opened: [...state.opened, ...ids],
      isScanning: true,
      pages: {
        ...state.pages,
        for (final id in ids) id: const FeedPage(FeedPageStatus.loading),
      },
    );
    try {
      await _runPool(ids);
    } finally {
      _stepRunning = false;
    }
    if (!ref.mounted) return;

    final keepGoing =
        !state.hasVisible && state.hasMore && ++_emptySteps < _maxEmptySteps;
    if (keepGoing) {
      await loadMore(auto: true);
      return;
    }
    state = state.copyWith(isScanning: false);
  }

  /// Tải lại trang đầu của các giải đã mở, giữ dữ liệu cũ khi lỗi. Các lệnh
  /// không `force` cách nhau dưới 1,5 giây gộp thành một lần.
  Future<void> refresh({bool force = false}) async {
    if (_gated && !force) return;
    _gated = true;
    _gateTimer?.cancel();
    _gateTimer = Timer(_refreshGate, () => _gated = false);
    _idleTicks = 0;
    if (_stepRunning) return;
    final ids = [
      for (final id in state.opened)
        if (state.pages[id]?.status != FeedPageStatus.loading) id,
    ];
    await _runPool(ids);
  }

  Future<void> retry(String tournamentId) async {
    if (_inFlight.contains(tournamentId)) return;
    _setPage(tournamentId, const FeedPage(FeedPageStatus.loading));
    await _load(tournamentId);
  }

  Future<void> _runPool(List<String> ids) async {
    var next = 0;
    Future<void> worker() async {
      while (next < ids.length) {
        await _load(ids[next++]);
      }
    }

    final workers = ids.length < _maxConcurrent ? ids.length : _maxConcurrent;
    await Future.wait([for (var i = 0; i < workers; i++) worker()]);
  }

  Future<void> _load(String id) async {
    if (!_inFlight.add(id)) return;
    try {
      final page = await _fetchFirstPage(id);
      if (ref.mounted) _setPage(id, page);
    } catch (error, stack) {
      _log.error('Không tải được trận của giải $id', error, stack);
      if (!ref.mounted) return;
      final current = state.pages[id]?.status;
      final hasOlderResult =
          current == FeedPageStatus.ready || current == FeedPageStatus.empty;
      if (!hasOlderResult) _setPage(id, const FeedPage(FeedPageStatus.error));
    } finally {
      _inFlight.remove(id);
    }
  }

  void _setPage(String id, FeedPage page) {
    if (!ref.mounted) return;
    state = state.copyWith(pages: {...state.pages, id: page});
  }

  Future<FeedPage> _fetchFirstPage(String id) async {
    final repo = ref.read(matchRepositoryProvider);
    final filter = query.status;
    final page = await fetchCursorPageWhere<MatchModel>(
      startCursor: null,
      accept: (match) => isRenderablePublicMatch(match) && filter.accepts(match),
      fetchPage: (cursor) async {
        final result = await repo.getTournamentMatchesPaged(
          tournamentId: id,
          status: filter.toServerParam(),
          cursor: cursor,
          limit: _firstPageSize,
          trigger: 'home_feed',
        );
        return (items: result.matches, nextCursor: result.nextCursor);
      },
    );
    return page.items.isEmpty
        ? const FeedPage(FeedPageStatus.empty)
        : FeedPage(
            FeedPageStatus.ready,
            items: page.items,
            nextCursor: page.nextCursor,
          );
  }
}
