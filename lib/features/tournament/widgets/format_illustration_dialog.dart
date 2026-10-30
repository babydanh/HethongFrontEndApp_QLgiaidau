import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/format_illustration_stage.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Explanation of a bracket format: a looping animation (a compact take on
/// the Web `FormatIllustration` player) plus the Web description text.
/// [formatName] is the localized format label shown in the title.
Future<void> showFormatIllustrationDialog(
  BuildContext context, {
  required String bracketType,
  required String formatName,
}) => showDialog<void>(
  context: context,
  builder: (_) => _FormatIllustrationDialog(
    bracketType: bracketType,
    formatName: formatName,
  ),
);

class _FormatIllustrationDialog extends StatelessWidget {
  const _FormatIllustrationDialog({
    required this.bracketType,
    required this.formatName,
  });

  final String bracketType;
  final String formatName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final (description, summary) = switch (bracketType.toUpperCase()) {
      'ROUND_ROBIN' => (
        l10n.formatIllustrationRoundRobinDescription,
        l10n.formatIllustrationRoundRobinSummary,
      ),
      'DOUBLE_ELIMINATION' => (
        l10n.formatIllustrationDoubleEliminationDescription,
        l10n.formatIllustrationDoubleEliminationSummary,
      ),
      'GROUP_STAGE_KNOCKOUT' => (
        l10n.formatIllustrationGroupStageDescription,
        l10n.formatIllustrationGroupStageSummary,
      ),
      'SWISS' => (
        l10n.formatIllustrationSwissDescription,
        l10n.formatIllustrationSwissSummary,
      ),
      _ => (
        l10n.formatIllustrationSingleEliminationDescription,
        l10n.formatIllustrationSingleEliminationSummary,
      ),
    };
    return AlertDialog(
      key: const ValueKey('format-illustration-dialog'),
      title: Text(l10n.formatIllustrationTitle(formatName)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormatIllustrationStage(bracketType: bracketType),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(summary, style: TextStyle(color: colors.textSecondary)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
