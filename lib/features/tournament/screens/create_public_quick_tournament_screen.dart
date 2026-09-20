import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/lite_tournament_create_result.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/regions_provider.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/bracket_format_icons.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/public_tournament_type_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';

/// Tạo giải nhanh Public trên mobile app.
/// Giải thuộc CLB phải được tạo từ trang chi tiết/quản lý CLB.
class CreatePublicQuickTournamentScreen extends ConsumerStatefulWidget {
  const CreatePublicQuickTournamentScreen({super.key});

  @override
  ConsumerState<CreatePublicQuickTournamentScreen> createState() =>
      _CreatePublicQuickTournamentScreenState();
}

class _CreatePublicQuickTournamentScreenState
    extends ConsumerState<CreatePublicQuickTournamentScreen> {
  static const _log = AppLogger('CreatePublicQuickTournament');
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _maxTeamsController = TextEditingController(text: '16');
  final _venueNameController = TextEditingController();
  final _locationAddressController = TextEditingController();

  String _sport = AppConstants.sportPickleball;
  String _formatKey =
      'MALE_DOUBLES'; // MALE_SINGLES, FEMALE_SINGLES, MALE_DOUBLES, FEMALE_DOUBLES, MIXED_DOUBLES, FOOTBALL_MALE, FOOTBALL_FEMALE, FOOTBALL_MIXED
  final Set<String> _selectedFormatKeys = {'MALE_DOUBLES'};
  String _bracket = AppConstants.bracketSingleElimination;
  String _registrationMode = 'APPROVAL';
  DateTime? _startDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime? _endDate;
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);
  DateTime? _regStartDate;
  DateTime? _regEndDate;
  TimeOfDay _regStartTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _regEndTime = const TimeOfDay(hour: 23, minute: 59);
  String? _provinceCode;
  String? _wardCode;
  int _teamSize = 7;
  int _maxReserve = 5;
  int _footballHalvesCount = 2;
  int _footballHalfDuration = 45;
  bool _footballAllowDraw = true;
  int _durationHours = 1;
  int _durationMinutes = 30;
  bool _isSubmitting = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  bool _hasCheckedRole = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final defaultStart = now.add(const Duration(days: 7));
    _startDate = DateTime(
      defaultStart.year,
      defaultStart.month,
      defaultStart.day,
    );
    final defaultEnd = defaultStart.add(const Duration(hours: 2));
    _endDate = DateTime(defaultEnd.year, defaultEnd.month, defaultEnd.day);
    _startTime = TimeOfDay.fromDateTime(defaultStart);
    _endTime = TimeOfDay.fromDateTime(defaultEnd);
    _regStartDate = DateTime(now.year, now.month, now.day);
    _regEndDate = _startDate!.subtract(const Duration(days: 1));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _verifyOrganizerPermission(),
    );
  }

  Future<void> _verifyOrganizerPermission() async {
    if (_hasCheckedRole || !mounted) return;
    _hasCheckedRole = true;

    try {
      final userProfile = await ref.read(userProfileProvider.future);
      final role = (userProfile.role ?? '').toUpperCase();
      final isOrganizerOrAdmin = role == 'ORGANIZER' || role == 'ADMIN';
      if (!isOrganizerOrAdmin && mounted) {
        showOrganizerRequiredDialog(
          context,
          onCancel: () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        );
      }
    } catch (_) {
      final cached = ref.read(userProfileProvider).asData?.value;
      if (cached != null) {
        final role = (cached.role ?? '').toUpperCase();
        final isOrganizerOrAdmin = role == 'ORGANIZER' || role == 'ADMIN';
        if (!isOrganizerOrAdmin && mounted) {
          showOrganizerRequiredDialog(
            context,
            onCancel: () {
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _maxTeamsController.dispose();
    _venueNameController.dispose();
    _locationAddressController.dispose();
    super.dispose();
  }

  String _mapSportSlug() {
    switch (_sport) {
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
        return 'pickleball';
    }
  }

  DateTime _withTime(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  String _formatLabel(String key) {
    switch (key) {
      case 'MALE_SINGLES':
        return l10n.tournamentCategoryMenSingles;
      case 'FEMALE_SINGLES':
        return l10n.tournamentCategoryWomenSingles;
      case 'MALE_DOUBLES':
        return l10n.tournamentCategoryMenDoubles;
      case 'FEMALE_DOUBLES':
        return l10n.tournamentCategoryWomenDoubles;
      case 'MIXED_DOUBLES':
        return l10n.tournamentCategoryMixedDoubles;
      case 'FOOTBALL_MALE':
        return l10n.tournamentCategoryFootballMen;
      case 'FOOTBALL_FEMALE':
        return l10n.tournamentCategoryFootballWomen;
      case 'FOOTBALL_MIXED':
        return l10n.tournamentCategoryFootballMixed;
      default:
        return key;
    }
  }

  String _divisionMatchType(String key) {
    if (key.contains('SINGLES')) return 'SINGLES';
    if (key == 'MIXED_DOUBLES') return 'MIXED_DOUBLES';
    return 'DOUBLES';
  }

  String? _divisionGender(String key) {
    if (key.contains('MALE')) return 'MALE';
    if (key.contains('FEMALE')) return 'FEMALE';
    if (key.contains('MIXED')) return 'MIXED';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final cached = ref.read(userProfileProvider).asData?.value;
    final role = (cached?.role ?? '').toUpperCase();
    final isOrganizerOrAdmin = role == 'ORGANIZER' || role == 'ADMIN';
    if (!isOrganizerOrAdmin) {
      showOrganizerRequiredDialog(
        context,
        onCancel: () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      );
      return;
    }

    final name = _nameController.text.trim();
    final maxTeams = int.tryParse(_maxTeamsController.text.trim()) ?? 16;
    if (_startDate == null) {
      _showError('Vui lòng chọn ngày giờ bắt đầu giải');
      return;
    }
    if (_selectedFormatKeys.isEmpty) {
      _showError('Vui lòng chọn ít nhất một nội dung thi đấu');
      return;
    }

    final startDateTime = _withTime(_startDate!, _startTime);
    final endDateTime = _endDate != null
        ? _withTime(_endDate!, _endTime)
        : startDateTime.add(
            Duration(minutes: (_durationHours * 60) + _durationMinutes),
          );
    final registrationStartDateTime = _regStartDate == null
        ? null
        : _withTime(_regStartDate!, _regStartTime);
    final registrationEndDateTime = _regEndDate == null
        ? null
        : _withTime(_regEndDate!, _regEndTime);

    if (!endDateTime.isAfter(startDateTime)) {
      _showError('Thời gian kết thúc phải sau thời gian bắt đầu');
      return;
    }
    if (registrationStartDateTime != null &&
        registrationEndDateTime != null &&
        !registrationEndDateTime.isAfter(registrationStartDateTime)) {
      _showError('Thời gian đóng đăng ký phải sau thời gian mở đăng ký');
      return;
    }
    if (registrationEndDateTime != null &&
        !registrationEndDateTime.isBefore(startDateTime)) {
      _showError('Hạn đăng ký phải trước giờ bắt đầu giải');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String apiFormat = 'doubles';
      String? genderRestriction;

      if (_formatKey == 'MALE_SINGLES') {
        apiFormat = 'singles';
        genderRestriction = 'MALE';
      } else if (_formatKey == 'FEMALE_SINGLES') {
        apiFormat = 'singles';
        genderRestriction = 'FEMALE';
      } else if (_formatKey == 'MALE_DOUBLES') {
        apiFormat = 'doubles';
        genderRestriction = 'MALE';
      } else if (_formatKey == 'FEMALE_DOUBLES') {
        apiFormat = 'doubles';
        genderRestriction = 'FEMALE';
      } else if (_formatKey == 'MIXED_DOUBLES') {
        apiFormat = 'doubles';
        genderRestriction = 'MIXED';
      } else if (_formatKey == 'FOOTBALL_MALE') {
        apiFormat = 'doubles';
        genderRestriction = 'MALE';
      } else if (_formatKey == 'FOOTBALL_FEMALE') {
        apiFormat = 'doubles';
        genderRestriction = 'FEMALE';
      } else if (_formatKey == 'FOOTBALL_MIXED') {
        apiFormat = 'doubles';
        genderRestriction = 'MIXED';
      }

      final province = ref
          .read(provincesProvider)
          .asData
          ?.value
          .firstWhere(
            (item) => item.code == _provinceCode,
            orElse: () => Province(code: _provinceCode ?? '', name: ''),
          );
      final wards = _provinceCode == null
          ? const <Ward>[]
          : ref.read(wardsProvider(_provinceCode!)).asData?.value ??
                const <Ward>[];
      final ward = wards.firstWhere(
        (item) => item.code == _wardCode,
        orElse: () => Ward(
          code: _wardCode ?? '',
          name: '',
          provinceCode: _provinceCode ?? '',
        ),
      );
      final primaryFormat = _formatKey;
      final divisions = _selectedFormatKeys.map((formatKey) {
        return <String, dynamic>{
          'name': _formatLabel(formatKey),
          'matchType': _divisionMatchType(formatKey),
          if (_divisionGender(formatKey) != null)
            'genderRestriction': _divisionGender(formatKey),
          'maxParticipants': maxTeams,
          'bracketType': _bracket.toUpperCase(),
          'startDate': startDateTime.toUtc().toIso8601String(),
          if (registrationEndDateTime != null)
            'registrationEndDate': registrationEndDateTime
                .toUtc()
                .toIso8601String(),
        };
      }).toList();

      final payload = <String, dynamic>{
        'name': name,
        'sport': _mapSportSlug(),
        'format': apiFormat,
        if (_divisionGender(primaryFormat) != null)
          'genderRestriction': genderRestriction,
        'bracketType': _bracket,
        'maxTeams': maxTeams,
        'divisions': divisions,
        'tournamentType': 'PUBLIC',
        'visibility': 'PUBLIC',
        'registrationMode': _registrationMode,
        'isRanked': false,
        if (_mapSportSlug() == 'football') ...{
          'teamSize': _teamSize,
          'maxReserve': _maxReserve,
          'footballHalvesCount': _footballHalvesCount,
          'footballHalfDuration': _footballHalfDuration,
          'footballAllowDraw': _footballAllowDraw,
        },
        if (_descController.text.trim().isNotEmpty)
          'description': _descController.text.trim(),
        if (_venueNameController.text.trim().isNotEmpty)
          'venueName': _venueNameController.text.trim(),
        if (_locationAddressController.text.trim().isNotEmpty)
          'locationAddress': _locationAddressController.text.trim(),
        'startDate': startDateTime.toUtc().toIso8601String(),
        'startTime':
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        'endDate': endDateTime.toUtc().toIso8601String(),
        'durationMinutes': endDateTime.difference(startDateTime).inMinutes,
        'durationHours': endDateTime.difference(startDateTime).inMinutes / 60.0,
        if (registrationStartDateTime != null)
          'registrationStartDate': registrationStartDateTime
              .toUtc()
              .toIso8601String(),
        if (registrationEndDateTime != null)
          'registrationEndDate': registrationEndDateTime
              .toUtc()
              .toIso8601String(),
        if (province != null && province.name.isNotEmpty) ...{
          'province': province.name,
          'provinceCode': province.code,
        },
        if (ward.name.isNotEmpty) ...{'ward': ward.name, 'wardCode': ward.code},
      };

      _log.info('Gửi yêu cầu tạo giải nhanh Public: $name');
      final response = await ref
          .read(dioClientProvider)
          .dio
          .post('/tournaments/lite', data: payload);

      final raw = response.data;
      final dataJson = raw is Map<String, dynamic>
          ? (raw['data'] as Map<String, dynamic>? ?? raw)
          : <String, dynamic>{};

      final result = LiteTournamentCreateResult.fromJson(dataJson);
      _log.info('Tạo giải nhanh thành công ID: ${result.id}');

      if (mounted) {
        // Tự động điều hướng thẳng vào trang quản lý giải đấu ngay khi tạo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tạo giải đấu "${result.name}" thành công!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pushReplacement('/lite-manage/${result.id}');
      }
    } catch (error, stack) {
      _log.error('Lỗi khi tạo giải nhanh', error, stack);
      if (mounted) {
        _showError(ErrorParser.parse(error, l10n.quickCreateSubmitError));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.colors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        title: Text(l10n.quickCreateTitle),
        centerTitle: false,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            // ─── Banner Thông tin ───
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Khởi tạo giải đấu công khai trong 30 giây',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sơ đồ nhánh đấu và danh sách thi đấu sẽ được tự động thiết lập.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ─── Tên giải đấu ───
            _sectionLabel('Tên giải đấu *', colors),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'VD: Giải Giao Lưu Mùa Hè 2026',
                prefixIcon: const Icon(Icons.emoji_events_outlined, size: 20),
                filled: true,
                fillColor: colors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return l10n.quickCreateNameRequired;
                }
                if (val.trim().length < 3) {
                  return 'Tên giải đấu phải có ít nhất 3 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // ─── Môn thể thao ───
            _sectionLabel('Môn thể thao *', colors),
            const SizedBox(height: 8),
            _buildSportGrid(colors),
            const SizedBox(height: 18),

            // ─── Thể thức thi đấu ───
            _sectionLabel('Sơ đồ thi đấu *', colors),
            const SizedBox(height: 8),
            _buildBracketSelector(colors),
            const SizedBox(height: 18),

            // ─── Nội dung thi đấu (Bao gồm Giới tính) ───
            _sectionLabel('Nội dung thi đấu & Giới tính', colors),
            const SizedBox(height: 8),
            _buildFormatPills(colors),
            if (_sport == AppConstants.sportFootball) ...[
              const SizedBox(height: 12),
              _buildFootballOptions(colors),
            ],
            const SizedBox(height: 18),

            // ─── Quy mô & Giới hạn số đội ───
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Số đội / VĐV tối đa', colors),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _maxTeamsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '16',
                          prefixIcon: const Icon(
                            Icons.people_outline_rounded,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: colors.bgSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.border),
                          ),
                        ),
                        validator: (val) {
                          final n = int.tryParse(val?.trim() ?? '');
                          if (n == null || n < 2 || n > 128) {
                            return 'Số đội từ 2 đến 128';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 22),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.public_rounded,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Giải công khai thế giới',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ─── Lịch trình giống form Quick trên web ───
            _sectionLabel('Lịch trình & thời gian thi đấu', colors),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeField(
                    label: 'Bắt đầu giải *',
                    value: _startDate == null
                        ? null
                        : _withTime(_startDate!, _startTime),
                    icon: Icons.calendar_today_rounded,
                    onTap: _pickStartDateTime,
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDateTimeField(
                    label: 'Kết thúc giải',
                    value: _endDate == null
                        ? null
                        : _withTime(_endDate!, _endTime),
                    icon: Icons.event_available_rounded,
                    onTap: _pickEndDateTime,
                    onClear: () => setState(() => _endDate = null),
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ─── Thời lượng thi đấu ───
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.lite_duration,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  DropdownButton<int>(
                    value: _durationHours,
                    underline: const SizedBox.shrink(),
                    dropdownColor: colors.bgCard,
                    items: List.generate(24, (i) => i)
                        .map(
                          (h) => DropdownMenuItem(
                            value: h,
                            child: Text(
                              '$h ${l10n.lite_hours}',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        )
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
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              '$m ${l10n.lite_minutes}',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        )
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
            const SizedBox(height: 18),

            // ─── Chế độ xét duyệt đăng ký ───
            _sectionLabel('Chế độ đăng ký tham gia', colors),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _registrationMode,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: colors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
              selectedItemBuilder: (context) => const [
                Text(
                  'Ban tổ chức duyệt đơn đăng ký',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Đăng ký tự do (Vào thẳng)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Chỉ nhận người có mã mời',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              items: const [
                DropdownMenuItem(
                  value: 'APPROVAL',
                  child: Text(
                    'Ban tổ chức duyệt đơn đăng ký',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'OPEN',
                  child: Text(
                    'Đăng ký tự do (Vào thẳng nhánh đấu)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'INVITE_ONLY',
                  child: Text(
                    'Chỉ nhận người có mã mời',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _registrationMode = val);
              },
            ),
            const SizedBox(height: 14),

            const SizedBox(height: 8),

            // ─── Địa điểm thi đấu ───
            _sectionLabel('Địa điểm thi đấu (Tùy chọn)', colors),
            const SizedBox(height: 6),
            TextFormField(
              controller: _venueNameController,
              decoration: InputDecoration(
                hintText: 'VD: Sân Cầu Lông Kỳ Hòa',
                prefixIcon: const Icon(Icons.stadium_outlined, size: 20),
                filled: true,
                fillColor: colors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationAddressController,
              decoration: InputDecoration(
                hintText: 'VD: 238 Kỳ Đồng, Quận 3, TP.HCM',
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                filled: true,
                fillColor: colors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildRegionFields(colors),
            const SizedBox(height: 18),

            // ─── Lịch mở / đóng đăng ký ───
            _sectionLabel('Thời gian đăng ký', colors),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeField(
                    label: 'Mở đăng ký',
                    value: _regStartDate == null
                        ? null
                        : _withTime(_regStartDate!, _regStartTime),
                    icon: Icons.login_rounded,
                    onTap: _pickRegStartDateTime,
                    onClear: () => setState(() => _regStartDate = null),
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDateTimeField(
                    label: 'Đóng đăng ký',
                    value: _regEndDate == null
                        ? null
                        : _withTime(_regEndDate!, _regEndTime),
                    icon: Icons.logout_rounded,
                    onTap: _pickRegEndDateTime,
                    onClear: () => setState(() => _regEndDate = null),
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ─── Mô tả giải đấu ───
            _sectionLabel('Mô tả giải đấu (Tùy chọn)', colors),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Mô tả thể lệ, lệ phí, yêu cầu trình độ...',
                filled: true,
                fillColor: colors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ─── Nút Tạo giải đấu ───
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.flash_on_rounded, size: 20),
                label: Text(
                  _isSubmitting
                      ? 'Đang tạo giải đấu...'
                      : 'Hoàn Tất & Tạo Giải Đấu',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, AppColorsExtension colors) => Text(
    title,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: colors.textSecondary,
    ),
  );

  Widget _buildSportGrid(AppColorsExtension colors) {
    return Consumer(
      builder: (context, ref, _) {
        final activeCategories =
            ref.watch(categoriesProvider).value ?? const [];

        final sportsMeta = {
          'pickleball': ('Pickleball', Icons.sports_baseball_rounded),
          'badminton': ('Cầu lông', Icons.sports_tennis_rounded),
          'tennis': ('Tennis', Icons.sports_tennis_outlined),
          'table_tennis': ('Bóng bàn', Icons.sports_cricket_rounded),
          'football': ('Bóng đá', Icons.sports_soccer_rounded),
        };

        // Chỉ hiển thị các môn thể thao đang ACTIVE từ backend, tuyệt đối không fallback hiển thị môn đã tắt
        final sports = activeCategories.where((cat) => cat.isActive).map((cat) {
          final slug = cat.slug.toLowerCase();
          final metaKey = sportsMeta.keys.firstWhere(
            (k) => slug.contains(k) || k.contains(slug),
            orElse: () => 'pickleball',
          );
          final meta = sportsMeta[metaKey] ?? (cat.name, Icons.sports_rounded);
          return (metaKey, cat.name.isNotEmpty ? cat.name : meta.$1, meta.$2);
        }).toList();

        if (sports.isNotEmpty && !sports.any((s) => s.$1 == _sport)) {
          final firstSport = sports.first.$1;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _sport != firstSport) {
              setState(() => _sport = firstSport);
            }
          });
        }

        if (sports.isEmpty) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        return Row(
          children: sports.map((s) {
            final selected = _sport == s.$1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: s != sports.last ? 8 : 0),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _sport = s.$1;
                    _selectedFormatKeys
                      ..clear()
                      ..add(
                        s.$1 == AppConstants.sportFootball
                            ? 'FOOTBALL_MALE'
                            : 'MALE_DOUBLES',
                      );
                    if (s.$1 == AppConstants.sportFootball) {
                      _formatKey = 'FOOTBALL_MALE';
                    } else if (_formatKey.startsWith('FOOTBALL_')) {
                      _formatKey = 'MALE_DOUBLES';
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary.withValues(alpha: 0.12)
                          : colors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppTheme.primary : colors.border,
                        width: selected ? 1.8 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          s.$3,
                          size: 24,
                          color: selected
                              ? AppTheme.primary
                              : colors.textSecondary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.$2,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppTheme.primary
                                : colors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRegionFields(AppColorsExtension colors) {
    final provincesAsync = ref.watch(provincesProvider);
    final wardsAsync = _provinceCode == null
        ? null
        : ref.watch(wardsProvider(_provinceCode!));
    final provinces = provincesAsync.asData?.value ?? const <Province>[];
    final wards = wardsAsync?.asData?.value ?? const <Ward>[];

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: provinces.any((item) => item.code == _provinceCode)
                ? _provinceCode
                : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Tỉnh / thành phố',
              prefixIcon: const Icon(Icons.map_outlined, size: 19),
              filled: true,
              fillColor: colors.bgSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
            hint: Text(
              provincesAsync.isLoading ? 'Đang tải...' : 'Chọn tỉnh/thành',
              overflow: TextOverflow.ellipsis,
            ),
            items: provinces
                .map(
                  (province) => DropdownMenuItem<String>(
                    value: province.code,
                    child: Text(province.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: provinces.isEmpty
                ? null
                : (value) => setState(() {
                    _provinceCode = value;
                    _wardCode = null;
                  }),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: wards.any((item) => item.code == _wardCode)
                ? _wardCode
                : null,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Phường / xã',
              prefixIcon: const Icon(Icons.location_city_outlined, size: 19),
              filled: true,
              fillColor: colors.bgSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
            hint: Text(
              _provinceCode == null
                  ? 'Chọn tỉnh trước'
                  : wardsAsync?.isLoading == true
                  ? 'Đang tải...'
                  : 'Chọn phường/xã',
              overflow: TextOverflow.ellipsis,
            ),
            items: wards
                .map(
                  (ward) => DropdownMenuItem<String>(
                    value: ward.code,
                    child: Text(ward.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: _provinceCode == null || wards.isEmpty
                ? null
                : (value) => setState(() => _wardCode = value),
          ),
        ),
      ],
    );
  }

  Widget _buildFootballOptions(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cấu hình bóng đá',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _teamSize,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Số người/đội'),
                  items: const [5, 7, 11]
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value người'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _teamSize = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: _maxReserve.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Dự bị tối đa'),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed >= 0 && parsed <= 20) {
                      _maxReserve = parsed;
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _footballHalvesCount,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Số hiệp'),
                  items: [1, 2, 3, 4]
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value hiệp'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _footballHalvesCount = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _footballHalfDuration,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Phút/hiệp'),
                  items: [15, 30, 45, 60]
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value phút'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _footballHalfDuration = value);
                    }
                  },
                ),
              ),
            ],
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Cho phép kết quả hòa'),
            value: _footballAllowDraw,
            onChanged: (value) => setState(() => _footballAllowDraw = value),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatPills(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final isFootball = _sport == AppConstants.sportFootball;
    final formats = isFootball
        ? [
            ('FOOTBALL_MALE', l10n.tournamentCategoryFootballMen),
            ('FOOTBALL_FEMALE', l10n.tournamentCategoryFootballWomen),
            ('FOOTBALL_MIXED', l10n.tournamentCategoryFootballMixed),
          ]
        : [
            ('MALE_DOUBLES', l10n.tournamentCategoryMenDoubles),
            ('FEMALE_DOUBLES', l10n.tournamentCategoryWomenDoubles),
            ('MIXED_DOUBLES', l10n.tournamentCategoryMixedDoubles),
            ('MALE_SINGLES', l10n.tournamentCategoryMenSingles),
            ('FEMALE_SINGLES', l10n.tournamentCategoryWomenSingles),
          ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: formats.map((f) {
        final selected = _selectedFormatKeys.contains(f.$1);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              if (_selectedFormatKeys.length > 1) {
                _selectedFormatKeys.remove(f.$1);
                if (_formatKey == f.$1) {
                  _formatKey = _selectedFormatKeys.first;
                }
              }
            } else {
              _selectedFormatKeys.add(f.$1);
              _formatKey = _selectedFormatKeys.first;
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primary.withValues(alpha: 0.12)
                  : colors.bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppTheme.primary : colors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Text(
              f.$2,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? AppTheme.primary : colors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBracketSelector(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final brackets = [
      (
        AppConstants.bracketSingleElimination,
        l10n.quickCreateBracketSingle,
        l10n.quickCreateBracketSingleDesc,
        Icons.account_tree_outlined,
      ),
      (
        AppConstants.bracketDoubleElimination,
        l10n.quickCreateBracketDouble,
        l10n.quickCreateBracketDoubleDesc,
        Icons.call_split_rounded,
      ),
      (
        AppConstants.bracketRoundRobin,
        l10n.quickCreateBracketRoundRobin,
        l10n.quickCreateBracketRoundRobinDesc,
        Icons.sync_rounded,
      ),
      (
        AppConstants.bracketGroupStageKnockout,
        l10n.quickCreateBracketGroup,
        l10n.quickCreateBracketGroupDesc,
        Icons.grid_view_rounded,
      ),
    ];

    return Column(
      children: brackets.map((b) {
        final selected = _bracket == b.$1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => _bracket = b.$1),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppTheme.primary : colors.border,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: BracketFormatIcons.getIcon(
                        b.$1,
                        size: 18,
                        color: selected ? Colors.white : AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.$2,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppTheme.primary
                                : colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          b.$3,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? AppTheme.primary : colors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _pickStartDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _startDate == null ? _startTime : _startTime,
    );
    if (pickedTime == null || !mounted) return;

    final start = _withTime(pickedDate, pickedTime);
    setState(() {
      _startDate = pickedDate;
      _startTime = pickedTime;
      if (_endDate == null) {
        final estimatedEnd = start.add(
          Duration(minutes: (_durationHours * 60) + _durationMinutes),
        );
        _endDate = DateTime(
          estimatedEnd.year,
          estimatedEnd.month,
          estimatedEnd.day,
        );
        _endTime = TimeOfDay.fromDateTime(estimatedEnd);
      }
      _regStartDate ??= DateTime(now.year, now.month, now.day);
      _regEndDate ??= pickedDate.subtract(const Duration(days: 1));
    });
  }

  Future<void> _pickEndDateTime() async {
    final now = DateTime.now();
    final earliest = _startDate ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? earliest,
      firstDate: earliest,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _endDate == null ? _endTime : _endTime,
    );
    if (pickedTime == null || !mounted) return;
    setState(() {
      _endDate = pickedDate;
      _endTime = pickedTime;
    });
  }

  Future<void> _pickRegStartDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _regStartDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: _startDate ?? now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _regStartTime,
    );
    if (pickedTime == null || !mounted) return;
    setState(() {
      _regStartDate = pickedDate;
      _regStartTime = pickedTime;
    });
  }

  Future<void> _pickRegEndDateTime() async {
    final now = DateTime.now();
    final earliest = _regStartDate ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _regEndDate ?? earliest,
      firstDate: earliest,
      lastDate: _startDate ?? now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _regEndTime,
    );
    if (pickedTime == null || !mounted) return;
    setState(() {
      _regEndDate = pickedDate;
      _regEndTime = pickedTime;
    });
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onTap,
    required AppColorsExtension colors,
    VoidCallback? onClear,
  }) {
    final display = value == null
        ? 'Chọn ngày và giờ'
        : DateFormat('dd/MM/yyyy HH:mm').format(value);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: value == null
              ? colors.bgSurface
              : AppTheme.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value == null ? colors.border : AppTheme.primary,
            width: value == null ? 1 : 1.4,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: value == null ? colors.textMuted : AppTheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: colors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: value == null
                          ? FontWeight.normal
                          : FontWeight.w700,
                      color: value == null
                          ? colors.textMuted
                          : colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (value != null && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: colors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
