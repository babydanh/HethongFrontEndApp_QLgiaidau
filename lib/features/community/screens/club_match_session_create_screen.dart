import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';
import 'package:app_quanly_giaidau/core/widgets/form_section.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_match_session_create_widgets.dart';
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
                    ClubMatchSessionIntroCard(l10n: l10n),
                    const SizedBox(height: AppTheme.spacingMD),
                    FormSection(
                      title: l10n.clubMatchSessionBasicInfo,
                      child: _buildBasicInfo(l10n),
                    ),
                    FormSection(
                      title: l10n.clubMatchSessionRegistrationMode,
                      child: _buildRegistrationModes(l10n),
                    ),
                    FormSection(
                      title: l10n.clubMatchSessionRanked,
                      child: _buildRankedSection(l10n),
                    ),
                    FormSection(
                      title: l10n.clubMatchSessionSchedule,
                      child: _buildScheduleSection(l10n),
                    ),
                    ClubMatchSessionNoBracketHint(l10n: l10n),
                  ],
                ),
              ),
            ),
            ClubMatchSessionBottomActions(
              l10n: l10n,
              isSubmitting: _isSubmitting,
              onCancel: () => Navigator.of(context).pop(),
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo(AppLocalizations l10n) {
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

  Widget _buildRegistrationModes(AppLocalizations l10n) {
    return Column(
      children: [
        ClubMatchSessionModeCard(
          value: 'MIXED',
          selected: _registrationMode == 'MIXED',
          label: l10n.clubMatchSessionRegistrationMixed,
          icon: Icons.groups_rounded,
          onTap: () => setState(() => _registrationMode = 'MIXED'),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        ClubMatchSessionModeCard(
          value: 'SELF',
          selected: _registrationMode == 'SELF',
          label: l10n.clubMatchSessionRegistrationSelf,
          icon: Icons.person_add_alt_1_rounded,
          onTap: () => setState(() => _registrationMode = 'SELF'),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        ClubMatchSessionModeCard(
          value: 'MANAGER_ASSIGN',
          selected: _registrationMode == 'MANAGER_ASSIGN',
          label: l10n.clubMatchSessionRegistrationManager,
          icon: Icons.admin_panel_settings_rounded,
          onTap: () => setState(() => _registrationMode = 'MANAGER_ASSIGN'),
        ),
      ],
    );
  }

  Widget _buildRankedSection(AppLocalizations l10n) {
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

  Widget _buildScheduleSection(AppLocalizations l10n) {
    return Column(
      children: [
        ClubMatchSessionDateChoice(
          label: l10n.clubMatchSessionStartAt,
          valueLabel: _dateTimeLabel(context, _startAt),
          hasValue: _startAt != null,
          icon: Icons.event_rounded,
          onTap: () => _selectDateTime(isStart: true),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        ClubMatchSessionDateChoice(
          label: l10n.clubMatchSessionEndAt,
          valueLabel: _dateTimeLabel(context, _endAt),
          hasValue: _endAt != null,
          icon: Icons.event_available_rounded,
          onTap: () => _selectDateTime(isStart: false),
        ),
      ],
    );
  }
}
