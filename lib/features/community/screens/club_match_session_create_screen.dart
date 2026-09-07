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
  bool _isRecurring = false;
  String _recurringFrequency = 'WEEKLY';
  int _recurringDayOfWeek = 6;
  TimeOfDay _recurringTime = const TimeOfDay(hour: 18, minute: 0);
  int _recurringAdvanceDays = 3;
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
            isRecurring: _isRecurring,
            recurringFrequency: _recurringFrequency,
            recurringDayOfWeek: _recurringDayOfWeek,
            recurringDaysOfWeek: [_recurringDayOfWeek],
            recurringTimeOfDay:
                '${_recurringTime.hour.toString().padLeft(2, '0')}:${_recurringTime.minute.toString().padLeft(2, '0')}',
            recurringAdvanceDays: _recurringAdvanceDays,
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = _startAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;

    final existingTime = _startAt != null
        ? TimeOfDay.fromDateTime(_startAt!)
        : const TimeOfDay(hour: 8, minute: 0);

    setState(() {
      _startAt = DateTime(
        date.year,
        date.month,
        date.day,
        existingTime.hour,
        existingTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final current = _startAt ?? now;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;

    final baseDate = _startAt ?? now;
    setState(() {
      _startAt = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        time.hour,
        time.minute,
      );
    });
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
                    _buildRankedCard(l10n),
                    const SizedBox(height: 20),
                    FormSection(
                      title: '${l10n.lite_scheduleCardTitle} (${l10n.clubMatchSessionStartAt})',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildScheduleSection(l10n),
                          const SizedBox(height: AppTheme.spacingMD),
                          Text(
                            l10n.clubMatchSessionDuration,
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSM),
                          _buildDurationSection(l10n),
                        ],
                      ),
                    ),
                    FormSection(
                      title: l10n.clubMatchSessionMaxParticipants,
                      child: _buildParticipantsSection(l10n),
                    ),
                    FormSection(
                      title: l10n.clubMatchSessionRecurringTitle,
                      child: _buildRecurringSection(l10n),
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

  Widget _buildRankedCard(AppLocalizations l10n) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: _isRanked ? colors.info.withValues(alpha: 0.35) : colors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _isRanked
                  ? colors.info.withValues(alpha: 0.12)
                  : colors.bgSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.military_tech_rounded,
              size: 22,
              color: _isRanked ? colors.info : colors.textMuted,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xếp hạng',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isRanked
                      ? 'Áp dụng cộng/trừ ELO cho các trận hợp lệ'
                      : 'Trận giao lưu tự do, không tính điểm ELO',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isRanked,
            activeTrackColor: colors.info,
            onChanged: (value) => setState(() => _isRanked = value),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(AppLocalizations l10n) {
    return ClubMatchSessionDateTimePicker(
      selectedDate: _startAt,
      selectedTime: _startAt != null ? TimeOfDay.fromDateTime(_startAt!) : null,
      onPickDate: _pickDate,
      onPickTime: _pickTime,
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
              label: l10n.clubMatchSessionDurationTwoHours,
              value: 120,
            ),
            ClubMatchSessionChoice(
              label: l10n.clubMatchSessionDurationThreeHours,
              value: 180,
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
              if (value != null) {
                _durationMinutes = value;
                _customDurationController.clear();
              }
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

  Widget _buildRecurringSection(AppLocalizations l10n) {
    final colors = context.colors;
    final weekly =
        _recurringFrequency == 'WEEKLY' || _recurringFrequency == 'BIWEEKLY';

    InputDecoration inputDecoration(String labelText) {
      return InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          fontSize: 13,
          color: colors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: colors.bgSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.info, width: 1.5),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _isRecurring,
          activeTrackColor: colors.info,
          title: Text(
            l10n.clubMatchSessionRecurringEnabled,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            l10n.clubMatchSessionRecurringHint,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          onChanged: (value) => setState(() => _isRecurring = value),
        ),
        if (_isRecurring) ...[
          const SizedBox(height: AppTheme.spacingMD),
          DropdownButtonFormField<String>(
            initialValue: _recurringFrequency,
            decoration: inputDecoration(l10n.clubMatchSessionRecurringFrequency),
            dropdownColor: colors.bgCard,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.textMuted),
            items: [
              DropdownMenuItem(
                value: 'DAILY',
                child: Text(l10n.clubMatchSessionRecurringDaily, style: TextStyle(color: colors.textPrimary, fontSize: 13.5)),
              ),
              DropdownMenuItem(
                value: 'WEEKLY',
                child: Text(l10n.clubMatchSessionRecurringWeekly, style: TextStyle(color: colors.textPrimary, fontSize: 13.5)),
              ),
              DropdownMenuItem(
                value: 'BIWEEKLY',
                child: Text(l10n.clubMatchSessionRecurringBiweekly, style: TextStyle(color: colors.textPrimary, fontSize: 13.5)),
              ),
              DropdownMenuItem(
                value: 'MONTHLY',
                child: Text(l10n.clubMatchSessionRecurringMonthly, style: TextStyle(color: colors.textPrimary, fontSize: 13.5)),
              ),
            ],
            onChanged: (value) => setState(
              () => _recurringFrequency = value ?? _recurringFrequency,
            ),
          ),
          if (weekly) ...[
            const SizedBox(height: AppTheme.spacingMD),
            DropdownButtonFormField<int>(
              initialValue: _recurringDayOfWeek,
              decoration: inputDecoration(l10n.clubMatchSessionRecurringWeekday),
              dropdownColor: colors.bgCard,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.textMuted),
              items: [
                DropdownMenuItem(
                  value: 1,
                  child: Text(l10n.clubMatchSessionWeekdayMonday, style: TextStyle(color: colors.textPrimary, fontSize: 13.5)),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text(l10n.clubMatchSessionWeekdayTuesday, style: TextStyle(color: colors.textPrimary, fontSize: 13.5)),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text(l10n.clubMatchSessionWeekdayWednesday, style: TextStyle(color: colors.textPrimary, fontSize: 13.5)),
                ),
                DropdownMenuItem(
                  value: 4,
                  child: Text(l10n.clubMatchSessionWeekdayThursday, style: TextStyle(color: colors.textPrimary, fontSize: 13.5)),
                ),
                DropdownMenuItem(
                  value: 5,
                  child: Text(l10n.clubMatchSessionWeekdayFriday, style: TextStyle(color: colors.textPrimary, fontSize: 13.5)),
                ),
                DropdownMenuItem(
                  value: 6,
                  child: Text(l10n.clubMatchSessionWeekdaySaturday, style: TextStyle(color: colors.textPrimary, fontSize: 13.5)),
                ),
                DropdownMenuItem(
                  value: 0,
                  child: Text(l10n.clubMatchSessionWeekdaySunday, style: TextStyle(color: colors.textPrimary, fontSize: 13.5)),
                ),
              ],
              onChanged: (value) => setState(
                () => _recurringDayOfWeek = value ?? _recurringDayOfWeek,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingMD),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final value = await showTimePicker(
                context: context,
                initialTime: _recurringTime,
              );
              if (value != null && mounted) {
                setState(() => _recurringTime = value);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 18, color: colors.info),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.clubMatchSessionRecurringTime,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _recurringTime.format(context),
                          style: TextStyle(
                            fontSize: 13.5,
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 20, color: colors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          DropdownButtonFormField<int>(
            initialValue: _recurringAdvanceDays,
            decoration: inputDecoration(l10n.clubMatchSessionRecurringAdvanceDays),
            dropdownColor: colors.bgCard,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: colors.textMuted),
            items: List.generate(
              8,
              (days) => DropdownMenuItem(
                value: days,
                child: Text(
                  days == 0
                      ? l10n.clubMatchSessionRecurringSameDay
                      : l10n.clubMatchSessionRecurringBeforeDays(days),
                  style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
                ),
              ),
            ),
            onChanged: (value) => setState(
              () => _recurringAdvanceDays = value ?? _recurringAdvanceDays,
            ),
          ),
        ],
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
