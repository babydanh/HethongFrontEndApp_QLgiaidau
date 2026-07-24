import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/providers/match_control_notifier.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:app_quanly_giaidau/features/match/widgets/penalty_input_dialog.dart';
import 'package:app_quanly_giaidau/features/match/widgets/official_score_modal.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/domain/entities/match_event.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_state.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:intl/intl.dart';

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
  final _refereeController = TextEditingController();
  bool _winByTwo = true;
  bool _didSeedSetupControls = false;

  late TabController _tabController;
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
  bool _showScore1Anim = false;
  bool _showScore2Anim = false;

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

  Future<void> _handleCheer() async {
    _spawnHeart();
    try {
      await ref.read(matchRepositoryProvider).cheerMatch(widget.matchId);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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
  }

  @override
  void dispose() {
    _maxScoreController.dispose();
    _timeLimitController.dispose();
    _refereeController.dispose();
    _tabController.dispose();
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
      setState(() => _isLoadingComments = false);
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
        const SnackBar(
          content: Text('Không thể gửi bình luận. Vui lòng thử lại!'),
        ),
      );
    } finally {
      setState(() => _isSubmittingComment = false);
    }
  }

  void _trackScoreChanges(MatchModel match) {
    if (match.score1 != _lastScore1) {
      setState(() {
        _showScore1Anim = true;
        _lastScore1 = match.score1;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _showScore1Anim = false);
      });
    }
    if (match.score2 != _lastScore2) {
      setState(() {
        _showScore2Anim = true;
        _lastScore2 = match.score2;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _showScore2Anim = false);
      });
    }
  }

  void _checkWinner(MatchModel match) {
    if (match.maxScore == null) return;

    int max = match.maxScore!;
    if (match.score1 >= max || match.score2 >= max) {
      if (match.winByTwo) {
        if ((match.score1 - match.score2).abs() < 2) return;
      }

      String winnerName = match.score1 > match.score2
          ? match.team1Name
          : match.team2Name;
      String winnerId = match.score1 > match.score2
          ? match.team1Id
          : match.team2Id;
      String loserId = match.score1 > match.score2
          ? match.team2Id
          : match.team1Id;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: context.colors.bgCard,
          title: Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.amber,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Trận đấu kết thúc!',
                style: TextStyle(color: context.colors.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Đội $winnerName đã giành chiến thắng!',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.colors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${match.score1} - ${match.score2}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: context.colors.success,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tiếp tục đánh (Hủy)'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref
                    .read(
                      matchControllerProvider((
                        tournamentId: widget.tournamentId,
                        matchId: widget.matchId,
                      )),
                    )
                    .endMatch(winnerId, loserId);
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.success,
              ),
              child: const Text('Xác nhận Kết thúc'),
            ),
          ],
        ),
      );
    }
  }

  void _showFoulSheet(bool isTeam1, MatchModel match) {
    final tournamentAsync = ref.read(tournamentProvider(widget.tournamentId));
    final sport = match.sportKey ?? tournamentAsync.value?.sport ?? 'other';

    showDialog(
      context: context,
      builder: (_) => PenaltyInputDialog(
        sportType: sport,
        team1Name: match.team1Name,
        team2Name: match.team2Name,
        onSubmit: (teamName, option, reason) {
          final isT1 = teamName == match.team1Name;
          ref
              .read(
                matchControllerProvider((
                  tournamentId: widget.tournamentId,
                  matchId: widget.matchId,
                )),
              )
              .addPenalty(isT1, sport, option.id, option.name, reason);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã ghi nhận ${option.name}.'),
                backgroundColor: context.colors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showFoulSelectionDialog(MatchModel match) {
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
              'Đội nào bị phạt?',
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
                match.team1Name,
                style: TextStyle(color: context.colors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showFoulSheet(true, match);
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
                match.team2Name,
                style: TextStyle(color: context.colors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showFoulSheet(false, match);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showForceWinDialog(MatchModel match) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgCard,
        title: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              'Xử thắng nhanh',
              style: TextStyle(color: context.colors.error),
            ),
          ],
        ),
        content: Text(
          'Xác nhận xử thắng cho một đội (đối thủ bỏ cuộc hoặc phạm quy)?',
          style: TextStyle(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _forceWinMatch(match.team1Id, match.team2Id);
            },
            child: Text(match.team1Name),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              _forceWinMatch(match.team2Id, match.team1Id);
            },
            child: Text(match.team2Name),
          ),
        ],
      ),
    );
  }

  void _forceWinMatch(String winnerId, String loserId) {
    final match = ref
        .read(
          singleMatchProvider((
            tournamentId: widget.tournamentId,
            matchId: widget.matchId,
          )),
        )
        .value;
    if (match != null) {
      int newScore1 = match.score1;
      int newScore2 = match.score2;

      if (winnerId == match.team1Id) {
        newScore1 =
            match.maxScore ??
            (match.score1 <= match.score2 ? match.score2 + 1 : match.score1);
      } else {
        newScore2 =
            match.maxScore ??
            (match.score2 <= match.score1 ? match.score1 + 1 : match.score2);
      }

      ref
          .read(
            matchControllerProvider((
              tournamentId: widget.tournamentId,
              matchId: widget.matchId,
            )),
          )
          .updateMatchResultByAdmin(
            score1: newScore1,
            score2: newScore2,
            winnerId: winnerId,
            loserId: loserId,
          );
    } else {
      ref
          .read(
            matchControllerProvider((
              tournamentId: widget.tournamentId,
              matchId: widget.matchId,
            )),
          )
          .endMatch(winnerId, loserId);
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(
      singleMatchProvider((
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
      )),
    );

    ref.watch(
      matchControllerProvider((
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
      )),
    );
    final authRole = ref.watch(authProvider).role;
    final canOpenScoring =
        !widget.isViewer || authRole == UserRole.admin || authRole == UserRole.referee;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
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
              widget.isViewer
                  ? (matchAsync.value?.isLive == true
                        ? 'Trực tiếp'
                        : 'Chi Tiết Trận Đấu')
                  : 'Bàn Trọng Tài',
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
            matchAsync.when(
              data: (match) {
                if (match == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton.tonalIcon(
                    onPressed: () => showOfficialScoreModal(
                      context,
                      tournamentId: widget.tournamentId,
                      matchId: widget.matchId,
                      match: match,
                      onRecordPenalty: () => _showFoulSelectionDialog(match),
                      onForceWin: () => _showForceWinDialog(match),
                    ),
                    icon: const Icon(Icons.scoreboard_rounded, size: 18),
                    label: const Text('Tính điểm'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
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
                        'Không tìm thấy trận đấu',
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              // Track score changes for animation
              _trackScoreChanges(match);

              if (match.isLive) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _checkWinner(match),
                );
              }

              if (widget.isViewer) {
                return _buildLiveState(match, canOpenScoring: canOpenScoring);
              }

              if (match.isScheduled) {
                return _buildSetupState(match);
              } else if (match.isLive) {
                return _buildLiveState(match, canOpenScoring: canOpenScoring);
              } else {
                return _buildCompletedState(match, authRole);
              }
            },
            loading: () => const Center(child: CircularProgressIndicator()),
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
                    Text('Lỗi: $e', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Quay lại'),
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
  Widget _buildSetupState(MatchModel match) {
    final kind = SportRuleKind.fromString(match.sportKey);
    final config = resolveSportConfig(match.sportRules, kind);
    _ensureSetupControlsSeeded(match, config);
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.settings_rounded,
                  color: context.colors.info,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cấu hình Trận đấu',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
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
                  '${match.team1Name} vs ${match.team2Name}',
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cấu hình giải đang áp dụng',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      match.sportRules != null && match.sportRules!.isNotEmpty
                          ? 'Màn setup đang lấy mặc định từ cấu hình giải đấu. Bạn có thể chỉnh ở cấp trận nếu cần.'
                          : 'Giải chưa có sportRules chi tiết, hệ thống đang dùng cấu hình mặc định theo môn.',
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
                        _buildSetupChip('Môn', _setupSportLabel(kind)),
                        _buildSetupChip('Format', 'BO${config.bestOf}'),
                        _buildSetupChip('Thắng', '${config.setsToWin} set'),
                        _buildSetupChip(
                          'Mốc set',
                          kind == SportRuleKind.tennis
                              ? '${config.pointsPerSet} game'
                              : '${config.pointsPerSet} điểm',
                        ),
                        if (config.mustWinByTwo)
                          _buildSetupChip('Luật', 'Cách biệt 2'),
                        if (config.scoringModel ==
                            SportScoringModel.pickleballSideOut)
                          _buildSetupChip('Scoring', 'Side-out'),
                        if (kind == SportRuleKind.tennis)
                          _buildSetupChip(
                            'Tiebreak',
                            '${config.tiebreakPoints ?? 7} điểm',
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
                  helperText:
                      'Giá trị mặc định đang lấy từ setting của giải. Đây là tuỳ chỉnh ở cấp trận.',
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
                  labelText: 'Giới hạn thời gian (phút, tuỳ chọn)',
                  helperText:
                      'Nếu để trống, trận sẽ không giới hạn thời gian ở cấp trận.',
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

              // Referee name
              TextField(
                controller: _refereeController,
                style: TextStyle(
                  fontSize: 16,
                  color: context.colors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Tên trọng tài (Tùy chọn)',
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
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
              const SizedBox(height: 12),

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
                        'Áp dụng luật cách biệt 2 ${kind == SportRuleKind.tennis ? 'game/điểm' : 'điểm'}',
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
                    final controller = ref.read(
                      matchControllerProvider((
                        tournamentId: widget.tournamentId,
                        matchId: widget.matchId,
                      )),
                    );
                    final resolvedMaxScore =
                        int.tryParse(_maxScoreController.text) ??
                        match.maxScore ??
                        config.pointsPerSet;
                    final resolvedTimeLimit = int.tryParse(
                      _timeLimitController.text,
                    );
                    await controller.updateConfig(
                      maxScore: resolvedMaxScore,
                      winByTwo: _winByTwo,
                      timeLimitMinutes: resolvedTimeLimit,
                    );
                    await controller.startMatch(
                      maxScore: resolvedMaxScore,
                      timeLimitMinutes: resolvedTimeLimit,
                      refereeName: _refereeController.text.trim(),
                    );
                    if (!mounted) {
                      return;
                    }
                    showOfficialScoreModal(
                      context,
                      tournamentId: widget.tournamentId,
                      matchId: widget.matchId,
                      match: match.copyWith(
                        status: 'live',
                        maxScore: resolvedMaxScore,
                        winByTwo: _winByTwo,
                        timeLimitMinutes: resolvedTimeLimit,
                        refereeName: _refereeController.text.trim().isEmpty
                            ? match.refereeName
                            : _refereeController.text.trim(),
                      ),
                      onRecordPenalty: () => _showFoulSelectionDialog(match),
                      onForceWin: () => _showForceWinDialog(match),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    'BẮT ĐẦU VÀ MỞ BÀN CHẤM ĐIỂM',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
    _refereeController.text = match.refereeName ?? '';
    _winByTwo = seededWinByTwo;
    _didSeedSetupControls = true;
  }

  String _setupSportLabel(SportRuleKind kind) {
    switch (kind) {
      case SportRuleKind.tennis:
        return 'Tennis';
      case SportRuleKind.pickleball:
        return 'Pickleball';
      case SportRuleKind.tableTennis:
        return 'Bóng bàn';
      case SportRuleKind.badminton:
        return 'Cầu lông';
    }
  }

  String _setupScoreLabel(SportRuleKind kind, SportConfig config) {
    if (kind == SportRuleKind.tennis) {
      return 'Số game để chạm mốc set (mặc định ${config.pointsPerSet})';
    }
    if (config.scoringModel == SportScoringModel.pickleballSideOut) {
      return 'Mốc điểm game side-out (mặc định ${config.pointsPerSet})';
    }
    return 'Mốc điểm mỗi set (mặc định ${config.pointsPerSet})';
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
                fontWeight: FontWeight.w800,
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
    if (widget.isViewer || canOpenScoring) {
      return _buildViewerState(
        match,
        canOpenScoring:
            canOpenScoring && !match.isScheduled && !match.isCompleted,
      );
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

        // ─── Main Score Area ───
        Expanded(
          child: Row(
            children: [
              // Team 1
              Expanded(
                child: _buildTeamScoreControl(
                  match: match,
                  isTeam1: true,
                  color: const Color(0xFF2979FF),
                  showAnim: _showScore1Anim,
                ),
              ),
              // Center VS
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
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
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
                        borderRadius: BorderRadius.circular(20),
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
                              fontWeight: FontWeight.w900,
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
                child: _buildTeamScoreControl(
                  match: match,
                  isTeam1: false,
                  color: const Color(0xFFEF4444),
                  showAnim: _showScore2Anim,
                ),
              ),
            ],
          ),
        ),

        // ─── Bottom Controls ───
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
                  label: const Text(
                    'THỔI CÒI',
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
                    backgroundColor: context.colors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.emoji_events, size: 20),
                  label: const Text(
                    'XỬ THẮNG',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: () => _showForceWinDialog(match),
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
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildTeamScoreControl({
    required MatchModel match,
    required bool isTeam1,
    required Color color,
    required bool showAnim,
  }) {
    final teamName = isTeam1 ? match.team1Name : match.team2Name;
    final score = isTeam1 ? match.score1 : match.score2;
    final controller = ref.read(
      matchControllerProvider((
        tournamentId: widget.tournamentId,
        matchId: widget.matchId,
      )),
    );

    return GestureDetector(
      onTap: () => controller.addScore(isTeam1, 1),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
              color.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Team avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  teamName.isNotEmpty ? teamName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              teamName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Text(
                    '$score',
                    key: ValueKey('score_${isTeam1}_$score'),
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline_rounded,
                size: 36,
                color: color.withValues(alpha: 0.6),
              ),
              onPressed: () => controller.addScore(isTeam1, -1),
              splashRadius: 24,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  VIEWER STATE — Người xem
  // ═══════════════════════════════════════════════════════════
  Widget _buildViewerState(MatchModel match, {required bool canOpenScoring}) {
    final params = (tournamentId: widget.tournamentId, matchId: widget.matchId);

    return Column(
      children: [
        if (canOpenScoring)
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.refereeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.gavel_rounded,
                    color: AppTheme.refereeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bảng điều khiển tại sân',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        match.isScheduled
                            ? 'Trận chưa bắt đầu. Thiết lập và mở bàn chấm điểm khi sẵn sàng.'
                            : 'Mở modal chấm điểm theo môn để cập nhật tỉ số, set và xử lý tại sân.',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => showOfficialScoreModal(
                    context,
                    tournamentId: widget.tournamentId,
                    matchId: widget.matchId,
                    match: match,
                    onRecordPenalty: () => _showFoulSelectionDialog(match),
                    onForceWin: () => _showForceWinDialog(match),
                  ),
                  icon: const Icon(Icons.scoreboard_rounded, size: 18),
                  label: const Text('Tính điểm'),
                ),
              ],
            ),
          ),
        // ─── Live Video Stream Player Box (Mockup) ───
        Container(
          margin: EdgeInsets.fromLTRB(12, canOpenScoring ? 10 : 12, 12, 6),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
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
                  // Video feed mockup / Background
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF0F172A),
                              const Color(0xFF1E293B),
                              const Color(0xFF0F172A),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Opacity(
                            opacity: 0.15,
                            child: Icon(
                              Icons.videocam_rounded,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // TV Broadcast Scoreboard Overlay (Top-Left)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (match.isLive) ...[
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            match.isLive
                                ? 'LIVE'
                                : (match.isCompleted ? 'KẾT THÚC' : 'SẮP ĐẤU'),
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: match.isLive ? Colors.red : Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            height: 10,
                            width: 1,
                            color: Colors.white24,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_compactTeamName(match.team1Name)} ',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          _scoreBadge(match.score1, const Color(0xFF2979FF)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3),
                            child: Text(
                              '-',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _scoreBadge(match.score2, const Color(0xFFEF4444)),
                          Text(
                            ' ${_compactTeamName(match.team2Name)}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // TV Broadcast overlay for Camera source
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.videocam_rounded,
                            size: 10,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'CAM 1 (SÂN CHÍNH)',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Video controls overlay (Bottom bar)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            match.isLive ? '02:40' : '--:--',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white54,
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              '1080p 60fps',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.fullscreen_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Big central Play Button (simulating ready state)
                  Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ─── Floating Heart Button ───
        if (match.isLive)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 4),
              child: GestureDetector(
                onTap: _spawnHeart,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFE11D48),
                    size: 18,
                  ),
                ),
              ),
            ),
          ),

        // ─── TabBar ───
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.border),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: context.colors.textSecondary,
            indicator: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            tabs: const [
              Tab(text: 'Tỉ số & Diễn biến'),
              Tab(text: 'Phòng thảo luận'),
            ],
          ),
        ),

        // ─── Tab Content ───
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Score (Premium Viewer Scoreboard)
              Consumer(
                builder: (context, ref, _) {
                  final n = ref.watch(scorePanelNotifierProvider(params));
                  return _buildViewerScoreboard(match, n.state);
                },
              ),

              // Tab 2: Chat
              _buildChatTab(match),
            ],
          ),
        ),
      ],
    );
  }

  String _memberEloLabel(MatchMemberInfo member) {
    final name = member.fullName.trim();
    final elo = member.eloPoints;
    final tier = member.tierName?.trim();
    if (elo == null) return '$name • Chưa có ELO';
    if (tier != null && tier.isNotEmpty) return '$name • ELO $elo • $tier';
    return '$name • ELO $elo';
  }

  String _teamMemberSummary(
    List<MatchMemberInfo> memberInfos,
    List<String> displayList,
  ) {
    final realMembers = memberInfos
        .where((member) => member.fullName.trim().isNotEmpty)
        .toList();
    if (realMembers.isNotEmpty) {
      return realMembers.map(_memberEloLabel).join('\n');
    }
    if (displayList.length == 1) return '${displayList.first} • Chưa có ELO';
    return displayList.join(' & ');
  }

  Widget _teamMemberSummaryWidget(
    List<MatchMemberInfo> memberInfos,
    List<String> displayList,
    TextStyle style,
  ) {
    final realMembers = memberInfos
        .where((member) => member.fullName.trim().isNotEmpty)
        .toList();
    if (realMembers.isEmpty) {
      return Text(
        _teamMemberSummary(memberInfos, displayList),
        style: style,
        textAlign: TextAlign.center,
      );
    }
    return Column(
      children: realMembers.map((member) {
        final userId = member.userId?.trim();
        final label = _memberEloLabel(member);
        if (userId == null || userId.isEmpty) {
          return Text(label, style: style, textAlign: TextAlign.center);
        }
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.push('/profile/user/$userId'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              label,
              style: style.copyWith(decoration: TextDecoration.underline),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _compactTeamName(String name) {
    if (name.length <= 8) {
      return name;
    }
    return '${name.substring(0, 6)}..';
  }

  Widget _scoreBadge(int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '$score',
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildViewerScoreboard(
    MatchModel match,
    ScorePanelState notifierState,
  ) {
    final colors = context.colors;
    final int team1SetWins = notifierState.team1SetWins;
    final int team2SetWins = notifierState.team2SetWins;
    final kind = SportRuleKind.fromString(match.sportKey);
    final config = resolveSportConfig(match.sportRules, kind);
    final maxSets = config.bestOf;
    final scoreSummary = _viewerScoreSummary(match, config);
    final modelLabel = _viewerModelLabel(config);
    final currentSetLabel = _viewerCurrentSetLabel(
      match,
      notifierState,
      config,
    );

    // Split names if double matches format
    final t1Names = match.team1Name.split(RegExp(r'[-–\n]'));
    final t2Names = match.team2Name.split(RegExp(r'[-–\n]'));

    final t1List =
        (match.team1Members != null && match.team1Members!.isNotEmpty)
        ? match.team1Members!
        : t1Names;
    final t2List =
        (match.team2Members != null && match.team2Members!.isNotEmpty)
        ? match.team2Members!
        : t2Names;

    final t1Cleaned = t1List
        .where(
          (name) =>
              name.trim().isNotEmpty && name.trim().toLowerCase() != 'tbd',
        )
        .toList();
    final t2Cleaned = t2List
        .where(
          (name) =>
              name.trim().isNotEmpty && name.trim().toLowerCase() != 'tbd',
        )
        .toList();

    final t1DisplayList = t1Cleaned.isNotEmpty ? t1Cleaned : [match.team1Name];
    final t2DisplayList = t2Cleaned.isNotEmpty ? t2Cleaned : [match.team2Name];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Match metadata card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  match.court.isNotEmpty ? match.court : 'Sân trung tâm',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    scoreSummary,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildViewerConfigChip('Môn', _setupSportLabel(kind)),
                _buildViewerConfigChip('Scoring', modelLabel),
                _buildViewerConfigChip('Thắng', '${config.setsToWin} set'),
                if (config.mustWinByTwo)
                  _buildViewerConfigChip('Luật', 'Cách biệt 2'),
                if (kind == SportRuleKind.tennis)
                  _buildViewerConfigChip(
                    'Tiebreak',
                    '${config.tiebreakPoints ?? 7} điểm',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main Premium Scoreboard
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.bgCard, colors.bgSurface],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Team 1
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(
                              0xFF2979FF,
                            ).withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.sports_tennis_rounded,
                              size: 28,
                              color: Color(0xFF2979FF),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            match.team1Name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Player Info / ELO từ API thật; fallback trung thực nếu chưa có.
                          _teamMemberSummaryWidget(
                            match.team1MemberInfos,
                            t1DisplayList,
                            TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF2979FF,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'SET THẮNG: $team1SetWins',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2979FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Center Score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${match.score1}',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: colors.textPrimary,
                                  fontFamily: 'Courier',
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '-',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Text(
                                '${match.score2}',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: colors.textPrimary,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currentSetLabel,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Team 2
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.sports_tennis_rounded,
                              size: 28,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            match.team2Name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Player Info / ELO từ API thật; fallback trung thực nếu chưa có.
                          _teamMemberSummaryWidget(
                            match.team2MemberInfos,
                            t2DisplayList,
                            TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'SET THẮNG: $team2SetWins',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // TỈ SỐ CÁC SET Section
          Text(
            'TỈ SỐ CÁC SET',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colors.textSecondary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(maxSets, (index) {
              final isPlayed = index < notifierState.finishedSets.length;
              final currentPlaying = index == notifierState.finishedSets.length;
              String scoreDisplay = '-';
              Color boxBg = colors.bgSurface;
              Color borderCol = colors.border;

              if (isPlayed) {
                final setScore = notifierState.finishedSets[index];
                scoreDisplay = '${setScore.score1} - ${setScore.score2}';
                boxBg = Colors.green.withValues(alpha: 0.06);
                borderCol = Colors.green.withValues(alpha: 0.2);
              } else if (currentPlaying && !match.isCompleted) {
                scoreDisplay = '${match.score1} - ${match.score2}';
                boxBg = AppTheme.primary.withValues(alpha: 0.05);
                borderCol = AppTheme.primary.withValues(alpha: 0.3);
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: boxBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      'SET ${index + 1}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      scoreDisplay,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isPlayed || currentPlaying
                            ? colors.textPrimary
                            : colors.textMuted.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          // Match details expansion card
          const SizedBox(height: 24),
          Card(
            color: colors.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colors.border, width: 0.5),
            ),
            elevation: 0,
            child: ExpansionTile(
              shape: const Border(),
              title: Text(
                'Thông tin trận đấu chi tiết',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              leading: Icon(
                Icons.info_outline_rounded,
                color: colors.textSecondary,
                size: 20,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'Giải đấu',
                        match.tournamentName ?? 'Giải Vô Địch Mùa Hè',
                      ),
                      const Divider(height: 16),
                      _buildInfoRow(
                        'Trọng tài chính',
                        match.refereeName ?? 'Nguyễn Trọng Tài',
                      ),
                      const Divider(height: 16),
                      _buildInfoRow(
                        'Thời gian xếp lịch',
                        match.scheduledTime != null
                            ? DateFormat(
                                'HH:mm - dd/MM/yyyy',
                              ).format(match.scheduledTime!.toLocal())
                            : 'Chưa xếp lịch',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _viewerScoreSummary(MatchModel match, SportConfig config) {
    final matchCap = match.maxScore;
    if (config.kind == SportRuleKind.tennis) {
      final setGames = matchCap ?? config.pointsPerSet;
      return 'BO${config.bestOf} • $setGames game/set';
    }
    if (config.scoringModel == SportScoringModel.pickleballSideOut) {
      final target = matchCap ?? config.pointsPerSet;
      return 'BO${config.bestOf} • side-out • chạm $target';
    }
    final target = matchCap ?? config.pointsPerSet;
    return 'BO${config.bestOf} • $target điểm/set';
  }

  String _viewerModelLabel(SportConfig config) {
    switch (config.scoringModel) {
      case SportScoringModel.tennisSet:
        return 'Game';
      case SportScoringModel.pickleballSideOut:
        return 'Side-out';
      case SportScoringModel.rallyPointSet:
        return 'Rally';
    }
  }

  String _viewerCurrentSetLabel(
    MatchModel match,
    ScorePanelState state,
    SportConfig config,
  ) {
    if (match.isCompleted) {
      return 'KẾT THÚC';
    }
    final currentSet = state.finishedSets.length + 1;
    if (config.scoringModel == SportScoringModel.tennisSet) {
      return 'Set $currentSet';
    }
    return 'Hiệp $currentSet';
  }

  Widget _buildViewerConfigChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 11, color: context.colors.textMuted),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  COMPLETED STATE — Đã kết thúc
  // ═══════════════════════════════════════════════════════════
  Widget _buildCompletedState(MatchModel match, UserRole? role) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Trophy animation
            const Icon(
                  Icons.emoji_events_rounded,
                  size: 72,
                  color: Colors.amber,
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .then()
                .shimmer(
                  duration: 1500.ms,
                  color: Colors.amber.withValues(alpha: 0.3),
                ),
            const SizedBox(height: 16),
            Text(
              'TRẬN ĐẤU ĐÃ KẾT THÚC',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            // Score display
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.success.withValues(alpha: 0.1),
                    context.colors.success.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.colors.success.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Team 1
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${match.score1}',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: match.winnerId == match.team1Id
                                ? context.colors.success
                                : context.colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          match.team1Name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: match.winnerId == match.team1Id
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: match.winnerId == match.team1Id
                                ? context.colors.success
                                : context.colors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '-',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ),
                  // Team 2
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${match.score2}',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: match.winnerId == match.team2Id
                                ? context.colors.success
                                : context.colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          match.team2Name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: match.winnerId == match.team2Id
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: match.winnerId == match.team2Id
                                ? context.colors.success
                                : context.colors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fade(duration: 400.ms),

            const SizedBox(height: 24),

            // Winner badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Thắng: ${match.winnerId == match.team1Id ? match.team1Name : match.team2Name}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (role == UserRole.admin) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.edit, color: Colors.red, size: 18),
                label: const Text(
                  'SỬA KẾT QUẢ (ADMIN)',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showAdminEditDialog(context, match),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Quay lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.bgSurface,
                foregroundColor: context.colors.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/'),
              child: Text(
                'Về trang chủ',
                style: TextStyle(color: context.colors.textMuted),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showAdminEditDialog(BuildContext context, MatchModel match) {
    final score1Ctrl = TextEditingController(text: match.score1.toString());
    final score2Ctrl = TextEditingController(text: match.score2.toString());
    String selectedWinnerId = match.winnerId.isNotEmpty
        ? match.winnerId
        : match.team1Id;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: context.colors.bgCard,
              title: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Admin: Sửa Kết Quả',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Việc thay đổi kết quả sẽ ghi đè dữ liệu và tự động cập nhật nhánh đấu tiếp theo.',
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.team1Name,
                                style: TextStyle(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: score1Ctrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  color: context.colors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: context.colors.bgDark,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: context.colors.border,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.team2Name,
                                style: TextStyle(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: score2Ctrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  color: context.colors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: context.colors.bgDark,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: context.colors.border,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Đội chiến thắng:',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedWinnerId,
                      dropdownColor: context.colors.bgCard,
                      items: [
                        DropdownMenuItem(
                          value: match.team1Id,
                          child: Text(
                            match.team1Name,
                            style: TextStyle(color: context.colors.textPrimary),
                          ),
                        ),
                        DropdownMenuItem(
                          value: match.team2Id,
                          child: Text(
                            match.team2Name,
                            style: TextStyle(color: context.colors.textPrimary),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedWinnerId = val);
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: context.colors.bgDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: context.colors.border),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    final s1 = int.tryParse(score1Ctrl.text) ?? 0;
                    final s2 = int.tryParse(score2Ctrl.text) ?? 0;
                    final wId = selectedWinnerId;
                    final lId = selectedWinnerId == match.team1Id
                        ? match.team2Id
                        : match.team1Id;

                    Navigator.pop(ctx);
                    ref
                        .read(
                          matchControllerProvider((
                            tournamentId: widget.tournamentId,
                            matchId: widget.matchId,
                          )),
                        )
                        .updateMatchResultByAdmin(
                          score1: s1,
                          score2: s2,
                          winnerId: wId,
                          loserId: lId,
                        );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật kết quả trận đấu!'),
                      ),
                    );
                  },
                  child: const Text(
                    'Lưu Thay Đổi',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  CHAT TAB
  // ═══════════════════════════════════════════════════════════
  Widget _buildChatTab(MatchModel match) {
    final colors = context.colors;
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
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 28,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có thảo luận',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hãy là người đầu tiên chia sẻ cảm nghĩ!',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: mergedList.length,
                    itemBuilder: (context, index) {
                      final item = mergedList[index];
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
                            borderRadius: BorderRadius.circular(10),
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
                          user?['fullName']?.toString() ?? 'Người xem';
                      final commentText = item['commentText']?.toString() ?? '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              backgroundImage: avatarUrl.isNotEmpty
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl.isEmpty
                                  ? Text(
                                      userName.isNotEmpty
                                          ? userName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        userName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: colors.textPrimary,
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
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.bgSurface,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      commentText,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colors.bgCard,
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentTextController,
                    enabled: isAuth && !_isSubmittingComment,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: isAuth
                          ? 'Nhập bình luận...'
                          : 'Đăng nhập để bình luận',
                      hintStyle: TextStyle(
                        color: colors.textMuted,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _postComment(),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFE11D48),
                  ),
                  onPressed: _handleCheer,
                ),
                if (!isAuth)
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: _isSubmittingComment
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: AppTheme.primary,
                          ),
                    onPressed: _postComment,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
