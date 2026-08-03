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
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
        final l10n = AppLocalizations.of(context)!;
        final state = ref.read(liteManagementProvider);
        if (state.loading && state.error == null) {
          ref.read(liteManagementProvider.notifier).markLoadFailed(
            l10n.lite_loadFailed,
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
    final l10n = AppLocalizations.of(context)!;
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
          state.tournamentName ?? l10n.lite_managementTitle,
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
          isScrollable: true,
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
          tabs: [
            Tab(icon: const Icon(Icons.dashboard_outlined, size: 18), text: l10n.organizer_tabOverview),
            Tab(icon: const Icon(Icons.people_outline_rounded, size: 18), text: l10n.lite_participantsTab),
            Tab(icon: const Icon(Icons.account_tree_outlined, size: 18), text: l10n.lite_bracketAndMatches),
            const Tab(icon: Icon(Icons.tune_rounded, size: 18), text: 'Điều hành'),
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
                      label: Text(l10n.infoRetry),
                    ),
                  ],
                ),
              ),
            )
          : AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                Widget frame(Widget child) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: child,
                    ),
                  );
                }

                switch (_tabController.index) {
                  case 0:
                    return frame(_buildOverviewTab(colors, state, notifier));
                  case 1:
                    return frame(_buildParticipantsTab(colors, state, notifier));
                  case 2:
                    // Do not call the public bracket endpoint before the organizer
                    // has created a Lite bracket.
                    return state.hasBracket
                        ? frame(BracketViewScreen(
                            tournamentId: widget.tournamentId,
                            isEmbedded: true,
                          ))
                        : frame(_buildBracketTab(colors, state, notifier));
                  case 3:
                    return frame(_buildOperationsTab(colors, state, notifier));
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.lite_tournamentInfo,
            Icons.info_outline_rounded,
          ),
          const SizedBox(height: 10),
          _infoGrid(colors, [
            (l10n.sportLabel, sportLabel),
            (l10n.formatLabel, formatLabel),
            (l10n.lite_bracketFormat, bracketLabel),
            (l10n.maxTeamsLabel, tournament?.maxTeams.toString() ?? '--'),
            (l10n.lite_participants, '${state.participants.length}'),
            (l10n.matchesTitle, state.hasBracket ? l10n.lite_created : l10n.lite_notCreated),
          ]),
          const SizedBox(height: 24),

          // ─── Invite Code ───
          if (state.inviteCode != null && state.inviteCode!.isNotEmpty) ...[
            _sectionHeader(colors, l10n.lite_inviteCodeTitle, Icons.link_rounded),
            const SizedBox(height: 10),
            _inviteCodeCard(colors, state.inviteCode!),
            const SizedBox(height: 20),

            // ─── QR Code ───
            _sectionHeader(colors, l10n.lite_qrCodeTitle, Icons.qr_code_rounded),
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
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      (l10n.lite_participants, state.participants.isNotEmpty, Icons.people_outline_rounded),
      (l10n.lite_stepPairing, state.isDoubles ? state.completeParticipants.isNotEmpty : true, Icons.link_rounded),
      (l10n.lite_createBracket, state.hasBracket, Icons.account_tree_outlined),
      (l10n.lite_stepFollowMatches, state.hasBracket, Icons.sports_tennis_rounded),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.lite_progressTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          // Perfect Aligned Progress Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final stepWidth = (constraints.maxWidth) / steps.length;
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Center Line Divider running behind circles
                  Positioned(
                    top: 16, // Center of 32px CircleAvatar
                    left: stepWidth / 2,
                    right: stepWidth / 2,
                    child: Container(
                      height: 2,
                      color: colors.border,
                    ),
                  ),
                  // Progress active lines
                  Positioned(
                    top: 16,
                    left: stepWidth / 2,
                    right: stepWidth / 2,
                    child: Row(
                      children: [
                        for (var i = 0; i < steps.length - 1; i++)
                          Expanded(
                            child: Container(
                              height: 2,
                              color: steps[i].$2 && steps[i + 1].$2
                                  ? AppTheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Steps Nodes
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < steps.length; i++)
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: steps[i].$2
                                    ? AppTheme.primary
                                    : colors.bgSurface,
                                child: Icon(
                                  steps[i].$3,
                                  size: 15,
                                  color: steps[i].$2
                                      ? Colors.white
                                      : colors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 28,
                                child: Text(
                                  steps[i].$1,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.2,
                                    fontWeight: steps[i].$2
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: steps[i].$2
                                        ? AppTheme.primary
                                        : colors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    AppColorsExtension colors,
    LiteManagementState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
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
                  state.tournamentName ?? l10n.navTournaments,
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
                state.isDoubles ? l10n.lite_doubles : l10n.lite_singles,
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
                '${l10n.maxTeamsLabel}: ${tournament?.maxTeams ?? '--'} ${l10n.teamsUnit}',
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
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.lite_inviteCode,
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
                  SnackBar(content: Text(l10n.lite_inviteCopied)),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: Text(l10n.lite_copy, style: const TextStyle(fontSize: 13)),
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.lite_qrInstruction,
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
    final l10n = AppLocalizations.of(context)!;

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
                child: Text(l10n.infoRetry),
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
                  state.mockLoading ? l10n.lite_creating : l10n.lite_createMockPlayers,
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
              '${l10n.lite_waitingPair} (${pending.length})',
              Icons.people_outline_rounded,
            ),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              _emptyCard(colors, l10n.lite_noPendingPairs)
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
                    state.pairing ? l10n.lite_pairing : l10n.lite_pairSelected,
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
                l10n.lite_autoPairing,
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
                              l10n.lite_random,
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
                              l10n.lite_eloBalanced,
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
                        l10n.lite_oddNotice,
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
                '${l10n.lite_paired} (${allPaired.length})',
                Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 8),
              ...allPaired.map((p) => _pairedTile(colors, notifier, p)),
            ],
          ] else ...[
            // ─── Singles: just participant list ───
            _sectionHeader(
              colors,
              '${l10n.lite_participants} (${state.participants.length})',
              Icons.people_rounded,
            ),
            const SizedBox(height: 6),
            if (state.participants.isEmpty)
              _emptyCard(colors, l10n.noParticipants)
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
                    : const Icon(Icons.emoji_events_rounded, size: 20),
                label: Text(
                  state.creatingBracket ? l10n.lite_creating : l10n.lite_createBracket,
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
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: '8');
    final count = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.lite_createMockPlayers),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.lite_quantity,
            hintText: l10n.lite_quantityHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.matchesCancel),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim()) ?? 0;
              if (n < 1 || n > 50) return;
              Navigator.pop(ctx, n);
            },
            child: Text(l10n.lite_create),
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
    final l10n = AppLocalizations.of(context)!;
    final replacingExisting = ref.read(liteManagementProvider).hasBracket;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(replacingExisting ? 'Tạo lại bracket?' : l10n.lite_createBracketTitle),
        content: Text(
          replacingExisting
              ? 'Bracket cũ và lịch trận chưa bắt đầu sẽ bị thay thế hoàn toàn. Không thể hoàn tác. Bạn có chắc muốn tiếp tục?'
              : l10n.lite_createBracketConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.matchesCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(replacingExisting ? 'Tạo lại' : l10n.lite_createBracket),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      if (replacingExisting) {
        await notifier.resetBracket(widget.tournamentId);
      } else {
        await notifier.createBracket(widget.tournamentId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(replacingExisting ? 'Đã tạo lại bracket mới.' : l10n.lite_bracketCreated)),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e is DioException && e.response?.statusCode == 401
            ? l10n.lite_sessionExpired
            : e is DioException && e.response?.statusCode == 403
                ? l10n.lite_unauthorized
                : e.toString().replaceAll('Exception: ', '').replaceAll('DioException: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorPrefix}: $message'),
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
    final l10n = AppLocalizations.of(context)!;
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
              state.hasBracket ? l10n.lite_bracketCreated : l10n.lite_noBracket,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.hasBracket
                  ? l10n.lite_viewBracketDesc
                  : l10n.lite_createBracketDesc,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            if (state.hasBracket)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.lite_bracketComingSoon)),
                      );
                    },
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: Text(l10n.viewBracket),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: state.creatingBracket
                        ? null
                        : () => _createBracket(colors, notifier),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Tạo lại bracket'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.warning,
                      side: BorderSide(color: colors.warning),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      ),
                    ),
                  ),
                ],
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
                    state.creatingBracket ? l10n.lite_creating : l10n.lite_createBracket,
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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.matchesTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.lite_matchesAfterBracket,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsTab(
    AppColorsExtension colors,
    LiteManagementState state,
    LiteManagementNotifier notifier,
  ) {
    final matches = state.matches;
    return RefreshIndicator(
      onRefresh: () => notifier.refreshMatches(widget.tournamentId),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            'Điều hành giải',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Theo dõi trận, mở bảng điểm và xử lý kết quả từ một nơi.',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          if (state.matchesError != null) ...[
            const SizedBox(height: 12),
            _operationsNotice(colors, state.matchesError!),
          ],
          const SizedBox(height: 16),
          if (matches.isEmpty)
            _emptyCard(colors, state.matchesError == null
                ? 'Chưa có trận đấu trong giải.'
                : 'Chưa thể đồng bộ trận mới. Dữ liệu cũ vẫn được giữ nguyên; kéo xuống để thử lại.')
          else
            ...matches.map((match) => _operationMatchCard(colors, notifier, match)),
        ],
      ),
    );
  }

  Widget _operationsNotice(AppColorsExtension colors, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 18, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(fontSize: 12, color: colors.textSecondary))),
        ],
      ),
    );
  }

  Widget _operationMatchCard(
    AppColorsExtension colors,
    LiteManagementNotifier notifier,
    MatchModel match,
  ) {
    final status = match.status.toUpperCase();
    final canStart = match.team1Id.isNotEmpty && match.team2Id.isNotEmpty &&
        status != 'COMPLETED' && status != 'ONGOING' && status != 'LIVE';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border.withValues(alpha: 0.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Vòng ${match.round} · Trận ${match.matchNumber}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textMuted))),
                _statusChip(colors, status),
              ],
            ),
            const SizedBox(height: 10),
            Text('${match.team1Name}  ${match.score1} - ${match.score2}  ${match.team2Name}', style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary)),
            if (match.court.isNotEmpty || match.refereeName != null) ...[
              const SizedBox(height: 6),
              Text('${match.court.isEmpty ? 'Chưa xếp sân' : match.court} · ${match.refereeName ?? 'Chưa có trọng tài'}', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push('/live/${match.id}'),
                  icon: const Icon(Icons.scoreboard_outlined, size: 17),
                  label: const Text('Mở bảng điểm'),
                ),
                if (canStart)
                  FilledButton.icon(
                    onPressed: () => notifier.startMatch(widget.tournamentId, match.id),
                    icon: const Icon(Icons.play_arrow_rounded, size: 17),
                    label: const Text('Bắt đầu'),
                  ),
                if (status == 'ONGOING' || status == 'LIVE')
                  OutlinedButton.icon(
                    onPressed: () => _showOperationDialog(notifier, match),
                    icon: const Icon(Icons.gavel_rounded, size: 17),
                    label: const Text('Quyết định'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(AppColorsExtension colors, String status) {
    final live = status == 'LIVE' || status == 'ONGOING';
    final completed = status == 'COMPLETED' || status == 'FINISHED';
    final color = live ? Colors.green : completed ? colors.textMuted : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(live ? 'Đang diễn ra' : completed ? 'Đã xong' : 'Chưa đấu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Future<void> _showOperationDialog(LiteManagementNotifier notifier, MatchModel match) async {
    const actions = <String, String>{
      'WALKOVER': 'Xử thắng / bỏ cuộc',
      'RETIREMENT': 'Dừng trận',
      'DISQUALIFICATION': 'Loại khỏi giải',
    };
    final action = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Quyết định trận đấu'),
        children: actions.entries.map((entry) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, entry.key),
          child: Text(entry.value),
        )).toList(),
      ),
    );
    if (!mounted || action == null) return;
    await notifier.applyMatchOperation(
      widget.tournamentId,
      match.id,
      action: action,
      reason: actions[action]!,
      winnerId: match.team1Id,
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
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.lite_pendingPair,
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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.joined,
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
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.lite_unpair,
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.lite_unpairTitle),
        content: Text(l10n.lite_unpairContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.lite_keepPair),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.lite_unpair),
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
        ).showSnackBar(SnackBar(content: Text(l10n.lite_unpairSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException && e.response?.statusCode == 404
                  ? l10n.lite_unpairApiNotFound
                  : l10n.lite_unpairError,
            ),
          ),
        );
      }
    }
  }
}
