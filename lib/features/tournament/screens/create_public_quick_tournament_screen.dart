import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:app_quanly_giaidau/core/widgets/sport_choice_tile.dart';

class _QuickTournamentContentDraft {
  const _QuickTournamentContentDraft({
    required this.id,
    required this.formatKey,
    required this.name,
    this.maxParticipantsOverride,
    this.bracketType,
    this.eloEnabled = false,
    this.minElo,
    this.maxElo,
  });

  final String id;
  final String formatKey;
  final String name;
  final int? maxParticipantsOverride;
  final String? bracketType;
  final bool eloEnabled;
  final int? minElo;
  final int? maxElo;
}

/// Owns the editor controllers for the dialog route.
///
/// `showDialog` completes its future when Navigator.pop is called, before the
/// reverse transition has removed the dialog subtree. Keeping the controllers
/// on a widget that lives inside that route prevents them from being disposed
/// while TextField/Focus/Inherited dependencies are still active.
class _QuickTournamentContentDialogOwner extends StatefulWidget {
  const _QuickTournamentContentDialogOwner({
    required this.controllers,
    required this.builder,
  });

  final List<TextEditingController> controllers;
  final WidgetBuilder builder;

  @override
  State<_QuickTournamentContentDialogOwner> createState() =>
      _QuickTournamentContentDialogOwnerState();
}

class _QuickTournamentContentDialogOwnerState
    extends State<_QuickTournamentContentDialogOwner> {
  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

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
  List<_QuickTournamentContentDraft> _contentDrafts = const [
    _QuickTournamentContentDraft(
      id: 'MALE_DOUBLES',
      formatKey: 'MALE_DOUBLES',
      name: '',
    ),
  ];
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

  int _globalMaxParticipants() =>
      int.tryParse(_maxTeamsController.text.trim()) ?? 16;

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
    final maxTeams = _globalMaxParticipants();
    if (_startDate == null) {
      _showError('Vui lòng chọn ngày giờ bắt đầu giải');
      return;
    }
    if (_contentDrafts.isEmpty) {
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
      final primaryFormat = _contentDrafts.first.formatKey;
      String apiFormat = 'doubles';
      String? genderRestriction;

      if (primaryFormat == 'MALE_SINGLES') {
        apiFormat = 'singles';
        genderRestriction = 'MALE';
      } else if (primaryFormat == 'FEMALE_SINGLES') {
        apiFormat = 'singles';
        genderRestriction = 'FEMALE';
      } else if (primaryFormat == 'MALE_DOUBLES') {
        apiFormat = 'doubles';
        genderRestriction = 'MALE';
      } else if (primaryFormat == 'FEMALE_DOUBLES') {
        apiFormat = 'doubles';
        genderRestriction = 'FEMALE';
      } else if (primaryFormat == 'MIXED_DOUBLES') {
        apiFormat = 'doubles';
        genderRestriction = 'MIXED';
      } else if (primaryFormat == 'FOOTBALL_MALE') {
        apiFormat = 'doubles';
        genderRestriction = 'MALE';
      } else if (primaryFormat == 'FOOTBALL_FEMALE') {
        apiFormat = 'doubles';
        genderRestriction = 'FEMALE';
      } else if (primaryFormat == 'FOOTBALL_MIXED') {
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
      final divisions = _contentDrafts.map((draft) {
        final formatKey = draft.formatKey;
        return <String, dynamic>{
          'name': draft.name.trim().isEmpty
              ? _formatLabel(formatKey)
              : draft.name.trim(),
          'matchType': _divisionMatchType(formatKey),
          if (_divisionGender(formatKey) != null)
            'genderRestriction': _divisionGender(formatKey),
          'maxParticipants': draft.maxParticipantsOverride ?? maxTeams,
          'bracketType': (draft.bracketType ?? _bracket).toUpperCase(),
          if (draft.eloEnabled && draft.minElo != null) 'minElo': draft.minElo,
          if (draft.eloEnabled && draft.maxElo != null) 'maxElo': draft.maxElo,
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
                  const Icon(Icons.public, size: 18),
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
                    prefixIcon: const Icon(Icons.groups_outlined, size: 20),
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

            // ─── Lịch trình thi đấu & đăng ký theo style danh sách ───
            _sectionLabel('THỜI GIAN ĐĂNG KÝ & THI ĐẤU', colors),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border.withValues(alpha: 0.6)),
              ),
              child: Column(
                children: [
                  _buildScheduleRow(
                    avatarLetter: 'S',
                    title: 'Thời gian bắt đầu *',
                    value: _startDate == null
                        ? null
                        : _withTime(_startDate!, _startTime),
                    onTap: _pickStartDateTime,
                    colors: colors,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.border.withValues(alpha: 0.4),
                    indent: 56,
                  ),
                  _buildScheduleRow(
                    avatarLetter: 'E',
                    title: 'Thời gian kết thúc',
                    value: _endDate == null
                        ? null
                        : _withTime(_endDate!, _endTime),
                    onTap: _pickEndDateTime,
                    colors: colors,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.border.withValues(alpha: 0.4),
                    indent: 56,
                  ),
                  _buildScheduleRow(
                    avatarLetter: 'R',
                    title: 'Mở đăng ký',
                    value: _regStartDate == null
                        ? null
                        : _withTime(_regStartDate!, _regStartTime),
                    onTap: _pickRegStartDateTime,
                    colors: colors,
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.border.withValues(alpha: 0.4),
                    indent: 56,
                  ),
                  _buildScheduleRow(
                    avatarLetter: 'C',
                    title: 'Hạn chót đăng ký (Đóng)',
                    value: _regEndDate == null
                        ? null
                        : _withTime(_regEndDate!, _regEndTime),
                    onTap: _pickRegEndDateTime,
                    colors: colors,
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
                prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
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
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
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
                      Icons.auto_awesome,
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
          'pickleball': ('Pickleball', Icons.sports_tennis),
          'badminton': ('Cầu lông', Icons.sports_handball),
          'tennis': ('Tennis', Icons.sports_tennis),
          'table_tennis': ('Bóng bàn', Icons.sports_mma),
          'football': ('Bóng đá', Icons.sports_soccer),
        };

        // Chỉ hiển thị các môn thể thao đang ACTIVE từ backend, tuyệt đối không fallback hiển thị môn đã tắt
        final sports = activeCategories.where((cat) => cat.isActive).map((cat) {
          final slug = cat.slug.toLowerCase();
          final metaKey = sportsMeta.keys.firstWhere(
            (k) => slug.contains(k) || k.contains(slug),
            orElse: () => 'pickleball',
          );
          final meta =
              sportsMeta[metaKey] ?? (cat.name, Icons.emoji_events_outlined);
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
            return SportChoiceTile(
              sportKey: s.$1,
              label: s.$2,
              selected: selected,
              iconSize: 24,
              withTrailingGap: s != sports.last,
              onTap: () => setState(() {
                _sport = s.$1;
                final defaultFormat = s.$1 == AppConstants.sportFootball
                    ? 'FOOTBALL_MALE'
                    : 'MALE_DOUBLES';
                _contentDrafts = [
                  _QuickTournamentContentDraft(
                    id: defaultFormat,
                    formatKey: defaultFormat,
                    name: '',
                  ),
                ];
              }),
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
              prefixIcon: const Icon(Icons.map_outlined, size: 18),
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
              prefixIcon: const Icon(Icons.business_outlined, size: 18),
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
            onTap: () =>
                setState(() => _footballAllowDraw = !_footballAllowDraw),
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
    final maxParticipants = _globalMaxParticipants();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._contentDrafts.map(
          (draft) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _editContentDraft(draft),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.layers_outlined,
                              size: 16,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  draft.name.trim().isEmpty
                                      ? _formatLabel(draft.formatKey)
                                      : draft.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${draft.maxParticipantsOverride ?? maxParticipants} người/đội tối đa',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Sửa nội dung',
                  onPressed: () => _editContentDraft(draft),
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  color: colors.textMuted,
                ),
                if (_contentDrafts.length > 1)
                  IconButton(
                    tooltip: 'Xóa nội dung',
                    onPressed: () => _removeContentDraft(draft),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: colors.textMuted,
                  ),
              ],
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _openContentDraftDialog(),
          icon: const Icon(Icons.add, size: 17),
          label: const Text('Thêm nội dung'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.45)),
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editContentDraft(_QuickTournamentContentDraft draft) async {
    await _openContentDraftDialog(existing: draft);
  }

  void _removeContentDraft(_QuickTournamentContentDraft draft) {
    if (_contentDrafts.length <= 1) {
      _showError('Giải phải có ít nhất một nội dung thi đấu');
      return;
    }
    setState(() {
      _contentDrafts = _contentDrafts
          .where((item) => item.id != draft.id)
          .toList();
    });
  }

  Future<void> _openContentDraftDialog({
    _QuickTournamentContentDraft? existing,
  }) async {
    if (!mounted) return;

    final isFootball = _sport == AppConstants.sportFootball;
    final formatOptions = isFootball
        ? <String>['FOOTBALL_MALE', 'FOOTBALL_FEMALE', 'FOOTBALL_MIXED']
        : <String>[
            'MALE_SINGLES',
            'FEMALE_SINGLES',
            'MALE_DOUBLES',
            'FEMALE_DOUBLES',
            'MIXED_DOUBLES',
          ];
    var formatKey = existing?.formatKey ?? formatOptions.first;
    if (!formatOptions.contains(formatKey)) formatKey = formatOptions.first;
    var nameTouched = existing != null && existing.name.trim().isNotEmpty;
    var limitTouched = existing?.maxParticipantsOverride != null;
    var bracketType = existing?.bracketType;
    var advanced =
        existing != null &&
        (existing.bracketType != null || existing.eloEnabled);
    var eloEnabled = existing?.eloEnabled ?? false;
    var minElo = existing?.minElo;
    var maxElo = existing?.maxElo;
    String? nameError;
    String? limitError;
    String? eloError;

    final nameController = TextEditingController(
      text: existing?.name.trim().isNotEmpty == true
          ? existing!.name
          : _formatLabel(formatKey),
    );
    final limitController = TextEditingController(
      text: '${existing?.maxParticipantsOverride ?? _globalMaxParticipants()}',
    );
    final minEloController = TextEditingController(
      text: minElo?.toString() ?? '',
    );
    final maxEloController = TextEditingController(
      text: maxElo?.toString() ?? '',
    );

    final saved = await showDialog<_QuickTournamentContentDraft>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _QuickTournamentContentDialogOwner(
        controllers: [
          nameController,
          limitController,
          minEloController,
          maxEloController,
        ],
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final dialogColors = dialogContext.colors;
            final bracketOptions = [
              (AppConstants.bracketSingleElimination, 'Loại trực tiếp'),
              (
                AppConstants.bracketDoubleElimination,
                'Nhánh thắng / nhánh thua',
              ),
              (AppConstants.bracketRoundRobin, 'Vòng tròn tính điểm'),
              (AppConstants.bracketGroupStageKnockout, 'Vòng bảng + Knockout'),
            ];

            void saveDraft() {
              final name = nameController.text.trim();
              final maxParticipants = int.tryParse(limitController.text.trim());
              final parsedMinElo = int.tryParse(minEloController.text.trim());
              final parsedMaxElo = int.tryParse(maxEloController.text.trim());
              final usesRoundRobin =
                  (bracketType ?? _bracket) == AppConstants.bracketRoundRobin;

              setDialogState(() {
                nameError = name.isEmpty ? 'Vui lòng nhập tên nội dung' : null;
                limitError =
                    maxParticipants == null ||
                        maxParticipants < 2 ||
                        maxParticipants > 128
                    ? 'Số người/đội phải từ 2 đến 128'
                    : usesRoundRobin && maxParticipants > 15
                    ? 'Vòng tròn tối đa 15 người/đội'
                    : null;
                eloError =
                    eloEnabled &&
                        ((parsedMinElo != null && parsedMinElo < 0) ||
                            (parsedMaxElo != null && parsedMaxElo < 0) ||
                            (parsedMinElo != null &&
                                parsedMaxElo != null &&
                                parsedMinElo > parsedMaxElo))
                    ? 'Khoảng ELO không hợp lệ'
                    : null;
              });

              if (nameError != null || limitError != null || eloError != null) {
                return;
              }

              Navigator.of(dialogContext).pop(
                _QuickTournamentContentDraft(
                  id:
                      existing?.id ??
                      'content-${DateTime.now().microsecondsSinceEpoch}',
                  formatKey: formatKey,
                  name: name,
                  maxParticipantsOverride: limitTouched
                      ? maxParticipants
                      : null,
                  bracketType: bracketType,
                  eloEnabled: eloEnabled,
                  minElo: eloEnabled ? parsedMinElo : null,
                  maxElo: eloEnabled ? parsedMaxElo : null,
                ),
              );
            }

            return AlertDialog(
              title: Text(
                existing == null
                    ? 'Thêm nội dung thi đấu mới'
                    : 'Sửa nội dung thi đấu',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.68,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Mỗi nội dung có thể cấu hình riêng như trên web.',
                        style: TextStyle(
                          fontSize: 12,
                          color: dialogColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Loại nội dung',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: dialogColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: formatKey,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: dialogColors.bgSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: formatOptions
                            .map(
                              (key) => DropdownMenuItem(
                                value: key,
                                child: Text(_formatLabel(key)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            formatKey = value;
                            if (!nameTouched) {
                              nameController.text = _formatLabel(value);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nameController,
                        onChanged: (_) => setDialogState(() {
                          nameTouched = true;
                          nameError = null;
                        }),
                        decoration: InputDecoration(
                          labelText: 'Tên nội dung riêng',
                          helperText:
                              'Tên này hiển thị trong danh sách nội dung và bảng đấu.',
                          errorText: nameError,
                          filled: true,
                          fillColor: dialogColors.bgSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Số lượng người/đội tham gia',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            SizedBox(
                              width: 140,
                              child: TextField(
                                controller: limitController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setDialogState(() {
                                  limitTouched = true;
                                  limitError = null;
                                }),
                                decoration: InputDecoration(
                                  suffixText: 'người/đội',
                                  errorText: limitError,
                                  filled: true,
                                  fillColor: dialogColors.bgSurface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              limitTouched
                                  ? 'Đã đặt giới hạn riêng cho nội dung này.'
                                  : 'Mặc định theo quy mô chung của giải: ${_globalMaxParticipants()} người/đội.',
                              style: TextStyle(
                                fontSize: 11,
                                color: dialogColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: () =>
                            setDialogState(() => advanced = !advanced),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          side: BorderSide(color: dialogColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.tune,
                              size: 17,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Tùy chọn nâng cao (thể thức, ELO)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              advanced ? 'Thu gọn' : 'Mở rộng',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (advanced) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: dialogColors.bgSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: dialogColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: bracketType ?? '',
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Thể thức riêng',
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: '',
                                    child: Text('Theo thể thức chung của giải'),
                                  ),
                                  ...bracketOptions.map(
                                    (option) => DropdownMenuItem(
                                      value: option.$1,
                                      child: Text(option.$2),
                                    ),
                                  ),
                                ],
                                onChanged: (value) => setDialogState(
                                  () => bracketType =
                                      value == null || value.isEmpty
                                      ? null
                                      : value,
                                ),
                              ),
                              const SizedBox(height: 12),
                              CheckboxListTile(
                                value: eloEnabled,
                                onChanged: (value) => setDialogState(
                                  () => eloEnabled = value ?? false,
                                ),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: const Text(
                                  'Giới hạn ELO',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                              if (eloEnabled) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: minEloController,
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setDialogState(
                                          () => eloError = null,
                                        ),
                                        decoration: const InputDecoration(
                                          labelText: 'ELO tối thiểu',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: maxEloController,
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setDialogState(
                                          () => eloError = null,
                                        ),
                                        decoration: const InputDecoration(
                                          labelText: 'ELO tối đa',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (eloError != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    eloError!,
                                    style: TextStyle(
                                      color: dialogColors.error,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton.icon(
                  onPressed: saveDraft,
                  icon: const Icon(Icons.add, size: 17),
                  label: Text(
                    existing == null ? 'Thêm nội dung' : 'Lưu thay đổi',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    if (!mounted || saved == null) return;
    setState(() {
      if (existing == null) {
        _contentDrafts = [..._contentDrafts, saved];
      } else {
        _contentDrafts = _contentDrafts
            .map((draft) => draft.id == saved.id ? saved : draft)
            .toList();
      }
    });
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
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
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

  String _formatScheduleDisplay(DateTime dt) {
    // e.g. T2 21 Tháng 9 0:00 or T3 28 Tháng 9 08:00
    final weekdayStr = switch (dt.weekday) {
      DateTime.monday => 'T2',
      DateTime.tuesday => 'T3',
      DateTime.wednesday => 'T4',
      DateTime.thursday => 'T5',
      DateTime.friday => 'T6',
      DateTime.saturday => 'T7',
      _ => 'CN',
    };
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    return '$weekdayStr ${dt.day} Tháng ${dt.month} ${dt.hour}:$minuteStr';
  }

  Widget _buildScheduleRow({
    required String avatarLetter,
    required String title,
    required DateTime? value,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    final hasValue = value != null;
    final displayTime = hasValue ? _formatScheduleDisplay(value) : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Avatar Letter (like R, E, C, D in Image 2)
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.textSecondary.withValues(alpha: 0.15),
              ),
              alignment: Alignment.center,
              child: Text(
                avatarLetter,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Middle Content: Title • action & Date Time text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasValue ? 'sửa' : 'thêm',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (displayTime != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      displayTime,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
