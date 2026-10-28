import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Bottom sheet to tick which sheets go into the whole-tournament Excel report.
///
/// [onExport] does the export and opens the share sheet; it throws on
/// failure. The sheet then stays open with the ticks kept so the user can
/// retry, and the export button is locked while a run is in progress.
class TournamentReportSheet extends StatefulWidget {
  const TournamentReportSheet({super.key, required this.onExport});

  final Future<void> Function(Set<TournamentReportSection> sections) onExport;

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(Set<TournamentReportSection> sections)
    onExport,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => TournamentReportSheet(onExport: onExport),
  );

  @override
  State<TournamentReportSheet> createState() => _TournamentReportSheetState();
}

class _TournamentReportSheetState extends State<TournamentReportSheet> {
  final Set<TournamentReportSection> _selected = {
    ...TournamentReportSection.values,
  };
  bool _isExporting = false;
  bool _failed = false;

  void _toggle(TournamentReportSection section, bool? checked) => setState(() {
    if (checked == true) {
      _selected.add(section);
    } else {
      _selected.remove(section);
    }
  });

  Future<void> _export() async {
    if (_isExporting || _selected.isEmpty) return;
    setState(() {
      _isExporting = true;
      _failed = false;
    });
    try {
      await widget.onExport({..._selected});
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // Keep the ticks and show a generic message; never surface details.
      if (mounted) {
        setState(() {
          _isExporting = false;
          _failed = true;
        });
      }
    }
  }

  Widget _tile(String title, String subtitle, TournamentReportSection value) =>
      CheckboxListTile(
        value: _selected.contains(value),
        onChanged: _isExporting ? null : (checked) => _toggle(value, checked),
        title: Text(title),
        subtitle: Text(subtitle),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_isExporting,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.tournamentReportTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.tournamentReportHint,
              style: TextStyle(color: context.colors.textSecondary),
            ),
            const SizedBox(height: 8),
            _tile(
              l10n.tournamentReportSheetParticipants,
              l10n.tournamentReportSheetParticipantsDesc,
              TournamentReportSection.participants,
            ),
            _tile(
              l10n.tournamentReportSheetMatches,
              l10n.tournamentReportSheetMatchesDesc,
              TournamentReportSection.matches,
            ),
            if (_failed) ...[
              const SizedBox(height: 8),
              Text(
                l10n.tournamentReportError,
                style: TextStyle(color: context.colors.error),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isExporting || _selected.isEmpty ? null : _export,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isExporting)
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.download_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _isExporting
                        ? l10n.tournamentReportExporting
                        : l10n.tournamentReportExport(_selected.length),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
