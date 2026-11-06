import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';
import 'package:app_quanly_giaidau/core/widgets/form_section.dart';
import 'package:app_quanly_giaidau/domain/entities/managed_series.dart';
import 'package:app_quanly_giaidau/features/series/screens/series_detail_screen.dart';
import 'package:app_quanly_giaidau/features/series/screens/series_screen.dart';
import 'package:app_quanly_giaidau/features/series/series_management_error.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/series_management_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

const _statuses = ['DRAFT', 'ACTIVE', 'COMPLETED', 'CANCELLED'];

/// Tạo chuỗi giải ([seriesId] null) hoặc sửa chuỗi đã có, dùng chung một form.
class SeriesFormScreen extends ConsumerWidget {
  const SeriesFormScreen({super.key, this.seriesId});

  final String? seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final id = seriesId;
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(
        title: Text(
          id == null ? l10n.seriesMgmtCreateTitle : l10n.seriesMgmtEditTitle,
        ),
        centerTitle: true,
      ),
      body: id == null
          ? const _SeriesForm()
          : ref
                .watch(managedSeriesProvider(id))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            seriesMgmtErrorText(
                              l10n,
                              e,
                              fallback: l10n.seriesMgmtLoadError,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () =>
                                ref.invalidate(managedSeriesProvider(id)),
                            child: Text(l10n.seriesMgmtRetry),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (series) => _SeriesForm(initial: series),
                ),
    );
  }
}

class _RankRow {
  _RankRow(int rank, int points)
    : rank = TextEditingController(text: '$rank'),
      points = TextEditingController(text: '$points');

  final TextEditingController rank;
  final TextEditingController points;

  void dispose() {
    rank.dispose();
    points.dispose();
  }
}

class _SeriesForm extends ConsumerStatefulWidget {
  const _SeriesForm({this.initial});

  final ManagedSeries? initial;

  @override
  ConsumerState<_SeriesForm> createState() => _SeriesFormState();
}

class _SeriesFormState extends ConsumerState<_SeriesForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _description = TextEditingController(
    text: widget.initial?.description,
  );
  late final _banner = TextEditingController(text: widget.initial?.bannerUrl);
  late final _logo = TextEditingController(text: widget.initial?.logoUrl);
  late final _prize = TextEditingController(
    text: widget.initial?.totalPrize?.toString(),
  );
  late final _directEntry = TextEditingController();
  late final _wildcard = TextEditingController();
  late final _rulesDescription = TextEditingController();
  late final List<_RankRow> _rows;
  late String _visibility = widget.initial?.visibility ?? 'PUBLIC';
  late String _status = _statuses.contains(widget.initial?.status)
      ? widget.initial!.status
      : 'DRAFT';
  late String _exclusionScope;
  late bool _exclusionRule;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _defaultsApplied = false;
  bool _submitting = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final rules = initial?.rules ?? SeriesRules.defaults('');
    _directEntry.text = '${rules.directEntryThreshold}';
    _wildcard.text = '${rules.wildcardCount}';
    _rulesDescription.text = rules.description;
    _exclusionRule = rules.exclusionRule;
    _exclusionScope = rules.exclusionScope;
    _startDate = initial?.startDate;
    _endDate = initial?.endDate;
    final entries = rules.pointsByRank.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    _rows = [for (final e in entries) _RankRow(e.key, e.value)];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultsApplied || _isEdit) return;
    _defaultsApplied = true;
    _rulesDescription.text = AppLocalizations.of(
      context,
    )!.seriesMgmtDefaultRulesDescription;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _description,
      _banner,
      _logo,
      _prize,
      _directEntry,
      _wildcard,
      _rulesDescription,
    ]) {
      c.dispose();
    }
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  SeriesInput _buildInput() => SeriesInput(
    name: _name.text.trim(),
    description: _description.text.trim(),
    bannerUrl: _banner.text.trim(),
    logoUrl: _logo.text.trim(),
    visibility: _visibility,
    startDate: _startDate,
    endDate: _endDate,
    totalPrize: int.tryParse(_prize.text.trim()),
    status: _isEdit ? _status : null,
    rules: SeriesRules(
      pointsByRank: {
        for (final r in _rows)
          int.parse(r.rank.text.trim()): int.parse(r.points.text.trim()),
      },
      directEntryThreshold: int.parse(_directEntry.text.trim()),
      wildcardCount: int.parse(_wildcard.text.trim()),
      exclusionRule: _exclusionRule,
      exclusionScope: _exclusionScope,
      description: _rulesDescription.text.trim(),
    ),
  );

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final initial = widget.initial;
    setState(() => _submitting = true);
    try {
      final repo = ref.read(seriesManagementRepositoryProvider);
      final input = _buildInput();
      if (initial == null) {
        await repo.create(input);
      } else {
        await repo.update(initial.id, input);
        ref.invalidate(managedSeriesProvider(initial.id));
      }
      ref.invalidate(mySeriesProvider);
      ref.invalidate(seriesListProvider);
      ref.invalidate(seriesDetailProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            initial == null ? l10n.seriesMgmtCreated : l10n.seriesMgmtUpdated,
          ),
        ),
      );
      if (!mounted) return;
      router.canPop() ? router.pop() : router.go('/organizer/series');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            seriesMgmtErrorText(l10n, e, fallback: l10n.seriesMgmtSaveFailed),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _nonNegativeInt(String? value, {int min = 0}) {
    final n = int.tryParse(value?.trim() ?? '');
    return n == null || n < min
        ? AppLocalizations.of(context)!.seriesMgmtInvalidNumber
        : null;
  }

  String? _rankError(_RankRow row, String? value) {
    final l10n = AppLocalizations.of(context)!;
    final text = value?.trim() ?? '';
    final n = int.tryParse(text);
    if (n == null || n < 1) return l10n.seriesMgmtRankInvalid;
    final duplicate = _rows.any((r) => r != row && r.rank.text.trim() == text);
    return duplicate ? l10n.seriesMgmtRankDuplicate : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [_generalSection(context), _rulesSection(context)],
              ),
            ),
          ),
        ),
        _submitBar(context),
      ],
    );
  }

  Widget _generalSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FormSection(
      title: l10n.seriesMgmtSectionGeneral,
      child: Column(
        children: [
          AppTextFormField(
            key: const ValueKey('series-form-name'),
            controller: _name,
            label: l10n.seriesMgmtNameLabel,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? l10n.seriesMgmtNameRequired
                : null,
          ),
          const SizedBox(height: 12),
          AppTextFormField(
            controller: _description,
            label: l10n.seriesMgmtDescriptionLabel,
            minLines: 3,
            maxLines: 6,
          ),
          const SizedBox(height: 12),
          AppTextFormField(
            controller: _banner,
            label: l10n.seriesMgmtBannerLabel,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          AppTextFormField(
            controller: _logo,
            label: l10n.seriesMgmtLogoLabel,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          _dateFields(l10n),
          const SizedBox(height: 12),
          AppTextFormField(
            key: const ValueKey('series-form-prize'),
            controller: _prize,
            label: l10n.seriesMgmtPrizeLabel,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? null : _nonNegativeInt(v),
          ),
          const SizedBox(height: 12),
          _dropdown(
            label: l10n.seriesMgmtVisibilityLabel,
            value: _visibility,
            items: {
              'PUBLIC': l10n.seriesMgmtVisibilityPublic,
              'PRIVATE': l10n.seriesMgmtVisibilityPrivate,
            },
            onChanged: (v) => setState(() => _visibility = v),
          ),
          if (_isEdit) ...[
            const SizedBox(height: 12),
            _dropdown(
              label: l10n.seriesMgmtStatusLabel,
              value: _status,
              items: {
                'DRAFT': l10n.seriesMgmtStatusDraft,
                'ACTIVE': l10n.seriesMgmtStatusActive,
                'COMPLETED': l10n.seriesMgmtStatusCompleted,
                'CANCELLED': l10n.seriesMgmtStatusCancelled,
              },
              onChanged: (v) => setState(() => _status = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateFields(AppLocalizations l10n) {
    return Column(
      children: [
        _DateFormField(
          key: const ValueKey('series-form-start-date'),
          label: l10n.seriesMgmtStartDateLabel,
          clearTooltip: l10n.seriesMgmtClearDate,
          value: _startDate,
          onChanged: (d) => _startDate = d,
        ),
        const SizedBox(height: 12),
        _DateFormField(
          key: const ValueKey('series-form-end-date'),
          label: l10n.seriesMgmtEndDateLabel,
          clearTooltip: l10n.seriesMgmtClearDate,
          value: _endDate,
          onChanged: (d) => _endDate = d,
          validator: (end) {
            final start = _startDate;
            return end != null && start != null && end.isBefore(start)
                ? l10n.seriesMgmtEndBeforeStart
                : null;
          },
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final e in items.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _rulesSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FormSection(
      title: l10n.seriesMgmtSectionRules,
      child: Column(
        children: [
          AppTextFormField(
            key: const ValueKey('series-form-direct-entry'),
            controller: _directEntry,
            label: l10n.seriesMgmtDirectEntryLabel,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) => _nonNegativeInt(v, min: 1),
          ),
          const SizedBox(height: 12),
          AppTextFormField(
            key: const ValueKey('series-form-wildcard'),
            controller: _wildcard,
            label: l10n.seriesMgmtWildcardLabel,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _nonNegativeInt,
          ),
          Row(
            children: [
              Expanded(child: Text(l10n.seriesMgmtExclusionRuleLabel)),
              Switch(
                value: _exclusionRule,
                onChanged: (v) => setState(() => _exclusionRule = v),
              ),
            ],
          ),
          if (_exclusionRule)
            _dropdown(
              label: l10n.seriesMgmtExclusionScopeLabel,
              value: _exclusionScope,
              items: {
                'CATEGORY': l10n.seriesMgmtScopeCategory,
                'ALL': l10n.seriesMgmtScopeAll,
              },
              onChanged: (v) => setState(() => _exclusionScope = v),
            ),
          const SizedBox(height: 12),
          AppTextFormField(
            controller: _rulesDescription,
            label: l10n.seriesMgmtRulesDescriptionLabel,
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          _pointsEditor(l10n),
        ],
      ),
    );
  }

  Widget _pointsEditor(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.seriesMgmtPointsTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              key: const ValueKey('series-add-rank'),
              onPressed: _addRank,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.seriesMgmtAddRank),
            ),
          ],
        ),
        for (var i = 0; i < _rows.length; i++) _rankRow(l10n, i),
      ],
    );
  }

  void _addRank() {
    final next = _rows.isEmpty
        ? 1
        : _rows
                  .map((r) => int.tryParse(r.rank.text.trim()) ?? 0)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    setState(() => _rows.add(_RankRow(next, 0)));
  }

  void _removeRank(int index) {
    final removed = _rows[index];
    setState(() => _rows.removeAt(index));
    // Controllers are disposed after the frame that stops using them.
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  Widget _rankRow(AppLocalizations l10n, int i) {
    final row = _rows[i];
    return Padding(
      key: ObjectKey(row),
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextFormField(
              key: ValueKey('series-rank-$i'),
              controller: row.rank,
              label: l10n.seriesMgmtRankLabel,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => _rankError(row, v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppTextFormField(
              key: ValueKey('series-points-$i'),
              controller: row.points,
              label: l10n.seriesMgmtPointsLabel,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _nonNegativeInt,
            ),
          ),
          IconButton(
            key: ValueKey('series-remove-rank-$i'),
            tooltip: l10n.seriesMgmtRemoveRank,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _removeRank(i),
          ),
        ],
      ),
    );
  }

  Widget _submitBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('series-form-submit'),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.seriesMgmtSave),
          ),
        ),
      ),
    );
  }
}

/// Ô chọn ngày (có xoá) kèm kiểm tra của form.
class _DateFormField extends StatelessWidget {
  const _DateFormField({
    super.key,
    required this.label,
    required this.clearTooltip,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final String clearTooltip;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final FormFieldValidator<DateTime>? validator;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return FormField<DateTime>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        final date = field.value;
        return InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked == null) return;
            field.didChange(picked);
            onChanged(picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              errorText: field.errorText,
              suffixIcon: date == null
                  ? const Icon(Icons.calendar_today_outlined)
                  : IconButton(
                      tooltip: clearTooltip,
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        field.didChange(null);
                        onChanged(null);
                      },
                    ),
            ),
            child: Text(
              date == null ? '' : DateFormat('dd/MM/yyyy', locale).format(date),
            ),
          ),
        );
      },
    );
  }
}
