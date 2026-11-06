import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/repositories/series_legs_repository.dart';
import 'package:app_quanly_giaidau/features/series/widgets/series_leg_form_sheet.dart';
import 'package:app_quanly_giaidau/features/series/widgets/series_leg_link_sheet.dart';
import 'package:app_quanly_giaidau/features/series/widgets/series_legs_error_text.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/series_legs_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Màn BTC quản lý vòng của một chuỗi: thêm/sửa/xóa vòng, gắn/gỡ giải.
/// Quyền (chủ chuỗi hoặc ADMIN) do Backend kiểm; nút vào màn này chỉ hiện cho họ.
class SeriesLegsManageScreen extends ConsumerStatefulWidget {
  const SeriesLegsManageScreen({super.key, required this.seriesId});

  final String seriesId;

  @override
  ConsumerState<SeriesLegsManageScreen> createState() =>
      _SeriesLegsManageScreenState();
}

class _SeriesLegsManageScreenState
    extends ConsumerState<SeriesLegsManageScreen> {
  /// Đang chạy một lệnh xóa/gỡ — khoá để bấm đúp không gửi hai lần.
  bool _busy = false;

  SeriesLegsRepository get _repository =>
      ref.read(seriesLegsRepositoryProvider);

  void _reload() => ref.invalidate(seriesLegsOverviewProvider(widget.seriesId));

  void _say(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _openLegForm(SeriesLegRecord? leg, int legCount) async {
    final l10n = AppLocalizations.of(context)!;
    final saved = await SeriesLegFormSheet.show(
      context,
      initial: leg,
      defaultOrder: legCount + 1,
      onSubmit: (input) => leg == null
          ? _repository.createLeg(widget.seriesId, input)
          : _repository.updateLeg(widget.seriesId, leg.id, input),
    );
    if (saved != true || !mounted) return;
    _reload();
    _say(leg == null ? l10n.seriesLegsCreated : l10n.seriesLegsUpdated);
  }

  Future<void> _openLinkSheet(
    SeriesLegWithEvents item,
    List<SeriesLegWithEvents> all,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final saved = await SeriesLegLinkSheet.show(
      context,
      legName: item.leg.name,
      defaultOrder: item.events.length + 1,
      excludedTournamentIds: {
        for (final entry in all)
          for (final event in entry.events) event.tournamentId,
      },
      onSubmit: (input) =>
          _repository.linkTournament(widget.seriesId, item.leg.id, input),
    );
    if (saved != true || !mounted) return;
    _reload();
    _say(l10n.seriesLegsLinked);
  }

  Future<bool> _confirm(String title, String message, String action) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            key: const ValueKey('series-legs-confirm-no'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.seriesLegsCancel),
          ),
          FilledButton(
            key: const ValueKey('series-legs-confirm-yes'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// Chạy một lệnh ghi một lần. Luôn tải lại sau đó: thành công thì thấy kết
  /// quả, lỗi 409 thì thấy dữ liệu mới.
  Future<void> _run(Future<void> Function() call, String successText) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await call();
      if (mounted) _say(successText);
    } catch (error) {
      if (mounted) _say(seriesLegsErrorText(error, l10n));
    }
    if (!mounted) return;
    _reload();
    setState(() => _busy = false);
  }

  Future<void> _deleteLeg(SeriesLegRecord leg) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      l10n.seriesLegsDeleteTitle,
      l10n.seriesLegsDeleteMessage(leg.name),
      l10n.seriesLegsDeleteAction,
    );
    if (!confirmed || !mounted) return;
    await _run(
      () => _repository.deleteLeg(widget.seriesId, leg.id),
      l10n.seriesLegsDeleted,
    );
  }

  Future<void> _unlinkEvent(SeriesLegRecord leg, SeriesLegEvent event) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      l10n.seriesLegsUnlinkTitle,
      l10n.seriesLegsUnlinkMessage(event.tournamentName),
      l10n.seriesLegsUnlinkAction,
    );
    if (!confirmed || !mounted) return;
    await _run(
      () => _repository.unlinkTournament(widget.seriesId, leg.id, event.id),
      l10n.seriesLegsUnlinked,
    );
  }

  Widget _error(AppLocalizations l10n) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.seriesLegsLoadError),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _reload,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(l10n.infoRetry),
        ),
      ],
    ),
  );

  Widget _list(List<SeriesLegWithEvents> items, AppLocalizations l10n) {
    if (items.isEmpty) {
      return Center(child: Text(l10n.seriesLegsEmpty));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _LegCard(
          item: item,
          busy: _busy,
          onEdit: () => _openLegForm(item.leg, items.length),
          onDelete: () => _deleteLeg(item.leg),
          onLink: () => _openLinkSheet(item, items),
          onUnlink: (event) => _unlinkEvent(item.leg, event),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overview = ref.watch(seriesLegsOverviewProvider(widget.seriesId));
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(title: Text(l10n.seriesLegsManage)),
      floatingActionButton: overview.hasValue
          ? FloatingActionButton.extended(
              key: const ValueKey('series-legs-add'),
              onPressed: () => _openLegForm(null, overview.requireValue.length),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.seriesLegsAdd),
            )
          : null,
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _error(l10n),
        data: (items) => _list(items, l10n),
      ),
    );
  }
}

class _LegCard extends StatelessWidget {
  const _LegCard({
    required this.item,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onLink,
    required this.onUnlink,
  });

  final SeriesLegWithEvents item;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLink;
  final ValueChanged<SeriesLegEvent> onUnlink;

  String _dateRange(SeriesLegRecord leg) {
    final fmt = DateFormat('dd/MM/yyyy');
    final start = leg.startDate == null
        ? '—'
        : fmt.format(leg.startDate!.toLocal());
    final end = leg.endDate == null ? '—' : fmt.format(leg.endDate!.toLocal());
    return '$start → $end';
  }

  Widget _header(BuildContext context, AppLocalizations l10n) {
    final colors = context.colors;
    final leg = item.leg;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.seriesLegsHeading(leg.order, leg.name),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                _dateRange(leg),
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              Text(
                l10n.seriesLegsSlots(leg.directEntrySlots, leg.wildcardSlots),
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
            ],
          ),
        ),
        IconButton(
          key: ValueKey('series-leg-edit-${leg.id}'),
          tooltip: l10n.seriesLegsEdit,
          onPressed: busy ? null : onEdit,
          icon: const Icon(Icons.edit_rounded),
        ),
        IconButton(
          key: ValueKey('series-leg-delete-${leg.id}'),
          tooltip: l10n.seriesLegsDelete,
          onPressed: busy ? null : onDelete,
          icon: Icon(Icons.delete_outline_rounded, color: colors.error),
        ),
      ],
    );
  }

  Widget _eventRow(
    BuildContext context,
    SeriesLegEvent event,
    AppLocalizations l10n,
  ) {
    final meta = l10n.seriesLegsEventMeta(
      event.order,
      '${event.pointMultiplier}',
    );
    final region = event.region;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(event.tournamentName),
      subtitle: Text(
        region == null || region.isEmpty ? meta : '$meta · $region',
      ),
      trailing: IconButton(
        key: ValueKey('series-event-unlink-${event.id}'),
        tooltip: l10n.seriesLegsUnlink,
        onPressed: busy ? null : () => onUnlink(event),
        icon: const Icon(Icons.link_off_rounded),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, l10n),
          const Divider(height: 20),
          if (item.events.isEmpty)
            Text(
              l10n.seriesLegsNoEvents,
              style: TextStyle(color: colors.textMuted),
            )
          else
            for (final event in item.events) _eventRow(context, event, l10n),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: ValueKey('series-leg-link-${item.leg.id}'),
              onPressed: busy ? null : onLink,
              icon: const Icon(Icons.link_rounded, size: 18),
              label: Text(l10n.seriesLegsLinkTournament),
            ),
          ),
        ],
      ),
    );
  }
}
