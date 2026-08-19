import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/violation_report.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/report_provider.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final reportsAsync = ref.watch(myReportsProvider);

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          tooltip: l10n.myReportsBack,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(
          l10n.myReportsTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.textSecondary),
            tooltip: l10n.myReportsRefresh,
            onPressed: () => ref.read(myReportsProvider.notifier).loadPage(1),
          ),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(myReportsProvider.notifier).loadPage(1),
        ),
        data: (data) => _ReportsContent(data: data),
      ),
    );
  }
}

class _ReportsContent extends ConsumerWidget {
  final MyReportsState data;

  const _ReportsContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    if (data.reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(myReportsProvider.notifier).loadPage(1),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
          children: [
            Icon(Icons.flag_outlined, size: 56, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              l10n.myReportsEmptyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.myReportsEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, height: 1.5),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(myReportsProvider.notifier).loadPage(1),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: data.reports.length + (data.totalPages > 1 ? 1 : 0),
        separatorBuilder: (_, index) => SizedBox(
          height: index == data.reports.length - 1 && data.totalPages > 1
              ? 12
              : 10,
        ),
        itemBuilder: (context, index) {
          if (index == data.reports.length) {
            return _Pagination(
              page: data.page,
              totalPages: data.totalPages,
              onPrevious: data.page > 1
                  ? () => ref
                        .read(myReportsProvider.notifier)
                        .loadPage(data.page - 1)
                  : null,
              onNext: data.page < data.totalPages
                  ? () => ref
                        .read(myReportsProvider.notifier)
                        .loadPage(data.page + 1)
                  : null,
            );
          }
          return _ReportCard(report: data.reports[index]);
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ViolationReport report;

  const _ReportCard({required this.report});

  String _targetLabel(AppLocalizations l10n) => switch (report.targetType) {
    ReportTargetType.user => l10n.myReportsTargetUser,
    ReportTargetType.tournament => l10n.myReportsTargetTournament,
    ReportTargetType.match => l10n.myReportsTargetMatch,
    ReportTargetType.community => l10n.myReportsTargetCommunity,
  };

  String _categoryLabel(AppLocalizations l10n) => switch (report.category) {
    ReportCategory.cheating => l10n.myReportsCategoryCheating,
    ReportCategory.ruleViolation => l10n.myReportsCategoryRuleViolation,
    ReportCategory.abusiveBehavior => l10n.myReportsCategoryAbusiveBehavior,
    ReportCategory.fakeInformation => l10n.myReportsCategoryFakeInformation,
    ReportCategory.paymentFraud => l10n.myReportsCategoryPaymentFraud,
    ReportCategory.unsafeOrganization =>
      l10n.myReportsCategoryUnsafeOrganization,
    ReportCategory.other => l10n.myReportsCategoryOther,
  };

  String _statusLabel(AppLocalizations l10n) => switch (report.status) {
    ReportStatus.submitted => l10n.myReportsStatusSubmitted,
    ReportStatus.triaged => l10n.myReportsStatusTriaged,
    ReportStatus.underReview => l10n.myReportsStatusUnderReview,
    ReportStatus.escalated => l10n.myReportsStatusEscalated,
    ReportStatus.resolved => l10n.myReportsStatusResolved,
    ReportStatus.rejected => l10n.myReportsStatusRejected,
  };

  Color _statusColor() => switch (report.status) {
    ReportStatus.submitted => Colors.blue,
    ReportStatus.triaged => Colors.indigo,
    ReportStatus.underReview => Colors.orange,
    ReportStatus.escalated => Colors.deepOrange,
    ReportStatus.resolved => Colors.green,
    ReportStatus.rejected => Colors.red,
  };

  String? _targetRoute() => switch (report.targetType) {
    ReportTargetType.user => '/profile/user/${report.targetId}',
    ReportTargetType.tournament => '/tournaments/${report.targetId}',
    ReportTargetType.match => '/live/${report.targetId}',
    ReportTargetType.community => '/communities/${report.targetId}',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final date = report.createdAt == null
        ? l10n.myReportsUnknownDate
        : DateFormat.yMd(
            Localizations.localeOf(context).languageCode,
          ).add_jm().format(report.createdAt!.toLocal());
    final targetName = report.target?.name.isNotEmpty == true
        ? report.target!.name
        : report.targetId.length > 8
        ? report.targetId.substring(0, 8)
        : report.targetId;
    final route = _targetRoute();
    final statusColor = _statusColor();

    return Card(
      margin: EdgeInsets.zero,
      color: colors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(label: _statusLabel(l10n), color: statusColor),
                _MetaLabel(
                  label: _targetLabel(l10n),
                  color: colors.textSecondary,
                ),
                _MetaLabel(
                  label: _categoryLabel(l10n),
                  color: colors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              targetName.isEmpty ? l10n.myReportsUnknownTarget : targetName,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              report.reason,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.myReportsSentAt(date),
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
            if (report.resolutionNote?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: colors.border),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${l10n.myReportsResolutionNote}: ',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: report.resolutionNote,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (route != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => context.push(route),
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: Text(l10n.myReportsViewTarget),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _Pagination({
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrevious,
          tooltip: l10n.myReportsPreviousPage,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(
          l10n.myReportsPageCount(page, totalPages),
          style: TextStyle(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        IconButton(
          onPressed: onNext,
          tooltip: l10n.myReportsNextPage,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
            const SizedBox(height: 12),
            Text(
              l10n.myReportsLoadError,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.myReportsRetry),
            ),
          ],
        ),
      ),
    );
  }
}
