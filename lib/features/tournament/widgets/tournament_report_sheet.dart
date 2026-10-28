import 'package:app_quanly_giaidau/core/services/excel_export_service.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
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

  Widget _tile(String title, String subtitle, TournamentReportSection value) {
    final checked = _selected.contains(value);
    return LavishRow(
      leading: _CheckCircle(checked: checked),
      title: title,
      subtitle: subtitle,
      onTap: _isExporting ? null : () => _toggle(value, !checked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = LavishColors.of(context);
    return PopScope(
      canPop: !_isExporting,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.tournamentReportTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.text,
                ),
              ),
            ),
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
            if (_failed)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Text(
                  l10n.tournamentReportError,
                  style: const TextStyle(fontSize: 13, color: LavishColors.bad),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: LavishButton(
                busy: _isExporting,
                onPressed: _isExporting || _selected.isEmpty ? null : _export,
                label: _isExporting
                    ? l10n.tournamentReportExporting
                    : l10n.tournamentReportExport(_selected.length),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Text(
                l10n.tournamentReportFooter,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Design 21 tick: 26px green disc with a white check, or an empty ring.
class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) => Container(
    width: 26,
    height: 26,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: checked ? LavishColors.ok : Colors.transparent,
      border: Border.all(
        color: checked ? LavishColors.ok : LavishColors.of(context).chipLine,
        width: 1.5,
      ),
    ),
    child: checked
        ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
        : null,
  );
}
