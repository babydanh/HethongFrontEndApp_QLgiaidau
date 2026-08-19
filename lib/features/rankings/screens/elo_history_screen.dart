import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/elo_history_log.dart';
import 'package:app_quanly_giaidau/providers/ranking_provider.dart';
import 'package:app_quanly_giaidau/features/rankings/widgets/elo_progress_chart.dart';

class EloHistoryScreen extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int currentElo;
  final String? tierName;

  const EloHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.currentElo,
    this.tierName,
  });

  @override
  ConsumerState<EloHistoryScreen> createState() => _EloHistoryScreenState();
}

class _EloHistoryScreenState extends ConsumerState<EloHistoryScreen> {
  String? _selectedScope;
  static const _limit = 50;

  EloHistoryQuery get _query => (
    userId: widget.userId,
    categoryId: null,
    scope: _selectedScope,
    communityId: null,
    limit: _limit,
    cursor: null,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final historyAsync = ref.watch(eloHistoryProvider(_query));
    final history = historyAsync.asData?.value ?? [];

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
          'Lịch sử ELO',
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
                  'ELO hiện tại',
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  'Chưa có lịch sử biến động ELO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hãy tham gia các trận đấu xếp hạng để ghi nhận điểm ELO',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textMuted,
                  ),
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
                'Peak ELO (Cao nhất)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                NumberFormat('#,###', 'vi_VN').format(peakElo),
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
    final scopes = [
      (null, 'Tất cả'),
      ('PUBLIC', 'Công khai'),
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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

  Widget _buildActivityLog(List<EloHistoryLog> history, AppColorsExtension colors) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'HOẠT ĐỘNG',
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
    final date = DateTime.tryParse(log.createdAt) ?? DateTime.now();
    final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(date);
    final gain = log.isGain;
    final diffStr = gain ? '+${log.eloDiff}' : '${log.eloDiff}';
    final diffColor = gain ? colors.success : colors.error;

    String reasonLabel;
    if (log.match?.tournamentName != null) {
      reasonLabel = log.match!.tournamentName!;
    } else if (log.reason != null && log.reason!.toLowerCase().contains('decay')) {
      reasonLabel = 'Suy giảm ELO (không thi đấu)';
    } else if (log.reason != null) {
      reasonLabel = log.reason!;
    } else {
      reasonLabel = 'Cập nhật ELO';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: diffColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                diffStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: diffColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reasonLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$timeStr • ${log.previousElo} → ${log.newElo}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

