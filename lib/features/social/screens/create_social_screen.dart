import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_duration_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_price_dialog.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_privacy_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_setting_tile.dart';
import 'package:app_quanly_giaidau/features/social/widgets/participant_tab/social_participant_counter.dart';

class CreateSocialScreen extends ConsumerStatefulWidget {
  final String clubId;
  final String clubName;
  final String? clubLogoUrl;
  final SocialSessionModel? initialSession;

  const CreateSocialScreen({
    super.key,
    required this.clubId,
    required this.clubName,
    this.clubLogoUrl,
    this.initialSession,
  });

  @override
  ConsumerState<CreateSocialScreen> createState() => _CreateSocialScreenState();
}

class _CreateSocialScreenState extends ConsumerState<CreateSocialScreen> {
  // Sports options
  final List<({String key, String name, IconData icon})> _sports = const [
    (key: 'pickleball', name: 'Pickleball', icon: Icons.sports_tennis),
    (key: 'badminton', name: 'Cầu lông', icon: Icons.sports_tennis_rounded),
    (key: 'tennis', name: 'Tennis', icon: Icons.sports_baseball_outlined),
  ];

  late String _selectedSportKey;
  late String _selectedSportName;

  // Format options: Giao lưu, Đánh vòng tròn, Đánh đơn, Đánh đôi
  final List<String> _formats = const [
    'Giao lưu',
    'Đánh vòng tròn',
    'Đánh đơn',
    'Đánh đôi',
  ];
  late String _selectedFormat;

  // Date and Time
  late DateTime _selectedDateTime;
  double _durationHours = 1.0;

  // Venue / Location (Tách 2 trường theo Yêu cầu 5)
  final TextEditingController _venueNameController = TextEditingController();
  final TextEditingController _venueAddressController = TextEditingController();

  // Configurations
  int _maxParticipants = 6;
  String _privacy = 'Công khai';
  int _price = 0;

  // Title and Notes
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isClubAttached = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialSession;
    if (init != null) {
      _selectedSportKey = init.sport;
      _selectedSportName = init.sportName;
      _selectedFormat = init.playFormat;
      _selectedDateTime = init.startAt;
      _durationHours = init.durationMinutes / 60.0;
      _maxParticipants = init.maxSlots;
      _privacy = init.visibility == 'CLUB_ONLY' ? 'Nội bộ CLB' : 'Công khai';
      _price = init.feePerSlot;
      _venueNameController.text = init.venueName;
      _venueAddressController.text = init.venueAddress;
      _titleController.text = init.title;
      _notesController.text = init.description ?? '';
      _isClubAttached =
          (init.communityId != null && init.communityId!.isNotEmpty);
    } else {
      _selectedSportKey = _sports.first.key;
      _selectedSportName = _sports.first.name;
      _selectedFormat = _formats.first;

      // Default time: next hour or 14:45
      final now = DateTime.now();
      _selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour + 1,
        0,
      );
    }
  }

  @override
  void dispose() {
    _venueNameController.dispose();
    _venueAddressController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _getHostName() {
    final user = ref.read(userProfileProvider).asData?.value;
    final fullName = user?.fullName?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      return parts.last;
    }
    return 'Host';
  }

  String _getComputedDefaultTitle() {
    final hostName = _getHostName();
    return '$_selectedSportName $_selectedFormat với $hostName';
  }

  String _formatCurrency(int amount) {
    if (amount <= 0) return 'Không có';
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} đ';
  }

  String _formatDateTimeDisplay(DateTime dt) {
    const days = [
      'Thứ hai',
      'Thứ ba',
      'Thứ tư',
      'Thứ năm',
      'Thứ sáu',
      'Thứ bảy',
      'Chủ nhật',
    ];
    final weekdayName = days[dt.weekday - 1];
    final timeStr = DateFormat('HH:mm').format(dt);
    final dateStr = DateFormat('dd/MM/yyyy').format(dt);
    return '$timeStr $weekdayName, $dateStr';
  }

  Future<void> _pickDateTime() async {
    final colors = context.colors;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: colors.bgCard,
              onSurface: colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: colors.bgCard,
              onSurface: colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _showDurationPicker() async {
    final hours = await SocialDurationSheet.show(context, _durationHours);
    if (hours != null && mounted) setState(() => _durationHours = hours);
  }

  Future<void> _showPriceInputDialog() async {
    final price = await SocialPriceDialog.show(context, _price);
    if (price != null && mounted) setState(() => _price = price);
  }

  Future<void> _showPrivacyPicker() async {
    final privacy = await SocialPrivacySheet.show(context, _privacy);
    if (privacy != null && mounted) setState(() => _privacy = privacy);
  }

  /// Invalidate cache Social theo CLB để tab Hoạt động cập nhật ngay.
  /// [session] là kèo vừa tạo/sửa (lấy communityId thực tế từ server).
  void _invalidateClubSocialProviders(
    WidgetRef ref,
    SocialSessionModel session,
  ) {
    final attachedId = session.communityId ?? session.community?.id;
    final initialAttachedId = widget.initialSession?.communityId;
    final ids = <String>{
      if (widget.clubId.isNotEmpty) widget.clubId,
      if (attachedId != null && attachedId.isNotEmpty) attachedId,
      if (initialAttachedId != null && initialAttachedId.isNotEmpty)
        initialAttachedId,
    };
    for (final id in ids) {
      ref.invalidate(clubSocialSessionsQueryProvider(id));
      ref.invalidate(communitySocialSessionsQueryProvider(id));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final venueNameText = _venueNameController.text.trim();
    final venueAddressText = _venueAddressController.text.trim();
    if (venueNameText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên sân.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (venueAddressText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập địa điểm.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = ref.read(userProfileProvider).asData?.value;
    final customTitle = _titleController.text.trim();
    final resolvedTitle = customTitle.isNotEmpty
        ? customTitle
        : _getComputedDefaultTitle();

    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(socialSessionRepositoryProvider);

      if (widget.initialSession != null) {
        final sessionId = widget.initialSession!.id;
        final updateFields = <String, dynamic>{
          'sport': _selectedSportKey,
          'title': resolvedTitle.length > 100
              ? resolvedTitle.substring(0, 100)
              : resolvedTitle,
          if (notes != null && notes.isNotEmpty) 'description': notes,
          'playFormat': _selectedFormat,
          'startAt': _selectedDateTime.toIso8601String(),
          'durationMinutes': (_durationHours * 60).round(),
          'venueName': venueNameText,
          'venueAddress': venueAddressText,
          'maxSlots': _maxParticipants,
          'feePerSlot': _price,
          'levelRequirement': 'ALL',
          'visibility': _privacy == 'Nội bộ CLB' ? 'CLUB_ONLY' : 'PUBLIC',
          if (_isClubAttached && widget.clubId.isNotEmpty)
            'communityId': widget.clubId,
        };

        final updatedSession = await repo.update(sessionId, updateFields);

        ref.read(socialSessionsProvider.notifier).refresh();
        ref.read(socialSessionDetailProvider(sessionId).notifier).refresh();
        // Tab Hoạt động CLB dùng provider riêng theo communityId —
        // phải invalidate để kèo mới/sửa hiện ngay ở filter "Mở".
        _invalidateClubSocialProviders(ref, updatedSession);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cập nhật kèo "$resolvedTitle" thành công!'),
              backgroundColor: context.colors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(updatedSession);
        }
      } else {
        final request = CreateSocialSessionRequest(
          sport: _selectedSportKey,
          title: resolvedTitle.length > 100
              ? resolvedTitle.substring(0, 100)
              : resolvedTitle,
          description: notes,
          playFormat: _selectedFormat,
          startAt: _selectedDateTime,
          durationMinutes: (_durationHours * 60).round(),
          venueName: venueNameText,
          venueAddress: venueAddressText,
          maxSlots: _maxParticipants,
          feePerSlot: _price,
          levelRequirement: 'ALL',
          visibility: _privacy == 'Nội bộ CLB' ? 'CLUB_ONLY' : 'PUBLIC',
          contactPhone: user?.phoneNumber,
          communityId: _isClubAttached && widget.clubId.isNotEmpty
              ? widget.clubId
              : null,
        );

        final createdSession = await repo.create(request);

        ref.read(socialSessionsProvider.notifier).refresh();
        ref
            .read(socialFilterProvider.notifier)
            .setSelectedDate(_selectedDateTime);
        // Tab Hoạt động CLB dùng provider riêng theo communityId —
        // phải invalidate để kèo mới hiện ngay ở filter "Mở".
        _invalidateClubSocialProviders(ref, createdSession);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tạo Social "$resolvedTitle" thành công!'),
              backgroundColor: context.colors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(createdSession);
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      widget.initialSession != null
                          ? 'CẬP NHẬT KÈO'
                          : 'TẠO KÈO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    widget.initialSession != null
                        ? const SizedBox(width: 48)
                        : Icon(
                            Icons.swap_horiz_rounded,
                            color: colors.textPrimary,
                          ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.border),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── 1. SECTION CLB (Hình 1) ───
                      if (_isClubAttached) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CLB',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.textSecondary,
                              ),
                            ),
                            Text(
                              'Thay đổi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: colors.success.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.bgCard,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: colors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: colors.success.withValues(
                                          alpha: 0.2,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.sports_tennis_rounded,
                                        color: colors.success,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        widget.clubName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Thành viên CLB có gắn thẻ sẽ nhận được thông báo và được tự động mời tham gia kèo.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  color: colors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _isClubAttached = false);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      'Xóa CLB',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: colors.error,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ─── 2. SECTION MÔN THỂ THAO & THỂ THỨC (Hình 1) ───
                      Text(
                        'MÔN THỂ THAO',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: colors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Sports Grid
                      Row(
                        children: _sports.map((sport) {
                          final isSelected = _selectedSportKey == sport.key;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedSportKey = sport.key;
                                    _selectedSportName = sport.name;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colors.success.withValues(alpha: 0.16)
                                        : colors.bgCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? colors.success
                                          : colors.border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      if (sport.key == 'pickleball')
                                        Positioned(
                                          top: 6,
                                          left: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.refereeColor,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'CLB',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              sport.icon,
                                              size: 30,
                                              color: isSelected
                                                  ? colors.textPrimary
                                                  : colors.textSecondary,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              sport.name,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: colors.textPrimary,
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
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Format Chips: Giao lưu, Đánh vòng tròn, Đánh đơn, Đánh đôi
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _formats.map((fmt) {
                          final isSelected = _selectedFormat == fmt;
                          return InkWell(
                            onTap: () {
                              setState(() => _selectedFormat = fmt);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: colors.bgCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : colors.border,
                                  width: isSelected ? 1.8 : 1,
                                ),
                              ),
                              child: Text(
                                fmt,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : colors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: colors.border),
                      const SizedBox(height: 16),

                      // ─── 3. SECTION KÈO (Hình 2) ───
                      Text(
                        'KÈO',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: colors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      SocialSettingTile(
                        icon: Icons.calendar_month_outlined,
                        label: _formatDateTimeDisplay(_selectedDateTime),
                        onTap: _pickDateTime,
                      ),
                      const SizedBox(height: 10),

                      SocialSettingTile(
                        icon: Icons.access_time_rounded,
                        label:
                            '${_durationHours == _durationHours.toInt() ? _durationHours.toInt() : _durationHours} giờ',
                        onTap: _showDurationPicker,
                      ),
                      const SizedBox(height: 10),

                      // Tách venueName và venueAddress thành 2 input field (Yêu cầu 5)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Icon(
                              Icons.location_on_outlined,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _venueNameController,
                                  maxLength: 100,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Tên sân',
                                    hintText:
                                        'Nhập tên sân (VD: 22 Cộng Hòa)...',
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Tên sân không được để trống';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _venueAddressController,
                                  maxLength: 500,
                                  maxLines: 2,
                                  minLines: 1,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    color: colors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Địa điểm',
                                    hintText: 'Nhập địa chỉ cụ thể...',
                                    counterText: '',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Địa điểm không được để trống';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: colors.border),
                      const SizedBox(height: 16),

                      // ─── 4. CẤU HÌNH NGƯỜI CHƠI, QUYỀN RIÊNG TƯ, PHÍ (Hình 2) ───
                      SocialParticipantCounter(
                        initialValue: _maxParticipants,
                        onChanged: (value) => _maxParticipants = value,
                      ),
                      const SizedBox(height: 14),

                      SocialSettingTile(
                        icon: Icons.lock_outline_rounded,
                        label: 'Quyền riêng tư',
                        value: _privacy,
                        verticalPadding: 6,
                        onTap: _showPrivacyPicker,
                      ),
                      const SizedBox(height: 14),

                      SocialSettingTile(
                        icon: Icons.local_offer_outlined,
                        label: 'Phí tham gia kèo',
                        value: _formatCurrency(_price),
                        valueColor: _price > 0 ? colors.success : null,
                        verticalPadding: 6,
                        onTap: _showPriceInputDialog,
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: colors.border),
                      const SizedBox(height: 16),

                      // ─── 5. SECTION TÊN KÈO & GHI CHÚ (Hình 3) ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TÊN KÈO',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: colors.textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _titleController,
                            builder: (context, child) {
                              final length = _titleController.text.length;
                              return Text(
                                '$length/100',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: colors.textMuted,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _titleController,
                        maxLength: 100,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: _getComputedDefaultTitle(),
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Ghi chú
                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        minLines: 3,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Thêm ghi chú',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            widget.initialSession != null
                                ? 'Cập nhật kèo'
                                : 'Tạo kèo',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
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
}
