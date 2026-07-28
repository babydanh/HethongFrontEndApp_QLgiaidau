import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/status_helpers.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/providers/lite_management_notifier.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';

class LiteManagementScreen extends ConsumerStatefulWidget {
  final String tournamentId;

  const LiteManagementScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<LiteManagementScreen> createState() =>
      _LiteManagementScreenState();
}

class _LiteManagementScreenState extends ConsumerState<LiteManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _loadWatchdog;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    // Wait until the first frame so auth/provider state is ready before the
    // first protected Lite request. Manual refresh already runs after this.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(liteManagementProvider.notifier).init(widget.tournamentId);
      _loadWatchdog = Timer(const Duration(seconds: 18), () {
        if (!mounted) return;
        final state = ref.read(liteManagementProvider);
        if (state.loading && state.error == null) {
          ref.read(liteManagementProvider.notifier).markLoadFailed(
            'Không tải được dữ liệu giải Lite. Kiểm tra mạng hoặc thử lại.',
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _loadWatchdog?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(liteManagementProvider);
    final notifier = ref.read(liteManagementProvider.notifier);

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          state.tournamentName ?? 'Quản lý giải',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.textPrimary),
            onPressed: state.loading
                ? null
                : () => notifier.refresh(widget.tournamentId),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: colors.textMuted,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.people_outline_rounded, size: 18), text: 'Người tham gia'),
            Tab(icon: Icon(Icons.account_tree_outlined, size: 18), text: 'Bracket & trận đấu'),
          ],
        ),
      ),
      body: state.loading && state.error == null && state.participants.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.tournament == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 44, color: colors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => notifier.init(widget.tournamentId),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                switch (_tabController.index) {
                  case 0:
                    return _buildOverviewTab(colors, state, notifier);
                  case 1:
                    return _buildParticipantsTab(colors, state, notifier);
                  case 2:
                    // Lazy-load bracket API only after the tab is opened.
                    return BracketViewScreen(
                      tournamentId: widget.tournamentId,
                      isEmbedded: true,
                    );
                  default:
                    return const SizedBox.shrink();
                }
              },
            ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 1: TỔNG QUAN
  // ═══════════════════════════════════════════

  Widget _buildOverviewTab(
    AppColorsExtension colors,
    LiteManagementState state,
    LiteManagementNotifier notifier,
  ) {
    final tournament = state.tournament;
    final sportLabel = tournament != null
        ? (AppConstants.sportNames[tournament.sport] ?? tournament.sport)
        : '--';
    final formatLabel = tournament != null
        ? (AppConstants.formatNames[tournament.format] ??
              AppConstants.categoryNames[tournament.format] ??
              tournament.format)
        : '--';
    final bracketLabel = tournament != null
        ? (AppConstants.bracketTypeNames[tournament.bracketType] ??
              tournament.bracketType)
        : '--';

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(widget.tournamentId),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ─── Header Card ───
          _buildHeaderCard(colors, state),
          const SizedBox(height: 20),
          _buildLiteFlow(colors, state),
          const SizedBox(height: 24),

          // ─── Info Grid ───
          _sectionHeader(
            colors,
            'Thông tin giải đấu',
            Icons.info_outline_rounded,
          ),
          const SizedBox(height: 10),
          _infoGrid(colors, [
            ('Môn thể thao', sportLabel),
            ('Hình thức', formatLabel),
            ('Thể thức bảng đấu', bracketLabel),
            ('Số đội tối đa', tournament?.maxTeams.toString() ?? '--'),
            ('Người tham gia', '${state.participants.length}'),
            ('Trận đấu', state.hasBracket ? 'Đã tạo' : 'Chưa tạo'),
          ]),
          const SizedBox(height: 24),

          // ─── Invite Code ───
          if (state.inviteCode != null && state.inviteCode!.isNotEmpty) ...[
            _sectionHeader(colors, 'Mã mời tham gia', Icons.link_rounded),
            const SizedBox(height: 10),
            _inviteCodeCard(colors, state.inviteCode!),
            const SizedBox(height: 20),

            // ─── QR Code ───
            _sectionHeader(colors, 'Mã QR', Icons.qr_code_rounded),
            const SizedBox(height: 10),
            _qrCodeCard(colors, state.inviteCode!),
          ],
        ],
      ),
    );
  }

  Widget _buildLiteFlow(
    AppColorsExtension colors,
    LiteManagementState state,
  ) {
    final steps = [
      ('Người tham gia', state.participants.isNotEmpty, Icons.people_outline_rounded),
      ('Ghép cặp', state.isDoubles ? state.completeParticipants.isNotEmpty : true, Icons.link_rounded),
      ('Tạo bracket', state.hasBracket, Icons.account_tree_outlined),
      ('Theo dõi trận', state.hasBracket, Icons.sports_tennis_rounded),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiến độ giải Lite',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: steps[i].$2
                            ? AppTheme.primary
                            : colors.bgSurface,
                        child: Icon(
                          steps[i].$3,
                          size: 16,
                          color: steps[i].$2 ? Colors.white : colors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        steps[i].$1,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: steps[i].$2 ? AppTheme.primary : colors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Divider(
                      color: steps[i].$2 ? AppTheme.primary : colors.border,
                      thickness: 1.5,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    AppColorsExtension colors,
    LiteManagementState state,
  ) {
    final tournament = state.tournament;
    final status = tournament?.status ?? '';
    final statusLabel = StatusHelper.getTournamentStatusLabel(status);
    final statusColor = StatusHelper.getTournamentStatusColor(status, context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              Expanded(
                child: Text(
                  state.tournamentName ?? 'Giải đấu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.sports_rounded, size: 16, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                tournament != null
                    ? (AppConstants.sportNames[tournament.sport] ??
                          tournament.sport)
                    : '--',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.people_outline_rounded,
                size: 16,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                state.isDoubles ? 'Đánh đôi' : 'Đánh đơn',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.groups_rounded, size: 16, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Tối đa: ${tournament?.maxTeams ?? '--'} đội',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoGrid(AppColorsExtension colors, List<(String, String)> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final (label, value) = items[index];
          final isLast = index == items.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 13, color: colors.textMuted),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _inviteCodeCard(AppColorsExtension colors, String inviteCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mã mời',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  inviteCode,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép mã mời')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Sao chép', style: TextStyle(fontSize: 13)),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrCodeCard(AppColorsExtension colors, String inviteCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: QrImageView(
              data: inviteCode,
              version: QrVersions.auto,
              size: 160,
              backgroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quét mã QR để tham gia giải',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 2: NGƯỜI THAM GIA
  // ═══════════════════════════════════════════

  Widget _buildParticipantsTab(
    AppColorsExtension colors,
    LiteManagementState state,
    LiteManagementNotifier notifier,
  ) {
    if (state.loading && state.participants.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.participants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => notifier.refresh(widget.tournamentId),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final pending = state.pendingParticipants;
    final allPaired = state.completeParticipants;
    final isDoubles = state.isDoubles;

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(widget.tournamentId),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ─── Loading banner ───
          if (state.loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),

          // ─── Mock tools ───
          Row(
            children: [
              const Spacer(),
              TextButton.icon(
                onPressed: state.mockLoading
                    ? null
                    : () => _promptSeedMock(colors, notifier),
                icon: state.mockLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.science_outlined,
                        size: 18,
                        color: colors.warning,
                      ),
                label: Text(
                  state.mockLoading ? 'Đang tạo...' : 'Tạo VĐV ảo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.warning,
                  ),
                ),
              ),
            ],
          ),

          if (isDoubles) ...[
            // ─── Pending Section ───
            _sectionHeader(
              colors,
              'Chờ ghép cặp (${pending.length})',
              Icons.people_outline_rounded,
            ),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              _emptyCard(colors, 'Không có người chơi đang chờ ghép cặp')
            else
              ...pending.map((p) => _pendingTile(colors, state, notifier, p)),

            // ─── Manual pair button ───
            if (state.selectedIds.length == 2) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: state.pairing
                      ? null
                      : () => notifier.manualPair(widget.tournamentId),
                  icon: state.pairing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.link_rounded, size: 18),
                  label: Text(
                    state.pairing ? 'Đang ghép...' : 'Ghép 2 người đã chọn',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                  ),
                ),
              ),
            ],

            // ─── Auto generate section ───
            if (pending.length >= 2) ...[
              const SizedBox(height: 16),
              _sectionHeader(
                colors,
                'Ghép cặp tự động',
                Icons.auto_fix_high_rounded,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.generating
                          ? null
                          : () => notifier.generatePairs(
                              widget.tournamentId,
                              'RANDOM',
                            ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXL,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child:
                          state.generating &&
                              state.generatingStrategy == 'RANDOM'
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Ngẫu nhiên',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.generating
                          ? null
                          : () => notifier.generatePairs(
                              widget.tournamentId,
                              'ELO_BALANCED',
                            ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXL,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child:
                          state.generating &&
                              state.generatingStrategy == 'ELO_BALANCED'
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Cân bằng ELO',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],

            // ─── Odd notice ───
            if (pending.length.isOdd) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(
                    color: colors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: colors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Số lẻ: 1 người chơi sẽ ở lại trạng thái chờ ghép',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ─── Paired Section ───
            if (allPaired.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionHeader(
                colors,
                'Đã ghép cặp (${allPaired.length})',
                Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 8),
              ...allPaired.map((p) => _pairedTile(colors, notifier, p)),
            ],
          ] else ...[
            // ─── Singles: just participant list ───
            _sectionHeader(
              colors,
              'Người tham gia (${state.participants.length})',
              Icons.people_rounded,
            ),
            const SizedBox(height: 6),
            if (state.participants.isEmpty)
              _emptyCard(colors, 'Chưa có người tham gia')
            else
              ...state.participants.map((p) => _singlesTile(colors, p)),
          ],

          // ─── Bracket generation button ───
          if (allPaired.isNotEmpty ||
              (state.participants.isNotEmpty && !isDoubles)) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: state.creatingBracket
                    ? null
                    : () => _createBracket(colors, notifier),
                icon: state.creatingBracket
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.emoji_events_rounded, size: 20),
                label: Text(
                  state.creatingBracket ? 'Đang tạo...' : 'Tạo bracket',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _promptSeedMock(
    AppColorsExtension colors,
    LiteManagementNotifier notifier,
  ) async {
    final ctrl = TextEditingController(text: '8');
    final count = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo VĐV ảo'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Số lượng',
            hintText: '1-50',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim()) ?? 0;
              if (n < 1 || n > 50) return;
              Navigator.pop(ctx, n);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
    if (count != null) {
      notifier.seedMock(widget.tournamentId, count);
    }
  }

  Future<void> _createBracket(
    AppColorsExtension colors,
    LiteManagementNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tạo bracket?'),
        content: const Text(
          'Sau khi tạo bracket, không thể ghép thêm cặp mới. Tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Tạo bracket'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await notifier.createBracket(widget.tournamentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo bracket thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is DioException && e.response?.statusCode == 401
            ? 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại rồi thử tạo bracket.'
            : e is DioException && e.response?.statusCode == 403
                ? 'Tài khoản chưa được xác thực hoặc không có quyền tạo bracket.'
                : e.toString().replaceAll('Exception: ', '').replaceAll('DioException: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $message'),
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════
  // TAB 3: BRACKET
  // ═══════════════════════════════════════════

  Widget _buildBracketTab(
    AppColorsExtension colors,
    LiteManagementState state,
    LiteManagementNotifier notifier,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.hasBracket
                  ? Icons.emoji_events_rounded
                  : Icons.dashboard_customize_rounded,
              size: 56,
              color: colors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              state.hasBracket ? 'Bracket đã được tạo' : 'Chưa có bracket',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.hasBracket
                  ? 'Xem sơ đồ thi đấu để theo dõi các trận đấu'
                  : 'Tạo bracket để bắt đầu các trận đấu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            if (state.hasBracket)
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to bracket view (placeholder for now)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tính năng xem bracket sẽ được cập nhật sau',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('Xem bracket'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                ),
              )
            else ...[
              SizedBox(
                width: 200,
                height: 48,
                child: FilledButton.icon(
                  onPressed: state.creatingBracket
                      ? null
                      : () => _createBracket(colors, notifier),
                  icon: state.creatingBracket
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    state.creatingBracket ? 'Đang tạo...' : 'Tạo bracket',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 4: TRẬN ĐẤU
  // ═══════════════════════════════════════════

  Widget _buildMatchesTab(AppColorsExtension colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_tennis_rounded,
              size: 56,
              color: colors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Trận đấu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Danh sách trận đấu sẽ xuất hiện sau khi tạo bracket',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════

  Widget _sectionHeader(
    AppColorsExtension colors,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _emptyCard(AppColorsExtension colors, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.textMuted, fontSize: 13),
      ),
    );
  }

  Widget _pendingTile(
    AppColorsExtension colors,
    LiteManagementState state,
    LiteManagementNotifier notifier,
    LiteParticipant participant,
  ) {
    final selected = state.selectedIds.contains(participant.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primary.withValues(alpha: 0.06)
            : colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: selected ? AppTheme.primary : colors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => notifier.toggleSelection(participant.id),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 22,
                color: selected ? AppTheme.primary : colors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (participant.members.isNotEmpty)
                      Text(
                        participant.members.map((m) => m.fullName).join(', '),
                        style: TextStyle(fontSize: 11, color: colors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  'Chờ cặp',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _singlesTile(AppColorsExtension colors, LiteParticipant participant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.person_rounded, size: 20, color: colors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (participant.members.isNotEmpty)
                  Text(
                    participant.members.map((m) => m.fullName).join(', '),
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              'Đã tham gia',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pairedTile(
    AppColorsExtension colors,
    LiteManagementNotifier notifier,
    LiteParticipant participant,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(Icons.group_rounded, size: 20, color: colors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (participant.members.isNotEmpty)
                  Text(
                    participant.members.map((m) => m.fullName).join(', '),
                    style: TextStyle(fontSize: 11, color: colors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (participant.members.length >= 2)
            SizedBox(
              height: 32,
              child: OutlinedButton(
                onPressed: () => _confirmUnpair(colors, notifier, participant),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                ),
                child: Text(
                  'Hủy ghép',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmUnpair(
    AppColorsExtension colors,
    LiteManagementNotifier notifier,
    LiteParticipant participant,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy ghép cặp?'),
        content: const Text('Hai người chơi sẽ trở lại danh sách chờ ghép.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Giữ nguyên'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hủy ghép'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await notifier.unpair(widget.tournamentId, participant.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã hủy ghép cặp')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi: ${e.toString().replaceAll('Exception: ', '').replaceAll('DioException: ', '')}',
            ),
          ),
        );
      }
    }
  }
}
