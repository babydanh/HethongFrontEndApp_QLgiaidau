import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/extensions/animation_extensions.dart';
import 'package:app_quanly_giaidau/core/widgets/form_section.dart';

class TournamentInfoForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descController;
  final FocusNode nameFocusNode;

  const TournamentInfoForm({
    super.key,
    required this.nameController,
    required this.descController,
    required this.nameFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        FormSection(
          title: l10n.tournamentInfoNameLabel,
          child: TextFormField(
            controller: nameController,
            focusNode: nameFocusNode,
            style: TextStyle(color: context.colors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.tournamentInfoNameHint,
              prefixIcon: Icon(Icons.edit, color: AppTheme.primaryLight),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.tournamentInfoNameRequired;
              }
              return null;
            },
          ),
        ).slideInFromBottom(delay: 0.ms),

        FormSection(
          title: l10n.tournamentInfoDescriptionLabel,
          child: TextFormField(
            controller: descController,
            style: TextStyle(color: context.colors.textPrimary),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.tournamentInfoDescriptionHint,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Icon(Icons.notes, color: context.colors.textSecondary),
              ),
            ),
          ),
        ).slideInFromBottom(delay: 300.ms),
      ],
    );
  }
}
