import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/violation_report.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit_extras.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/report_provider.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reportsAsync = ref.watch(myReportsProvider);
    void reload() => ref.read(myReportsProvider.notifier).loadPage(1);

    return LavishScaffold(
      title: l10n.myReportsTitle,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/profile');
        }
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: l10n.myReportsRefresh,
          onPressed: reload,
        ),
      ],
      body: reportsAsync.when(
        loading: () => const LavishRowSkeleton(),
        error: (error, _) => LavishErrorState(
          message: ErrorParser.parse(error, '', l10n),
          onRetry: reload,
        ),
        data: (data) => data.reports.isEmpty
            ? LavishEmptyState(
                icon: Icons.flag_outlined,
                title: l10n.myReportsEmptyTitle,
              )
            : _ReportsList(data: data),
      ),
    );
  }
}

class _ReportsList extends ConsumerWidget {
  const _ReportsList({required this.data});

  final MyReportsState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(myReportsProvider.notifier);
    final hasPages = data.totalPages > 1;
    return RefreshIndicator(
      onRefresh: () => notifier.loadPage(1),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: data.reports.length + (hasPages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == data.reports.length) {
            return _Pagination(
              page: data.page,
              totalPages: data.totalPages,
              onPrevious: data.page > 1
                  ? () => notifier.loadPage(data.page - 1)
                  : null,
              onNext: data.page < data.totalPages
                  ? () => notifier.loadPage(data.page + 1)
                  : null,
            );
          }
          return _ReportRow(report: data.reports[index]);
        },
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report});

  final ViolationReport report;

  IconData get _icon => switch (report.targetType) {
    ReportTargetType.user => Icons.person_outline_rounded,
    ReportTargetType.tournament => Icons.emoji_events_outlined,
    ReportTargetType.match => Icons.sports_score_rounded,
    ReportTargetType.community => Icons.groups_outlined,
  };

  String _statusLabel(AppLocalizations l10n) => switch (report.status) {
    ReportStatus.submitted => l10n.myReportsStatusSubmitted,
    ReportStatus.triaged => l10n.myReportsStatusTriaged,
    ReportStatus.underReview => l10n.myReportsStatusUnderReview,
    ReportStatus.escalated => l10n.myReportsStatusEscalated,
    ReportStatus.resolved => l10n.myReportsStatusResolved,
    ReportStatus.rejected => l10n.myReportsStatusRejected,
  };

  LavishTone get _tone => switch (report.status) {
    ReportStatus.resolved => LavishTone.ok,
    ReportStatus.rejected => LavishTone.bad,
    _ => LavishTone.warn,
  };

  String get _route => switch (report.targetType) {
    ReportTargetType.user => '/profile/user/${report.targetId}',
    ReportTargetType.tournament => '/tournaments/${report.targetId}',
    ReportTargetType.match => '/live/${report.targetId}',
    ReportTargetType.community => '/communities/${report.targetId}',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final created = report.createdAt;
    final date = created == null
        ? l10n.myReportsUnknownDate
        : DateFormat.yMd(
            Localizations.localeOf(context).languageCode,
          ).add_jm().format(created.toLocal());
    final note = report.resolutionNote;
    final subtitle = note != null && note.isNotEmpty ? '$date\n$note' : date;
    return LavishRow(
      leading: LavishIconBox(child: Icon(_icon)),
      title: report.reason,
      subtitle: subtitle,
      trailing: [LavishPill(_statusLabel(l10n), tone: _tone)],
      onTap: report.targetId.isEmpty ? null : () => context.push(_route),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LavishColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
              color: c.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: onNext,
            tooltip: l10n.myReportsNextPage,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
