import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/features/match/utils/pickleball_court.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

CourtState _courtFromScoreDetails(Map<String, dynamic>? scoreDetails) =>
    CourtState.fromJson(scoreDetails?['courtState']);

/// Trạng thái hiển thị khi có bản server. Server chưa có lượt giao (mở màn
/// không ghi nên server có thể chưa có) thì giữ lượt suy tại chỗ.
CourtState _displayFromServer(CourtState server, CourtState local) =>
    server.turnStart == null && local.turnStart != null
    ? server.copyWith(turnStart: local.turnStart)
    : server;

/// Đội (1 hoặc 2) vừa được cộng điểm gần nhất trong phiên. Rally giao theo
/// đội này. Null khi chưa quan sát được điểm nào.
class PickleballLastScoringTeamNotifier extends Notifier<int?> {
  PickleballLastScoringTeamNotifier(this._arg);

  final MatchControlParams _arg;

  @override
  int? build() {
    ref.listen(scorePanelNotifierProvider(_arg), (previous, next) {
      final before = previous?.rally;
      final after = next.rally;
      if (before == null || after == null) return;
      if (after.currentP1 > before.currentP1) {
        state = 1;
      } else if (after.currentP2 > before.currentP2) {
        state = 2;
      }
    });
    return null;
  }
}

final pickleballLastScoringTeamProvider = NotifierProvider.autoDispose
    .family<PickleballLastScoringTeamNotifier, int?, MatchControlParams>(
      PickleballLastScoringTeamNotifier.new,
    );

/// Ngữ cảnh suy vị trí sân từ điểm và cấu hình trận. Null khi chưa có trận.
final pickleballCourtContextProvider = Provider.autoDispose
    .family<CourtContext?, MatchControlParams>((ref, arg) {
      final match = ref.watch(singleMatchProvider(arg)).value;
      if (match == null) return null;
      final panel = ref.watch(scorePanelNotifierProvider(arg));
      final lastScoringTeam = ref.watch(pickleballLastScoringTeamProvider(arg));
      final rally = panel.rally ?? const RallySetState();
      final serve = panel.pickleball;
      final team1PlayerCount = (match.team1Members?.length ?? 0) >= 2 ? 2 : 1;
      final team2PlayerCount = (match.team2Members?.length ?? 0) >= 2 ? 2 : 1;
      final config = panel.config;
      final setIndex = panel.finishedSets.length;
      return CourtContext(
        score1: rally.currentP1,
        score2: rally.currentP2,
        isDoubles: team1PlayerCount == 2 || team2PlayerCount == 2,
        team1PlayerCount: team1PlayerCount,
        team2PlayerCount: team2PlayerCount,
        servingTeam: serve == null
            ? lastScoringTeam
            : (serve.isTeam1Serving ? 1 : 2),
        serverNumber: serve?.serverNumber ?? 1,
        scoringMode: serve == null
            ? CourtScoringMode.rally
            : CourtScoringMode.sideOut,
        setIndex: setIndex,
        targetPoints: config.pointsPerSet,
        isDecidingSet: !config.isOpenScoring && setIndex == config.bestOf - 1,
      );
    });

/// Trạng thái sơ đồ sân của một trận. Nguồn sự thật là server
/// (`scoreDetails.courtState`). Thay đổi cài đặt áp dụng lạc quan rồi ghi
/// server; ghi lỗi thì quay về trạng thái server đã xác nhận.
class PickleballCourtNotifier extends Notifier<CourtState> {
  PickleballCourtNotifier(this._arg);

  final MatchControlParams _arg;
  CourtState _server = const CourtState();
  int _pendingWrites = 0;
  int _writeSeq = 0;
  bool _disposed = false;
  /// Lần đồng bộ đầu tiên (mở màn): chỉ suy lượt tại chỗ, không ghi server.
  bool _hasSynced = false;
  /// Các lỗi ghi đã báo trong phiên; cùng một loại chỉ báo một lần.
  final Set<String> _reportedErrors = <String>{};

  @override
  CourtState build() {
    ref.onDispose(() => _disposed = true);
    _server = _courtFromScoreDetails(
      ref.read(singleMatchProvider(_arg)).value?.scoreDetails,
    );
    ref.listen(singleMatchProvider(_arg), (previous, next) {
      final match = next.value;
      if (match == null) return;
      _server = _courtFromScoreDetails(match.scoreDetails);
      if (_pendingWrites == 0) state = _displayFromServer(_server, state);
    });
    return _server;
  }

  /// Áp dụng một hành động cài đặt (⚙ hoặc hoàn tác). Trả về lỗi khi ghi server
  /// thất bại, null khi thành công hoặc không cần ghi.
  Future<Object?> apply(
    CourtState Function(CourtState state, CourtContext context) action,
  ) async {
    final context = ref.read(pickleballCourtContextProvider(_arg));
    if (context == null) return null;
    final next = action(state, context);
    if (!needsServerWrite(state, next)) {
      state = next;
      return null;
    }
    return _persist(next);
  }

  /// Sau mỗi điểm và khi mở màn: suy lại lượt giao và mốc đổi sân. Lần đầu
  /// (mở màn) chỉ suy tại chỗ, không ghi server; các thay đổi sau đó mới ghi.
  Future<Object?> syncAutomatic() async {
    final context = ref.read(pickleballCourtContextProvider(_arg));
    if (context == null) return null;
    final reconciled = reconcileCourtState(state, context);
    if (!_hasSynced) {
      _hasSynced = true;
      state = reconciled;
      return null;
    }
    if (!needsServerWrite(state, reconciled)) return null;
    return _persist(reconciled);
  }

  /// Báo lỗi ghi cho người dùng: true lần đầu gặp [message] trong phiên này.
  bool claimErrorReport(String message) => _reportedErrors.add(message);

  Future<Object?> _persist(CourtState next) async {
    final seq = ++_writeSeq;
    _pendingWrites++;
    state = next;
    final repository = ref.read(matchRepositoryProvider);
    try {
      final saved = await repository.updateCourtState(
        _arg.matchId,
        next.toJson(),
      );
      _server = _courtFromScoreDetails(saved.scoreDetails);
      if (seq == _writeSeq && !_disposed) state = _server;
      return null;
    } catch (error) {
      if (seq == _writeSeq && !_disposed) {
        state = _displayFromServer(_server, state);
      }
      return error;
    } finally {
      _pendingWrites--;
    }
  }
}

final pickleballCourtNotifierProvider = NotifierProvider.autoDispose
    .family<PickleballCourtNotifier, CourtState, MatchControlParams>(
      PickleballCourtNotifier.new,
    );
