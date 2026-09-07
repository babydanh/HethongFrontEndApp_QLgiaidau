import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';
import 'package:app_quanly_giaidau/core/widgets/form_section.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_match_session_create_widgets.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/club_match_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  bool _isRanked = true;
  DateTime? _startAt;
  int _durationMinutes = 60;
  int _maxParticipants = 16;
  bool _isCustomDuration = false;
  bool _isCustomParticipants = false;
  final _customDurationController = TextEditingController();
  final _customParticipantsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customDurationController.dispose();
    _customParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(clubMatchSessionsProvider(widget.communityId).notifier)
          .create(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            registrationMode: 'MIXED',
            isRanked: _isRanked,
            startAt: _startAt,
            endAt: _startAt?.add(Duration(minutes: _durationMinutes)),
            maxParticipants: _maxParticipants,
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

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final current = _startAt;
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
      _startAt = value;
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
                      title: l10n.clubMatchSessionRanked,
                      child: _buildRankedSection(l10n),
                    ),
                    FormSection(
                      title: l10n.clubMatchSessionSchedule,
                      child: _buildScheduleSection(l10n),
                    ),
                    FormSection(
                      title: l10n.clubMatchSessionDuration,
                      child: _buildDurationSection(l10n),
                    ),
                    FormSection(
                      title: l10n.clubMatchSessionMaxParticipants,
                      child: _buildParticipantsSection(l10n),
                    ),
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
    return ClubMatchSessionDateChoice(
      label: l10n.clubMatchSessionStartAt,
      valueLabel: _dateTimeLabel(context, _startAt),
      hasValue: _startAt != null,
      icon: Icons.event_rounded,
      onTap: _selectDateTime,
    );
  }

  Widget _buildDurationSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClubMatchSessionChoiceRow(
          options: [
            ClubMatchSessionChoice(
              label: l10n.clubMatchSessionDurationOneHour,
              value: 60,
            ),
            ClubMatchSessionChoice(
              label: l10n.clubMatchSessionDurationNinetyMinutes,
              value: 90,
            ),
            ClubMatchSessionChoice(
              label: l10n.clubMatchSessionDurationCustom,
              value: null,
            ),
          ],
          selectedValue: _isCustomDuration ? null : _durationMinutes,
          onSelected: (value) {
            setState(() {
              _isCustomDuration = value == null;
              _durationMinutes = value ?? _durationMinutes;
              if (value != null) _customDurationController.clear();
            });
          },
        ),
        if (_isCustomDuration)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingSM),
            child: AppTextFormField(
              controller: _customDurationController,
              label: l10n.clubMatchSessionDurationCustomLabel,
              hint: l10n.clubMatchSessionDurationCustomHint,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) => _validatePositiveNumber(
                value,
                l10n.clubMatchSessionDurationInvalid,
                minimum: 30,
                maximum: 720,
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value);
                if (parsed != null) _durationMinutes = parsed;
                setState(() {});
              },
            ),
          ),
      ],
    );
  }

  Widget _buildParticipantsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClubMatchSessionChoiceRow(
          options: [
            ClubMatchSessionChoice(label: '8', value: 8),
            ClubMatchSessionChoice(label: '16', value: 16),
            ClubMatchSessionChoice(label: '32', value: 32),
            ClubMatchSessionChoice(label: '64', value: 64),
            ClubMatchSessionChoice(
              label: l10n.clubMatchSessionMaxParticipantsCustom,
              value: null,
            ),
          ],
          selectedValue: _isCustomParticipants ? null : _maxParticipants,
          onSelected: (value) {
            setState(() {
              _isCustomParticipants = value == null;
              _maxParticipants = value ?? _maxParticipants;
              if (value != null) _customParticipantsController.clear();
            });
          },
        ),
        if (_isCustomParticipants)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingSM),
            child: AppTextFormField(
              controller: _customParticipantsController,
              label: l10n.clubMatchSessionMaxParticipantsCustomLabel,
              hint: l10n.clubMatchSessionMaxParticipantsCustomHint,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) => _validatePositiveNumber(
                value,
                l10n.clubMatchSessionMaxParticipantsInvalid,
                minimum: 2,
                maximum: 128,
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value);
                if (parsed != null) _maxParticipants = parsed;
                setState(() {});
              },
            ),
          ),
      ],
    );
  }

  String? _validatePositiveNumber(
    String? value,
    String error, {
    required int minimum,
    required int maximum,
  }) {
    final parsed = int.tryParse(value ?? '');
    return parsed == null || parsed < minimum || parsed > maximum
        ? error
        : null;
  }
}
