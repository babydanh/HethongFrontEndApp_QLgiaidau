import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/utils/vietnam_address_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/lite_tournament_create_result.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/regions_provider.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/bracket_format_icons.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/public_tournament_type_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/core/widgets/app_icons.dart';

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
  bool _isPublic = true;
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
  Province? _suggestedProvince;
  Ward? _suggestedWard;
  int _teamSize = 7;
  int _maxReserve = 5;
  int _footballHalvesCount = 2;
  int _footballHalfDuration = 45;
  bool _footballAllowDraw = true;
  bool _endDateManuallySet = false;
  bool _registrationEndManuallySet = false;
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
    final defaultEnd = DateTime(
      defaultStart.year,
      defaultStart.month,
      defaultStart.day,
      23,
      59,
    );
    _startTime = TimeOfDay.fromDateTime(defaultStart);
    _endDate = DateTime(defaultEnd.year, defaultEnd.month, defaultEnd.day);
    _endTime = TimeOfDay.fromDateTime(defaultEnd);
    final nextRoundedMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: 1));
    _regStartDate = DateTime(
      nextRoundedMinute.year,
      nextRoundedMinute.month,
      nextRoundedMinute.day,
    );
    _regStartTime = TimeOfDay.fromDateTime(nextRoundedMinute);
    _syncDefaultRegistrationEnd(defaultStart);
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

  /// Keeps the default end datetime aligned when the organizer changes the
  /// start before explicitly choosing an end datetime.
  void _syncDefaultEnd(DateTime start) {
    final estimatedEnd = DateTime(start.year, start.month, start.day, 23, 59);
    _endDate = DateTime(
      estimatedEnd.year,
      estimatedEnd.month,
      estimatedEnd.day,
    );
    _endTime = TimeOfDay.fromDateTime(estimatedEnd);
  }

  void _syncDefaultRegistrationEnd(DateTime start) {
    final previousDay = start.subtract(const Duration(days: 1));
    _regEndDate = DateTime(
      previousDay.year,
      previousDay.month,
      previousDay.day,
    );
    _regEndTime = const TimeOfDay(hour: 23, minute: 59);
  }

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
    if (key.contains('FEMALE')) return 'FEMALE';
    if (key.contains('MALE')) return 'MALE';
    if (key.contains('MIXED')) return 'MIXED';
    return null;
  }

  Future<void> _detectAddressSuggestion() async {
    final address = _locationAddressController.text.trim();
    final provinces = ref.read(provincesProvider).asData?.value ?? const [];
    if (address.isEmpty || provinces.isEmpty) {
      if (_suggestedProvince != null || _suggestedWard != null) {
        setState(() {
          _suggestedProvince = null;
          _suggestedWard = null;
        });
      }
      return;
    }

    final province = VietnamAddressParser.detectProvince<Province>(
      rawAddress: address,
      provinces: provinces,
      getCode: (item) => item.code,
      getName: (item) => item.name,
    );
    Ward? ward;
    if (province != null) {
      final wards = await ref.read(wardsProvider(province.code).future);
      if (!mounted || _locationAddressController.text.trim() != address) {
        return;
      }
      ward = VietnamAddressParser.detectWard<Ward>(
        rawAddress: address,
        wards: wards,
        getCode: (item) => item.code,
        getName: (item) => item.name,
      );
    }

    if (!mounted || _locationAddressController.text.trim() != address) return;
    if (province != _suggestedProvince || ward != _suggestedWard) {
      setState(() {
        _suggestedProvince = province;
        _suggestedWard = ward;
      });
    }
  }

  void _applyAddressSuggestion() {
    final province = _suggestedProvince;
    if (province == null) return;
    setState(() {
      _provinceCode = province.code;
      _wardCode = _suggestedWard?.code;
    });
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
        : startDateTime.add(const Duration(minutes: 90));
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
        'visibility': _isPublic ? 'PUBLIC' : 'PRIVATE',
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(AppIcons.globe, size: 18, color: colors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Công khai',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: _isPublic,
                    onChanged: (value) => setState(() => _isPublic = value),
                    activeThumbColor: AppTheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ─── Tên giải đấu ───
            _sectionLabel('Tên giải đấu *', colors),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'VD: Giải Giao Lưu Mùa Hè 2026',
                prefixIcon: const Icon(AppIcons.trophy, size: 20),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Số đội / VĐV tối đa', colors),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _maxTeamsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '16',
                    prefixIcon: const Icon(AppIcons.users, size: 20),
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
                    if (_bracket == AppConstants.bracketRoundRobin && n > 15) {
                      return 'Vòng tròn tối đa 15 đội / VĐV';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ─── Lịch trình giống form Quick trên web ───
            _sectionLabel('Thời gian thi đấu & đăng ký', colors),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeField(
                    label: 'Thời gian bắt đầu *',
                    value: _startDate == null
                        ? null
                        : _withTime(_startDate!, _startTime),
                    icon: AppIcons.calendar,
                    onTap: _pickStartDateTime,
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDateTimeField(
                    label: 'Thời gian kết thúc',
                    value: _endDate == null
                        ? null
                        : _withTime(_endDate!, _endTime),
                    icon: AppIcons.calendarCheck,
                    onTap: _pickEndDateTime,
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeField(
                    label: 'Mở đăng ký',
                    value: _regStartDate == null
                        ? null
                        : _withTime(_regStartDate!, _regStartTime),
                    icon: AppIcons.login,
                    onTap: _pickRegStartDateTime,
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
                    icon: AppIcons.logout,
                    onTap: _pickRegEndDateTime,
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ─── Chế độ xét duyệt đăng ký ───
            _sectionLabel('Chế độ đăng ký tham gia', colors),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _registrationMode,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
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
                prefixIcon: const Icon(AppIcons.landmark, size: 20),
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
              onChanged: (_) => _detectAddressSuggestion(),
              decoration: InputDecoration(
                hintText: 'VD: 238 Kỳ Đồng, Quận 3, TP.HCM',
                prefixIcon: const Icon(AppIcons.mapPin, size: 20),
                filled: true,
                fillColor: colors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
            ),
            if (_suggestedProvince != null || _suggestedWard != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      AppIcons.sparkles,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.lite_aiDetectedAddress} ${_suggestedProvince?.name ?? ''}${_suggestedWard == null ? '' : ' > ${_suggestedWard!.name}'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _applyAddressSuggestion,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Text(
                          l10n.filterApply,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            _buildRegionFields(colors),
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
            const SizedBox(height: 12),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: colors.bgDark,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: SizedBox(
            height: 42,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Tạo giải đấu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
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
          'pickleball': ('Pickleball', AppIcons.sportPickleball),
          'badminton': ('Cầu lông', AppIcons.sportTennis),
          'tennis': ('Tennis', AppIcons.sportTennis),
          'table_tennis': ('Bóng bàn', AppIcons.sportTableTennis),
          'football': ('Bóng đá', AppIcons.sportFootball),
        };

        // Chỉ hiển thị các môn thể thao đang ACTIVE từ backend, tuyệt đối không fallback hiển thị môn đã tắt
        final sports = activeCategories.where((cat) => cat.isActive).map((cat) {
          final slug = cat.slug.toLowerCase();
          final metaKey = sportsMeta.keys.firstWhere(
            (k) => slug.contains(k) || k.contains(slug),
            orElse: () => 'pickleball',
          );
          final meta = sportsMeta[metaKey] ?? (cat.name, AppIcons.trophy);
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              labelText: 'Tỉnh / thành',
              prefixIcon: const Icon(AppIcons.map, size: 18),
              filled: true,
              fillColor: colors.bgSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
            hint: Text(
              provincesAsync.isLoading ? 'Đang tải...' : 'Chọn tỉnh',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            items: provinces
                .map(
                  (province) => DropdownMenuItem<String>(
                    value: province.code,
                    child: Text(
                      province.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
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
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: wards.any((item) => item.code == _wardCode)
                ? _wardCode
                : null,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              labelText: 'Phường / xã',
              prefixIcon: const Icon(AppIcons.building, size: 18),
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
                  : 'Chọn phường',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            items: wards
                .map(
                  (ward) => DropdownMenuItem<String>(
                    value: ward.code,
                    child: Text(
                      ward.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
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
          InkWell(
            onTap: () => setState(() => _footballAllowDraw = !_footballAllowDraw),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cho phép kết quả hòa',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: _footballAllowDraw,
                    onChanged: (value) =>
                        setState(() => _footballAllowDraw = value),
                    activeTrackColor: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatPills(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final isFootball = _sport == AppConstants.sportFootball;
    final allFormats = isFootball
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
    final baseFormats = isFootball
        ? allFormats
        : allFormats
              .where(
                (format) =>
                    format.$1 == 'MALE_DOUBLES' ||
                    format.$1 == 'FEMALE_DOUBLES' ||
                    format.$1 == 'MIXED_DOUBLES',
              )
              .toList();
    final addedFormats = allFormats
        .where(
          (format) =>
              _selectedFormatKeys.contains(format.$1) &&
              !baseFormats.any((base) => base.$1 == format.$1),
        )
        .toList();
    final formats = [...baseFormats, ...addedFormats];
    final canAddMore = allFormats.any(
      (format) => !formats.any((shown) => shown.$1 == format.$1),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...formats.map((f) {
          final selected = _selectedFormatKeys.contains(f.$1);
          return GestureDetector(
            onTap: () => _toggleFormat(f.$1),
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
        }),
        if (canAddMore)
          GestureDetector(
            onTap: _showAdditionalFormats,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AppIcons.add, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Thêm nội dung',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _toggleFormat(String key) {
    setState(() {
      if (_selectedFormatKeys.contains(key)) {
        if (_selectedFormatKeys.length > 1) {
          _selectedFormatKeys.remove(key);
          if (_formatKey == key) _formatKey = _selectedFormatKeys.first;
        }
      } else {
        _selectedFormatKeys.add(key);
        _formatKey = key;
      }
    });
  }

  Future<void> _showAdditionalFormats() async {
    final l10n = AppLocalizations.of(context)!;
    final isFootball = _sport == AppConstants.sportFootball;
    final formats = isFootball
        ? <(String, String)>[
            ('FOOTBALL_MALE', l10n.tournamentCategoryFootballMen),
            ('FOOTBALL_FEMALE', l10n.tournamentCategoryFootballWomen),
            ('FOOTBALL_MIXED', l10n.tournamentCategoryFootballMixed),
          ]
        : <(String, String)>[
            ('MALE_SINGLES', l10n.tournamentCategoryMenSingles),
            ('FEMALE_SINGLES', l10n.tournamentCategoryWomenSingles),
          ];
    final available = formats
        .where((format) => !_selectedFormatKeys.contains(format.$1))
        .toList();
    if (available.isEmpty || !mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thêm nội dung thi đấu',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...available.map(
                (format) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(AppIcons.add, color: AppTheme.primary),
                  title: Text(format.$2),
                  onTap: () {
                    _toggleFormat(format.$1);
                    Navigator.pop(sheetContext);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBracketSelector(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    final brackets = [
      (AppConstants.bracketSingleElimination, l10n.quickCreateBracketSingle),
      (AppConstants.bracketDoubleElimination, l10n.quickCreateBracketDouble),
      (AppConstants.bracketRoundRobin, l10n.quickCreateBracketRoundRobin),
      (AppConstants.bracketGroupStageKnockout, l10n.quickCreateBracketGroup),
    ];

    return Column(
      children: brackets.map((b) {
        final selected = _bracket == b.$1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.08)
                : colors.bgSurface,
            borderRadius: BorderRadius.circular(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected ? AppTheme.primary : colors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: InkWell(
              onTap: () => setState(() => _bracket = b.$1),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: BracketFormatIcons.getIcon(
                          b.$1,
                          size: 16,
                          color: selected ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        b.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppTheme.primary
                              : colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      selected ? AppIcons.circleDot : AppIcons.circle,
                      color: selected ? AppTheme.primary : colors.textMuted,
                      size: 18,
                    ),
                  ],
                ),
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
      if (!_endDateManuallySet) {
        _syncDefaultEnd(start);
      }
      _regStartDate ??= DateTime(now.year, now.month, now.day);
      if (!_registrationEndManuallySet) {
        _syncDefaultRegistrationEnd(start);
      }
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
      _endDateManuallySet = true;
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
      _registrationEndManuallySet = true;
    });
  }

  // Compatibility aliases for incremental compile & hot reload
  // ignore: unused_element
  Future<void> _pickStartDate() => _pickStartDateTime();
  // ignore: unused_element
  Future<void> _pickStartTime() => _pickStartDateTime();
  // ignore: unused_element
  Future<void> _pickEndDate() => _pickEndDateTime();
  // ignore: unused_element
  Future<void> _pickEndTime() => _pickEndDateTime();
  // ignore: unused_element
  Future<void> _pickRegStartDate() => _pickRegStartDateTime();
  // ignore: unused_element
  Future<void> _pickRegEndDate() => _pickRegEndDateTime();

  Widget _buildDateTimeField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    final display = value == null
        ? ''
        : DateFormat('dd/MM/yyyy HH:mm').format(value);
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 12, color: colors.textSecondary),
          prefixIcon: Icon(icon, size: 18, color: colors.textSecondary),
          suffixIcon: value == null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      'Thêm',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                )
              : null,
          isDense: true,
          filled: true,
          fillColor: colors.bgSurface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.border),
          ),
        ),
        child: Text(
          display,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: value == null ? FontWeight.normal : FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
