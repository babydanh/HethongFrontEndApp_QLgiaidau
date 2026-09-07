import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';
import 'package:app_quanly_giaidau/core/widgets/form_section.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClubMatchSessionCreateScreen extends ConsumerStatefulWidget {
  final String communityId;

  const ClubMatchSessionCreateScreen({super.key, required this.communityId});

  @override
  ConsumerState<ClubMatchSessionCreateScreen> createState() =>
      _ClubMatchSessionCreateScreenState();
}

class _ClubMatchSessionCreateScreenState
    extends ConsumerState<ClubMatchSessionCreateScreen> {
  static const _log = AppLogger('ClubMatchSessionCreate');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _registrationMode = 'MIXED';
  bool _isRanked = true;
  DateTime? _startAt;
  DateTime? _endAt;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_startAt != null && _endAt != null && _endAt!.isBefore(_startAt!)) {
      _showError(l10n.clubMatchSessionInvalidDateRange);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(clubMatchSessionsProvider(widget.communityId).notifier)
          .create(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            registrationMode: _registrationMode,
            isRanked: _isRanked,
            startAt: _startAt,
            endAt: _endAt,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      _log.error('Không thể tạo buổi giao lưu CLB', error, stackTrace);
      if (mounted) _showError(ErrorParser.parse(error, '', l10n));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _selectDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final current = isStart ? _startAt : _endAt;
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? now),
    );
    if (time == null || !mounted) return;

    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _startAt = value;
        if (_endAt != null && _endAt!.isBefore(value)) _endAt = null;
      } else {
        _endAt = value;
      }
    });
  }

  String _dateTimeLabel(BuildContext context, DateTime? value) {
    if (value == null) {
      return AppLocalizations.of(context)!.clubMatchSessionOptionalDate;
    }
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(value)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value))}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.bgSurface,
      appBar: AppBar(
        backgroundColor: context.colors.bgSurface,
        elevation: 0,
        leading: IconButton(
          tooltip: l10n.commonCancel,
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(l10n.clubMatchSessionCreateTitle),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMD,
                  AppTheme.spacingSM,
                  AppTheme.spacingMD,
                  AppTheme.spacingLG,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIntroCard(context, l10n),
                    const SizedBox(height: AppTheme.spacingMD),
                    FormSection(
                      title: l10n.clubMatchSessionBasicInfo,
                      child: _buildBasicInfo(context, l10n),
                    ),
                    FormSection(
                      title: l10n.clubMatchSessionRegistrationMode,
                      child: _buildRegistrationModes(context, l10n),
                    ),
                    FormSection(
                      title: l10n.clubMatchSessionRanked,
                      child: _buildRankedSection(context, l10n),
                    ),
                    FormSection(
                      title: l10n.clubMatchSessionSchedule,
                      child: _buildScheduleSection(context, l10n),
                    ),
                    _buildNoBracketHint(context, l10n),
                  ],
                ),
              ),
            ),
            _buildBottomActions(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context, AppLocalizations l10n) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: context.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: onPrimary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(Icons.groups_rounded, color: onPrimary, size: 26),
            ),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.clubMatchSessionCreateTitle,
                    style: TextStyle(
                      color: onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    l10n.clubMatchSessionNoBracketHint,
                    style: TextStyle(
                      color: onPrimary.withValues(alpha: 0.88),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        AppTextFormField(
          controller: _nameController,
          label: l10n.clubMatchSessionName,
          hint: l10n.clubMatchSessionNameHint,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: AppTheme.spacingSM),
        AppTextFormField(
          controller: _descriptionController,
          label: l10n.clubMatchSessionDescription,
          hint: l10n.clubMatchSessionDescription,
          maxLines: 4,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildRegistrationModes(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        _buildModeCard(
          context,
          value: 'MIXED',
          label: l10n.clubMatchSessionRegistrationMixed,
          icon: Icons.groups_rounded,
        ),
        const SizedBox(height: AppTheme.spacingSM),
        _buildModeCard(
          context,
          value: 'SELF',
          label: l10n.clubMatchSessionRegistrationSelf,
          icon: Icons.person_add_alt_1_rounded,
        ),
        const SizedBox(height: AppTheme.spacingSM),
        _buildModeCard(
          context,
          value: 'MANAGER_ASSIGN',
          label: l10n.clubMatchSessionRegistrationManager,
          icon: Icons.admin_panel_settings_rounded,
        ),
      ],
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    final selected = value == _registrationMode;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: () => setState(() => _registrationMode = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppTheme.spacingSM),
          decoration: BoxDecoration(
            color: selected
                ? context.colors.info.withValues(alpha: 0.10)
                : context.colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: selected ? context.colors.info : context.colors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? context.colors.info
                      : context.colors.bgSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimary
                      : context.colors.textSecondary,
                  size: 21,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? context.colors.info
                    : context.colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankedSection(BuildContext context, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.insights_rounded, color: context.colors.info),
        const SizedBox(width: AppTheme.spacingSM),
        Expanded(
          child: Text(
            l10n.clubMatchSessionRanked,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch.adaptive(
          value: _isRanked,
          onChanged: (value) => setState(() => _isRanked = value),
        ),
      ],
    );
  }

  Widget _buildScheduleSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        _buildDateChoice(
          context,
          label: l10n.clubMatchSessionStartAt,
          value: _startAt,
          icon: Icons.event_rounded,
          onTap: () => _selectDateTime(isStart: true),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        _buildDateChoice(
          context,
          label: l10n.clubMatchSessionEndAt,
          value: _endAt,
          icon: Icons.event_available_rounded,
          onTap: () => _selectDateTime(isStart: false),
        ),
      ],
    );
  }

  Widget _buildDateChoice(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMD,
            vertical: AppTheme.spacingSM,
          ),
          decoration: BoxDecoration(
            color: context.colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: context.colors.info),
              const SizedBox(width: AppTheme.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dateTimeLabel(context, value),
                      style: TextStyle(
                        color: hasValue
                            ? context.colors.info
                            : context.colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoBracketHint(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: context.colors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: context.colors.info.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: context.colors.info),
          const SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: Text(
              l10n.clubMatchSessionNoBracketHint,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingMD,
          AppTheme.spacingSM,
          AppTheme.spacingMD,
          AppTheme.spacingSM,
        ),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          border: Border(top: BorderSide(color: context.colors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSM),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(l10n.clubMatchSessionCreate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
