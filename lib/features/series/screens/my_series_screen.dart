import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/list_skeletons.dart';
import 'package:app_quanly_giaidau/domain/entities/managed_series.dart';
import 'package:app_quanly_giaidau/features/series/series_management_error.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/series_management_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// "Chuỗi giải của tôi": danh sách chuỗi BTC đã tạo, kèm sửa và xoá.
class MySeriesScreen extends ConsumerStatefulWidget {
  const MySeriesScreen({super.key});

  @override
  ConsumerState<MySeriesScreen> createState() => _MySeriesScreenState();
}

class _MySeriesScreenState extends ConsumerState<MySeriesScreen> {
  bool _deleting = false;

  Future<void> _delete(ManagedSeries series) async {
    if (_deleting) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(name: series.name),
    );
    if (confirmed != true || !mounted || _deleting) return;
    setState(() => _deleting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(seriesManagementRepositoryProvider).delete(series.id);
      ref.invalidate(mySeriesProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.seriesMgmtDeleted)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            seriesMgmtErrorText(l10n, e, fallback: l10n.seriesMgmtDeleteFailed),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final series = ref.watch(mySeriesProvider);
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        title: Text(l10n.seriesMgmtListTitle),
        centerTitle: true,
        actions: [
          IconButton(
            key: const ValueKey('series-add'),
            tooltip: l10n.seriesMgmtCreateAction,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/organizer/series/create'),
          ),
        ],
      ),
      body: series.when(
        loading: () => const _ListSkeleton(),
        error: (_, _) => _ErrorView(
          message: l10n.seriesMgmtLoadError,
          onRetry: () => ref.invalidate(mySeriesProvider),
        ),
        data: (list) => list.isEmpty
            ? const _EmptyView()
            : RefreshIndicator(
                onRefresh: () => ref.refresh(mySeriesProvider.future),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _SeriesRow(
                    series: list[i],
                    busy: _deleting,
                    onDelete: () => _delete(list[i]),
                  ),
                ),
              ),
      ),
    );
  }
}

class _SeriesRow extends StatelessWidget {
  const _SeriesRow({
    required this.series,
    required this.busy,
    required this.onDelete,
  });

  final ManagedSeries series;
  final bool busy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final start = series.startDate;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: ValueKey('series-row-${series.id}'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            // Legs and tournament linking live on a separate screen.
            onTap: () => context.push('/organizer/series/${series.id}/manage'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          series.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _StatusChip(status: series.status),
                            Text(
                              series.visibility == 'PRIVATE'
                                  ? l10n.seriesMgmtVisibilityPrivate
                                  : l10n.seriesMgmtVisibilityPublic,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textMuted,
                              ),
                            ),
                            if (start != null)
                              Text(
                                DateFormat('dd/MM/yyyy', locale).format(start),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textMuted,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.seriesMgmtManageLegs,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                key: ValueKey('series-edit-${series.id}'),
                tooltip: l10n.seriesMgmtEditAction,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    context.push('/organizer/series/${series.id}/edit'),
              ),
              IconButton(
                key: ValueKey('series-delete-${series.id}'),
                tooltip: l10n.seriesMgmtDeleteAction,
                icon: Icon(Icons.delete_outline_rounded, color: colors.error),
                onPressed: busy ? null : onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final (label, color) = switch (status) {
      'ACTIVE' => (l10n.seriesMgmtStatusActive, colors.info),
      'COMPLETED' => (l10n.seriesMgmtStatusCompleted, colors.success),
      'CANCELLED' => (l10n.seriesMgmtStatusCancelled, colors.error),
      _ => (l10n.seriesMgmtStatusDraft, colors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.seriesMgmtDeleteTitle),
      content: Text(l10n.seriesMgmtDeleteMessage(name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.seriesMgmtCancel),
        ),
        TextButton(
          key: const ValueKey('series-delete-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            l10n.seriesMgmtDeleteAction,
            style: TextStyle(color: context.colors.error),
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: colors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.seriesMgmtEmptyTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.seriesMgmtEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textMuted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('series-empty-create'),
              onPressed: () => context.push('/organizer/series/create'),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.seriesMgmtCreateAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textPrimary),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(l10n.seriesMgmtRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    child: Column(
      children: [
        for (var i = 0; i < 5; i++) const TournamentListItemSkeleton(),
      ],
    ),
  );
}
