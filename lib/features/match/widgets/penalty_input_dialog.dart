import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/widgets/app_info_dialog.dart';
import 'package:app_quanly_giaidau/core/strategy/penalty_strategy.dart';

class PenaltyInputDialog extends StatefulWidget {
  final String sportType;
  final String team1Name;
  final String team2Name;
  final Function(String teamName, PenaltyOption option, String reason) onSubmit;

  const PenaltyInputDialog({
    super.key,
    required this.sportType,
    required this.team1Name,
    required this.team2Name,
    required this.onSubmit,
  });

  @override
  State<PenaltyInputDialog> createState() => _PenaltyInputDialogState();
}

class _PenaltyInputDialogState extends State<PenaltyInputDialog> {
  late IPenaltyStrategy _strategy;
  late List<PenaltyOption> _options;
  
  PenaltyOption? _selectedOption;
  String? _selectedTeam;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _strategy = PenaltyStrategyFactory.getStrategy(widget.sportType);
    _options = _strategy.getOptions();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _showRulesDialog() {
    AppInfoDialog.show(
      context,
      title: AppConstants.textPenaltyRules,
      content: _strategy.getRulesDescription(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _selectedOption != null && _selectedTeam != null && _reasonController.text.trim().isNotEmpty;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return AlertDialog(
      backgroundColor: context.colors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 24.0 : 40.0,
        vertical: isLandscape ? 8.0 : 24.0,
      ),
      titlePadding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 8),
      contentPadding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 8),
      actionsPadding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 16),
      title: Row(
        children: [
          Icon(Icons.style, color: context.colors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(AppConstants.textRecordPenalty, style: TextStyle(color: context.colors.textPrimary, fontSize: 16))),
          IconButton(
            icon: Icon(Icons.info_outline, color: context.colors.textMuted, size: 20),
            onPressed: _showRulesDialog,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppConstants.textOffendingTeam, style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTeamChoice(widget.team1Name),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTeamChoice(widget.team2Name),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(AppConstants.textPenaltyType, style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _options.map((opt) => _buildOptionChip(opt)).toList(),
              ),
              const SizedBox(height: 16),
              Text(AppConstants.textReasonRequired, style: TextStyle(color: context.colors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                style: TextStyle(color: context.colors.textPrimary),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Nhập lý do vi phạm...',
                  filled: true,
                  fillColor: context.colors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppConstants.textCancel, style: TextStyle(color: context.colors.textMuted)),
        ),
        ElevatedButton(
          onPressed: canSubmit ? () {
            widget.onSubmit(_selectedTeam!, _selectedOption!, _reasonController.text.trim());
            Navigator.pop(context);
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedOption?.color ?? context.colors.error,
          ),
          child: const Text(AppConstants.textConfirm),
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
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.2) : context.colors.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : context.colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          teamName,
          style: TextStyle(
            color: isSelected ? AppTheme.primary : context.colors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildOptionChip(PenaltyOption option) {
    final isSelected = _selectedOption?.id == option.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? option.color.withValues(alpha: 0.15) : context.colors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? option.color : context.colors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(option.icon, color: option.color, size: 16),
            const SizedBox(width: 6),
            Text(
              option.name,
              style: TextStyle(
                color: isSelected ? option.color : context.colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
