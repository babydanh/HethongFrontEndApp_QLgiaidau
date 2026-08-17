import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/domain/entities/lite_tournament_create_result.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app_quanly_giaidau/core/widgets/app_share_modal.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_quanly_giaidau/features/community/widgets/club_region_selector.dart';

/// Tạo giải đấu Lite trong CLB hoặc giải nhanh riêng của Organizer.
/// Gọi POST /tournaments/lite — dùng chung contract với Web.
class CreateClubTournamentScreen extends ConsumerStatefulWidget {
  final String clubId;
  const CreateClubTournamentScreen({super.key, required this.clubId});

  @override
  ConsumerState<CreateClubTournamentScreen> createState() =>
      _CreateClubTournamentScreenState();
}

class _CreateClubTournamentScreenState
    extends ConsumerState<CreateClubTournamentScreen> {
  static const _log = AppLogger('CreateClubTournament');
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _maxTeamsCtrl = TextEditingController(text: '16');
  final _venueCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _prizeCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();

  String? _selectedSport;
  String _selectedFormat = AppConstants.formatDoubles;
  final Set<String> _selectedFormats = {'MALE_DOUBLES'};
  String _selectedBracket = AppConstants.bracketSingleElimination;
  bool _isLoading = false;
  bool _isRanked = false;
  bool _isPublic = false;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  DateTime _registrationStartDate = DateTime.now();
  TimeOfDay _registrationStartTime = const TimeOfDay(hour: 0, minute: 0);
  DateTime _registrationEndDate = DateTime.now();
  TimeOfDay _registrationEndTime = const TimeOfDay(hour: 17, minute: 0);
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isRecurring = false;
  String _recurringFrequency = 'WEEKLY';
  final Set<int> _recurringDaysOfWeek = <int>{6};
  TimeOfDay _recurringTime = const TimeOfDay(hour: 18, minute: 0);
  int _recurringAdvanceDays = 0;
  int _footballTeamSize = 7;
  final _footballReserveCtrl = TextEditingController(text: '5');
  String _footballGenderRestriction = 'MALE';
  ClubRegionSelection _region = const ClubRegionSelection();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, now.hour + 1);
    final end = start.add(const Duration(hours: 2));
    final registrationEnd = start.subtract(const Duration(hours: 1));
    _startDate = start;
    _startTime = TimeOfDay.fromDateTime(start);
    _endDate = end;
    _endTime = TimeOfDay.fromDateTime(end);
    _registrationStartDate = DateTime(now.year, now.month, now.day);
    _registrationStartTime = const TimeOfDay(hour: 0, minute: 0);
    _registrationEndDate = registrationEnd;
    _registrationEndTime = TimeOfDay.fromDateTime(registrationEnd);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _maxTeamsCtrl.dispose();
    _venueCtrl.dispose();
    _addressCtrl.dispose();
    _prizeCtrl.dispose();
    _contactCtrl.dispose();
    _footballReserveCtrl.dispose();
    super.dispose();
  }

  /// Map App sport slug → backend slug
  String? _mapSportSlug() {
    if (_selectedSport == null) return null;
    switch (_selectedSport) {
      case AppConstants.sportBadminton:
        return 'badminton';
      case AppConstants.sportTennis:
        return 'tennis';
      case AppConstants.sportPickleball:
        return 'pickleball';
      case AppConstants.sportTableTennis:
        return 'table_tennis';
      case AppConstants.sportFootball:
        return 'football';
      default:
        return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final sport = _mapSportSlug();
    if (sport == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Môn thể thao của CLB không còn hoạt động hoặc chưa được tải. Không thể tạo giải.',
          ),
        ),
      );
      return;
    }

    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để tạo giải đấu.')),
      );
      context.push('/login');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final registrationStart = _combineDateTime(_registrationStartDate, _registrationStartTime);
      final registrationEnd = _combineDateTime(_registrationEndDate, _registrationEndTime);
      final start = _combineDateTime(_startDate, _startTime);
      final end = _combineDateTime(_endDate, _endTime);
      if (!registrationStart.isBefore(registrationEnd)) {
        throw const FormatException('Thời gian mở đăng ký phải trước thời gian đóng.');
      }
      if (!registrationEnd.isBefore(start)) {
        throw const FormatException('Thời gian đóng đăng ký phải trước giờ bắt đầu giải.');
      }
      if (!start.isBefore(end)) {
        throw const FormatException('Thời gian kết thúc phải sau thời gian bắt đầu.');
      }
      final dio = ref.read(dioClientProvider).dio;

      final body = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'sport': sport,
        'format': _selectedFormat,
        'selectedFormats': _selectedFormats.toList(),
        'bracketType': _selectedBracket,
        'maxTeams': int.tryParse(_maxTeamsCtrl.text) ?? 16,
        'description': _descCtrl.text.trim(),
        'isRanked': _isRanked,
        'visibility': _isPublic ? 'PUBLIC' : 'PRIVATE',
        if (_prizeCtrl.text.trim().isNotEmpty)
          'prizeDescription': _prizeCtrl.text.trim(),
        if (_contactCtrl.text.trim().isNotEmpty)
          'contactInfo': {'phone': _contactCtrl.text.trim()},
        if (_venueCtrl.text.trim().isNotEmpty)
          'venueName': _venueCtrl.text.trim(),
        if (_addressCtrl.text.trim().isNotEmpty)
          'locationAddress': _addressCtrl.text.trim(),
        if (_region.provinceName != null) 'province': _region.provinceName,
        if (_region.wardName != null) 'ward': _region.wardName,
        if (_footballGenderRestriction.isNotEmpty)
          'genderRestriction': _footballGenderRestriction,
        if (widget.clubId.isNotEmpty) 'communityId': widget.clubId,
        // Quick tournaments start in approval mode; the organizer can
        // switch to open or invite-only from management later.
        'registrationMode': 'APPROVAL',
        'startDate': _formatDateTime(_startDate, _startTime),
        'startTime': _formatTime(_startTime),
        'endDate': _formatDateTime(_endDate, _endTime),
        'registrationStartDate': _formatDateTime(_registrationStartDate, _registrationStartTime),
        'registrationEndDate': _formatDateTime(_registrationEndDate, _registrationEndTime),
        'isRecurring': _isRecurring,
        if (_isRecurring) ...{
          'recurringFrequency': _recurringFrequency,
          'recurringDayOfWeek': _recurringDaysOfWeek.isEmpty
              ? 6
              : _recurringDaysOfWeek.first,
          'recurringDaysOfWeek': _recurringDaysOfWeek.toList()..sort(),
          'recurringTimeOfDay': _formatTime(_recurringTime),
          'recurringAdvanceDays': _recurringAdvanceDays,
        },
        if (_selectedSport == AppConstants.sportFootball) ...{
          'teamSize': _footballTeamSize,
          'maxReserve': int.tryParse(_footballReserveCtrl.text) ?? 0,
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

        if (widget.clubId.isNotEmpty) {
          ref.invalidate(communityTournamentsProvider(widget.clubId));
          ref.invalidate(communityDetailProvider(widget.clubId));
        }

        _showSuccessSheet(result);
      }
    } catch (e, stack) {
      _log.error('Lỗi tạo giải đấu trong CLB', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorParser.parse(e, 'Không thể tạo giải đấu.')),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  DateTime _combineDateTime(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  String _formatDateTime(DateTime date, TimeOfDay time) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T${_formatTime(time)}:00';

  Future<void> _pickTime({required bool recurring}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: recurring ? _recurringTime : _startTime,
      helpText: recurring ? 'Chọn giờ lặp lại' : 'Chọn giờ thi đấu',
    );
    if (picked == null || !mounted) return;
    setState(() => recurring ? _recurringTime = picked : _startTime = picked);
  }

  Future<void> _pickScheduleDate(String target) async {
    final current = switch (target) {
      'registrationStart' => _registrationStartDate,
      'registrationEnd' => _registrationEndDate,
      'end' => _endDate,
      _ => _startDate,
    };
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: current,
      helpText: 'Chọn ngày',
    );
    if (picked == null || !mounted) return;
    setState(() {
      switch (target) {
        case 'registrationStart': _registrationStartDate = picked;
        case 'registrationEnd': _registrationEndDate = picked;
        case 'end': _endDate = picked;
        default: _startDate = picked;
      }
    });
  }

  Future<void> _pickScheduleTime(String target) async {
    final current = switch (target) {
      'registrationStart' => _registrationStartTime,
      'registrationEnd' => _registrationEndTime,
      'end' => _endTime,
      _ => _startTime,
    };
    final picked = await showTimePicker(context: context, initialTime: current, helpText: 'Chọn giờ');
    if (picked == null || !mounted) return;
    setState(() {
      switch (target) {
        case 'registrationStart': _registrationStartTime = picked;
        case 'registrationEnd': _registrationEndTime = picked;
        case 'end': _endTime = picked;
        default: _startTime = picked;
      }
    });
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

  Widget _scheduleRow(String label, String target, DateTime date, TimeOfDay time) {
    return Row(
      children: [
        Expanded(child: OutlinedButton.icon(onPressed: () => _pickScheduleDate(target), icon: const Icon(Icons.calendar_today_outlined, size: 16), label: Text('$label: ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(onPressed: () => _pickScheduleTime(target), icon: const Icon(Icons.schedule_outlined, size: 16), label: Text(_formatTime(time)))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final communityAsync = widget.clubId.isNotEmpty
        ? ref.watch(communityDetailProvider(widget.clubId))
        : null;
    final community = communityAsync?.value;
    final clubCat = community != null && community.sports.isNotEmpty
        ? community.sports.first
        : null;
    final isClubLocked = clubCat != null;

    if (isClubLocked && _selectedSport == null) {
      final normalizedClubCategory = clubCat.trim().toLowerCase();
      final activeCategory = ref.watch(categoriesProvider).asData?.value.where((
        category,
      ) {
        return category.slug.trim().toLowerCase() == normalizedClubCategory ||
            category.name.trim().toLowerCase() == normalizedClubCategory;
      }).firstOrNull;
      // Không được âm thầm đổi sang badminton khi category CLB không tồn tại
      // hoặc đã bị Admin tắt.
      _selectedSport = activeCategory?.slug;
      if (_selectedSport == AppConstants.sportFootball) {
        _selectedFormat = AppConstants.formatDoubles;
      }
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
          widget.clubId.isEmpty ? 'Tạo giải nhanh' : 'Tạo giải đấu trong CLB',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
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
              _label('Tên giải đấu *', colors),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameCtrl,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập tên giải đấu'
                    : null,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'VD: Giải Cầu lông Mở rộng 2026',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Môn thể thao ───
              _label('Môn thể thao', colors),
              const SizedBox(height: 6),
              _buildSportSelector(
                isClubLocked: isClubLocked,
                clubCategoryName: clubCat,
              ),
              const SizedBox(height: 20),

              // ─── Hình thức ───
              _label('Hình thức', colors),
              const SizedBox(height: 6),
              _buildFormatSelector(),
              if (_selectedSport == AppConstants.sportFootball) ...[
                const SizedBox(height: 16),
                _label('Cấu hình đội bóng', colors),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _footballTeamSize,
                        decoration: const InputDecoration(
                          labelText: 'Cầu thủ chính',
                        ),
                        items: const [5, 7, 11]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text('$value người'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _footballTeamSize = value ?? 7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _footballReserveCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Dự bị tối đa',
                        ),
                        validator: (value) {
                          if (_selectedSport != AppConstants.sportFootball) {
                            return null;
                          }
                          final reserve = int.tryParse(value ?? '');
                          return reserve == null || reserve < 0 || reserve > 20
                              ? '0-20 người'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              // ─── Thể thức ───
              _label('Thể thức thi đấu', colors),
              const SizedBox(height: 6),
              _buildBracketSelector(),
              const SizedBox(height: 20),

              // ─── Số đội tối đa ───
              _label('Số đội tối đa', colors),
              const SizedBox(height: 6),
              TextFormField(
                controller: _maxTeamsCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 2 || n > 32) return 'Từ 2-32 đội';
                  return null;
                },
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: '16',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              _label('Lịch thi đấu', colors),
              const SizedBox(height: 6),
              _scheduleRow('Mở đăng ký', 'registrationStart', _registrationStartDate, _registrationStartTime),
              const SizedBox(height: 8),
              _scheduleRow('Đóng đăng ký', 'registrationEnd', _registrationEndDate, _registrationEndTime),
              const SizedBox(height: 8),
              _scheduleRow('Bắt đầu giải', 'start', _startDate, _startTime),
              const SizedBox(height: 8),
              _scheduleRow('Kết thúc dự kiến', 'end', _endDate, _endTime),
              const SizedBox(height: 8),
              Text('Mặc định mở đăng ký từ hôm nay; kết thúc dự kiến sau giờ bắt đầu 2 tiếng. Bạn có thể chỉnh lại.', style: TextStyle(fontSize: 11, color: colors.textMuted)),
              const SizedBox(height: 10),
              Card(
                margin: EdgeInsets.zero,
                child: SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: const Text('Công khai giải đấu'),
                  subtitle: Text(
                    _isPublic
                        ? 'Sẽ chờ Admin duyệt trước khi xuất hiện công khai.'
                        : widget.clubId.isNotEmpty
                            ? 'Chỉ thành viên CLB nhìn thấy và tham gia.'
                            : 'Giải riêng, chỉ người có mã mời nhìn thấy.',
                  ),
                  value: _isPublic,
                  onChanged: (value) => setState(() => _isPublic = value),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: const Text('Thông tin thêm (không bắt buộc)'),
                  subtitle: const Text('Địa điểm, ghi chú và liên hệ BTC'),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    TextFormField(
                      controller: _venueCtrl,
                      decoration: const InputDecoration(labelText: 'Tên sân/địa điểm'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(labelText: 'Địa chỉ chi tiết'),
                    ),
                    const SizedBox(height: 10),
                    ClubRegionSelector(onChanged: (selection) => _region = selection),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _contactCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'SĐT BTC'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _prizeCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Giải thưởng/mô tả thêm'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tự động tạo giải định kỳ'),
                        subtitle: const Text(
                          'Tạo giải mới và thông báo vào feed CLB theo lịch',
                        ),
                        value: _isRecurring,
                        onChanged: (value) =>
                            setState(() => _isRecurring = value),
                      ),
                      if (_isRecurring) ...[
                        DropdownButtonFormField<String>(
                          initialValue: _recurringFrequency,
                          decoration: const InputDecoration(
                            labelText: 'Tần suất lặp lại',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'WEEKLY',
                              child: Text('Hằng tuần'),
                            ),
                            DropdownMenuItem(
                              value: 'BIWEEKLY',
                              child: Text('2 tuần một lần'),
                            ),
                            DropdownMenuItem(
                              value: 'DAILY',
                              child: Text('Hằng ngày'),
                            ),
                            DropdownMenuItem(
                              value: 'MONTHLY',
                              child: Text('Hằng tháng'),
                            ),
                          ],
                          onChanged: (value) => setState(
                            () => _recurringFrequency = value ?? 'WEEKLY',
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => _pickTime(recurring: true),
                          icon: const Icon(Icons.schedule_outlined, size: 16),
                          label: Text(
                            'Giờ lặp lại: ${_formatTime(_recurringTime)}',
                          ),
                        ),
                        if (_recurringFrequency != 'DAILY' &&
                            _recurringFrequency != 'MONTHLY') ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            children: [
                              for (final day in [1, 2, 3, 4, 5, 6, 0])
                                FilterChip(
                                  label: Text(day == 0 ? 'CN' : 'T$day'),
                                  selected: _recurringDaysOfWeek.contains(day),
                                  onSelected: (selected) => setState(() {
                                    if (selected) {
                                      _recurringDaysOfWeek.add(day);
                                    } else if (_recurringDaysOfWeek.length >
                                        1) {
                                      _recurringDaysOfWeek.remove(day);
                                    }
                                  }),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          initialValue: _recurringAdvanceDays,
                          decoration: const InputDecoration(
                            labelText: 'Tạo trước và mở đăng ký',
                          ),
                          items: const [0, 1, 2, 3, 5, 7]
                              .map(
                                (days) => DropdownMenuItem(
                                  value: days,
                                  child: Text('Trước $days ngày'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(
                            () => _recurringAdvanceDays = value ?? 0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Thành viên CLB sẽ nhận thông báo và bài đăng poll khi kỳ mới được tạo.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Mô tả ───
              _label('Mô tả (không bắt buộc)', colors),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Thông tin thêm về giải đấu...',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRanked ? 'Xếp hạng ELO' : 'Phong trào',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _isRanked
                                  ? AppTheme.primary
                                  : context.colors.textPrimary,
                            ),
                          ),
                          Text(
                            _isRanked
                                ? 'Kết quả ảnh hưởng đến điểm ELO trong câu lạc bộ'
                                : 'Giải giao hữu, không tính xếp hạng',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colors.textMuted,
                            ),
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
              const SizedBox(height: 20),

              // Giữ app gọn cho giải nhanh; các cấu hình chuyên sâu mở trên Web.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.colors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Cần vòng bảng, thu phí hoặc luật nâng cao?',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse('${AppConstants.appDomain}/tournaments/create'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Text('Mở Web'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ─── Nút Submit ───
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded),
                  label: Text(
                    _isLoading ? 'Đang tạo...' : 'Tạo giải đấu',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    ),
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
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: colors.textSecondary,
      ),
    );
  }

  Widget _buildSportSelector({
    bool isClubLocked = false,
    String? clubCategoryName,
  }) {
    final categories =
        ref.watch(categoriesProvider).asData?.value ?? const <CategoryModel>[];
    final sports = categories
        .map((category) {
          final slug = category.slug.toLowerCase();
          final icon = slug == 'football'
              ? Icons.sports_soccer
              : Icons.sports_tennis;
          return (category.slug, category.name, icon);
        })
        .toList(growable: false);
    if (sports.isEmpty) {
      return Text(
        'Không có môn thi đấu đang hoạt động. Vui lòng thử lại sau.',
        style: TextStyle(color: context.colors.error, fontSize: 12),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isClubLocked && clubCategoryName != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_rounded, size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bộ môn được cố định theo CLB: $clubCategoryName',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Row(
          children: sports.map((s) {
            final selected = _selectedSport == s.$1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: s != sports.last ? 8 : 0),
                child: GestureDetector(
                  onTap: isClubLocked
                      ? null
                      : () => setState(() {
                          _selectedSport = s.$1;
                          if (s.$1 == AppConstants.sportFootball) {
                            _selectedFormat = AppConstants.formatDoubles;
                            _footballGenderRestriction = '';
                          }
                        }),
                  child: Opacity(
                    opacity: (isClubLocked && !selected) ? 0.4 : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : context.colors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : context.colors.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            s.$3,
                            size: 22,
                            color: selected
                                ? AppTheme.primary
                                : context.colors.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.$2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? AppTheme.primary
                                  : context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedSport == null) ...[
          const SizedBox(height: 6),
          Text(
            'Vui lòng chọn môn thể thao',
            style: TextStyle(color: context.colors.error, fontSize: 12),
          ),
        ],
      ],
    );
  }

  void _toggleFormat(String formatKey) {
    setState(() {
      if (_selectedFormats.contains(formatKey)) {
        if (_selectedFormats.length > 1) {
          _selectedFormats.remove(formatKey);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cần chọn ít nhất 1 nội dung thi đấu.')),
          );
        }
      } else {
        _selectedFormats.add(formatKey);
      }
      _syncLegacyFormat();
    });
  }

  void _syncLegacyFormat() {
    if (_selectedFormats.isEmpty) return;
    final primary = _selectedFormats.first;
    if (primary.contains('SINGLES')) {
      _selectedFormat = AppConstants.formatSingles;
      _footballGenderRestriction = primary.contains('FEMALE') ? 'FEMALE' : 'MALE';
    } else if (primary.contains('DOUBLES')) {
      _selectedFormat = AppConstants.formatDoubles;
      if (primary.contains('MIXED')) {
        _footballGenderRestriction = 'MIXED';
      } else if (primary.contains('FEMALE')) {
        _footballGenderRestriction = 'FEMALE';
      } else {
        _footballGenderRestriction = 'MALE';
      }
    } else if (primary.startsWith('FOOTBALL_')) {
      _selectedFormat = AppConstants.formatDoubles;
      if (primary == 'FOOTBALL_MALE') {
        _footballGenderRestriction = 'MALE';
      } else if (primary == 'FOOTBALL_FEMALE') {
        _footballGenderRestriction = 'FEMALE';
      } else {
        _footballGenderRestriction = '';
      }
    }
  }

  Widget _buildFormatSelector() {
    if (_selectedSport == AppConstants.sportFootball) {
      final footballFormats = [
        ('FOOTBALL_MALE', 'Đội nam'),
        ('FOOTBALL_FEMALE', 'Đội nữ'),
        ('FOOTBALL_MIXED', 'Không giới hạn'),
      ];
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: footballFormats.map((f) => SizedBox(
          width: (MediaQuery.sizeOf(context).width - 56) / 3,
          child: _formatChoice(f.$1, f.$2),
        )).toList(),
      );
    }
    final formats = [
      ('MALE_SINGLES', 'Đơn nam'),
      ('FEMALE_SINGLES', 'Đơn nữ'),
      ('MALE_DOUBLES', 'Đôi nam'),
      ('FEMALE_DOUBLES', 'Đôi nữ'),
      ('MIXED_DOUBLES', 'Đôi nam nữ'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: formats.map((f) => SizedBox(
        width: (MediaQuery.sizeOf(context).width - 56) / 2,
        child: _formatChoice(f.$1, f.$2),
      )).toList(),
    );
  }

  Widget _formatChoice(String formatKey, String label) {
    final selected = _selectedFormats.contains(formatKey);
    return GestureDetector(
      onTap: () => _toggleFormat(formatKey),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.1) : context.colors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : context.colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? AppTheme.primary : context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBracketSelector() {
    final brackets = [
      (
        AppConstants.bracketSingleElimination,
        'Loại trực tiếp',
        'Loại ngay khi thua',
      ),
      (
        AppConstants.bracketDoubleElimination,
        'Loại kép',
        'Có nhánh thắng/thua',
      ),
      (AppConstants.bracketRoundRobin, 'Vòng tròn', 'Tất cả gặp nhau'),
      (
        AppConstants.bracketGroupStageKnockout,
        'Vòng bảng + Loại trực tiếp',
        'Tối thiểu 4 đội, hệ thống tự động chia đều',
      ),
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
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : context.colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppTheme.primary : context.colors.border,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected
                        ? AppTheme.primary
                        : context.colors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.$2,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppTheme.primary
                                : context.colors.textPrimary,
                          ),
                        ),
                        Text(
                          b.$3,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.textMuted,
                          ),
                        ),
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
    final colors = context.colors;
    final link = result.resolvedJoinUrl;

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
                child: Icon(
                  Icons.check_circle_rounded,
                  color: colors.success,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),

              // ─── Title ───
              Text(
                'Tạo giải thành công!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
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
              if (result.resolvedQrPayload.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: result.resolvedQrPayload,
                    version: QrVersions.auto,
                    size: 160,
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                ),
              if (result.resolvedQrPayload.isNotEmpty)
                const SizedBox(height: 16),

              // ─── Link ───
              if (link.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
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
              if (link.isNotEmpty) const SizedBox(height: 20),

              // ─── Buttons ───
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép link mời!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text(
                        'Sao chép link',
                        style: TextStyle(fontSize: 13),
                      ),
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
                        AppShareModal.show(
                          context: context,
                          title: 'Giải Nhanh: ${result.name}',
                          subtitle:
                              'Mã mời: ${result.inviteCode} • Quét QR hoặc mở link để tham gia',
                          webUrl: link,
                          badgeText: 'Giải Nhanh (Lite)',
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text(
                        'Chia sẻ',
                        style: TextStyle(fontSize: 13),
                      ),
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
                  label: const Text(
                    'Vào quản lý nhanh',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
                    'Đóng',
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
