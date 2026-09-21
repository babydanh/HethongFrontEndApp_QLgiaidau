import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/social/models/social_session_model.dart';
import 'package:app_quanly_giaidau/features/social/providers/social_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';

class CreateSocialScreen extends ConsumerStatefulWidget {
  final String clubId;
  final String clubName;
  final String? clubLogoUrl;

  const CreateSocialScreen({
    super.key,
    required this.clubId,
    required this.clubName,
    this.clubLogoUrl,
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

  // Venue / Location (NVARCHAR(500))
  final TextEditingController _venueController = TextEditingController();

  // Configurations
  int _maxParticipants = 6;
  String _privacy = 'Công khai';
  final TextEditingController _priceController = TextEditingController();
  int _price = 0;

  // Title and Notes
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isClubAttached = true;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _venueController.dispose();
    _priceController.dispose();
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

  String _getHostFullName() {
    final user = ref.read(userProfileProvider).asData?.value;
    final fullName = user?.fullName?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
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

  String _getDayOfWeek(DateTime dt) {
    switch (dt.weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return 'T2';
    }
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

  void _showDurationPicker() {
    final colors = context.colors;
    final options = [1.0, 1.5, 2.0, 2.5, 3.0, 4.0];

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Chọn thời lượng kèo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const Divider(),
                ...options.map(
                  (d) => ListTile(
                    title: Text(
                      '${d == d.toInt() ? d.toInt() : d} giờ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _durationHours == d
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _durationHours == d
                            ? AppTheme.primary
                            : colors.textPrimary,
                      ),
                    ),
                    trailing: _durationHours == d
                        ? const Icon(Icons.check, color: AppTheme.primary)
                        : null,
                    onTap: () {
                      setState(() => _durationHours = d);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPriceInputDialog() {
    final colors = context.colors;
    final tempController = TextEditingController(
      text: _price > 0 ? _price.toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          ),
          title: Text(
            'Phí tham gia kèo (VNĐ)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Để trống hoặc nhập 0 nếu là kèo miễn phí.',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tempController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'VD: 50000',
                  suffixText: 'VNĐ',
                  suffixStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _price = 0;
                  _priceController.clear();
                });
                Navigator.pop(ctx);
              },
              child: Text('Miễn phí', style: TextStyle(color: colors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(tempController.text.trim()) ?? 0;
                setState(() {
                  _price = parsed;
                  _priceController.text = parsed > 0 ? parsed.toString() : '';
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPicker() {
    final colors = context.colors;
    final options = ['Công khai', 'Nội bộ CLB'];

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Quyền riêng tư',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const Divider(),
                ...options.map(
                  (p) => ListTile(
                    title: Text(
                      p,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _privacy == p
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _privacy == p
                            ? AppTheme.primary
                            : colors.textPrimary,
                      ),
                    ),
                    trailing: _privacy == p
                        ? const Icon(Icons.check, color: AppTheme.primary)
                        : null,
                    onTap: () {
                      setState(() => _privacy = p);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final venueText = _venueController.text.trim();
    if (venueText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập địa điểm tổ chức kèo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = ref.read(userProfileProvider).asData?.value;
    final hostFullName = _getHostFullName();
    final initials = hostFullName.isNotEmpty
        ? hostFullName.trim().split(' ').last.substring(0, 1).toUpperCase()
        : 'H';

    final customTitle = _titleController.text.trim();
    final resolvedTitle = customTitle.isNotEmpty
        ? customTitle
        : _getComputedDefaultTitle();

    final timeSlot = DateFormat('HH:mm').format(_selectedDateTime);
    final dayOfWeek = _getDayOfWeek(_selectedDateTime);
    final dayOfMonth = _selectedDateTime.day;
    final dateDisplay = '$timeSlot ${_formatDateTimeDisplay(_selectedDateTime).split(' ')[1]}, $dayOfMonth/${_selectedDateTime.month}';
    final fullDateTimeDisplay = _formatDateTimeDisplay(_selectedDateTime);

    final sessionId = 'social_${DateTime.now().millisecondsSinceEpoch}';
    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : 'Buổi giao lưu môn $_selectedSportName câu lạc bộ ${widget.clubName}.';

    final newSession = SocialSessionModel(
      id: sessionId,
      clubId: _isClubAttached ? widget.clubId : null,
      creatorId: user?.id ?? 'me',
      title: resolvedTitle,
      status: 'OPEN',
      sport: _selectedSportKey,
      sportName: _selectedSportName,
      hostClubName: _isClubAttached ? widget.clubName : hostFullName,
      hostClubAvatar: _isClubAttached ? widget.clubLogoUrl : user?.avatarUrl,
      hostFrequency: 'Hàng tuần',
      hostPhone: user?.phoneNumber ?? '0901234567',
      hostZalo: user?.phoneNumber ?? '0901234567',
      playFormat: _selectedFormat,
      venueName: venueText.length > 50 ? venueText.substring(0, 50) : venueText,
      venueAddress: venueText,
      distanceKm: 1.5,
      dateTime: _selectedDateTime,
      durationHours: _durationHours.round(),
      timeSlot: timeSlot,
      dateDisplay: dateDisplay,
      fullDateTimeDisplay: fullDateTimeDisplay,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
      currentParticipants: 1,
      maxParticipants: _maxParticipants,
      pricePerSlot: _price,
      skillLevel: 'Tất cả trình độ',
      notes: notes,
      participants: [
        SocialParticipantModel(
          id: user?.id ?? 'part_host_${DateTime.now().millisecondsSinceEpoch}',
          name: hostFullName,
          avatarUrl: user?.avatarUrl,
          initials: initials,
          skillLevel: 'Tất cả trình độ',
          isHost: true,
          status: 'Host · Đã tham gia',
          joinedAt: DateTime.now(),
        ),
      ],
      matches: const [],
      chatMessages: [
        SocialChatMessageModel(
          id: 'msg_welcome_${DateTime.now().millisecondsSinceEpoch}',
          senderName: hostFullName,
          senderAvatar: user?.avatarUrl,
          senderInitials: initials,
          isHost: true,
          isMe: true,
          message: 'Chào mừng các bạn đến với buổi giao lưu $resolvedTitle!',
          time: DateTime.now(),
        ),
      ],
      payments: [
        SocialPaymentModel(
          id: 'pay_host_${DateTime.now().millisecondsSinceEpoch}',
          participantId: user?.id ?? 'part_host',
          participantName: hostFullName,
          participantAvatar: user?.avatarUrl,
          ticketCount: 1,
          totalAmount: _price,
          status: 'PAID',
          paymentMethod: 'CASH',
          paidAt: DateTime.now(),
        ),
      ],
    );

    // Save to Riverpod state
    ref.read(socialSessionsProvider.notifier).addSession(newSession);
    ref.read(socialFilterProvider.notifier).setDayOfMonth(dayOfMonth);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tạo Social "$resolvedTitle" thành công!'),
        backgroundColor: context.colors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop(newSession);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      'TẠO KÈO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Icon(
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
                                        color: colors.success.withValues(alpha: 0.2),
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
                                              borderRadius: BorderRadius.circular(4),
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

                      // Chọn ngày và giờ
                      InkWell(
                        onTap: _pickDateTime,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: AppTheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  _formatDateTimeDisplay(_selectedDateTime),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: colors.textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Thời lượng
                      InkWell(
                        onTap: _showDurationPicker,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: AppTheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  '${_durationHours == _durationHours.toInt() ? _durationHours.toInt() : _durationHours} giờ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: colors.textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Chọn địa điểm (NVARCHAR(500))
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
                            child: TextFormField(
                              controller: _venueController,
                              maxLength: 500,
                              maxLines: 2,
                              minLines: 1,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Nhập địa điểm thi đấu...',
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: colors.border),
                      const SizedBox(height: 16),

                      // ─── 4. CẤU HÌNH NGƯỜI CHƠI, QUYỀN RIÊNG TƯ, PHÍ (Hình 2) ───
                      // Số người chơi
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            color: AppTheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Số người chơi',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if (_maxParticipants > 2) {
                                setState(() => _maxParticipants--);
                              }
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.border),
                              ),
                              child: Icon(
                                Icons.remove,
                                size: 18,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '$_maxParticipants',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if (_maxParticipants < 64) {
                                setState(() => _maxParticipants++);
                              }
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.border),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 18,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Quyền riêng tư
                      InkWell(
                        onTap: _showPrivacyPicker,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                color: AppTheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Quyền riêng tư',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                _privacy,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                color: colors.textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Phí tham gia kèo
                      InkWell(
                        onTap: _showPriceInputDialog,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_offer_outlined,
                                color: AppTheme.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Phí tham gia kèo',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                _formatCurrency(_price),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _price > 0
                                      ? colors.success
                                      : colors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                color: colors.textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
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
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? colors.bgElevated
                          : const Color(0xFF334155),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Tạo kèo',
                      style: TextStyle(
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
