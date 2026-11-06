import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/series_legs_repository.dart';
import 'package:app_quanly_giaidau/features/series/widgets/series_legs_error_text.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/my_tournament_workspace_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bộ chọn giải của tôi để gắn vào một vòng. Giải đã gắn trong chuỗi
/// ([excludedTournamentIds]) không hiện; Backend vẫn từ chối giải đã thuộc chuỗi khác.
class SeriesLegLinkSheet extends ConsumerStatefulWidget {
  const SeriesLegLinkSheet({
    super.key,
    required this.legName,
    required this.defaultOrder,
    required this.excludedTournamentIds,
    required this.onSubmit,
  });

  final String legName;
  final int defaultOrder;
  final Set<String> excludedTournamentIds;
  final Future<void> Function(SeriesLinkInput input) onSubmit;

  /// Trả `true` khi đã gắn thành công.
  static Future<bool?> show(
    BuildContext context, {
    required String legName,
    required int defaultOrder,
    required Set<String> excludedTournamentIds,
    required Future<void> Function(SeriesLinkInput input) onSubmit,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.bgCard,
    builder: (_) => SeriesLegLinkSheet(
      legName: legName,
      defaultOrder: defaultOrder,
      excludedTournamentIds: excludedTournamentIds,
      onSubmit: onSubmit,
    ),
  );

  @override
  ConsumerState<SeriesLegLinkSheet> createState() => _SeriesLegLinkSheetState();
}

class _SeriesLegLinkSheetState extends ConsumerState<SeriesLegLinkSheet> {
  static const _minMultiplier = 0.1;

  final _formKey = GlobalKey<FormState>();
  late final _order = TextEditingController(text: '${widget.defaultOrder}');
  final _region = TextEditingController();
  final _multiplier = TextEditingController();
  String? _selectedId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _order.dispose();
    _region.dispose();
    _multiplier.dispose();
    super.dispose();
  }

  double? _parseMultiplier(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));

  String? _validateMultiplier(String? value, AppLocalizations l10n) {
    if ((value ?? '').trim().isEmpty) return null;
    final number = _parseMultiplier(value);
    return number == null || number < _minMultiplier
        ? l10n.seriesLegsMultiplierInvalid
        : null;
  }

  Future<void> _submit() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    if (_selectedId == null) {
      setState(() => _error = l10n.seriesLegsTournamentRequired);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        SeriesLinkInput(
          tournamentId: _selectedId!,
          order: int.parse(_order.text.trim()),
          region: _region.text,
          pointMultiplier: _parseMultiplier(_multiplier.text),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = seriesLegsErrorText(error, l10n);
      });
    }
  }

  Widget _tournamentPicker(AppLocalizations l10n) {
    final workspace = ref.watch(myTournamentWorkspaceProvider);
    return workspace.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Column(
        children: [
          Text(l10n.seriesLegsTournamentsLoadError),
          TextButton(
            onPressed: () => ref.invalidate(myTournamentWorkspaceProvider),
            child: Text(l10n.infoRetry),
          ),
        ],
      ),
      data: (data) {
        final available = data.organizedTournaments
            .where((t) => !widget.excludedTournamentIds.contains(t.id))
            .toList();
        if (available.isEmpty) return Text(l10n.seriesLegsNoTournaments);
        return Column(children: available.map(_tournamentTile).toList());
      },
    );
  }

  Widget _tournamentTile(Tournament tournament) {
    final selected = tournament.id == _selectedId;
    return ListTile(
      key: ValueKey('link-tournament-${tournament.id}'),
      dense: true,
      enabled: !_busy,
      selected: selected,
      title: Text(tournament.name),
      trailing: selected ? const Icon(Icons.check_circle_rounded) : null,
      onTap: () => setState(() {
        _selectedId = tournament.id;
        _error = null;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.seriesLegsLinkTitle(widget.legName),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.seriesLegsPickTournament,
              style: TextStyle(color: colors.textSecondary),
            ),
            _tournamentPicker(l10n),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('link-form-order'),
              controller: _order,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.seriesLegsFieldOrder),
              validator: (value) => (int.tryParse(value?.trim() ?? '') ?? 0) < 1
                  ? l10n.seriesLegsOrderInvalid
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('link-form-region'),
              controller: _region,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: l10n.seriesLegsFieldRegion,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('link-form-multiplier'),
              controller: _multiplier,
              enabled: !_busy,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.seriesLegsFieldMultiplier,
                hintText: '1.0',
              ),
              validator: (value) => _validateMultiplier(value, l10n),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: colors.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('link-form-submit'),
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.seriesLegsLinkTournament),
            ),
          ],
        ),
      ),
    );
  }
}
