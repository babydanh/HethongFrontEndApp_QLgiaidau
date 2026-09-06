import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/entities/lite_tournament_create_result.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Tạo giải đấu Lite trong câu lạc bộ
/// Gọi POST /tournaments/lite — đơn giản, không cần categoryId UUID
class CreateClubTournamentScreen extends ConsumerStatefulWidget {
  final String clubId;
  const CreateClubTournamentScreen({super.key, required this.clubId});

  @override
  ConsumerState<CreateClubTournamentScreen> createState() => _CreateClubTournamentScreenState();
}

class _CreateClubTournamentScreenState extends ConsumerState<CreateClubTournamentScreen> {
  static const _log = AppLogger('CreateClubTournament');
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxTeamsCtrl = TextEditingController(text: '16');

  String _selectedSport = AppConstants.sportBadminton;
  String _selectedFormat = AppConstants.formatDoubles;
  String _selectedBracket = AppConstants.bracketSingleElimination;
  DateTime? _startDate;
  int _durationHours = 1;
  int _durationMinutes = 30;
  bool _isRecurring = false;
  String _recurringFrequency = 'WEEKLY';
  int _recurringDayOfWeek = 6;
  TimeOfDay _recurringTime = const TimeOfDay(hour: 18, minute: 0);
  int _recurringAdvanceDays = 3;
  bool _isLoading = false;
  bool _isRanked = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _maxTeamsCtrl.dispose();
    super.dispose();
  }

  bool _hasUserEditedName = false;

  /// Map App sport slug → backend slug
  String _mapSportSlug() {
    switch (_selectedSport) {
      case AppConstants.sportBadminton: return 'badminton';
      case AppConstants.sportTennis: return 'tennis';
      case AppConstants.sportPickleball: return 'pickleball';
      case AppConstants.sportTableTennis: return 'table_tennis';
      case AppConstants.sportFootball: return 'football';
      default: return 'badminton';
    }
  }

  String? _mapClubSport(String value) {
    final slug = value.toLowerCase().trim();
    if (slug.contains('cầu lông') || slug.contains('cau long') || slug.contains('badminton')) return AppConstants.sportBadminton;
    if (slug.contains('tennis') || slug.contains('quần vợt') || slug.contains('quan vot')) return AppConstants.sportTennis;
    if (slug.contains('pickleball')) return AppConstants.sportPickleball;
    if (slug.contains('bóng bàn') || slug.contains('bong ban') || slug.contains('table')) return AppConstants.sportTableTennis;
    if (slug.contains('bóng đá') || slug.contains('bong da') || slug.contains('football')) return AppConstants.sportFootball;
    return null;
  }

  String _getWeekdayName(int dayOfWeek, AppLocalizations l10n) {
    switch (dayOfWeek) {
      case 1: return l10n.createClubTournament_monday;
      case 2: return l10n.createClubTournament_tuesday;
      case 3: return l10n.createClubTournament_wednesday;
      case 4: return l10n.createClubTournament_thursday;
      case 5: return l10n.createClubTournament_friday;
      case 6: return l10n.createClubTournament_saturday;
      case 0: return l10n.createClubTournament_sunday;
      default: return l10n.createClubTournament_saturday;
    }
  }

  String _getSportDisplayName(String sport, AppLocalizations l10n) {
    switch (sport) {
      case AppConstants.sportBadminton: return l10n.createClubTournament_sportBadminton;
      case AppConstants.sportTennis: return l10n.createClubTournament_sportTennis;
      case AppConstants.sportPickleball: return l10n.createClubTournament_sportPickleball;
      case AppConstants.sportTableTennis: return l10n.createClubTournament_sportTableTennis;
      case AppConstants.sportFootball: return l10n.createClubTournament_sportFootball;
      default: return l10n.createClubTournament_sportBadminton;
    }
  }

  void _applyAutoNameIfUntouched(String? clubName, String sport, AppLocalizations l10n) {
    if (_hasUserEditedName && _nameCtrl.text.trim().isNotEmpty) return;
    final cleanClub = (clubName ?? '').trim();
    final sportName = _getSportDisplayName(sport, l10n);
    final weekdayStr = _getWeekdayName(_recurringDayOfWeek, l10n);
    if (cleanClub.isNotEmpty) {
      if (_isRecurring) {
        _nameCtrl.text = 'Giải $sportName $cleanClub - $weekdayStr';
      } else {
        _nameCtrl.text = 'Giải $sportName $cleanClub';
      }
    } else {
      _nameCtrl.text = 'Giải $sportName Mini';
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final club = widget.clubId.isEmpty ? null : ref.read(communityDetailProvider(widget.clubId)).value;
      final clubSport = club?.sports.isNotEmpty == true ? _mapClubSport(club!.sports.first) : null;
      final resolvedSport = clubSport ?? _mapSportSlug();
      final recurringTimeString = _formatTime(_recurringTime);

      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'communityId': widget.clubId,
        'sport': resolvedSport,
        'format': _selectedSport == AppConstants.sportFootball
            ? AppConstants.formatDoubles
            : (_selectedFormat == AppConstants.formatMixedDoubles
                ? AppConstants.formatDoubles
                : _selectedFormat),
        'bracketType': _selectedBracket,
        'maxTeams': int.tryParse(_maxTeamsCtrl.text) ?? 16,
        'description': _descCtrl.text.trim(),
        'isRanked': _isRanked,
        'durationMinutes': (_durationHours * 60) + _durationMinutes,
        'durationHours': ((_durationHours * 60) + _durationMinutes) / 60.0,
        if (_startDate != null) ...{
          'startDate': _startDate!.toUtc().toIso8601String(),
          'startTime':
              '${_startDate!.hour.toString().padLeft(2, '0')}:${_startDate!.minute.toString().padLeft(2, '0')}',
          'endDate': _startDate!
              .add(Duration(minutes: (_durationHours * 60) + _durationMinutes))
              .toUtc()
              .toIso8601String(),
        } else if (_isRecurring) ...{
          // Khi tạo định kỳ không chọn ngày cụ thể, luôn gửi startTime bằng giờ recurring đã chọn
          'startTime': recurringTimeString,
        },
        if (_isRecurring) ...{
          'isRecurring': true,
          'recurringFrequency': _recurringFrequency,
          'recurringDayOfWeek': _recurringDayOfWeek,
          'recurringDaysOfWeek': [_recurringDayOfWeek],
          'recurringTimeOfDay': recurringTimeString,
          'recurringAdvanceDays': _recurringAdvanceDays,
        },
      };

      _log.info('Tạo giải Lite trong CLB: ${body['name']}');
      final response = await dio.post('/tournaments/lite', data: body);

      if (mounted) {
        final raw = response.data;
        final dataJson = raw is Map<String, dynamic>
            ? (raw['data'] as Map<String, dynamic>? ?? raw)
            : <String, dynamic>{};
        final result = LiteTournamentCreateResult.fromJson(dataJson);

        ref.invalidate(communityTournamentsProvider(widget.clubId));
        ref.invalidate(communityDetailProvider(widget.clubId));

        _showSuccessSheet(result);
      }
    } catch (e, stack) {
      _log.error('Lỗi tạo giải đấu trong CLB', e, stack);
      if (mounted) {
        String msg = l10n.createClubTournament_submitError;
        if (e is DioException) {
          final resData = e.response?.data;
          if (resData is Map<String, dynamic>) {
            final serverMsg = resData['message'];
            if (serverMsg is String) {
              msg = serverMsg;
            } else if (serverMsg is List) {
              msg = serverMsg.join(', ');
            }
          } else if (e.response?.statusCode == 403) {
            msg = l10n.createClubTournament_forbiddenError;
          }
        } else {
          msg = e.toString().replaceAll('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSheet(LiteTournamentCreateResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LiteSuccessSheet(
        result: result,
        onManage: () {
          context.pop();
          context.push('/lite-manage/${result.id}');
        },
        onClose: () {
          context.pop();
          context.pop();
        },
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final firstAvailableDate = DateTime(now.year, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now.add(const Duration(days: 1)),
      firstDate: firstAvailableDate,
      lastDate: DateTime(now.year + 3, 12, 31),
      helpText: l10n.createClubTournament_pickStartDate,
      cancelText: l10n.commonCancel,
      confirmText: l10n.createClubTournament_continue,
    );
    if (pickedDate == null || !mounted) return;

    final initialTime = _startDate != null
        ? TimeOfDay(hour: _startDate!.hour, minute: _startDate!.minute)
        : const TimeOfDay(hour: 8, minute: 0);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: l10n.createClubTournament_pickStartTime,
      cancelText: l10n.createClubTournament_defaultTime,
      confirmText: l10n.createClubTournament_done,
    );

    if (!mounted) return;
    final time = pickedTime ?? const TimeOfDay(hour: 8, minute: 0);
    setState(() {
      _startDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickRecurringTime() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showTimePicker(
      context: context,
      initialTime: _recurringTime,
      helpText: l10n.createClubTournament_pickRecurringTime,
      cancelText: l10n.commonCancel,
      confirmText: l10n.createClubTournament_pickTime,
    );
    if (picked != null && mounted) setState(() => _recurringTime = picked);
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String _formatRecurringTime(TimeOfDay time) => MaterialLocalizations.of(context).formatTimeOfDay(time);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final club = widget.clubId.isEmpty ? null : ref.watch(communityDetailProvider(widget.clubId)).value;
    final clubSport = club?.sports.isNotEmpty == true ? _mapClubSport(club!.sports.first) : null;
    final activeSport = clubSport ?? _selectedSport;

    if (!_hasUserEditedName && _nameCtrl.text.isEmpty && club != null) {
      _applyAutoNameIfUntouched(club.name, activeSport, l10n);
    }

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.createClubTournament_title,
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Tên giải đấu ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _label(l10n.createClubTournament_nameLabel, colors),
                  if (club != null)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _hasUserEditedName = false;
                          _applyAutoNameIfUntouched(club.name, activeSport, l10n);
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_fix_high_rounded, size: 13, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              l10n.club_autoGenerateNameHint,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                onChanged: (val) {
                  if (!_hasUserEditedName) {
                    setState(() => _hasUserEditedName = true);
                  }
                },
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.createClubTournament_nameRequired : null,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.createClubTournament_nameHint,
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                  suffixIcon: _nameCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            setState(() {
                              _nameCtrl.clear();
                              _hasUserEditedName = true;
                            });
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // ─── Môn thể thao ───
              _label(l10n.createClubTournament_sportLabel, colors),
              const SizedBox(height: 6),
              _buildSportSelector(lockedSport: clubSport),
              const SizedBox(height: 20),

              // ─── Nội dung thi đấu ───
              _label(l10n.createClubTournament_formatLabel, colors),
              const SizedBox(height: 6),
              _buildFormatSelector(),
              const SizedBox(height: 20),

              // ─── Thể thức ───
              _label(l10n.createClubTournament_bracketLabel, colors),
              const SizedBox(height: 6),
              _buildBracketSelector(),
              const SizedBox(height: 20),

              // ─── Ngày bắt đầu ───
              _label(l10n.createClubTournament_startDateLabel, colors),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickStartDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    hintText: l10n.createClubTournament_startDateHint,
                    hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                    suffixIcon: _startDate == null
                        ? null
                        : IconButton(
                            tooltip: l10n.createClubTournament_clearDate,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setState(() => _startDate = null),
                          ),
                  ),
                  child: Text(
                    _startDate == null
                        ? l10n.createClubTournament_notSelected
                        : DateFormat('HH:mm - dd/MM/yyyy').format(_startDate!),
                    style: TextStyle(
                      color: _startDate == null ? colors.textMuted : colors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // ─── Thời lượng thi đấu ───
              if (_startDate != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: colors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.lite_duration,
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                        ),
                      ),
                      DropdownButton<int>(
                        value: _durationHours,
                        underline: const SizedBox.shrink(),
                        dropdownColor: colors.bgCard,
                        items: List.generate(24, (i) => i)
                            .map((h) => DropdownMenuItem(
                                  value: h,
                                  child: Text(
                                    '$h ${l10n.lite_hours}',
                                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            _durationHours = val;
                            if (_durationHours == 0 && _durationMinutes < 15) {
                              _durationMinutes = 15;
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _durationMinutes,
                        underline: const SizedBox.shrink(),
                        dropdownColor: colors.bgCard,
                        items: [0, 15, 30, 45]
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    '$m ${l10n.lite_minutes}',
                                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            _durationMinutes = val;
                            if (_durationHours == 0 && _durationMinutes < 15) {
                              _durationMinutes = 15;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // ─── Tạo định kỳ ───
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isRecurring ? AppTheme.primary.withValues(alpha: 0.06) : colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isRecurring ? AppTheme.primary : colors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.createClubTournament_recurringTitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                              const SizedBox(height: 3),
                              Text(l10n.createClubTournament_recurringDescription, style: TextStyle(fontSize: 11, color: colors.textMuted, height: 1.3)),
                            ],
                          ),
                        ),
                        Switch.adaptive(value: _isRecurring, onChanged: (value) => setState(() => _isRecurring = value), activeTrackColor: AppTheme.primary),
                      ],
                    ),
                    if (_isRecurring) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _recurringFrequency,
                        decoration: InputDecoration(labelText: l10n.createClubTournament_frequency),
                        items: [
                          DropdownMenuItem(value: 'DAILY', child: Text(l10n.createClubTournament_daily)),
                          DropdownMenuItem(value: 'WEEKLY', child: Text(l10n.createClubTournament_weekly)),
                          DropdownMenuItem(value: 'BIWEEKLY', child: Text(l10n.createClubTournament_biweekly)),
                          DropdownMenuItem(value: 'MONTHLY', child: Text(l10n.createClubTournament_monthly)),
                        ],
                        onChanged: (value) => setState(() => _recurringFrequency = value ?? _recurringFrequency),
                      ),
                      if (_recurringFrequency == 'WEEKLY' || _recurringFrequency == 'BIWEEKLY') ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          initialValue: _recurringDayOfWeek,
                          decoration: InputDecoration(labelText: l10n.createClubTournament_weekday),
                          items: [
                            DropdownMenuItem(value: 1, child: Text(l10n.createClubTournament_monday)),
                            DropdownMenuItem(value: 2, child: Text(l10n.createClubTournament_tuesday)),
                            DropdownMenuItem(value: 3, child: Text(l10n.createClubTournament_wednesday)),
                            DropdownMenuItem(value: 4, child: Text(l10n.createClubTournament_thursday)),
                            DropdownMenuItem(value: 5, child: Text(l10n.createClubTournament_friday)),
                            DropdownMenuItem(value: 6, child: Text(l10n.createClubTournament_saturday)),
                            DropdownMenuItem(value: 0, child: Text(l10n.createClubTournament_sunday)),
                          ],
                          onChanged: (value) => setState(() => _recurringDayOfWeek = value ?? _recurringDayOfWeek),
                        ),
                      ],
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _pickRecurringTime,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(labelText: l10n.createClubTournament_autoCreateTime),
                          child: Row(children: [
                            const Icon(Icons.schedule_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(_formatRecurringTime(_recurringTime)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue: _recurringAdvanceDays,
                        decoration: InputDecoration(labelText: l10n.createClubTournament_advanceDays),
                        items: List.generate(8, (days) => DropdownMenuItem(value: days, child: Text(days == 0 ? l10n.createClubTournament_sameDay : l10n.createClubTournament_beforeDays(days)))),
                        onChanged: (value) => setState(() => _recurringAdvanceDays = value ?? _recurringAdvanceDays),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Số đội tối đa ───
              _label(l10n.createClubTournament_maxTeams, colors),
              const SizedBox(height: 6),
              TextFormField(
                controller: _maxTeamsCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 2 || n > 128) return l10n.createClubTournament_maxTeamsInvalid;
                  return null;
                },
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.createClubTournament_maxTeamsHint,
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Mô tả ───
              _label(l10n.createClubTournament_descriptionLabel, colors),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.createClubTournament_descriptionHint,
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 32),

              // ─── Xếp hạng ELO toggle ───
              Container(
                decoration: BoxDecoration(
                  color: _isRanked
                      ? AppTheme.primary.withValues(alpha: 0.08)
                      : context.colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isRanked ? AppTheme.primary : context.colors.border,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRanked ? l10n.createClubTournament_ranked : l10n.createClubTournament_unranked,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _isRanked ? AppTheme.primary : context.colors.textPrimary,
                            ),
                          ),
                          Text(
                            _isRanked
                                ? l10n.createClubTournament_rankedDescription
                                : l10n.createClubTournament_unrankedDescription,
                            style: TextStyle(fontSize: 11, color: context.colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isRanked,
                      onChanged: (v) => setState(() => _isRanked = v),
                      activeTrackColor: AppTheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Nút Submit ───
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_rounded),
                  label: Text(
                    _isLoading ? l10n.createClubTournament_creating : l10n.createClubTournament_create,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, AppColorsExtension colors) {
    return Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary));
  }

  Widget _buildSportSelector({String? lockedSport}) {
    final l10n = AppLocalizations.of(context)!;
    final sports = [
      (AppConstants.sportBadminton, l10n.createClubTournament_sportBadminton, '🏸'),
      (AppConstants.sportTennis, l10n.createClubTournament_sportTennis, '🎾'),
      (AppConstants.sportPickleball, l10n.createClubTournament_sportPickleball, '🥒'),
      (AppConstants.sportTableTennis, l10n.createClubTournament_sportTableTennis, '🏓'),
      (AppConstants.sportFootball, l10n.createClubTournament_sportFootball, '⚽'),
    ];
    return Row(
      children: sports.where((s) => lockedSport == null || lockedSport == s.$1).map((s) {
        final selected = _selectedSport == s.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: s != sports.last ? 8 : 0),
            child: GestureDetector(
              onTap: lockedSport == null
                  ? () => setState(() {
                      _selectedSport = s.$1;
                      if (s.$1 == AppConstants.sportFootball) {
                        _selectedFormat = AppConstants.formatDoubles;
                      }
                    })
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary.withValues(alpha: 0.1) : context.colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppTheme.primary : context.colors.border, width: selected ? 1.5 : 1),
                ),
                child: Column(
                  children: [
                    Text(s.$3, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 4),
                    Text(s.$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? AppTheme.primary : context.colors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormatSelector() {
    final l10n = AppLocalizations.of(context)!;
    final isTeamSport = _selectedSport == AppConstants.sportFootball;
    final formats = isTeamSport
        ? [(AppConstants.formatDoubles, l10n.createClubTournament_formatDoubles)]
        : [
            (AppConstants.formatSingles, l10n.createClubTournament_formatSingles),
            (AppConstants.formatDoubles, l10n.createClubTournament_formatDoubles),
          ];
    return Row(
      children: formats.map((f) {
        final selected = _selectedFormat == f.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: f != formats.last ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFormat = f.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary.withValues(alpha: 0.1) : context.colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppTheme.primary : context.colors.border, width: selected ? 1.5 : 1),
                ),
                child: Center(
                  child: Text(f.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? AppTheme.primary : context.colors.textSecondary)),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBracketSelector() {
    final l10n = AppLocalizations.of(context)!;
    final brackets = [
      (AppConstants.bracketSingleElimination, l10n.createClubTournament_bracketSingleElimination, l10n.createClubTournament_bracketSingleEliminationDescription),
      (AppConstants.bracketDoubleElimination, l10n.createClubTournament_bracketDoubleElimination, l10n.createClubTournament_bracketDoubleEliminationDescription),
      (AppConstants.bracketRoundRobin, l10n.createClubTournament_bracketRoundRobin, l10n.createClubTournament_bracketRoundRobinDescription),
      (AppConstants.bracketGroupStageKnockout, l10n.createClubTournament_bracketGroupStageKnockout, l10n.createClubTournament_bracketGroupStageKnockoutDescription),
    ];
    return Column(
      children: brackets.map((b) {
        final selected = _selectedBracket == b.$1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedBracket = b.$1),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary.withValues(alpha: 0.08) : context.colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppTheme.primary : context.colors.border, width: selected ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: selected ? AppTheme.primary : context.colors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.$2, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: selected ? AppTheme.primary : context.colors.textPrimary)),
                        Text(b.$3, style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Bottom sheet hiển thị sau khi tạo giải Lite thành công
/// Gồm QR, link mời, các nút Sao chép / Chia sẻ / Vào quản lý nhanh
class _LiteSuccessSheet extends StatelessWidget {
  const _LiteSuccessSheet({
    required this.result,
    required this.onManage,
    required this.onClose,
  });

  final LiteTournamentCreateResult result;
  final VoidCallback onManage;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final link = result.joinUrl ?? '/lite/tournaments/join/${result.inviteCode ?? result.id}';

    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Drag handle ───
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ─── Success icon ───
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, color: colors.success, size: 32),
              ),
              const SizedBox(height: 14),

              // ─── Title ───
              Text(
                l10n.createClubTournament_successTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.name,
                style: TextStyle(fontSize: 13, color: colors.textMuted),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              // ─── QR Code ───
              if (result.qrPayload != null || result.joinUrl != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: QrImageView(
                    data: result.qrPayload ?? link,
                    version: QrVersions.auto,
                    size: 160,
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                ),
              if (result.qrPayload != null || result.joinUrl != null)
                const SizedBox(height: 16),

              // ─── Link ───
              if (link.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    link,
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (link.isNotEmpty)
                const SizedBox(height: 20),

              // ─── Buttons ───
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.createClubTournament_linkCopied),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(l10n.createClubTournament_copyLink, style: const TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        SharePlus.instance.share(
                          ShareParams(text: l10n.createClubTournament_shareText(result.name, link)),
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text(l10n.createClubTournament_share, style: const TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ─── Vào quản lý nhanh ───
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: onManage,
                  icon: const Icon(Icons.speed_rounded, size: 20),
                  label: Text(
                    l10n.createClubTournament_manageQuickly,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ─── Đóng ───
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onClose,
                  child: Text(
                    l10n.createClubTournament_close,
                    style: TextStyle(color: colors.textMuted, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
