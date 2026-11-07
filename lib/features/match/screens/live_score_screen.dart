import 'package:app_quanly_giaidau/core/widgets/skeleton/list_skeletons.dart';
import 'package:app_quanly_giaidau/shared/widgets/content_skeletons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/core/utils/tournament_location_formatter.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';

import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations_extensions.dart';

import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/services/live_control_access.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/match_score_access_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:app_quanly_giaidau/features/match/widgets/penalty_input_dialog.dart';
import 'package:app_quanly_giaidau/core/participants/match_side_players.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/features/match/utils/live_bracket_scope.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_video_box.dart';
import 'package:app_quanly_giaidau/features/match/widgets/official_score_modal.dart';
import 'package:app_quanly_giaidau/core/strategy/penalty_strategy.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/domain/entities/match_event.dart';
import 'package:app_quanly_giaidau/domain/entities/penalty.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/match/widgets/match_discussion_message.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/domain/entities/live_overlay_kind.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_overlay_controls.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_viewer_header.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_comment_input.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_h2h_overlay.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_scoreboard_overlay.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_viewer_suggestions.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_chat_grouping.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_landscape_chat.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_match_details_sheet.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_match_sides.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_new_messages_pill.dart';
import 'package:app_quanly_giaidau/shared/widgets/report_sheet.dart';


class _HeartModel {
  final double startX;
  final double scale;
  final Color color;
  final double speed;
  double yProgress = 0.0;

  _HeartModel({
    required this.startX,
    required this.scale,
    required this.color,
    required this.speed,
  });
}

class LiveScoreScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String matchId;
  final bool isViewer;

  const LiveScoreScreen({
    super.key,
    required this.tournamentId,
    required this.matchId,
    this.isViewer = false,
  });

  @override
  ConsumerState<LiveScoreScreen> createState() => _LiveScoreScreenState();
}

class _LiveScoreScreenState extends ConsumerState<LiveScoreScreen>
    with TickerProviderStateMixin {
  final _maxScoreController = TextEditingController(text: '21');
  final _timeLimitController = TextEditingController();
  bool _winByTwo = true;
  bool _didSeedSetupControls = false;

  String _effectiveTournamentId([MatchModel? match]) {
    if (widget.tournamentId.isNotEmpty) return widget.tournamentId;
    if (match?.tournamentId?.isNotEmpty == true) return match!.tournamentId!;
    final matchFromSub = ref
        .read(
          singleMatchProvider((
            tournamentId: widget.tournamentId,
            matchId: widget.matchId,
          )),
        )
        .value;
    return matchFromSub?.tournamentId ?? '';
  }

  Future<bool> _startMatchSafely({required String tournamentId}) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(
            matchControllerProvider((
              tournamentId: tournamentId,
              matchId: widget.matchId,
            )),
          )
          .startMatch();
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorParser.parse(error, l10n.liveMatchStartError, l10n),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  // Viewer layout: 0 = Chat, 1 = More videos.
  int _liveTab = 0;
  bool _landscapeChatOpen = true;
  bool _systemChromeTouched = false;
  Timer? _orientationReleaseTimer;
  final ScrollController _chatScroll = ScrollController();
  // Chat length when the viewer scrolled up; newer rows stay hidden (and are
  // counted on the pill) until they return to the bottom.
  int? _chatBaseline;
  int _lastChatLength = 0;
  int _cheerCount = 0;
  bool _loadingCheerCount = false;
  LiveOverlayKind? _pendingOverlayKind;
  // Overlay bị nút đóng ẩn cục bộ; đổi cờ server sẽ xóa trạng thái này.
  LiveOverlayKind? _dismissedOverlay;
  final List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  StreamSubscription? _commentSub;
  StreamSubscription? _cheerSub;
  final _commentTextController = TextEditingController();
  bool _isSubmittingComment = false;

  late AnimationController _livePulseCtrl;
  late Animation<double> _livePulseAnim;

  // Score animation
  int _lastScore1 = 0;
  int _lastScore2 = 0;

  final List<_HeartModel> _hearts = [];
  Timer? _heartTimer;

  void _spawnHeart() {
    final random = math.Random();
    final colors = [
      const Color(0xFFEF4444),
      const Color(0xFFEC4899),
      const Color(0xFFF43F5E),
      const Color(0xFFD946EF),
      const Color(0xFF8B5CF6),
    ];
    setState(() {
      for (int i = 0; i < 3; i++) {
        _hearts.add(
          _HeartModel(
            startX: 20.0 + random.nextDouble() * 50.0,
            scale: 0.6 + random.nextDouble() * 0.8,
            color: colors[random.nextInt(colors.length)],
            speed: 0.012 + random.nextDouble() * 0.012,
          ),
        );
      }
    });

    _heartTimer ??= Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        for (int i = _hearts.length - 1; i >= 0; i--) {
          _hearts[i].yProgress += _hearts[i].speed;
          if (_hearts[i].yProgress >= 1.0) {
            _hearts.removeAt(i);
          }
        }
      });

      if (_hearts.isEmpty) {
        timer.cancel();
        _heartTimer = null;
      }
    });
  }

  Future<void> _loadCheerCount() async {
    if (_loadingCheerCount) return;
    _loadingCheerCount = true;
    try {
      final count = await ref
          .read(matchRepositoryProvider)
          .getCheerCount(widget.matchId);
      if (mounted) setState(() => _cheerCount = count);
    } catch (_) {
      // The count is cosmetic; keep the last known value.
    } finally {
      _loadingCheerCount = false;
    }
  }

  Future<void> _handleCheer() async {
    _spawnHeart();
    setState(() => _cheerCount++);
    try {
      await ref.read(matchRepositoryProvider).cheerMatch(widget.matchId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.liveCheerFailed)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _livePulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _livePulseAnim = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _livePulseCtrl, curve: Curves.easeInOut));

    // Fetch comments and connect WebSocket for all users
    _fetchComments();
    _setupSocketComments();
    _loadCheerCount();
    _chatScroll.addListener(_onChatScroll);
  }

  static const _chatBottomSlack = 80.0;

  void _onChatScroll() {
    if (!_chatScroll.hasClients) return;
    final scrolledUp = _chatScroll.offset > _chatBottomSlack;
    if (scrolledUp && _chatBaseline == null) {
      setState(() => _chatBaseline = _lastChatLength);
    } else if (!scrolledUp && _chatBaseline != null) {
      setState(() => _chatBaseline = null);
    }
  }

  void _jumpToLatestChat() {
    if (!_chatScroll.hasClients) return;
    _chatScroll.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Portrait <-> landscape fullscreen for the video. Landscape locks the
  /// orientation and hides the system bars; leaving restores both.
  Future<void> _toggleFullscreen() async {
    final entering =
        MediaQuery.of(context).orientation == Orientation.portrait;
    _systemChromeTouched = true;
    _orientationReleaseTimer?.cancel();
    if (entering) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      return;
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    // Give the rotation a moment, then let auto-rotate work again.
    _orientationReleaseTimer = Timer(const Duration(milliseconds: 600), () {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    });
  }

  void _restoreSystemChrome() {
    _orientationReleaseTimer?.cancel();
    if (!_systemChromeTouched) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  Future<void> _reportMatch(MatchModel match) async {
    final auth = ref.read(authProvider);
    if (auth.status != AuthStatus.authenticated) {
      context.push('/login');
      return;
    }
    await ReportSheet.show(context, targetId: match.id, targetType: 'match');
  }

  @override
  void dispose() {
    _maxScoreController.dispose();
    _timeLimitController.dispose();
    _chatScroll.dispose();
    _restoreSystemChrome();
    _commentSub?.cancel();
    _cheerSub?.cancel();
    try {
      ref.read(matchSocketServiceProvider).leave(widget.matchId);
    } catch (_) {}
    _commentTextController.dispose();
    _livePulseCtrl.dispose();
    _heartTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.get('/matches/${widget.matchId}/comments');
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = response.data['data'] as List?;
        if (data != null) {
          setState(() {
            _comments.clear();
            _comments.addAll(
              data.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
            );
          });
        }
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  void _setupSocketComments() {
    final socket = ref.read(matchSocketServiceProvider);
    socket.connect(widget.matchId);

    _commentSub = socket.onCommentNew.listen((data) {
      if (data['matchId'] == widget.matchId || data['matchId'] == null) {
        if (!mounted) return;
        setState(() {
          if (!_comments.any((c) => c['id'] == data['id'])) {
            _comments.insert(0, data);
          }
        });
      }
    });

    _cheerSub = socket.onCheerUpdate.listen((data) {
      if (!mounted) return;
      _spawnHeart();
      _loadCheerCount();
    });
  }

  Future<void> _postComment() async {
    final text = _commentTextController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingComment = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post(
        '/matches/${widget.matchId}/comments',
        data: {'commentText': text},
      );
      _commentTextController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.liveCommentFailed),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  void _trackScoreChanges(MatchModel match) {
    final currentScore = _currentLiveScore(match);
    if (currentScore.score1 != _lastScore1) {
      setState(() {
        _lastScore1 = currentScore.score1;
      });
    }
    if (currentScore.score2 != _lastScore2) {
      setState(() {
        _lastScore2 = currentScore.score2;
      });
    }
  }

  List<SetScoreData> _scoreDetailsSets(MatchModel match) {
    final rawSets = match.scoreDetails?['sets'];
    if (rawSets is! List) return const [];
    return rawSets.whereType<Map>().map((rawSet) {
      return SetScoreData.fromJson(Map<String, dynamic>.from(rawSet));
    }).toList();
  }

  /// Live score is the currently open set, not the match-level set aggregate.
  /// The API keeps p1SetsWon/p2SetsWon in score1/score2 for compatibility, so
  /// using those fields directly makes the viewer show 0-0 or a set tally after
  /// the previous set is closed. This mirrors the web live page's
  /// scoreDetails.sets source of truth.
  SetScoreData _currentLiveScore(
    MatchModel match, [
    ScorePanelState? scorePanelState,
  ]) {
    final sets = _scoreDetailsSets(match);
    final activeSet = sets.where((set) => !set.isFinished).lastOrNull;
    final rally = scorePanelState?.rally;
    final localActiveSet = scorePanelState?.finishedSets
        .where((set) => !set.isFinished)
        .lastOrNull;
    // Prefer a local optimistic point while it is ahead of the server echo,
    // but do not let a stale 0-0 notifier state hide a newer active set from
    // scoreDetails.
    if (rally != null && (rally.currentP1 > 0 || rally.currentP2 > 0)) {
      return SetScoreData(score1: rally.currentP1, score2: rally.currentP2);
    }
    if (localActiveSet != null) return localActiveSet;
    if (activeSet != null) return activeSet;
    // After closing a set the next set starts at 0-0. Keep that local zero
    // instead of falling back to the previous finished set's score.
    if (rally != null) {
      return SetScoreData(score1: rally.currentP1, score2: rally.currentP2);
    }
    if (scorePanelState?.config.scoringModel == SportScoringModel.tennisSet &&
        !match.isCompleted) {
      return const SetScoreData(score1: 0, score2: 0);
    }
    if (sets.isNotEmpty) return sets.last;
    return SetScoreData(score1: match.score1, score2: match.score2);
  }

  // ═══════════════════════════════════════════════════════════
  //  FOUL / PENALTY
  // ═══════════════════════════════════════════════════════════

  void _showFoulSheet(MatchModel match) {
    final effectiveId = _effectiveTournamentId(match);
    final tournamentAsync = effectiveId.isNotEmpty
        ? ref.read(tournamentProvider(effectiveId))
        : null;
    final sport = match.sportKey ?? tournamentAsync?.value?.sport ?? 'other';

    showDialog(
      context: context,
      builder: (_) => PenaltyInputDialog(
        sportType: sport,
        team1Label: matchSideLabel(match, 1),
        team2Label: matchSideLabel(match, 2),
        onSubmit: (teamSide, option, reason) {
          final isT1 = teamSide == 1;
          ref
              .read(
                matchControllerProvider((
                  tournamentId: effectiveId,
                  matchId: widget.matchId,
                )),
              )
              .addPenalty(isT1, sport, option.id, option.name, reason);
        },
      ),
    );
  }

  Future<void> _submitPenalty(
    MatchModel match,
    int teamSide,
    PenaltyOption option,
    String reason,
  ) async {
    final effectiveId = _effectiveTournamentId(match);
    final tournamentAsync = effectiveId.isNotEmpty
        ? ref.read(tournamentProvider(effectiveId))
        : null;
    final sport = match.sportKey ?? tournamentAsync?.value?.sport ?? 'other';
    final isTeam1 = teamSide == 1;
    await ref
        .read(
          matchControllerProvider((
            tournamentId: effectiveId,
            matchId: widget.matchId,
          )),
        )
        .addPenalty(isTeam1, sport, option.id, option.name, reason);
  }

  void _showFoulSelectionDialog(MatchModel match) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgCard,
        title: Row(
          children: [
            const Icon(
              Icons.sports_kabaddi_rounded,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.liveFoulSelectTeam,
              style: TextStyle(color: context.colors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.sports_rounded,
                  color: Colors.blueAccent,
                ),
              ),
              title: Text(
                matchSideLabel(match, 1),
                style: TextStyle(color: context.colors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showFoulSheet(match);
              },
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.sports_rounded,
                  color: Colors.redAccent,
                ),
              ),
              title: Text(
                matchSideLabel(match, 2),
                style: TextStyle(color: context.colors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showFoulSheet(match);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showForceWinDialog(MatchModel match) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgCard,
        title: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              l10n.liveForceWinTitle,
              style: TextStyle(color: context.colors.error),
            ),
          ],
        ),
        content: Text(
          l10n.liveForceWinContent,
          style: TextStyle(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await _forceWinMatch(match.team1Id, match.team2Id);
            },
            child: Text(matchSideLabel(match, 1)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await _forceWinMatch(match.team2Id, match.team1Id);
            },
            child: Text(matchSideLabel(match, 2)),
          ),
        ],
      ),
    );
  }

  Future<void> _forceWinMatch(String winnerId, String loserId) async {
    final effectiveId = _effectiveTournamentId();
    final match = ref
        .read(
          singleMatchProvider((
            tournamentId: effectiveId,
            matchId: widget.matchId,
          )),
        )
        .value;
    if (match == null) return;
    final scorePanelParams = (
      tournamentId: effectiveId,
      matchId: widget.matchId,
    );
    final currentScore = _currentLiveScore(
      match,
      ref.read(scorePanelNotifierProvider(scorePanelParams)),
    );
    try {
      await ref
          .read(matchControllerProvider(scorePanelParams))
          .completeMatchWithDetails(
            winnerId: winnerId,
            loserId: loserId,
            finalSets: [
              SetScoreData(
                score1: currentScore.score1,
                score2: currentScore.score2,
                isFinished: true,
              ),
            ],
            overrideReason: 'Xử thắng trực tiếp (force win)',
            expectedRevision: match.revision,
          );
      if (mounted) context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.scorePanel_completeError(error),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveTournamentId = _effectiveTournamentId();
    final matchAsync = ref.watch(
      singleMatchProvider((
        tournamentId: effectiveTournamentId,
        matchId: widget.matchId,
      )),
    );

    // Nút đóng chỉ ẩn cục bộ; đổi cờ server (socket hoặc snapshot) thì xóa.
    ref.listen(
      singleMatchProvider((
        tournamentId: effectiveTournamentId,
        matchId: widget.matchId,
      )),
      (previous, next) {
        final before = previous?.value;
        final after = next.value;
        if (before == null || after == null) return;
        final flagsChanged =
            before.h2hOverlayVisible != after.h2hOverlayVisible ||
            before.bracketOverlayVisible != after.bracketOverlayVisible;
        if (flagsChanged && _dismissedOverlay != null) {
          setState(() => _dismissedOverlay = null);
        }
      },
    );

    ref.watch(
      matchControllerProvider((
        tournamentId: effectiveTournamentId,
        matchId: widget.matchId,
      )),
    );
    final auth = ref.watch(authProvider);
    final match = matchAsync.value;
    final tournamentAsync = effectiveTournamentId.isNotEmpty
        ? ref.watch(tournamentProvider(effectiveTournamentId))
        : null;
    final isSuperLiteMatch = isSuperLiteTournament(
      tournamentConfig: match?.tournamentConfig,
      tournamentIsLite: tournamentAsync?.value?.isLite == true,
    );
    // A completed match remains viewable, but must never expose a scoring
    // action again. This also prevents the old score panel from appearing
    // after the server has finalized the match.
    final profileId = ref.watch(userProfileProvider).asData?.value.id;
    final scoreAccess = auth.isAuthenticated && effectiveTournamentId.isNotEmpty
        ? ref.watch(matchScoreAccessProvider(widget.matchId)).asData?.value
        : null;
    // A referee signed in with a tournament token has no user profile, so keep
    // their access for the tournament the token was issued for.
    final isTokenReferee =
        auth.isReferee &&
        effectiveTournamentId.isNotEmpty &&
        auth.tournamentId == effectiveTournamentId;
    final canOpenScoring =
        match != null &&
        !match.isCompleted &&
        ((isSuperLiteMatch && auth.isAuthenticated) ||
            isTokenReferee ||
            canControlTournamentLive(
              userId: profileId,
              isAdmin: auth.isAdmin,
              createdBy: tournamentAsync?.value?.creatorId,
              refereeId: match.refereeId,
              scoreAccess: scoreAccess,
            ));
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Every account gets the same modern page: back/share/menu (and, for a
    // scorer, the scoring button) sit on the video instead of an AppBar (see
    // _buildViewerState). Only the pre-match setup page keeps its AppBar, and
    // so do loading and empty states, so the user always has a back button.
    final showsSetup =
        match != null &&
        !widget.isViewer &&
        canOpenScoring &&
        match.isScheduled;
    final useViewerLayout = match != null && !showsSetup;

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: useViewerLayout
          ? null
          : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (matchAsync.value?.isLive == true)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FadeTransition(
                  opacity: _livePulseAnim,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.colors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.error.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Text(
              (!widget.isViewer && canOpenScoring)
                  ? l10n.liveRefereeDeskTitle
                  : (matchAsync.value?.isLive == true
                        ? l10n.liveMatchTitle
                        : l10n.liveMatchDetailsTitle),
              style: TextStyle(
                fontSize: isLandscape ? 16 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: true,
        toolbarHeight: isLandscape ? 40 : 52,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: isLandscape ? 18 : 22,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (canOpenScoring)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _scoringAction(match),
            ),
        ],
      ),
      body: Stack(
        children: [
          matchAsync.when(
            data: (match) {
              if (match == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: context.colors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.liveMatchNotFound,
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              // Track score changes for animation
              _trackScoreChanges(match);

              if (match.isLive) {
                // Live state — scoring handled via scorePanelNotifierProvider
              }

              // Every match card/deep link opens the shared live detail page.
              // Scoring is an explicit action inside that page, including
              // Super Lite matches.
              if (widget.isViewer) {
                return _buildLiveState(match, canOpenScoring: canOpenScoring);
              }

              // No scoring right: show the read-only page instead of the
              // referee-desk layout, which overflows on phone widths.
              if (!canOpenScoring) {
                return _buildViewerState(match, canControl: false);
              }

              if (match.isScheduled) {
                return _buildSetupState(match);
              } else if (match.isLive) {
                return _buildLiveState(match, canOpenScoring: canOpenScoring);
              } else {
                return _buildLiveState(match, canOpenScoring: false);
              }
            },
            loading: () => const ScrollFreeSkeleton(child: DetailPageSkeleton()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: context.colors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ErrorParser.parse(e, l10n.liveMatchLoadError),
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: Text(l10n.liveBack),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: _hearts.map((heart) {
                  final double opacity = math.max(0.0, 1.0 - heart.yProgress);
                  return Positioned(
                    bottom: 80.0 + (heart.yProgress * 320.0),
                    right:
                        heart.startX +
                        math.sin(heart.yProgress * 4 * math.pi) * 16.0,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: heart.scale,
                        child: Icon(
                          Icons.favorite_rounded,
                          color: heart.color,
                          size: 26,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SETUP STATE — Cấu hình trận đấu
  // ═══════════════════════════════════════════════════════════
  Widget _buildLiteSetupState(
    MatchModel match,
    SportRuleKind kind,
    SportConfig config,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: context.colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.sports_score_rounded,
                color: context.colors.info,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.liveMatchInfo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${matchSideLabel(match, 1)} ${l10n.matchVsLabel} '
                '${matchSideLabel(match, 2)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.colors.info,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.bgDark,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.liveAppliedRules,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.liveAppliedRulesDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSetupChip(
                          l10n.liveSportLabel,
                          (() {
                            final sportKey =
                                match.sportKey ??
                                ref
                                    .watch(
                                      tournamentProvider(widget.tournamentId),
                                    )
                                    .value
                                    ?.sport;
                            return sportKey == null || sportKey.trim().isEmpty
                                ? _setupSportLabel(kind)
                                : l10n.sportDisplayName(sportKey);
                          })(),
                        ),
                        _buildSetupChip(l10n.liveRuleLabel, l10n.liveOpenRules),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final effectiveId = _effectiveTournamentId(match);
                    final started = await _startMatchSafely(
                      tournamentId: effectiveId,
                    );
                    if (!started || !mounted) return;
                    showOfficialScoreModal(
                      context,
                      tournamentId: effectiveId,
                      matchId: widget.matchId,
                      match: match.copyWith(
                        status: 'ONGOING',
                        startedAt: DateTime.now(),
                      ),
                      onSubmitPenalty: (teamSide, option, reason) =>
                          _submitPenalty(match, teamSide, option, reason),
                      onRecordPenalty: () => _showFoulSelectionDialog(match),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: Text(
                    l10n.liveStartMatch,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 220.ms).scale(begin: const Offset(0.98, 0.98));
  }

  Widget _buildSetupState(MatchModel match) {
    final l10n = AppLocalizations.of(context)!;
    final kind = SportRuleKind.fromString(match.sportKey);
    final effectiveTournamentId = widget.tournamentId.isNotEmpty
        ? widget.tournamentId
        : (match.tournamentId ?? '');
    final tournamentAsync = effectiveTournamentId.isNotEmpty
        ? ref.watch(tournamentProvider(effectiveTournamentId))
        : null;
    final tournamentRules = tournamentAsync?.value?.sportRules;
    final effectiveSportRules =
        tournamentRules != null && tournamentRules.isNotEmpty
        ? {
            ...tournamentRules,
            if (match.sportRules != null && match.sportRules!.isNotEmpty)
              ...match.sportRules!,
          }
        : match.sportRules;
    final config = resolveSportConfig(effectiveSportRules, kind);
    _ensureSetupControlsSeeded(match, config);
    final isLiteMatch = isLiteScoringMode(
      tournamentConfig: match.tournamentConfig,
      sportRules: effectiveSportRules,
      tournamentIsLite: tournamentAsync?.value?.isLite == true,
    );
    if (isLiteMatch) {
      return _buildLiteSetupState(match, kind, config);
    }
    final scoreLabel = _setupScoreLabel(kind, config);

    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: context.colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: context.colors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                ),
                child: Icon(
                  Icons.settings_rounded,
                  color: context.colors.info,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.liveMatchConfiguration,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.colors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${matchSideLabel(match, 1)} ${l10n.matchVsLabel} '
                  '${matchSideLabel(match, 2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.colors.info,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.bgDark,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.liveTournamentConfiguration,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      match.sportRules != null && match.sportRules!.isNotEmpty
                          ? l10n.liveTournamentConfigurationDescription
                          : l10n.liveDefaultConfigurationDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSetupChip(
                          l10n.liveSportLabel,
                          _setupSportLabel(kind),
                        ),
                        _buildSetupChip(
                          l10n.liveFormatLabel,
                          'BO${config.bestOf}',
                        ),
                        _buildSetupChip(
                          l10n.liveWinLabel,
                          l10n.liveSetValue(config.setsToWin),
                        ),
                        _buildSetupChip(
                          l10n.liveSetTargetLabel,
                          kind == SportRuleKind.tennis
                              ? l10n.liveGamesValue(config.pointsPerSet)
                              : l10n.livePointsValue(config.pointsPerSet),
                        ),
                        if (config.mustWinByTwo)
                          _buildSetupChip(
                            l10n.liveRuleLabel,
                            l10n.liveDifferenceTwo,
                          ),
                        if (config.scoringModel ==
                            SportScoringModel.pickleballSideOut)
                          _buildSetupChip(l10n.liveScoringLabel, 'Side-out'),
                        if (kind == SportRuleKind.tennis)
                          _buildSetupChip(
                            l10n.liveTiebreakLabel,
                            l10n.livePointsValue(config.tiebreakPoints ?? 7),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Max score
              TextField(
                controller: _maxScoreController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 16,
                  color: context.colors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: scoreLabel,
                  helperText: l10n.liveTournamentConfigurationDescription,
                  prefixIcon: Icon(
                    Icons.track_changes_rounded,
                    color: context.colors.textMuted,
                  ),
                  filled: true,
                  fillColor: context.colors.bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _timeLimitController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 16,
                  color: context.colors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: l10n.liveTimeLimitLabel,
                  helperText: l10n.liveTimeLimitHelper,
                  prefixIcon: Icon(
                    Icons.timer_outlined,
                    color: context.colors.textMuted,
                  ),
                  filled: true,
                  fillColor: context.colors.bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Win by 2 toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.colors.bgDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_vert_rounded,
                      color: context.colors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.liveWinByTwoSetting(
                          kind == SportRuleKind.tennis
                              ? 'game/points'
                              : 'points',
                        ),
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Switch(
                      value: _winByTwo,
                      onChanged: (val) => setState(() => _winByTwo = val),
                      activeTrackColor: context.colors.info,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Start button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final effectiveId = _effectiveTournamentId(match);
                    await _startMatchSafely(tournamentId: effectiveId);
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    l10n.liveStartMatch,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }

  void _ensureSetupControlsSeeded(MatchModel match, SportConfig config) {
    if (_didSeedSetupControls) {
      return;
    }
    final seededMaxScore = match.maxScore ?? config.pointsPerSet;
    final seededWinByTwo =
        match.sportRules != null && match.sportRules!.isNotEmpty
        ? config.mustWinByTwo
        : match.winByTwo;
    _maxScoreController.text = seededMaxScore.toString();
    _timeLimitController.text = match.timeLimitMinutes != null
        ? match.timeLimitMinutes.toString()
        : '';
    _winByTwo = seededWinByTwo;
    _didSeedSetupControls = true;
  }

  String _setupSportLabel(SportRuleKind kind) {
    final l10n = AppLocalizations.of(context)!;
    switch (kind) {
      case SportRuleKind.tennis:
        return l10n.createClubTournament_sportTennis;
      case SportRuleKind.pickleball:
        return l10n.createClubTournament_sportPickleball;
      case SportRuleKind.tableTennis:
        return l10n.createClubTournament_sportTableTennis;
      case SportRuleKind.badminton:
        return l10n.createClubTournament_sportBadminton;
      case SportRuleKind.football:
        return l10n.createClubTournament_sportFootball;
    }
  }

  String _setupScoreLabel(SportRuleKind kind, SportConfig config) {
    final l10n = AppLocalizations.of(context)!;
    if (kind == SportRuleKind.tennis) {
      return l10n.liveScoreSetupTennisGames(config.pointsPerSet);
    }
    if (config.scoringModel == SportScoringModel.pickleballSideOut) {
      return l10n.liveScoreSetupSideOutPoints(config.pointsPerSet);
    }
    return l10n.liveScoreSetupSetPoints(config.pointsPerSet);
  }

  Widget _buildSetupChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.colors.border),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 11, color: context.colors.textMuted),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  LIVE STATE — Đang thi đấu / Viewer
  // ═══════════════════════════════════════════════════════════
  Widget _buildLiveState(MatchModel match, {required bool canOpenScoring}) {
    final l10n = AppLocalizations.of(context)!;
    final currentScore = _currentLiveScore(match);
    if (widget.isViewer || canOpenScoring) {
      return _buildViewerState(match, canControl: canOpenScoring);
    }

    return Column(
      children: [
        // ─── Info Bar ───
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          color: context.colors.bgCard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(
                Icons.track_changes_rounded,
                'Tối đa: ${match.maxScore ?? '∞'}',
              ),
              if (match.winByTwo) ...[
                const SizedBox(width: 12),
                _buildInfoChip(Icons.swap_vert_rounded, 'Cách biệt 2'),
              ],
              if (match.refereeName != null &&
                  match.refereeName!.isNotEmpty) ...[
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.person_outline_rounded,
                  match.refereeName!,
                ),
              ],
            ],
          ).animate().fadeIn(duration: 300.ms),
        ),

        // ─── Main Score Area (read-only) ───
        Expanded(
          child: Row(
            children: [
              // Team 1
              Expanded(
                child: _buildReadOnlyScoreCard(
                  match: match,
                  side: 1,
                  score: currentScore.score1,
                  setsWon: match.sets.length,
                ),
              ),
              // Center VS + LIVE
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.bgCard,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Live indicator
                  FadeTransition(
                    opacity: _livePulseAnim,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.error,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fiber_manual_record,
                            size: 8,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Team 2
              Expanded(
                child: _buildReadOnlyScoreCard(
                  match: match,
                  side: 2,
                  score: currentScore.score2,
                  setsWon: match.sets.length,
                ),
              ),
            ],
          ),
        ),

        // ─── Bottom Controls ───
        if (canOpenScoring)
          Container(
            padding: const EdgeInsets.all(12),
            color: context.colors.bgCard,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.sports_kabaddi_rounded, size: 20),
                    label: Text(
                      l10n.liveWhistle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onPressed: () => _showFoulSelectionDialog(match),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      l10n.liveEndMatch,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onPressed: () => _showCompleteMatchDialog(match),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.colors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteMatchDialog(MatchModel match) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgCard,
        title: Text(
          l10n.liveScoreCompleteTitle,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          l10n.liveScoreCompleteContent,
          style: TextStyle(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(dioProvider)
                    .patch(
                      '/matches/${match.id}/status',
                      data: {'status': 'COMPLETED'},
                    );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ErrorParser.parse(
                          e,
                          l10n.liveScoreCompleteErrorFallback,
                        ),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.success,
            ),
            child: Text(
              l10n.liveScoreCompleteConfirm,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyScoreCard({
    required MatchModel match,
    required int side,
    required int score,
    required int setsWon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgSurface.withValues(alpha: 0.3),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ParticipantLabel(
            teamName: matchSideTeamName(match, side),
            players: matchSidePlayers(match, side),
            teamOnly: isFootballMatch(match),
            compact: true,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
            textAlign: TextAlign.center,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Text(
              '$score',
              key: ValueKey('score_$score'),
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleScoreboardVisibility(MatchModel match) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(matchRepositoryProvider)
          .setScoreboardVisibility(
            match.id,
            visible: !match.scoreboardVisible,
            isClubMatch: match.clubMatchSessionId?.isNotEmpty == true,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorParser.parse(e, l10n.liveScoreboardToggleError)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setOverlayVisibility(
    MatchModel match,
    LiveOverlayKind kind, {
    required bool visible,
  }) async {
    if (_pendingOverlayKind != null) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _pendingOverlayKind = kind);
    try {
      await ref
          .read(matchRepositoryProvider)
          .setOverlayVisibility(
            match.id,
            kind: kind,
            visible: visible,
            isClubMatch: match.clubMatchSessionId?.isNotEmpty == true,
          );
      // Ghi thành công: làm mới snapshot; socket overlay:visibility cập nhật realtime.
      ref.invalidate(
        singleMatchProvider((
          tournamentId: _effectiveTournamentId(),
          matchId: widget.matchId,
        )),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.liveOverlaySaveError),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _pendingOverlayKind = null);
    }
  }

  void _dismissOverlay(LiveOverlayKind kind) {
    setState(() => _dismissedOverlay = kind);
  }

  bool _overlayFlag(MatchModel match, LiveOverlayKind kind) =>
      kind == LiveOverlayKind.h2h
      ? match.h2hOverlayVisible
      : match.bracketOverlayVisible;

  /// What the picture really shows: the server flag, unless the X hid it here.
  bool _overlayShowing(MatchModel match, LiveOverlayKind kind) =>
      _overlayFlag(match, kind) && _dismissedOverlay != kind;

  /// Menu action. The server flag stays true after the X, so a plain flip
  /// would switch it OFF and need a second tap; bring it back locally instead.
  void _toggleOverlay(MatchModel match, LiveOverlayKind kind) {
    final flag = _overlayFlag(match, kind);
    if (flag && _dismissedOverlay == kind) {
      setState(() => _dismissedOverlay = null);
      return;
    }
    _setOverlayVisibility(match, kind, visible: !flag);
  }

  /// H2H / bracket panels let the picture show through; the close button
  /// stays fully opaque.
  static const double _overlayOpacity = 0.75;

  Widget _withCloseButton(Widget overlay, {required VoidCallback onClose}) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Opacity(opacity: _overlayOpacity, child: overlay),
        Positioned(
          top: 4,
          right: 4,
          child: LiveOverlayCloseButton(onPressed: onClose),
        ),
      ],
    );
  }

  Widget _buildH2hOverlay(MatchModel match) {
    final l10n = AppLocalizations.of(context)!;
    final tournament = (match.tournamentName ?? '').trim();
    final roundLabel = MatchRoundLabel.formatRound(
      match: match,
      l10n: l10n,
      includeMatchCode: false,
    ).trim();
    // Web: roundName || categoryName || tournamentName. The App has no
    // categoryName, so the pill is the round, then the tournament name.
    final pill = roundLabel.isNotEmpty ? roundLabel : tournament;

    LiveH2hSideData side(int number, Color ring) {
      final players = matchSidePlayers(match, number);
      final name = participantLabel(
        teamName: matchSideTeamName(match, number),
        players: players,
        teamOnly: isFootballMatch(match),
      );
      return LiveH2hSideData(
        name: name.isEmpty ? l10n.matchNotDetermined : name,
        ringColor: ring,
        avatars: matchSideAvatars(match, number),
      );
    }

    final left = side(1, LiveH2hOverlay.leftRing);
    final right = side(2, LiveH2hOverlay.rightRing);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: LiveH2hOverlay(
        title: l10n.liveH2hTitle,
        roundLabel: pill.toUpperCase(),
        left: left,
        right: right,
        semanticsLabel:
            '${l10n.liveH2hTitle}: ${left.name} ${l10n.matchVsLabel} ${right.name}',
      ),
    );
  }

  Widget _buildBracketOverlay(MatchModel match) {
    final l10n = AppLocalizations.of(context)!;
    final tournamentId = _effectiveTournamentId(match);
    final bracketAsync = tournamentId.isEmpty
        ? null
        : ref.watch(
            bracketMatchesWithDivisionProvider((
              tournamentId: tournamentId,
              divisionId: match.divisionId,
            )),
          );
    final tournament = (match.tournamentName ?? '').trim();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        // Chừa 48 px bên phải cho nút đóng.
        padding: const EdgeInsets.fromLTRB(8, 8, 48, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xEE091B3E), Color(0xF2050F26)],
          ),
          border: Border.all(
            color: const Color.fromRGBO(11, 107, 184, 0.85),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Đầu thẻ như web: thanh xanh, nhãn sơ đồ + tên giải.
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D3FA8), Color(0xFF0A2C74)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2A85FE), Color(0xFF1473FC)],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      l10n.liveBracketTitle.toUpperCase(),
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (tournament.isNotEmpty
                              ? tournament
                              : l10n.liveBracketTournamentFallback)
                          .toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: bracketAsync == null
                  ? _bracketEmpty(l10n)
                  : bracketAsync.when(
                      loading: () => const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, _) => _bracketEmpty(l10n),
                      // DESIGN.md §3: sơ đồ nhánh đấu bọc để zoom/pan.
                      data: (bracketMatches) {
                        final scoped = liveBracketScope(bracketMatches, match);
                        if (scoped.isEmpty) return _bracketEmpty(l10n);
                        return InteractiveViewer(
                          constrained: false,
                          minScale: 0.8,
                          maxScale: 3,
                          child: _bracketRounds(match, scoped, l10n),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bracketRounds(
    MatchModel current,
    List<MatchModel> matches,
    AppLocalizations l10n,
  ) {
    if (matches.isEmpty) return _bracketEmpty(l10n);
    final rounds = <int, List<MatchModel>>{};
    for (final m in matches) {
      rounds.putIfAbsent(m.round, () => <MatchModel>[]).add(m);
    }
    final keys = rounds.keys.toList()..sort();
    final last = keys.last;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final round in keys)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  padding: const EdgeInsets.only(left: 5, right: 10),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0x8C30528C), Color(0x66162C58)],
                    ),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF1E90FF), width: 3),
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    _bracketRoundLabel(round, last, l10n).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                for (final m in rounds[round] ?? const <MatchModel>[])
                  _bracketMatchCard(m, current, l10n),
              ],
            ),
          ),
      ],
    );
  }

  Widget _bracketMatchCard(
    MatchModel m,
    MatchModel current,
    AppLocalizations l10n,
  ) {
    final isCurrent = m.id == current.id;
    const sky = Color(0xFF1E90FF);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      constraints: const BoxConstraints(minWidth: 96, maxWidth: 140),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: isCurrent ? sky : Colors.white.withValues(alpha: 0.14),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bracketTeamLine(
            m,
            1,
            won: m.winnerId.isNotEmpty && m.winnerId == m.team1Id,
            l10n: l10n,
          ),
          _bracketTeamLine(
            m,
            2,
            won: m.winnerId.isNotEmpty && m.winnerId == m.team2Id,
            l10n: l10n,
          ),
          if (isCurrent)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(vertical: 1.5),
              color: sky,
              child: Text(
                l10n.liveBracketCurrentMatch,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bracketEmpty(AppLocalizations l10n) {
    return Center(
      child: Text(
        l10n.liveBracketEmpty,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      ),
    );
  }

  String _bracketRoundLabel(int round, int last, AppLocalizations l10n) {
    if (round == last) return l10n.matchTableRoundFinal;
    if (round == last - 1) return l10n.matchTableRoundSemifinal;
    if (round == last - 2) return l10n.matchTableRoundQuarterfinal;
    return l10n.matchTableRound(round);
  }

  Widget _bracketTeamLine(
    MatchModel match,
    int side, {
    required bool won,
    required AppLocalizations l10n,
  }) {
    return Row(
      children: [
        Expanded(
          child: ParticipantLabel(
            teamName: matchSideTeamName(match, side),
            players: matchSidePlayers(match, side),
            teamOnly: isFootballMatch(match),
            compact: true,
            style: const TextStyle(color: Colors.white, fontSize: 9),
          ),
        ),
        if (won)
          Text(
            l10n.liveBracketWin,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  /// Huy hiệu Ping chỉ cho admin và chủ giải của giải. Không dùng
  /// `auth.canScore`: trọng tài có quyền chấm điểm nhưng không xem thông số luồng.
  bool _canSeeStreamStats(String tournamentId) {
    final profile = ref.watch(userProfileProvider).asData?.value;
    if (profile == null || profile.id.isEmpty) return false;
    if (profile.hasRole('ADMIN')) return true;
    if (tournamentId.isEmpty) return false;
    final creatorId = ref
        .watch(tournamentProvider(tournamentId))
        .value
        ?.creatorId;
    return creatorId != null &&
        creatorId.isNotEmpty &&
        creatorId == profile.id;
  }

  /// True once the live stream or the replay that `LiveVideoBox` shows exists.
  /// Mirrors its order: the replay is only looked up after the live answer
  /// came back empty, so no extra request is made while a stream is playing.
  bool _isVideoShowing() {
    final playback = ref.watch(matchPlaybackProvider(widget.matchId));
    if (playback.asData?.value != null) return true;
    if (!playback.hasValue) return false;
    return ref.watch(matchReplayProvider(widget.matchId)).asData?.value != null;
  }

  // ═══════════════════════════════════════════════════════════
  //  VIEWER STATE — Người xem
  // ═══════════════════════════════════════════════════════════
  Widget _buildViewerState(MatchModel match, {required bool canControl}) {
    final currentScore = _currentLiveScore(match);
    final effectiveId = _effectiveTournamentId(match);
    // No AppBar here: the controls live on the video and the lower half is
    // header + Chat/Videos, for viewers and scorers alike. [canControl] only
    // adds the scorer tools (scoring button, overlay toggles).
    // Overlays are part of the picture: a viewer sees them only while a live
    // stream or a replay is actually showing, never over "no signal"; a scorer
    // always sees them so the toggles have a visible effect.
    final videoShowing = canControl || _isVideoShowing();
    // Cờ server quyết định overlay; nút đóng chỉ ẩn cục bộ overlay đó.
    final serverOverlay = liveOverlayToShow(
      h2hVisible: match.h2hOverlayVisible,
      bracketVisible: match.bracketOverlayVisible,
      matchEnded: match.isCompleted,
    );
    final overlayToShow = !videoShowing || serverOverlay == _dismissedOverlay
        ? null
        : serverOverlay;
    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // ─── Live Video Stream Player Box (Mockup) ───
    final videoBox = Container(
          width: double.infinity,
          height: landscape ? double.infinity : null,
          padding: EdgeInsets.only(
            top: landscape ? 0 : MediaQuery.of(context).padding.top,
          ),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: context.colors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Luồng phát thật từ backend. Chưa có URL thì widget tự hiện
              // khung 'chưa có tín hiệu', không cần mockup gradient nữa.
              LiveVideoBox(
                matchId: widget.matchId,
                showStreamStats: _canSeeStreamStats(effectiveId),
                fill: landscape,
                fullscreen: landscape,
                onToggleFullscreen: _toggleFullscreen,
                showLiveDot: match.isLive,
              ),

              // Bảng điểm là một phần của khung hình: luôn ở góc trên trái của
              // hình video, tạm ẩn khi overlay H2H / Sơ đồ đang hiện. Người
              // xem chỉ nhìn, nên chạm xuyên qua để nút quay lại bên dưới vẫn bấm được.
              Positioned(
                top: 8,
                left: 8,
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                  duration: liveOverlayMotionDuration(context),
                  reverseDuration: liveOverlayReverseDuration(context),
                  switchInCurve: liveOverlayMotionCurve,
                  switchOutCurve: liveOverlayMotionCurve,
                  transitionBuilder: (child, animation) =>
                      liveOverlayTransition(
                        child,
                        animation,
                        slideFrom: const Offset(-0.15, 0),
                      ),
                  child:
                      match.scoreboardVisible &&
                          videoShowing &&
                          overlayToShow == null
                      ? KeyedSubtree(
                          key: const ValueKey('live-scoreboard-on'),
                          child: _liveScoreOverlay(match, currentScore),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('live-scoreboard-off'),
                        ),
                  ),
                ),
              ),
              // Overlay theo cờ server: một overlay một lúc, 240 ms easeOutCubic.
              Positioned(
                left: 8,
                right: 8,
                bottom: liveOverlayBottomInset,
                child: AnimatedSwitcher(
                  duration: liveOverlayMotionDuration(context),
                  reverseDuration: liveOverlayReverseDuration(context),
                  switchInCurve: liveOverlayMotionCurve,
                  switchOutCurve: liveOverlayMotionCurve,
                  transitionBuilder: (child, animation) =>
                      liveOverlayTransition(
                        child,
                        animation,
                        slideFrom: const Offset(0, 0.25),
                      ),
                  child: overlayToShow == LiveOverlayKind.h2h
                      ? KeyedSubtree(
                          key: const ValueKey('live-overlay-h2h'),
                          child: _withCloseButton(
                            _buildH2hOverlay(match),
                            onClose: () =>
                                _dismissOverlay(LiveOverlayKind.h2h),
                          ),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('live-overlay-h2h-hidden'),
                        ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                // Leave the header strip clear so its buttons never cover the
                // overlay's own close button.
                top: _viewerHeaderHeight,
                bottom: liveOverlayBottomInset,
                child: AnimatedSwitcher(
                  duration: liveOverlayMotionDuration(context),
                  reverseDuration: liveOverlayReverseDuration(context),
                  switchInCurve: liveOverlayMotionCurve,
                  switchOutCurve: liveOverlayMotionCurve,
                  transitionBuilder: (child, animation) =>
                      liveOverlayTransition(
                        child,
                        animation,
                        scaleFrom: 0.96,
                      ),
                  child: overlayToShow == LiveOverlayKind.bracket
                      ? KeyedSubtree(
                          key: const ValueKey('live-overlay-bracket'),
                          child: _withCloseButton(
                            _buildBracketOverlay(match),
                            onClose: () =>
                                _dismissOverlay(LiveOverlayKind.bracket),
                          ),
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('live-overlay-bracket-hidden'),
                        ),
                ),
              ),

              // Top layer: a translucent header over the whole picture, the
              // scoreboard and every overlay included. The scoreboard keeps
              // its top-left spot; the back button floats right over it.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildViewerTopBar(match, canControl: canControl),
                  ],
                ),
              ),
            ],
          ),
        );

    if (landscape) return _buildViewerLandscape(match, videoBox);

    return Column(
      children: [
        videoBox,
        ..._buildViewerBottom(match, effectiveId),
      ],
    );
  }

  // ─── Live page layout (same for every account) ───

  String _viewerTitle(MatchModel match) {
    final l10n = AppLocalizations.of(context)!;
    return '${matchSideLabel(match, 1)} ${l10n.matchVsLabel} ${matchSideLabel(match, 2)}';
  }

  /// Start (scheduled) or open-scoreboard (live) button for a scorer.
  Widget _scoringAction(MatchModel match, {ButtonStyle? style}) {
    final l10n = AppLocalizations.of(context)!;
    final tournamentId = _effectiveTournamentId(match);
    if (match.isScheduled) {
      return IconButton(
        tooltip: l10n.liveStartMatch,
        icon: const Icon(Icons.play_circle_fill_rounded),
        color: const Color(0xFF16A34A),
        style: style,
        onPressed: () async {
          await _startMatchSafely(tournamentId: tournamentId);
        },
      );
    }
    return IconButton(
      tooltip: l10n.liveOpenScoreboardShort,
      icon: const Icon(Icons.scoreboard_rounded),
      color: AppTheme.primary,
      style: style,
      onPressed: () {
        showOfficialScoreModal(
          context,
          tournamentId: tournamentId,
          matchId: widget.matchId,
          match: match,
          onRecordPenalty: () => _showFoulSelectionDialog(match),
          onSubmitPenalty: (teamSide, option, reason) =>
              _submitPenalty(match, teamSide, option, reason),
          onForceWin: () => _showForceWinDialog(match),
        );
      },
    );
  }

  /// Height of the header strip (one 40dp button row plus padding).
  static const double _viewerHeaderHeight = 44;

  /// Back / share / more, drawn over the top of the video. LIVE is no longer
  /// a pill here: it is a dot beside the sound button (see LiveVideoPlayer).
  Widget _buildViewerTopBar(MatchModel match, {required bool canControl}) {
    final l10n = AppLocalizations.of(context)!;
    Widget round(IconData icon, VoidCallback onTap, String tooltip) {
      return IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 22, color: Colors.white),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        children: [
          round(
            Icons.arrow_back_ios_new_rounded,
            () => context.pop(),
            l10n.liveBack,
          ),
          const Spacer(),
          if (canControl) _scoringAction(match),
          if (MediaQuery.of(context).orientation == Orientation.landscape) ...[
            round(
              _landscapeChatOpen
                  ? Icons.chat_bubble_rounded
                  : Icons.chat_bubble_outline_rounded,
              () => setState(() => _landscapeChatOpen = !_landscapeChatOpen),
              _landscapeChatOpen ? l10n.liveChatHide : l10n.liveChatShow,
            ),
            round(
              Icons.flag_outlined,
              () => _reportMatch(match),
              l10n.liveReportAction,
            ),
          ],
          round(
            Icons.share_outlined,
            () => _shareMatch(match),
            l10n.liveShareAction,
          ),
          if (canControl)
            _scorerMoreMenu(match)
          else
            round(
              Icons.more_vert_rounded,
              () => _showDetailsSheet(match),
              l10n.liveViewerMore,
            ),
        ],
      ),
    );
  }

  /// More menu for a scorer: match details plus the scoreboard / H2H / bracket
  /// switches that used to be a row of chips over the video.
  Widget _scorerMoreMenu(MatchModel match) {
    final l10n = AppLocalizations.of(context)!;
    final tournamentId = _effectiveTournamentId(match);
    final locked = _pendingOverlayKind != null || match.isCompleted;
    return PopupMenuButton<String>(
      key: const ValueKey('live-more-menu'),
      tooltip: l10n.liveViewerMore,
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_vert_rounded, size: 22, color: Colors.white),
      onSelected: (value) {
        switch (value) {
          case 'details':
            _showDetailsSheet(match);
          case 'board':
            _toggleScoreboardVisibility(match);
          case 'h2h':
            _toggleOverlay(match, LiveOverlayKind.h2h);
          case 'bracket':
            _toggleOverlay(match, LiveOverlayKind.bracket);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'details',
          child: Text(l10n.liveDetailsSheetTitle),
        ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem<String>(
          value: 'board',
          checked: match.scoreboardVisible,
          child: Text(l10n.liveScoreboardToggle),
        ),
        CheckedPopupMenuItem<String>(
          value: 'h2h',
          checked: _overlayShowing(match, LiveOverlayKind.h2h),
          enabled: !locked,
          child: Text(l10n.liveOverlayChipH2h),
        ),
        CheckedPopupMenuItem<String>(
          value: 'bracket',
          checked: _overlayShowing(match, LiveOverlayKind.bracket),
          enabled: !locked && tournamentId.isNotEmpty,
          child: Text(l10n.liveOverlayChipBracket),
        ),
      ],
    );
  }

  void _shareMatch(MatchModel match) {
    final l10n = AppLocalizations.of(context)!;
    AppShareModal.show(
      context: context,
      title: _viewerTitle(match),
      subtitle: (match.tournamentName ?? '').trim().isNotEmpty
          ? match.tournamentName!.trim()
          : l10n.matchLiveTitle,
      webUrl: 'https://sporto.asia/live/${match.id}',
      badgeText: match.isLive ? l10n.matchLiveStatus : null,
    );
  }

  /// Match details (the old score tab) in a sheet; the video keeps playing
  /// behind it and the content follows live updates.
  void _showDetailsSheet(MatchModel initial) {
    final effectiveId = _effectiveTournamentId(initial);
    final params = (tournamentId: effectiveId, matchId: widget.matchId);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Consumer(
          builder: (context, ref, _) {
            final match =
                ref.watch(singleMatchProvider(params)).value ?? initial;
            final state = ref.watch(scorePanelNotifierProvider(params));
            final tournament = effectiveId.isEmpty
                ? null
                : ref.watch(tournamentProvider(effectiveId)).value;
            return _buildDetailsSheet(
              match: match,
              state: state,
              tournament: tournament,
              tournamentId: effectiveId,
              sheetContext: sheetContext,
              scrollController: scrollController,
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailsSheet({
    required MatchModel match,
    required ScorePanelState state,
    required Tournament? tournament,
    required String tournamentId,
    required BuildContext sheetContext,
    required ScrollController scrollController,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isDoubles = isDoublesMatch(match);
    final score = _currentLiveScore(match, state);
    return LiveMatchDetailsSheet(
      sheetTitle: l10n.liveDetailsSheetTitle,
      sideA: buildLiveEloSide(
        match,
        1,
        isDoubles: isDoubles,
        undetermined: l10n.matchNotDetermined,
      ),
      sideB: buildLiveEloSide(
        match,
        2,
        isDoubles: isDoubles,
        undetermined: l10n.matchNotDetermined,
      ),
      score1: score.score1,
      score2: score.score2,
      live: match.isLive,
      sets: _detailsSetChips(match, state),
      rows: _detailsRows(match, tournament, tournamentId, sheetContext),
      extra: match.penalties.isEmpty ? null : _buildViewerPenaltyLog(match),
      reportLabel: l10n.liveReportAction,
      closeTooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      onClose: () => Navigator.of(sheetContext).pop(),
      onReport: () {
        Navigator.of(sheetContext).pop();
        _reportMatch(match);
      },
      scrollController: scrollController,
    );
  }

  /// Closed sets plus the one being played (red), as "Set N · a-b".
  List<LiveSetChipData> _detailsSetChips(
    MatchModel match,
    ScorePanelState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final all = state.finishedSets.isNotEmpty
        ? state.finishedSets
        : _scoreDetailsSets(match);
    final finished = all.where((set) => set.isFinished).toList();
    final chips = [
      for (var i = 0; i < finished.length; i++)
        LiveSetChipData(
          label:
              '${l10n.tennisInfoSet} ${i + 1} · ${finished[i].score1}-${finished[i].score2}',
        ),
    ];
    if (match.isCompleted) return chips;
    final live = _currentLiveScore(match, state);
    return [
      ...chips,
      LiveSetChipData(
        label:
            '${l10n.tennisInfoSet} ${finished.length + 1} · ${live.score1}-${live.score2}',
        current: true,
      ),
    ];
  }

  /// Tournament link, sport + rules, place, referee and penalties summary.
  List<LiveInfoRowData> _detailsRows(
    MatchModel match,
    Tournament? tournament,
    String tournamentId,
    BuildContext sheetContext,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final kind = SportRuleKind.fromString(match.sportKey);
    final tournamentRules = tournament?.sportRules;
    final rules = tournamentRules != null && tournamentRules.isNotEmpty
        ? {
            ...tournamentRules,
            if (match.sportRules != null && match.sportRules!.isNotEmpty)
              ...match.sportRules!,
          }
        : match.sportRules;
    final config = resolveSportConfig(rules, kind);
    final isLite = isLiteScoringMode(
      tournamentConfig: match.tournamentConfig,
      sportRules: rules,
      tournamentIsLite: tournament?.isLite == true,
    );
    final ruleText = [
      _setupSportLabel(kind),
      if (isLite)
        l10n.liveOpenRules
      else ...[
        '${l10n.liveWinLabel} ${l10n.liveSetValue(config.setsToWin)}',
        if (config.mustWinByTwo) l10n.liveDifferenceTwo,
      ],
    ].join(' · ');
    final place = tournament != null
        ? TournamentLocationFormatter.matchFullLocation(
            tournament: tournament,
            courtName: match.court,
          )
        : TournamentLocationFormatter.matchCourtLabel(match.court);
    final round = MatchRoundLabel.formatRound(
      match: match,
      l10n: l10n,
      includeMatchCode: false,
    ).trim();
    final tournamentName = (match.tournamentName ?? '').trim();
    final referee = match.refereeName?.trim() ?? '';
    final scheduled = match.scheduledTime?.toLocal();
    // A blank text means "no data": the sheet does not draw that row.
    return [
      LiveInfoRowData(
        icon: Icons.emoji_events_outlined,
        label: l10n.liveDetailsTournament,
        text: [
          if (tournamentName.isNotEmpty) tournamentName,
          if (round.isNotEmpty) round,
        ].join(' · '),
        onTap: tournamentId.isEmpty
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                context.push('/tournament/$tournamentId');
              },
      ),
      LiveInfoRowData(
        icon: Icons.sports_rounded,
        label: l10n.liveDetailsRules,
        text: ruleText,
      ),
      LiveInfoRowData(
        icon: Icons.location_on_outlined,
        label: l10n.liveDetailsPlace,
        text: place,
      ),
      LiveInfoRowData(
        icon: Icons.schedule_rounded,
        label: l10n.liveDetailsTime,
        text: scheduled == null
            ? ''
            : DateFormat('dd/MM/yyyy HH:mm').format(scheduled),
      ),
      LiveInfoRowData(
        icon: Icons.person_outline_rounded,
        label: l10n.liveRefereeLabel,
        text: referee,
      ),
    ];
  }

  /// Landscape: the video fills the screen, the chat floats over its right side.
  Widget _buildViewerLandscape(MatchModel match, Widget videoBox) {
    final isAuth = ref.watch(authProvider).status == AuthStatus.authenticated;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(top: false, bottom: false, child: videoBox),
          ),
          if (_landscapeChatOpen)
            LiveLandscapeChat(
              lines: [
                for (final c in _comments)
                  LiveChatLine(
                    id: c['id']?.toString() ?? '',
                    name:
                        (c['user'] as Map?)?['fullName']?.toString() ??
                        AppLocalizations.of(context)!.liveViewerPlaceholder,
                    text: c['commentText']?.toString() ?? '',
                  ),
              ],
              canPost: isAuth,
              controller: _commentTextController,
              sending: _isSubmittingComment,
              onSend: _postComment,
              onCheer: _handleCheer,
              onLogin: () => context.push('/login'),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildViewerBottom(MatchModel match, String tournamentId) {
    final l10n = AppLocalizations.of(context)!;
    final tournamentName = (match.tournamentName ?? '').trim();
    final round = MatchRoundLabel.formatRound(
      match: match,
      l10n: l10n,
      includeMatchCode: false,
    ).trim();

    return [
      Consumer(
        builder: (context, ref, _) {
          final viewers = ref.watch(viewerCountProvider(widget.matchId)).value;
          return LiveViewerHeader(
            title: _viewerTitle(match),
            viewersLabel: match.isLive && viewers != null
                ? l10n.liveViewerCount(viewers)
                : null,
            roundLabel: round,
            cheerCount: _cheerCount,
            onCheer: _handleCheer,
            onShare: () => _shareMatch(match),
            onMore: () => _showDetailsSheet(match),
            tournamentLabel: tournamentName,
            onOpenTournament: tournamentId.isEmpty
                ? null
                : () => context.push('/tournament/$tournamentId'),
          );
        },
      ),
      Row(
        children: [
          _viewerTabLabel(l10n.liveChatTab, 0),
          _viewerTabLabel(l10n.liveMoreVideosTab, 1),
        ],
      ),
      Divider(height: 1, color: context.colors.border),
      Expanded(
        child: _liveTab == 0
            ? _buildChatTab(match)
            : LiveViewerSuggestions(
                currentMatchId: match.id,
                onOpen: (next) => context.pushReplacement(
                  NavigationHelper.getLiveMatchRoute(
                    next.tournamentId,
                    next.matchId,
                  ),
                ),
              ),
      ),
    ];
  }

  Widget _viewerTabLabel(String text, int index) {
    final selected = _liveTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _liveTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppTheme.primary
                  : context.colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }


  /// Bảng điểm hai hàng chồng ở góc trên trái, giống web
  /// (`LiveScoreboardOverlay.tsx`): mỗi hàng là [tên viết tắt IN HOA | ô điểm
  /// vát]. Chỉ chữ, không avatar, như web.
  Widget _liveScoreOverlay(MatchModel match, dynamic score) {
    Widget sideName(int side) => Text(
      participantLabel(
        teamName: matchSideTeamName(match, side),
        players: matchSidePlayers(match, side),
        teamOnly: isFootballMatch(match),
        abbreviated: true,
      ).toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.2,
      ),
    );

    return LiveScoreboardOverlay(
      team1: sideName(1),
      team2: sideName(2),
      score1: score.score1 as int,
      score2: score.score2 as int,
      finished: match.isCompleted == true,
      semanticsLabel:
          '${matchSideLabel(match, 1)} ${score.score1}, '
          '${matchSideLabel(match, 2)} ${score.score2}',
    );
  }

  String _penaltyLabel(Penalty penalty) {
    final l10n = AppLocalizations.of(context)!;
    switch (penalty.type.toUpperCase()) {
      case 'YELLOW_CARD':
      case 'YELLOW':
        return l10n.livePenaltyYellowCard;
      case 'RED_CARD':
      case 'RED':
        return l10n.livePenaltyRedCard;
      case 'POINT_PENALTY':
        return l10n.livePenaltyPoint;
      case 'GAME_PENALTY':
        return l10n.livePenaltyGame;
      case 'SERVICE_FAULT':
        return l10n.livePenaltyServiceFault;
      case 'MISCONDUCT':
        return l10n.livePenaltyMisconduct;
      case 'WARNING':
        return l10n.livePenaltyWarning;
      default:
        return penalty.type;
    }
  }

  Widget _buildViewerPenaltyLog(MatchModel match) {
    if (match.penalties.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final penalties = match.penalties.take(6).toList();
    String teamLabel(Penalty penalty) {
      if (penalty.teamId == '1') return matchSideLabel(match, 1);
      if (penalty.teamId == '2') return matchSideLabel(match, 2);
      return l10n.liveMatchFallback;
    }

    Color penaltyColor(Penalty penalty) {
      final type = penalty.type.toUpperCase();
      if (type.contains('RED')) return const Color(0xFFDC2626);
      if (type.contains('YELLOW') || type == 'WARNING') {
        return const Color(0xFFD97706);
      }
      return AppTheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel_rounded, size: 18, color: colors.textSecondary),
              const SizedBox(width: 8),
              Text(
                l10n.livePenaltyLogTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                l10n.livePenaltyCount(match.penalties.length),
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...penalties.map((penalty) {
            final color = penaltyColor(penalty);
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_penaltyLabel(penalty)} • ${teamLabel(penalty)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  if (penalty.reason?.trim().isNotEmpty == true)
                    Flexible(
                      child: Text(
                        penalty.reason!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, color: colors.textMuted),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  CHAT TAB
  // ═══════════════════════════════════════════════════════════
  Widget _buildChatTab(MatchModel match) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final isAuth = ref.watch(authProvider).status == AuthStatus.authenticated;

    final List<Map<String, dynamic>> mergedList = [];

    // Add comments
    for (final c in _comments) {
      mergedList.add({
        'isSystem': false,
        'id': c['id'],
        'user': c['user'],
        'commentText': c['commentText'],
        'createdAt':
            DateTime.tryParse(c['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      });
    }

    // Add match events
    for (final e in match.events) {
      mergedList.add({
        'isSystem': true,
        'id': e.id,
        'commentText': e.description,
        'createdAt': e.timestamp,
        'eventType': e.type,
      });
    }

    // Sort by createdAt descending
    mergedList.sort((a, b) {
      final DateTime da = a['createdAt'] as DateTime;
      final DateTime db = b['createdAt'] as DateTime;
      return db.compareTo(da);
    });

    _lastChatLength = mergedList.length;
    // While scrolled up, rows newer than the baseline stay out of the list so
    // what the viewer is reading does not move; they are counted on the pill.
    final hiddenNewest = _chatBaseline == null
        ? 0
        : (mergedList.length - _chatBaseline!).clamp(0, mergedList.length);
    final shownList = hiddenNewest == 0
        ? mergedList
        : mergedList.sublist(hiddenNewest);

    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: _isLoadingComments && mergedList.isEmpty
                ? const ScrollFreeSkeleton(child: ChatMessagesSkeleton())
                : mergedList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: colors.bgSurface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXL,
                            ),
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 28,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.liveEmptyDiscussion,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.liveEmptyDiscussionHint,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                  ListView.builder(
                    controller: _chatScroll,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: shownList.length,
                    itemBuilder: (context, index) {
                      final item = shownList[index];
                      final isSystem = item['isSystem'] as bool? ?? false;
                      final timeStr = item['createdAt'] != null
                          ? (item['createdAt'] as DateTime)
                                .toLocal()
                                .toString()
                                .substring(11, 16)
                          : '';

                      if (isSystem) {
                        final eventType = item['eventType'] as MatchEventType;
                        final text = item['commentText']?.toString() ?? '';

                        IconData eventIcon = Icons.notifications_rounded;
                        Color badgeColor = Colors.blue;
                        if (eventType == MatchEventType.score) {
                          eventIcon = Icons.sports_tennis_rounded;
                          badgeColor = Colors.green;
                        } else if (eventType == MatchEventType.foul ||
                            eventType == MatchEventType.yellowCard) {
                          eventIcon = Icons.warning_amber_rounded;
                          badgeColor = Colors.amber;
                        } else if (eventType == MatchEventType.redCard) {
                          eventIcon = Icons.gavel_rounded;
                          badgeColor = Colors.red;
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLarge,
                            ),
                            border: Border.all(
                              color: badgeColor.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: badgeColor.withValues(
                                  alpha: 0.15,
                                ),
                                child: Icon(
                                  eventIcon,
                                  size: 12,
                                  color: badgeColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final user = item['user'] as Map?;
                      final avatarUrl = user?['avatarUrl']?.toString() ?? '';
                      final userName =
                          user?['fullName']?.toString() ??
                          l10n.liveViewerPlaceholder;
                      // The discussion feed is a raw REST/socket map, so the
                      // author id arrives under either spelling.
                      final commentUserId =
                          (user?['id'] ?? user?['userId'])?.toString().trim() ??
                          '';
                      final commentText = item['commentText']?.toString() ?? '';
                      // The next index is the older row (list is reversed).
                      final older = index + 1 < shownList.length
                          ? shownList[index + 1]
                          : null;
                      final olderIsComment =
                          older != null && older['isSystem'] != true;
                      final olderUser = olderIsComment
                          ? (older['user'] as Map?)
                          : null;
                      return MatchDiscussionMessage(
                        userId: commentUserId,
                        name: userName,
                        text: commentText,
                        timeLabel: timeStr,
                        avatarUrl: avatarUrl,
                        compact: isChatContinuation(
                          userId: commentUserId,
                          at: item['createdAt'] as DateTime,
                          olderUserId:
                              (olderUser?['id'] ?? olderUser?['userId'])
                                  ?.toString()
                                  .trim(),
                          olderAt: olderIsComment
                              ? older['createdAt'] as DateTime
                              : null,
                        ),
                      );
                    },
                  ),
                  if (hiddenNewest > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 8,
                      child: Center(
                        child: LiveNewMessagesPill(
                          count: hiddenNewest,
                          onTap: _jumpToLatestChat,
                        ),
                      ),
                    ),
                    ],
                  ),
          ),
          LiveCommentInput(
            controller: _commentTextController,
            hint: isAuth ? l10n.liveCommentHint : l10n.liveLoginToComment,
            canPost: isAuth,
            sending: _isSubmittingComment,
            onSend: _postComment,
            onLogin: () => context.go('/login'),
            loginLabel: l10n.liveLogin,
          ),
        ],
      ),
    );
  }
}
