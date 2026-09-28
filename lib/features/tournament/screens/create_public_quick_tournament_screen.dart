import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/utils/vietnam_address_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/lite_tournament_create_result.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/regions_provider.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/bracket_format_icons.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/public_tournament_create_entry.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/core/widgets/sport_choice_tile.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';

/// Nút viền đứt, dùng cho "Thêm nội dung" để khớp web. `OutlinedButton` của
/// Flutter không vẽ được nét đứt nên phải tự vẽ; chiều cao 48dp để đạt chuẩn
/// chạm tối thiểu trên Android.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppTheme.primary.withValues(alpha: 0.55),
          radius: 10,
        ),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    // Vẽ theo đường viền rồi cắt thành nét đứt bằng PathMetric.
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + 6),
          paint,
        );
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

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
  final _entryFeeController = TextEditingController(text: '0');
  final _maxCombinedEloController = TextEditingController();
  final _maxTeammateGapController = TextEditingController();
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
  bool _isRanked = false;
  String _bracket = AppConstants.bracketSingleElimination;
  final String _registrationMode = 'APPROVAL';
  // Không còn công tắc trên màn tạo nữa: luật ghép đôi do BTC quyết, mặc
  // định 'ORGANIZER' đúng như web (web cũng không có control này khi tạo).
  static const String _doublesPairingMode = 'ORGANIZER';
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
  bool _twoLegged = false;
  bool _awayGoalsRule = false;
  bool _penaltyShootout = false;
  bool _feesConfigLoaded = false;
  bool _allowEntryFees = false;
  bool _entryFeeEnabled = false;
  bool _regStartDateManuallySet = false;
  bool _endDateManuallySet = false;
  bool _registrationEndManuallySet = false;
  bool _isSubmitting = false;
  String? _logoUrl;
  String? _bannerUrl;
  bool _isUploadingBrand = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  bool _hasCheckedRole = false;

  @override
  void initState() {
    super.initState();
    _applyScheduleDefaults();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFeePolicy());
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _verifyOrganizerPermission(),
    );
  }

  /// Mốc thời gian mặc định, bám đúng web:
  ///
  /// - Bắt đầu: 06:00 hôm nay nếu lúc này còn trước 06:00, nếu không thì
  ///   00:00 ngày mai (`getVietnamNextTournamentStartIsoMinute`).
  /// - Kết thúc: để trống — web cho phép BTC tự bấm kết thúc giải.
  /// - Mở đăng ký: 00:00 hôm nay.
  /// - Hạn đăng ký: 23:59 hôm nay, lùi về trước giờ bắt đầu đúng một phút nếu
  ///   hai mốc chồng nhau, và nếu hôm nay đã qua thì lùi tới giờ bắt đầu
  ///   trừ một phút khi mốc đó còn ở tương lai
  ///   (`deriveRegistrationWindow`).
  void _applyScheduleDefaults() {
    final now = DateTime.now();
    final start = now.isBefore(DateTime(now.year, now.month, now.day, 6))
        ? DateTime(now.year, now.month, now.day, 6)
        : DateTime(now.year, now.month, now.day + 1);
    _startDate = DateTime(start.year, start.month, start.day);
    _startTime = TimeOfDay(hour: start.hour, minute: start.minute);
    // Kết thúc dự kiến: 00:00 ngày kế tiếp. Đây chỉ là mốc dự kiến để BTC
    // nhìn thấy quy mô giải; màn quản lý không tự tính lại nên BTC sửa tay
    // được bất cứ lúc nào.
    _endDate = DateTime(start.year, start.month, start.day + 1);
    _endTime = const TimeOfDay(hour: 0, minute: 0);
    _endDateManuallySet = false;
    _registrationEndManuallySet = false;

    _deriveRegistrationWindow(start);
  }

  /// Cửa sổ đăng ký, đúng `deriveRegistrationWindow` của web
  /// (`tournamentRegistrationSchedule.ts:69-100`):
  /// mở đăng ký 00:00 hôm nay, hạn chót 23:59 hôm nay nhưng lùi về trước
  /// giờ bắt đầu đúng một phút khi hai mốc chồng nhau, và nếu hạn chót hôm nay
  /// đã qua thì lùi tiếp tới giờ bắt đầu trừ một phút khi mốc đó còn ở tương
  /// lai. Backend cho phép mở đăng ký trong quá khứ, chỉ chặn hạn chót đã qua
  /// (`tournament-lite.service.ts:656`).
  void _deriveRegistrationWindow(DateTime start, {DateTime? nowOverride}) {
    final now = nowOverride ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _regStartDate = today;
    _regStartTime = const TimeOfDay(hour: 0, minute: 0);

    // 00:00 ngày hôm sau, lùi về trước giờ bắt đầu một phút khi trùng hoặc
    // vượt — backend từ chối hạn chót không nằm trước giờ bắt đầu.
    var regEnd = DateTime(today.year, today.month, today.day + 1);
    final lastUsable = start.subtract(const Duration(minutes: 1));
    if (!regEnd.isBefore(start)) regEnd = lastUsable;
    if (!regEnd.isAfter(now) && lastUsable.isAfter(now)) regEnd = lastUsable;
    _regEndDate = DateTime(regEnd.year, regEnd.month, regEnd.day);
    _regEndTime = TimeOfDay(hour: regEnd.hour, minute: regEnd.minute);
  }

  /// Đổi giờ bắt đầu thì kéo theo các mốc còn lại, trừ mốc BTC đã tự chọn.
  void _syncScheduleFromStart(DateTime start) {
    if (!_endDateManuallySet) {
      // Giữ quy tắc "00:00 ngày kế tiếp" khi BTC dịch giờ bắt đầu.
      _endDate = DateTime(start.year, start.month, start.day + 1);
      _endTime = const TimeOfDay(hour: 0, minute: 0);
    }
    // `_deriveRegistrationWindow` ghi cả mở đăng ký lẫn hạn chót, nên chỉ
    // chạy lại khi BTC chưa tự chọn mốc nào; nếu chỉ một trong hai đã chốt,
    // giữ nguyên mốc đó thay vì âm thầm ghi đè.
    if (!_regStartDateManuallySet && !_registrationEndManuallySet) {
      _deriveRegistrationWindow(start);
    }
  }

  Future<void> _loadFeePolicy() async {
    try {
      final values = await ref
          .read(tournamentManagementRepositoryProvider)
          .getFeesConfig();
      if (!mounted) return;
      setState(() {
        _feesConfigLoaded = true;
        _allowEntryFees = values['allowEntryFees'] == true;
        if (!_allowEntryFees) _entryFeeEnabled = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _feesConfigLoaded = true;
        _allowEntryFees = false;
        _entryFeeEnabled = false;
      });
    }
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
    _entryFeeController.dispose();
    _maxCombinedEloController.dispose();
    _maxTeammateGapController.dispose();
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

  /// Nội dung thi đấu mặc định phải thuộc môn đang chọn: bóng đá chỉ nhận
  /// `FOOTBALL_*`, các môn vợt chỉ nhận nhóm `SINGLES`/`DOUBLES`
  /// (`_openContentDraftDialog` lọc danh sách theo môn). Trước đây mọi môn đều
  /// nhận `MALE_DOUBLES`, nên đổi sang bóng đá xong bản nháp vẫn mang nội dung
  /// không hợp lệ cho môn.
  void _resetContentDraftsForSport(String sport) {
    final defaultFormat = sport == AppConstants.sportFootball
        ? 'FOOTBALL_MALE'
        : 'MALE_DOUBLES';
    _contentDrafts = [
      _QuickTournamentContentDraft(
        id: defaultFormat,
        formatKey: defaultFormat,
        name: '',
      ),
    ];
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
        if (_sport != AppConstants.sportFootball &&
            _contentDrafts.any((draft) => draft.formatKey.contains('DOUBLES')))
          'doublesPairingMode': _doublesPairingMode,
        'isRanked': _isRanked,
        if (_entryFeeEnabled)
          'entryFee': int.parse(_entryFeeController.text.trim()),
        if (_logoUrl != null && _logoUrl!.isNotEmpty) 'logoUrl': _logoUrl,
        if (_bannerUrl != null && _bannerUrl!.isNotEmpty)
          'bannerUrl': _bannerUrl,
        if (_mapSportSlug() == 'football') ...{
          'teamSize': _teamSize,
          'maxReserve': _maxReserve,
          'footballHalvesCount': _footballHalvesCount,
          'teamSizeOptions': [5, 7, 11],
          'minTeamSize': _teamSize,
          'maxTeamSize': _teamSize + _maxReserve,
          'footballHalfDuration': _footballHalfDuration,
          'footballAllowDraw': _footballAllowDraw,
          'twoLegged': _twoLegged,
          'awayGoalsRule': _awayGoalsRule,
          'penaltyShootout': _penaltyShootout,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
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
            _sectionLabel(l10n.quickCreateNameLabel, colors),
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
            _sectionLabel(l10n.quickCreateSportLabel, colors),
            const SizedBox(height: 8),
            _buildSportGrid(colors),
            const SizedBox(height: 18),

            // ─── Thể thức thi đấu ───
            _sectionLabel('${l10n.quickCreateBracketLabel} *', colors),
            const SizedBox(height: 8),
            _buildBracketSelector(colors),
            const SizedBox(height: 18),

            // ─── Nội dung thi đấu (Bao gồm Giới tính) ───
            // Bộ đếm đặt cạnh tiêu đề để người tạo luôn biết mình đang có bao
            // nhiêu nội dung — đây là trường bắt buộc tối thiểu 1.
            Row(
              children: [
                Expanded(
                  child: _sectionLabel(l10n.quickCreateFormatLabel, colors),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Đã chọn ${_contentDrafts.length} nội dung',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildFormatPills(colors),
            const SizedBox(height: 18),

            // ─── Quy mô & Giới hạn số đội ───
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _sectionLabel('Số đội / VĐV tối đa', colors)),
                    Text(
                      'Tối đa 128',
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildMaxTeamsSelector(colors),
                _buildRoundRobinHint(colors) ?? const SizedBox.shrink(),

            // ─── Luật bóng đá (chỉ môn bóng đá) ───
            // Web đặt luật bóng đá ngay dưới khối thể thức, hiện sẵn khi môn là
            // bóng đá (`QuickTournamentCreate.tsx:1209-1272`); hai luật hai lượt
            // / bàn thắng sân khách / luân lưu nằm ở khối nâng cao của web
            // (`:1715-1720`) nên mobile cũng tách vậy.
            if (_sport == AppConstants.sportFootball) ...[
              const SizedBox(height: 18),
              _buildFootballOptions(colors),
            ],
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
                    hint: 'Dự kiến',
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

            // ─── Cài đặt nâng cao (giống web: thu gọn, mở ra mới thấy) ───
            // Web đặt lệ phí, logo và banner trong khối "Thêm cài đặt giải
            // đấu" đóng mặc định và đặt sau mô tả. Mobile đặt cùng vị trí để
            // phần bắt buộc không bị đẩy xuống dưới màn hình.
            _buildAdvancedExtras(colors),
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
        final categoriesAsync = ref.watch(categoriesProvider);
        final activeCategories =
            categoriesAsync.asData?.value ?? const <CategoryModel>[];

        // Chỉ nhận đúng 5 môn mà `POST /tournaments/lite` chấp nhận
        // (`@IsIn` trong create-lite-tournament.dto.ts). Một category khác
        // (ví dụ bóng chuyền) không có nguồn scoring nên không được hiện:
        // map nó về môn khác sẽ tạo giải sai môn so với nhãn người dùng thấy.
        // Nhãn lấy từ `cat.name` của backend; icon do
        // `SportChoiceTile.buildSportIcon` tự tra theo slug, không cần bảng map.
        const creatableSlugs = {
          AppConstants.sportBadminton,
          AppConstants.sportPickleball,
          AppConstants.sportTennis,
          AppConstants.sportTableTennis,
          AppConstants.sportFootball,
        };
        final sports = activeCategories
            .where((cat) => creatableSlugs.contains(cat.slug.toLowerCase()))
            .map((cat) {
              final slug = cat.slug.toLowerCase();
              final fallbackName =
                  AppConstants.sportNames[slug] ?? slug;
              return (slug, cat.name.isNotEmpty ? cat.name : fallbackName);
            })
            .toList();

        if (categoriesAsync.hasError && activeCategories.isEmpty) {
          return _sportFallbackState(
            colors,
            message: l10n.socialActiveSportsError,
            retryLabel: l10n.socialActiveSportsRetry,
            onRetry: () => ref.invalidate(categoriesProvider),
          );
        }

        if (categoriesAsync.isLoading && activeCategories.isEmpty) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (sports.isEmpty) {
          return _sportFallbackState(colors, message: l10n.infoNoData);
        }

        if (!sports.any((s) => s.$1 == _sport)) {
          final firstSport = sports.first.$1;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _sport != firstSport) {
              // Nội dung thi đấu phải đi theo môn: đổi môn mà giữ bản nháp cũ
              // sẽ gửi lên một `matchType` không hợp lệ với môn mới.
              setState(() {
                _sport = firstSport;
                _resetContentDraftsForSport(firstSport);
              });
            }
          });
        }

        // Bề rộng ô cố định để danh sách môn tự xuống dòng: số môn thay đổi
        // theo `isActive` từ backend, `Row` + `Expanded` sẽ bóp nhãn về 0 và
        // kích hoạt ellipsis khi có từ 5 môn trở lên.
        return LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 8.0;
            const minTileWidth = 96.0;
            final columns = ((constraints.maxWidth + spacing) / (minTileWidth + spacing))
                .floor()
                .clamp(2, 4);
            final tileWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: sports.map((s) {
                final selected = _sport == s.$1;
                return SizedBox(
                  width: tileWidth,
                  child: SportChoiceTile(
                    sportKey: s.$1,
                    label: s.$2,
                    selected: selected,
                    iconSize: 24,
                    expanded: false,
                    onTap: () => setState(() {
                      _sport = s.$1;
                      _resetContentDraftsForSport(s.$1);
                    }),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  /// Trạng thái lỗi/rỗng cho khối chọn môn. Trước đây khối này chỉ có
  /// spinner, nên khi `GET /categories` lỗi người dùng thấy vòng xoay vô hạn.
  Widget _sportFallbackState(
    AppColorsExtension colors, {
    required String message,
    String? retryLabel,
    VoidCallback? onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.sports_rounded, size: 20, color: colors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ),
          if (onRetry != null && retryLabel != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                retryLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Chọn quy mô giải: chip mặc định + ô "Khác" cho giá trị tự do.
  ///
  /// Ô "Khác" phải là `TextFormField` gắn `_maxTeamsController` — `_submit`
  /// gọi `_formKey.currentState!.validate()`, nên `validator` của nó là nơi
  /// thực thi luật 2..128 và luật vòng tròn ≤ 15. Đổi sang `TextField` sẽ làm
  /// hai luật đó ngừng chạy và cho phép gửi số không hợp lệ.
  /// Danh sách chip bám đúng preset của web (`QuickTournamentCreate.tsx:1341`):
  /// vòng tròn chỉ tới 15 vì mỗi đội phải gặp nhau.
  List<int> get _maxTeamsPresets => _bracket == AppConstants.bracketRoundRobin
      ? const [4, 6, 8, 10, 12, 15]
      : const [4, 8, 16, 32, 64, 128];


  /// Quy mô: một hàng chip cuộn ngang + ô "Khác" gọn. Web cũng để vậy, và ô
  /// "Khác" viền xanh khi giá trị không thuộc chip để thấy rõ đang dùng số
  /// tuỳ chỉnh chứ không phải preset.
  Widget _buildMaxTeamsSelector(AppColorsExtension colors) {
    final current = int.tryParse(_maxTeamsController.text.trim());
    final presets = _maxTeamsPresets;
    final usesCustom = current != null && !presets.contains(current);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Một hàng ngang, cuộn được: 6 chip không làm khối này cao thêm dòng.
        Expanded(
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: presets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final value = presets[index];
                final selected = current == value;
                return ChoiceChip(
                  label: Text('$value'),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _maxTeamsController.text = '$value';
                  }),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : colors.textPrimary,
                  ),
                  selectedColor: AppTheme.primary,
                  backgroundColor: colors.bgSurface,
                  side: BorderSide(
                    color: selected ? AppTheme.primary : colors.border,
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Ô "Khác" gọn, viền xanh khi đang là giá trị tuỳ chỉnh.
        SizedBox(
          width: 92,
          child: TextFormField(
            controller: _maxTeamsController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              hintText: 'Khác',
              hintStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textMuted,
              ),
              filled: true,
              fillColor: usesCustom
                  ? AppTheme.primary.withValues(alpha: 0.06)
                  : colors.bgSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: usesCustom ? AppTheme.primary : colors.border,
                  width: usesCustom ? 1.6 : 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: usesCustom ? AppTheme.primary : colors.border,
                  width: usesCustom ? 1.6 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppTheme.primary,
                  width: 1.6,
                ),
              ),
            ),
            validator: (val) {
              final n = int.tryParse(val?.trim() ?? '');
              if (n == null || n < 2 || n > 128) {
                return '2–128';
              }
              if (_bracket == AppConstants.bracketRoundRobin && n > 15) {
                return 'Tối đa 15';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  /// Gợi ý chuyển thể thức khi vòng tròn đang vượt quy mô hợp lệ, như web.
  Widget? _buildRoundRobinHint(AppColorsExtension colors) {
    final current = int.tryParse(_maxTeamsController.text.trim()) ?? 0;
    if (_bracket != AppConstants.bracketRoundRobin || current <= 15) {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Vòng tròn chỉ hợp lệ tới 15 đội. Với quy mô này nên dùng '
              '"Vòng bảng + Knockout".',
              style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _bracket = AppConstants.bracketGroupStageKnockout;
              _maxTeamsController.text = '16';
            }),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'Đổi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
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


  Widget _buildPublicFeeOptions(AppColorsExtension colors) {
    final l10n = AppLocalizations.of(context)!;
    if (!_feesConfigLoaded) return const SizedBox.shrink();
    if (!_allowEntryFees) {
      return Text(
        l10n.tournamentCreateEntryFeePolicyUnavailable,
        style: TextStyle(fontSize: 12, color: colors.textMuted),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.tournamentCreateEntryFeeToggle),
            value: _entryFeeEnabled,
            onChanged: (value) => setState(() => _entryFeeEnabled = value),
          ),
          if (_entryFeeEnabled)
            TextFormField(
              controller: _entryFeeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.tournamentManagementEntryFee,
                prefixText: '₫ ',
              ),
              validator: (value) {
                if (!_entryFeeEnabled) return null;
                final amount = int.tryParse(value?.trim() ?? '');
                if (amount == null || amount < 0) {
                  return l10n.tournamentCreateIntegerNonNegative;
                }
                return null;
              },
            ),
        ],
      ),
    );
  }


  /// Các nội dung luôn hiện sẵn trong danh sách, giống web: tất cả đều ở
  /// trạng thái đã tick và nằm sẵn trong thẻ "Nội dung thi đấu". Đơn và nội
  /// dung riêng không mở sẵn — thêm qua dialog để không làm danh sách dài ra.
  List<String> get _defaultFormatKeys =>
      _sport == AppConstants.sportFootball
      ? const ['FOOTBALL_MALE', 'FOOTBALL_FEMALE', 'FOOTBALL_MIXED']
      : const ['MALE_DOUBLES', 'FEMALE_DOUBLES', 'MIXED_DOUBLES'];

  _QuickTournamentContentDraft? _draftFor(String formatKey) {
    for (final draft in _contentDrafts) {
      if (draft.formatKey == formatKey) return draft;
    }
    return null;
  }

  /// Tên hiển thị của một dòng: tên BTC tự đặt nếu có, không thì tên chuẩn.
  String _draftName(String formatKey) {
    final draft = _draftFor(formatKey);
    final custom = draft?.name.trim() ?? '';
    return custom.isEmpty ? _formatLabel(formatKey) : custom;
  }

  /// Quy mô đang áp dụng cho một nội dung: ghi đè riêng nếu có, nếu không thì
  /// theo quy mô chung của giải.
  int _draftLimit(_QuickTournamentContentDraft? draft) =>
      draft?.maxParticipantsOverride ?? _globalMaxParticipants();

  /// Bật/tắt một nội dung.
  ///
  /// Bỏ tick nội dung cuối cùng không báo lỗi: giải bắt buộc có ít nhất một
  /// nội dung, nên ta chuyển sang nội dung mặc định khác của môn thay vì chặn
  /// người dùng ở một ô tick đang bật.
  void _toggleFormatKey(String formatKey, bool on) {
    if (on) {
      if (_draftFor(formatKey) != null) return;
      _contentDrafts = [
        ..._contentDrafts,
        _QuickTournamentContentDraft(
          id: 'content-${DateTime.now().microsecondsSinceEpoch}',
          formatKey: formatKey,
          name: '',
        ),
      ];
      return;
    }

    final remaining = _contentDrafts
        .where((draft) => draft.formatKey != formatKey)
        .toList();
    if (remaining.isNotEmpty) {
      _contentDrafts = remaining;
      return;
    }

    final reseed = _defaultFormatKeys.firstWhere(
      (candidate) => candidate != formatKey,
      orElse: () => _defaultFormatKeys.first,
    );
    _contentDrafts = [
      _QuickTournamentContentDraft(id: reseed, formatKey: reseed, name: ''),
    ];
  }

  /// Danh sách nội dung: mỗi dòng có ô tick, tên, quy mô và nút sửa — bám
  /// theo `selectedFormats` của web. Danh sách dài cố định nên tick không
  /// làm form dài thêm, và nội dung đã thêm qua dialog hiện dưới dạng dòng
  /// có nút sửa.
  /// Luật bóng đá, bám đúng web: số người mỗi đội, số dự bị, số hiệp, số
  /// phút mỗi hiệp và có cho phép hòa hay không. Backend kiểm tra
  /// `teamSize ∈ {5,7,11}` và `teamSize === minTeamSize`
  /// (`assertValidFootballTeamConfig`), nên `minTeamSize`/`maxTeamSize` được
  /// tính theo để khớp DTO.
  Widget _buildFootballOptions(AppColorsExtension colors) {
    final l10nNow = l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sports_soccer,
                size: 16,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10nNow.tournamentCreateFootballOptions,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _footballDropdown<int>(
                  colors: colors,
                  label: l10nNow.tournamentCreateTeamSize,
                  value: _teamSize,
                  items: const [5, 7, 11],
                  format: (v) => '$v người',
                  onChanged: (v) => setState(() => _teamSize = v ?? _teamSize),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _footballDropdown<int>(
                  colors: colors,
                  label: l10nNow.tournamentCreateMaxReserve,
                  value: _maxReserve,
                  items: const [0, 3, 5, 7, 10],
                  format: (v) => '$v người',
                  onChanged: (v) =>
                      setState(() => _maxReserve = v ?? _maxReserve),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _footballDropdown<int>(
                  colors: colors,
                  label: l10nNow.tournamentCreateFootballHalves,
                  value: _footballHalvesCount,
                  items: const [1, 2, 3, 4],
                  format: (v) => '$v hiệp',
                  onChanged: (v) => setState(
                    () => _footballHalvesCount = v ?? _footballHalvesCount,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _footballDropdown<int>(
                  colors: colors,
                  label: l10nNow.tournamentCreateFootballHalfDuration,
                  value: _footballHalfDuration,
                  items: const [15, 30, 45, 60, 90],
                  format: (v) => '$v phút',
                  onChanged: (v) => setState(
                    () => _footballHalfDuration =
                        v ?? _footballHalfDuration,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _footballSwitch(
            colors: colors,
            label: l10nNow.tournamentCreateFootballAllowDraw,
            value: _footballAllowDraw,
            onChanged: (v) => setState(() => _footballAllowDraw = v),
          ),
        ],
      ),
    );
  }

  Widget _footballDropdown<T>({
    required AppColorsExtension colors,
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) format,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(10),
          isDense: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            filled: true,
            fillColor: colors.bgCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    format(item),
                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _footballSwitch({
    required AppColorsExtension colors,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
            ),
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.primary,
        ),
      ],
    );
  }

  Widget _buildFormatPills(AppColorsExtension colors) {
    final keys = <String>[..._defaultFormatKeys];
    for (final draft in _contentDrafts) {
      if (!keys.contains(draft.formatKey)) keys.add(draft.formatKey);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final key in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildFormatRow(colors, key),
          ),
        const SizedBox(height: 2),
        _buildAddContentButton(colors),
      ],
    );
  }

  Widget _buildFormatRow(AppColorsExtension colors, String formatKey) {
    final draft = _draftFor(formatKey);
    final selected = draft != null;
    final overrideNote = draft == null ? null : _contentDraftSummary(draft);

    return Material(
      color: selected
          ? AppTheme.primary.withValues(alpha: 0.06)
          : colors.bgSurface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => setState(() => _toggleFormatKey(formatKey, !selected)),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppTheme.primary : colors.border,
            ),
          ),
          child: Row(
            children: [
              // Ô tick tự đóng, không nuốt cả hàng: chạm vào nó thì chỉ
              // bật/tắt nội dung, chạm chỗ khác mở dialog sửa.
              SizedBox(
                width: 48,
                height: 48,
                child: Checkbox(
                  value: selected,
                  onChanged: (value) =>
                      setState(() => _toggleFormatKey(formatKey, value ?? false)),
                  activeColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _draftName(formatKey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? colors.textPrimary
                            : colors.textMuted,
                      ),
                    ),
                    if (overrideNote != null && overrideNote.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          overrideNote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Quy mô: hiển thị, sửa qua dialog. Ô nhỏ nhưng vẫn chạm được.
              Container(
                constraints: const BoxConstraints(minWidth: 56, minHeight: 36),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 14,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_draftLimit(draft)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Sửa nội dung này',
                onPressed: () => draft == null
                    ? setState(() => _toggleFormatKey(formatKey, true))
                    : _editContentDraft(draft),
                icon: Icon(
                  Icons.tune,
                  size: 18,
                  color: selected ? AppTheme.primary : colors.textMuted,
                ),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Nút "Thêm nội dung" dạng viền đứt như web, chỉ hiện khi còn nội dung chưa
  /// dùng trong danh sách mặc định.
  Widget _buildAddContentButton(AppColorsExtension colors) {
    final hasMore = _sport != AppConstants.sportFootball ||
        _contentDrafts.length < _defaultFormatKeys.length;
    if (!hasMore) return const SizedBox.shrink();

    return DottedBorderBox(
      onTap: _openContentDraftDialog,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add, size: 17, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            'Thêm nội dung',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Tóm tắt phần khác với luật chung: quy mô riêng, thể thức riêng, ELO.
  String _contentDraftSummary(_QuickTournamentContentDraft draft) {
    final parts = <String>[];
    if (draft.maxParticipantsOverride != null) {
      parts.add('${draft.maxParticipantsOverride} người/đội');
    }
    if (draft.bracketType != null) {
      parts.add(BracketFormatIcons.getFormatLabel(context, draft.bracketType));
    }
    if (draft.eloEnabled && draft.minElo != null && draft.maxElo != null) {
      parts.add('ELO ${draft.minElo}-${draft.maxElo}');
    }
    return parts.join(' · ');
  }

  /// Khối "Cài đặt nâng cao", thu gọn mặc định, đặt cuối form.
  ///
  /// Chỉ chứa lệ phí, logo và banner — đúng phần web đặt trong khối thu gọn
  /// `showCreateOptions` của form thủ công (`QuickTournamentCreate.tsx:1652-1774`).
  /// Trần ELO toàn giải, công tắc ghép đôi BTC và luật bóng đá đã bỏ khỏi màn
  /// này. Giới hạn ELO riêng vẫn đặt được cho từng nội dung trong dialog.
  Widget _buildAdvancedExtras(AppColorsExtension colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: const Icon(Icons.tune, size: 18, color: AppTheme.primary),
          title: Text(
            'Cài đặt nâng cao',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Lệ phí, logo, banner',
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _isRanked
                    ? l10n.tournamentCreateRanked
                    : l10n.tournamentCreateUnranked,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                _isRanked
                    ? l10n.tournamentCreateRankedDescription
                    : l10n.tournamentCreateUnrankedDescription,
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              value: _isRanked,
              onChanged: (value) => setState(() => _isRanked = value),
            ),
            const SizedBox(height: 6),
            _buildPublicFeeOptions(colors),
            // Ba luật này web để trong khối nâng cao
            // (QuickTournamentCreate.tsx:1715-1720), không đặt ở card bóng đá.
            if (_sport == AppConstants.sportFootball) ...[
              const Divider(height: 20),
              _footballSwitch(
                colors: colors,
                label: l10n.tournamentCreateTwoLegged,
                value: _twoLegged,
                onChanged: (v) => setState(() => _twoLegged = v),
              ),
              _footballSwitch(
                colors: colors,
                label: l10n.tournamentCreateAwayGoalsRule,
                value: _awayGoalsRule,
                onChanged: (v) => setState(() => _awayGoalsRule = v),
              ),
              _footballSwitch(
                colors: colors,
                label: l10n.footballScore_penaltyShootout,
                value: _penaltyShootout,
                onChanged: (v) => setState(() => _penaltyShootout = v),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Ảnh giải đấu',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildBrandPicker(
                    colors,
                    label: 'Logo',
                    icon: Icons.emoji_events_outlined,
                    url: _logoUrl,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBrandPicker(
                    colors,
                    label: 'Banner',
                    icon: Icons.panorama_outlined,
                    url: _bannerUrl,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Ô chọn ảnh. Ảnh đã chọn hiện kèm nút xoá, bấm lại để đổi ảnh.
  Widget _buildBrandPicker(
    AppColorsExtension colors, {
    required String label,
    required IconData icon,
    required String? url,
  }) {
    final isBanner = label == 'Banner';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pickAndUploadBrand(isBanner: isBanner),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 84,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: _isUploadingBrand
                ? const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : url == null || url.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 22, color: colors.textMuted),
                      const SizedBox(height: 6),
                      Text(
                        'Chọn ảnh',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        LiteTournamentCreateResult.resolveUrl(url),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => ColoredBox(
                          color: colors.bgCard,
                          child: Icon(icon, size: 22, color: colors.textMuted),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => setState(() {
                              if (isBanner) {
                                _bannerUrl = null;
                              } else {
                                _logoUrl = null;
                              }
                            }),
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadBrand({required bool isBanner}) async {
    if (_isUploadingBrand) return;
    setState(() => _isUploadingBrand = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (picked == null) return;
      final uploaded = await ref
          .read(communitySocialRepositoryProvider)
          .uploadImage(await picked.readAsBytes(), picked.name);
      if (!mounted) return;
      setState(() {
        if (isBanner) {
          _bannerUrl = uploaded;
        } else {
          _logoUrl = uploaded;
        }
      });
    } catch (error) {
      if (mounted) _showError('Không tải được ảnh lên. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isUploadingBrand = false);
    }
  }

  Future<void> _editContentDraft(_QuickTournamentContentDraft draft) async {
    await _openContentDraftDialog(existing: draft);
  }


  /// Thêm hoặc sửa một nội dung thi đấu.
  ///
  /// Dùng bottom sheet thay cho `AlertDialog`: trên điện thoại sheet chiếm hết
  /// bề ngang, tự co theo bàn phím và cho các trường đủ chỗ, trong khi
  /// `AlertDialog` bóp tiêu đề thành hai dòng và cắt chữ phụ. Bộ trường giữ
  /// nguyên theo web: loại nội dung, tên riêng, số lượng, rồi tới khối
  /// "Tuỳ chọn bổ sung" (thể thức riêng + khoảng ELO) đang thu gọn.
  Future<void> _openContentDraftDialog({
    _QuickTournamentContentDraft? existing,
  }) async {
    if (!mounted) return;

    final l10nNow = l10n;
    final isFootball = _sport == AppConstants.sportFootball;
    final formatOptions = isFootball
        ? const <String>['FOOTBALL_MALE', 'FOOTBALL_FEMALE', 'FOOTBALL_MIXED']
        : const <String>[
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
    var advanced = existing != null &&
        (existing.bracketType != null || existing.eloEnabled);
    var eloEnabled = existing?.eloEnabled ?? false;
    var minElo = existing?.minElo;
    var maxElo = existing?.maxElo;
    String? nameError;
    String? limitError;
    String? eloError;

    final nameController = TextEditingController(
      text: existing != null && existing.name.trim().isNotEmpty
          ? existing.name
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

    final bracketOptions = [
      ('', 'Theo thể thức chung của giải'),
      (AppConstants.bracketSingleElimination,
        l10nNow.quickCreateBracketSingle),
      (AppConstants.bracketDoubleElimination,
        l10nNow.quickCreateBracketDouble),
      (AppConstants.bracketRoundRobin, l10nNow.quickCreateBracketRoundRobin),
      (AppConstants.bracketGroupStageKnockout,
        l10nNow.quickCreateBracketGroup),
    ];

    _QuickTournamentContentDraft? buildDraft() {
      final name = nameController.text.trim();
      final limit = int.tryParse(limitController.text.trim());
      final parsedMin = int.tryParse(minEloController.text.trim());
      final parsedMax = int.tryParse(maxEloController.text.trim());
      final usesRoundRobin = bracketType == AppConstants.bracketRoundRobin;
      final ceiling = usesRoundRobin ? 15 : 128;

      if (name.isEmpty) {
        nameError = 'Vui lòng nhập tên nội dung';
      } else if (name.length > 60) {
        nameError = 'Tên nội dung tối đa 60 ký tự';
      }
      if (limit == null) {
        limitError = 'Vui lòng nhập số người/đội';
      } else if (limit < 2 || limit > ceiling) {
        limitError = usesRoundRobin
            ? 'Vòng tròn cần từ 2 đến 15 người/đội'
            : 'Số lượng cần từ 2 đến 128 người/đội';
      }
      String? eloFailure;
      if (eloEnabled) {
        if (parsedMin == null || parsedMin < 0 ||
            parsedMax == null || parsedMax < 0) {
          eloFailure = 'Khoảng ELO không hợp lệ';
        } else if (parsedMin > parsedMax) {
          eloFailure = 'ELO tối thiểu không được lớn hơn ELO tối đa';
        }
      }
      eloError = eloFailure;

      if (nameError != null || limitError != null || eloFailure != null) {
        return null;
      }

      return _QuickTournamentContentDraft(
          id: existing?.id ?? 'content-${DateTime.now().microsecondsSinceEpoch}',
          formatKey: formatKey,
          name: name,
          maxParticipantsOverride: limitTouched ? limit : null,
          bracketType: bracketType,
        eloEnabled: eloEnabled,
        minElo: eloEnabled ? parsedMin : null,
        maxElo: eloEnabled ? parsedMax : null,
      );
    }

    // Bottom sheet: cao tối đa 92% màn hình, co lại khi bàn phím mở.
    final saved = await showModalBottomSheet<_QuickTournamentContentDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        // Bốn controller phải sống cùng route của sheet: future của
        // showModalBottomSheet hoàn tất lúc pop, trước khi reverse transition
        // gỡ cây widget, nên dispose ở đây sẽ làm TextField còn mount gặp
        // controller đã dispose. Owner giữ chúng cho tới khi route thật sự
        // bị tháo.
        return _QuickTournamentContentDialogOwner(
          controllers: [
            nameController,
            limitController,
            minEloController,
            maxEloController,
          ],
          builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final colors = sheetContext.colors;
            void setDialogState(VoidCallback fn) => setSheetState(fn);

            return Padding(
              // Đệm theo viewInsets để bàn phím không che nút.
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.92,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nắm kéo + tiêu đề: giữ tiêu đề một dòng, phụ tắt.
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  existing == null
                                      ? 'Thêm nội dung thi đấu'
                                      : 'Sửa nội dung thi đấu',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Mặc định dùng thể thức chung của giải, bạn có thể chọn riêng cho nội dung này.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textMuted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close, size: 20),
                            color: colors.textMuted,
                            tooltip: 'Đóng',
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        children: [
                          _dialogFieldLabel('Loại nội dung'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: formatKey,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(12),
                            decoration: _dialogInputDecoration(),
                            items: formatOptions
                                .map(
                                  (key) => DropdownMenuItem(
                                    value: key,
                                    child: Text(
                                      _formatLabel(key),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colors.textPrimary,
                                      ),
                                    ),
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
                          const SizedBox(height: 18),

                          _dialogFieldLabel('Tên nội dung riêng'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameController,
                            onChanged: (value) {
                              setDialogState(() {
                                nameTouched = true;
                                nameError = null;
                              });
                            },
                            decoration: _dialogInputDecoration(
                              errorText: nameError,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Để trống để dùng tên chuẩn của loại nội dung.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 18),

                          _dialogFieldLabel('Số lượng người/đội tham gia'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: limitController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setDialogState(() {
                                limitTouched = true;
                                limitError = null;
                              });
                            },
                            decoration: _dialogInputDecoration(
                              errorText: limitError,
                              suffixText: 'người/đội',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mặc định theo quy mô chung của giải '
                            '(${_globalMaxParticipants()} người/đội).',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Khối tuỳ chọn bổ sung, thu gọn mặc định — web cũng
                          // vậy (QuickTournamentCreate.tsx:1875).
                          Container(
                            decoration: BoxDecoration(
                              color: colors.bgSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.border),
                            ),
                            child: Theme(
                              data: Theme.of(sheetContext).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                initiallyExpanded: advanced,
                                tilePadding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                childrenPadding:
                                    const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                leading: const Icon(
                                  Icons.tune,
                                  size: 18,
                                  color: AppTheme.primary,
                                ),
                                title: Text(
                                  'Tuỳ chọn bổ sung (thể thức, ELO)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                trailing: Icon(
                                  advanced
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 20,
                                  color: AppTheme.primary,
                                ),
                                children: [
                                  _dialogFieldLabel('Thể thức bảng đấu riêng'),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: bracketType ?? '',
                                    isExpanded: true,
                                    borderRadius: BorderRadius.circular(12),
                                    decoration: _dialogInputDecoration(),
                                    items: bracketOptions
                                        .map(
                                          (option) => DropdownMenuItem(
                                            value: option.$1,
                                            child: Text(
                                              option.$2,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: colors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) => setDialogState(() {
                                      bracketType = (value == null ||
                                              value.isEmpty)
                                          ? null
                                          : value;
                                    }),
                                  ),
                                  const SizedBox(height: 14),
                                  CheckboxListTile(
                                    value: eloEnabled,
                                    onChanged: (value) => setDialogState(() {
                                      eloEnabled = value ?? false;
                                      eloError = null;
                                    }),
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    activeColor: AppTheme.primary,
                                    title: Text(
                                      'Giới hạn ELO cho nội dung này',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight:
                                            FontWeight.w600,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (eloEnabled) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: minEloController,
                                            keyboardType:
                                                TextInputType.number,
                                            onChanged: (_) => setDialogState(
                                              () => eloError = null,
                                            ),
                                            decoration:
                                                _dialogInputDecoration(
                                              labelText: 'ELO tối thiểu',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: maxEloController,
                                            keyboardType:
                                                TextInputType.number,
                                            onChanged: (_) => setDialogState(
                                              () => eloError = null,
                                            ),
                                            decoration:
                                                _dialogInputDecoration(
                                              labelText: 'ELO tối đa',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (eloError != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8),
                                        child: Text(
                                          eloError!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.error,
                                          ),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Hành động dính đáy sheet, không cuộn theo nội dung.
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  minimumSize:
                                      const Size.fromHeight(48),
                                  foregroundColor: colors.textSecondary,
                                  side: BorderSide(color: colors.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Hủy',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: () {
                                  final draft = buildDraft();
                                  if (draft != null) {
                                    Navigator.of(sheetContext).pop(draft);
                                  }
                                },
                                icon: Icon(
                                  existing == null
                                      ? Icons.add
                                      : Icons.check,
                                  size: 18,
                                ),
                                label: Text(
                                  existing == null
                                      ? 'Thêm nội dung'
                                      : 'Lưu thay đổi',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize:
                                      const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        );
      },
    );

    if (!mounted || saved == null) return;
    setState(() {
      final index =
          _contentDrafts.indexWhere((draft) => draft.id == saved.id);
      if (index >= 0) {
        _contentDrafts = List.of(_contentDrafts)..[index] = saved;
      } else {
        _contentDrafts = [..._contentDrafts, saved];
      }
    });
  }

  Text _dialogFieldLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: context.colors.textPrimary,
    ),
  );

  InputDecoration _dialogInputDecoration({
    String? errorText,
    String? labelText,
    String? suffixText,
  }) {
    final sheetColors = context.colors;
    return InputDecoration(
      labelText: labelText,
      suffixText: suffixText,
      errorText: errorText,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      filled: true,
      fillColor: sheetColors.bgSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: sheetColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: sheetColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.6),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected ? AppTheme.primary : colors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: InkWell(
              onTap: () => setState(() {
                _bracket = b.$1;
                // Vòng tròn chỉ hợp lệ tới 15 đội vì mọi cặp đều phải gặp nhau.
                // Kẹp giá trị đang có lại, nếu không ô "Khác" sẽ giữ một số mà
                // chính validator của form cũng từ chối.
                if (b.$1 == AppConstants.bracketRoundRobin) {
                  final current = _globalMaxParticipants();
                  if (current > 15) _maxTeamsController.text = '15';
                }
              }),
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
      _syncScheduleFromStart(start);
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
      _regStartDateManuallySet = true;
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
    String? hint,
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
                      if (hint != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colors.textSecondary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            hint,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
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
