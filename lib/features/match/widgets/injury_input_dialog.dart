import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class InjuryInputDialog extends StatefulWidget {
  final String team1Name;
  final String team2Name;
  final Function(String teamName, String description) onSubmit;

  const InjuryInputDialog({
    super.key,
    required this.team1Name,
    required this.team2Name,
    required this.onSubmit,
  });

  @override
  State<InjuryInputDialog> createState() => _InjuryInputDialogState();
}

class _InjuryInputDialogState extends State<InjuryInputDialog> {
  String? _selectedTeam;
  final _descController = TextEditingController();

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canSubmit =
        _selectedTeam != null && _descController.text.trim().isNotEmpty;

    return AlertDialog(
      backgroundColor: context.colors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXL)),
      title: Row(
        children: [
          Icon(Icons.local_hospital_rounded, color: context.colors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.injuryDialogTitle,
              style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.injuryDialogTeamPrompt,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildTeamChoice(widget.team1Name)),
                const SizedBox(width: 8),
                Expanded(child: _buildTeamChoice(widget.team2Name)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.injuryDialogDescriptionLabel,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              style: TextStyle(color: context.colors.textPrimary),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l10n.injuryDialogDescriptionHint,
                filled: true,
                fillColor: context.colors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.commonCancel,
            style: TextStyle(color: context.colors.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: canSubmit
              ? () {
                  widget.onSubmit(_selectedTeam!, _descController.text.trim());
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.warning,
            foregroundColor: Colors.black,
          ),
          child: Text(l10n.injuryDialogConfirm),
        ),
      ],
    );
  }

  Widget _buildTeamChoice(String teamName) {
    final isSelected = _selectedTeam == teamName;
    return GestureDetector(
      onTap: () => setState(() => _selectedTeam = teamName),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.warning.withValues(alpha: 0.2)
              : context.colors.bgSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? context.colors.warning : context.colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          teamName,
          style: TextStyle(
            color: isSelected
                ? context.colors.warning
                : context.colors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
