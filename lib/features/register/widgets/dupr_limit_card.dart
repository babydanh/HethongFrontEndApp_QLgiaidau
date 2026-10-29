import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/dupr_limit.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_registration.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Phase { checking, ready, error }

/// Shows the division's DUPR limit against the user's own rating and lets the
/// user declare a rating when none is on file. Reports whether registering is
/// allowed through [onValidityChanged]; the backend stays the source of truth.
///
/// Renders nothing (and never calls the repository) when the division has no
/// limit, or when its category / match type is unknown so the rating cannot
/// be looked up.
class DuprLimitCard extends ConsumerStatefulWidget {
  const DuprLimitCard({
    super.key,
    required this.division,
    required this.onValidityChanged,
  });

  final TournamentDivisionOption division;
  final ValueChanged<bool> onValidityChanged;

  @override
  ConsumerState<DuprLimitCard> createState() => _DuprLimitCardState();
}

class _DuprLimitCardState extends ConsumerState<DuprLimitCard> {
  final _input = TextEditingController();
  _Phase _phase = _Phase.checking;
  double? _rating;
  bool _saving = false;
  bool _saveFailed = false;
  bool? _reportedValid;

  TournamentDivisionOption get _division => widget.division;
  bool get _hasLimit => _division.minDupr != null || _division.maxDupr != null;
  bool get _canLookUp =>
      _division.categoryId != null && _division.ratingMatchType != null;

  DuprLimitStatus get _status => checkDuprAgainstLimit(
    value: _rating,
    minDupr: _division.minDupr,
    maxDupr: _division.maxDupr,
  );

  @override
  void initState() {
    super.initState();
    if (_hasLimit && _canLookUp) {
      _load();
    } else {
      _report(true);
    }
  }

  @override
  void didUpdateWidget(DuprLimitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        oldWidget.division.id != _division.id ||
        oldWidget.division.minDupr != _division.minDupr ||
        oldWidget.division.maxDupr != _division.maxDupr;
    if (!changed) return;
    _reportedValid = null;
    if (_hasLimit && _canLookUp) {
      _load();
    } else {
      _report(true);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  /// Reports after the frame so the parent is never rebuilt mid-build.
  void _report(bool valid) {
    if (_reportedValid == valid) return;
    _reportedValid = valid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onValidityChanged(valid);
    });
  }

  Future<void> _load() async {
    setState(() => _phase = _Phase.checking);
    _report(false);
    final divisionId = _division.id;
    try {
      final rating = await ref
          .read(externalRatingRepositoryProvider)
          .getMyDuprRating(
            categoryId: _division.categoryId!,
            matchType: _division.ratingMatchType!,
          );
      if (!mounted || divisionId != _division.id) return;
      setState(() {
        _rating = rating;
        _phase = _Phase.ready;
      });
      _report(_status == DuprLimitStatus.ok);
    } catch (_) {
      if (!mounted || divisionId != _division.id) return;
      setState(() => _phase = _Phase.error);
      _report(false);
    }
  }

  double? get _typedValue =>
      double.tryParse(_input.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final value = _typedValue;
    if (_saving || value == null || value <= 0) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await ref
          .read(externalRatingRepositoryProvider)
          .saveMyDuprRating(
            categoryId: _division.categoryId!,
            matchType: _division.ratingMatchType!,
            value: value,
          );
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveFailed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.registerDuprSaved)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLimit || !_canLookUp) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final range =
        formatDuprRange(_division.minDupr, _division.maxDupr) ?? '';
    final (message, tone, icon) = switch (_phase) {
      _Phase.checking => (
        l10n.registerDuprChecking,
        colors.textSecondary,
        Icons.hourglass_top_rounded,
      ),
      _Phase.error => (
        l10n.registerDuprCheckError,
        colors.error,
        Icons.error_outline_rounded,
      ),
      _Phase.ready => switch (_status) {
        DuprLimitStatus.ok => (
          l10n.registerDuprMatches,
          colors.success,
          Icons.check_circle_outline_rounded,
        ),
        DuprLimitStatus.belowMin => (
          l10n.registerDuprBelowMin('$_rating', range),
          colors.error,
          Icons.trending_down_rounded,
        ),
        DuprLimitStatus.aboveMax => (
          l10n.registerDuprAboveMax('$_rating', range),
          colors.error,
          Icons.trending_up_rounded,
        ),
        DuprLimitStatus.missing => (
          l10n.registerDuprMissing,
          colors.warning,
          Icons.edit_note_rounded,
        ),
      },
    };
    final needsInput =
        _phase == _Phase.ready && _status == DuprLimitStatus.missing;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tone.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: tone),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tone,
                    ),
                  ),
                ),
              ],
            ),
            if (needsInput) ..._inputRows(l10n, colors),
            if (_phase == _Phase.error)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const ValueKey('dupr-card-retry'),
                  onPressed: _load,
                  child: Text(l10n.registerDuprRetry),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _inputRows(AppLocalizations l10n, AppColorsExtension colors) {
    final canSave = !_saving && (_typedValue ?? 0) > 0;
    return [
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('dupr-limit-input'),
              controller: _input,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                LengthLimitingTextInputFormatter(5),
              ],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.registerDuprInputLabel,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            key: const ValueKey('dupr-limit-save'),
            onPressed: canSave ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.registerDuprSave),
          ),
        ],
      ),
      if (_saveFailed)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            l10n.registerDuprSaveFailed,
            style: TextStyle(fontSize: 12, color: colors.error),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          l10n.registerDuprSelfDeclaredNote,
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
      ),
    ];
  }
}
