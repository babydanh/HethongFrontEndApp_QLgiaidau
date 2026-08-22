import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_history_log.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/elo_progress_chart.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class EloHistoryScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int currentElo;
  final String? tierName;
  final String? categoryId;
  final String? categoryName;
  final String? initialScope;
  final String? matchType;
  final String? genderRestriction;
  final String? partnerId;
  final bool lockRatingScope;

  const EloHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.currentElo,
    this.tierName,
    this.categoryId,
    this.categoryName,
    this.initialScope,
    this.matchType,
    this.genderRestriction,
    this.partnerId,
    this.lockRatingScope = false,
  });

  @override
  ConsumerState<EloHistoryScreen> createState() => _EloHistoryScreenState();
}

class _EloHistoryScreenState extends ConsumerState<EloHistoryScreen> {
  String? _selectedScope;
  static const _limit = 50;

  @override
  void initState() {
    super.initState();
    _selectedScope = widget.initialScope;
  }

  EloHistoryQuery get _query => (
    userId: widget.userId,
    categoryId: widget.categoryId,
    scope: _selectedScope,
    communityId: null,
    matchType: widget.matchType,
    genderRestriction: widget.genderRestriction,
    partnerId: widget.partnerId,
    limit: _limit,
    cursor: null,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final historyAsync = ref.watch(eloHistoryProvider(_query));
    final history = historyAsync.asData?.value ?? [];

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName != null && widget.categoryName!.isNotEmpty
              ? '${l10n.settingsEloHistory} · ${widget.categoryName}'
              : l10n.settingsEloHistory,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildChart(history, colors),
            const SizedBox(height: 20),
            _buildScopeFilter(colors),
            const SizedBox(height: 8),
            _buildActivityLog(history, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    final initial = widget.userName.isNotEmpty
        ? widget.userName[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
            backgroundImage: widget.avatarUrl?.isNotEmpty == true
                ? NetworkImage(widget.avatarUrl!)
                : null,
            child: widget.avatarUrl?.isNotEmpty == true
                ? null
                : Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.publicProfileEloAfter,
                  style: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${widget.currentElo}',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.tierName != null)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.tierName!,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<EloHistoryLog> history, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = List<EloHistoryLog>.from(history)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final peakElo = sorted.fold<int>(
      widget.currentElo,
      (peak, h) => h.newElo > peak ? h.newElo : peak,
    );

    return Column(
      children: [
        if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.show_chart_rounded,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.publicProfileNoPlayedElo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.publicProfileNoPlayedEloHint,
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          EloProgressChart(
            data: sorted.map((h) {
              final date = DateTime.tryParse(h.createdAt) ?? DateTime.now();
              return (DateFormat('dd/MM').format(date), h.newElo);
            }).toList(),
            currentElo: widget.currentElo,
            tierName: widget.tierName,
            height: 200,
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Text(
                l10n.publicProfilePeakElo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                NumberFormat.decimalPattern(
                  Localizations.localeOf(context).toLanguageTag(),
                ).format(peakElo),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              if (peakElo > widget.currentElo) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${peakElo - widget.currentElo}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colors.warning,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScopeFilter(AppColorsExtension colors) {
    if (widget.lockRatingScope) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final scopes = [
      (null, l10n.infoAll),
      ('PUBLIC', 'PUBLIC'),
      ('COMMUNITY', 'CLB'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: scopes.map((s) {
          final selected = _selectedScope == s.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedScope = s.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : colors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppTheme.primary : colors.border,
                  ),
                ),
                child: Text(
                  s.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityLog(
    List<EloHistoryLog> history,
    AppColorsExtension colors,
  ) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            AppLocalizations.of(context)!.publicProfileActivity,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...history.map((log) => _buildLogItem(log, colors)),
      ],
    );
  }

  Widget _buildLogItem(EloHistoryLog log, AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateTime.tryParse(log.createdAt) ?? DateTime.now();
    final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(date);
    final match = log.match;
    final result = match?.result?.toUpperCase();
    final resultColor = result == 'WIN'
        ? const Color(0xFF2563EB)
        : result == 'LOSS'
        ? const Color(0xFFDC2626)
        : colors.textMuted;
    final resultLabel = result == 'WIN'
        ? l10n.publicProfileResultWin
        : result == 'LOSS'
        ? l10n.publicProfileResultLoss
        : result == 'DRAW'
        ? l10n.publicProfileResultDraw
        : null;
    final diffColor = log.eloDiff >= 0 ? colors.success : colors.error;
    final diffStr = log.eloDiff >= 0 ? '+${log.eloDiff}' : '${log.eloDiff}';
    final title = match?.tournamentName?.isNotEmpty == true
        ? match!.tournamentName!
        : log.reason?.isNotEmpty == true
        ? log.reason!
        : l10n.publicProfileEloChange;
    final opponent = match?.opponentName ?? l10n.publicProfileUnknownOpponent;
    final score = match?.p1SetsWon != null && match?.p2SetsWon != null
        ? '${match!.p1SetsWon} - ${match.p2SetsWon}'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    diffStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: diffColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 10, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              if (resultLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    resultLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: resultColor,
                    ),
                  ),
                ),
            ],
          ),
          if (match != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 15,
                  color: colors.textMuted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${l10n.publicProfileOpponent}: $opponent',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (score != null) ...[
                  Icon(
                    Icons.sports_score_rounded,
                    size: 15,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n.publicProfileScore}: $score',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                '${l10n.publicProfileEloBefore}: ${log.previousElo}',
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
              Text(
                '${l10n.publicProfileEloAfter}: ${log.newElo}',
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
              Text(
                '${l10n.publicProfileEloChange}: $diffStr',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: diffColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
