import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/social/models/social_session_model.dart';
import 'package:app_quanly_giaidau/features/social/providers/social_provider.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_join_bottom_sheet.dart';

class SocialDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final bool? isAdmin;

  const SocialDetailScreen({
    super.key,
    required this.sessionId,
    this.isAdmin,
  });

  @override
  ConsumerState<SocialDetailScreen> createState() => _SocialDetailScreenState();
}

class _SocialDetailScreenState extends ConsumerState<SocialDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatInputController = TextEditingController();

  bool get _isAdmin => widget.isAdmin ?? true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isAdmin ? 4 : 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = ref.watch(socialSessionDetailProvider(widget.sessionId));

    if (session == null) {
      return Scaffold(
        backgroundColor: colors.bgDark,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text('Chi tiết Social', style: TextStyle(color: colors.textPrimary)),
        ),
        body: Center(
          child: Text(
            'Không tìm thấy thông tin buổi Social',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: _buildAppBar(context, colors, session),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session Title Headline (IMG2 & IMG3)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              session.title.toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
                letterSpacing: 0.2,
                height: 1.25,
              ),
            ),
          ),

          // Horizontal Tabs (4 tabs for Admin, 3 for Member) - style from club_detail_tab_delegate
          SizedBox(
            height: 44.0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  final activeIndex = _tabController.index;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTabItem(
                        index: 0,
                        label: 'Chi tiết',
                        isActive: activeIndex == 0,
                        colors: colors,
                      ),
                      const SizedBox(width: 14),
                      _buildTabItem(
                        index: 1,
                        label: 'Người tham gia',
                        isActive: activeIndex == 1,
                        colors: colors,
                      ),
                      if (_isAdmin) ...[
                        const SizedBox(width: 14),
                        _buildTabItem(
                          index: 2,
                          label: 'Thanh toán',
                          isActive: activeIndex == 2,
                          colors: colors,
                        ),
                      ],
                      const SizedBox(width: 14),
                      _buildTabItem(
                        index: _isAdmin ? 3 : 2,
                        label: 'Trò chuyện',
                        isActive: activeIndex == (_isAdmin ? 3 : 2),
                        colors: colors,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(isDark, session, colors),
                _buildParticipantsTab(colors, session),
                if (_isAdmin) _buildPaymentTab(colors, session),
                _buildChatTab(isDark, session, colors),
              ],
            ),
          ),

          // Bottom Sticky Action Bar (IMG2 & IMG3)
          _buildBottomActionBar(context, isDark, session, colors),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String label,
    required bool isActive,
    required AppColorsExtension colors,
  }) {
    return InkWell(
      onTap: () => _tabController.animateTo(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        height: 44.0,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive ? AppTheme.primary : colors.textMuted,
                ),
              ),
            ),
            const Spacer(),
            Container(
              height: 2.5,
              width: 24.0,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppColorsExtension colors,
    SocialSessionModel session,
  ) {
    return AppBar(
      backgroundColor: colors.bgDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: colors.textPrimary,
          size: 24,
        ),
        onPressed: () => context.pop(),
      ),
      centerTitle: true,
      title: Text(
        session.dateDisplay,
        style: const TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.ios_share_rounded,
            color: colors.textPrimary,
            size: 22,
          ),
          onPressed: () => _handleShare(session),
        ),
        IconButton(
          icon: Icon(
            Icons.more_vert_rounded,
            color: colors.textPrimary,
            size: 22,
          ),
          onPressed: () => _showMoreOptions(context, session),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 1: CHI TIẾT (IMG2 Upper + IMG3 Lower)
  // ═══════════════════════════════════════════════════════
  Widget _buildDetailsTab(
    bool isDark,
    SocialSessionModel session,
    AppColorsExtension colors,
  ) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── UPPER PART (IMG2) ───

          // 1. Club Host Banner Card (Light green background matching IMG2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? colors.bgCard
                  : colors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.success.withValues(alpha: isDark ? 0.3 : 0.2),
              ),
            ),
            child: Row(
              children: [
                // Club Logo Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.black26 : Colors.white,
                    border: Border.all(
                      color: colors.success,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.sports_tennis_rounded,
                      size: 22,
                      color: colors.success,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Host Name & Frequency
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🇻🇳 ', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Text(
                              session.hostClubName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.hostFrequency,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // 'Xem lịch' outlined button
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Xem lịch sinh hoạt của ${session.hostClubName}',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Xem lịch',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Participants Avatars Row & 'Liên hệ BTC' (IMG2)
          Row(
            children: [
              // Host Avatar Circle (e.g. MQ)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.success.withValues(alpha: 0.25),
                ),
                child: Center(
                  child: Text(
                    'MQ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Empty Slot Circles (Dashed/Grey border circles)
              for (int i = 0; i < 3; i++)
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.bgSurface,
                  ),
                ),

              // '+4' Counter Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.borderLight,
                ),
                child: const Center(
                  child: Text(
                    '+4',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 'Liên hệ BTC' link
          GestureDetector(
            onTap: () => _handleContactHost(session, colors),
            child: const Text(
              'Liên hệ BTC',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Date & Time Row (IMG2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 22,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.fullDateTimeDisplay,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${session.durationHours} giờ',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đã lưu buổi Social vào lịch điện thoại!',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text(
                        'Thêm vào lịch',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 4. Location Row (IMG2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 24,
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.venueName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary, // Blue location name
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.venueAddress,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.distanceKm.toStringAsFixed(1)} km từ Nhà',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 5. Play Format Row (IMG2)
          Row(
            children: [
              Icon(
                Icons.sports_tennis_outlined,
                size: 22,
                color: colors.textPrimary,
              ),
              const SizedBox(width: 14),
              Text(
                session.playFormat,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 6. Price Row (IMG2)
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 22,
                color: colors.textPrimary,
              ),
              const SizedBox(width: 14),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Mỗi người · ',
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.textSecondary,
                      ),
                    ),
                    TextSpan(
                      text: currencyFormatter.format(session.pricePerSlot),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Divider between upper details and lower notes
          Divider(
            color: colors.border,
            thickness: 1,
          ),
          const SizedBox(height: 16),

          // ─── LOWER PART: LƯU Ý / GHI CHÚ (IMG3) ───
          Text(
            'Lưu ý',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.border,
              ),
            ),
            child: SelectableText(
              session.descriptionNotes,
              style: TextStyle(
                fontSize: 14.5,
                color: colors.textPrimary,
                height: 1.6,
              ),
            ),
          ),

          if (_isAdmin) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    _showFindPlayersModal(context, session, isDark, colors),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                ),
                child: const Text(
                  'Tìm thêm người chơi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 2: NGƯỜI THAM GIA (Ảnh 3 Reclub)
  // ═══════════════════════════════════════════════════════
  Widget _buildParticipantsTab(AppColorsExtension colors, SocialSessionModel session) {
    final host = session.participants.where((p) => p.isHost).firstOrNull ??
        SocialParticipantModel(
          id: 'host_default',
          name: 'Sơn Bảo',
          initials: 'SB',
          skillLevel: session.skillLevel,
          isHost: true,
          status: 'Người tổ chức',
          joinedAt: DateTime.now(),
        );

    final totalSlots = session.maxParticipants;
    final confirmedCount = session.participants.length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // ─── 1. NGƯỜI TỔ CHỨC ───
        Text(
          'NGƯỜI TỔ CHỨC • 1',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: colors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.success.withValues(alpha: 0.25),
                      border: Border.all(
                        color: colors.success.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        host.initials,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                host.name,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Divider(color: colors.border, height: 1),
        const SizedBox(height: 14),

        // ─── 2. XÁC NHẬN THAM GIA Header & More icon ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'XÁC NHẬN THAM GIA • $confirmedCount/$totalSlots',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.more_horiz_rounded,
                color: colors.textSecondary,
                size: 22,
              ),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Sort dropdown
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sắp xếp: Xác nhận gần đây',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: colors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ─── 3. GRID 4 COLUMNS (Ảnh 3 Reclub) ───
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: totalSlots,
          itemBuilder: (context, index) {
            if (index < session.participants.length) {
              final p = session.participants[index];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.isHost
                          ? colors.success.withValues(alpha: 0.25)
                          : AppTheme.primaryLight.withValues(alpha: 0.35),
                      border: Border.all(
                        color: p.isHost
                            ? colors.success.withValues(alpha: 0.6)
                            : AppTheme.primary.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        p.initials,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              );
            } else {
              // Empty slot with '+' icon
              return InkWell(
                onTap: _isAdmin
                    ? () => _showAddParticipantDialog(context, session, index + 1)
                    : null,
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.bgSurface,
                        border: Border.all(
                          color: colors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 26,
                        color: colors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Slot ${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB THANH TOÁN (Dành cho Quản lý CLB)
  // ═══════════════════════════════════════════════════════
  Widget _buildPaymentTab(AppColorsExtension colors, SocialSessionModel session) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final totalExpected = session.maxParticipants * session.pricePerSlot;
    final payments = session.payments;
    final paidPayments = payments.where((p) => p.status == 'PAID').toList();
    final totalPaidAmount = paidPayments.fold<int>(0, (sum, p) => sum + p.totalAmount);
    final pendingCount = session.participants.length - paidPayments.length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Tổng quan tài chính
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TỔNG QUAN TÀI CHÍNH',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đã thu',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormatter.format(totalPaidAmount),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: colors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: colors.border,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dự thu tối đa',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormatter.format(totalExpected),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: colors.border, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đơn giá: ${currencyFormatter.format(session.pricePerSlot)} / vé',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    'Đã thanh toán: ${paidPayments.length}/${session.participants.length}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Danh sách thanh toán
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DANH SÁCH THANH TOÁN',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            if (pendingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Còn $pendingCount chưa thu',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.warning,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (payments.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Text(
              'Chưa có dữ liệu thanh toán',
              style: TextStyle(color: colors.textMuted),
            ),
          )
        else
          ...payments.map((payment) {
            final isPaid = payment.status == 'PAID';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isPaid
                        ? colors.success.withValues(alpha: 0.2)
                        : colors.warning.withValues(alpha: 0.2),
                    child: Text(
                      payment.participantName.isNotEmpty
                          ? payment.participantName.trim().split(' ').last.substring(0, 1).toUpperCase()
                          : 'P',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isPaid ? colors.success : colors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.participantName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${payment.ticketCount} vé • ${payment.paymentMethod == 'TRANSFER' ? 'Chuyển khoản' : 'Tiền mặt'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormatter.format(payment.totalAmount),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          ref.read(socialSessionsProvider.notifier).togglePaymentStatus(
                                session.id,
                                payment.id,
                              );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? colors.success.withValues(alpha: 0.15)
                                : colors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
                                size: 12,
                                color: isPaid ? colors.success : colors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPaid ? 'ĐÃ THU' : 'CHƯA THU',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isPaid ? colors.success : colors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showAddParticipantDialog(
    BuildContext context,
    SocialSessionModel session,
    int slotNumber,
  ) {
    final colors = context.colors;
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        ),
        title: Text(
          'Thêm người tham gia (Slot $slotNumber)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập họ tên thành viên...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                ref.read(socialSessionsProvider.notifier).addParticipantToSlot(
                      sessionId: session.id,
                      participantName: name,
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã thêm $name vào slot $slotNumber thành công!'),
                    backgroundColor: colors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Thêm slot'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 3: TRÒ CHUYỆN (IMG4)
  // ═══════════════════════════════════════════════════════
  Widget _buildChatTab(
    bool isDark,
    SocialSessionModel session,
    AppColorsExtension colors,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // System notification status matching IMG4
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Sơn Bảo đã tham gia cuộc trò chuyện.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bạn đã cập nhật lệ phí tham dự.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),

              // Chat messages
              ...session.chatMessages.map((msg) {
                if (msg.sharedSession != null) {
                  return _buildSocialSessionChatCard(
                    context,
                    msg.sharedSession!,
                    colors,
                    isDark,
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: msg.isHost
                            ? colors.success.withValues(alpha: 0.25)
                            : AppTheme.primaryLight.withValues(alpha: 0.35),
                        child: Text(
                          msg.senderInitials,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.bgSurface,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLarge),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    msg.senderName,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${msg.time.hour}:${msg.time.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg.message,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        // Chat Input Row (matching bottom of IMG4)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colors.bgCard,
            border: Border(
              top: BorderSide(
                color: colors.border,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatInputController,
                    decoration: InputDecoration(
                      hintText: 'Viết tin nhắn...',
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: colors.textMuted,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppTheme.primary),
                      ),
                      filled: true,
                      fillColor: colors.bgSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: AppTheme.primary,
                  ),
                  onPressed: () {
                    final text = _chatInputController.text.trim();
                    if (text.isNotEmpty) {
                      ref
                          .read(socialSessionsProvider.notifier)
                          .addChatMessage(session.id, text);
                      _chatInputController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Card Social Session inside Chat (IMG4) ──
  Widget _buildSocialSessionChatCard(
    BuildContext context,
    SocialSessionModel targetSession,
    AppColorsExtension colors,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Date/Time Box
              Container(
                width: 78,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                color: colors.bgSurface,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sports_tennis_rounded,
                      size: 26,
                      color: colors.textPrimary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      targetSession.dayOfWeek,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      '${targetSession.dayOfMonth.toString().padLeft(2, '0')}/${targetSession.dateTime.month.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      targetSession.timeSlot,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Right Session Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge: Tổ chức + Club Name
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.success.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Text(
                              'Tổ chức',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colors.success,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              targetSession.hostClubName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        targetSession.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              targetSession.venueName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Slot counter + Host avatar
                      Row(
                        children: [
                          Text(
                            '${targetSession.currentParticipants}/${targetSession.maxParticipants}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.success.withValues(alpha: 0.25),
                              border: Border.all(
                                color: colors.success.withValues(alpha: 0.6),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                targetSession.participants.isNotEmpty
                                    ? targetSession.participants.first.initials
                                    : 'SB',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  BOTTOM ACTION BAR (IMG2 & IMG3)
  // ═══════════════════════════════════════════════════════
  Widget _buildBottomActionBar(
    BuildContext context,
    bool isDark,
    SocialSessionModel session,
    AppColorsExtension colors,
  ) {
    if (_isAdmin) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(
          top: BorderSide(
            color: colors.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left Button: 'Chat với host'
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => _handleContactHost(session, colors),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppTheme.primary,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    foregroundColor: AppTheme.primary,
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Chat với host',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Right Button: 'Yêu cầu tham gia'
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _handleRequestJoin(context, session),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Yêu cầu tham gia',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Modal Tìm thêm người chơi (IMG3) ──
  void _showFindPlayersModal(
    BuildContext context,
    SocialSessionModel session,
    bool isDark,
    AppColorsExtension colors,
  ) {
    final inviteMessage = '''${session.title}
⏰ ${session.dayOfWeek}, ngày ${session.dayOfMonth.toString().padLeft(2, '0')} Th${session.dateTime.month.toString().padLeft(2, '0')} lúc ${session.timeSlot}
📍 ${session.venueName}

RSVP: https://sporto.vn/social/${session.id}''';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Tìm thêm người chơi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                // Preview Card (IMG3)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('⏰ ', style: TextStyle(fontSize: 13)),
                          Text(
                            '${session.dayOfWeek}, ngày ${session.dayOfMonth.toString().padLeft(2, '0')} Th${session.dateTime.month.toString().padLeft(2, '0')} lúc ${session.timeSlot}',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('📍 ', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Text(
                              session.venueName,
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'RSVP: https://sporto.vn/social/${session.id}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(color: colors.border, height: 1),
                      const SizedBox(height: 8),

                      // Button 'Sao chép tin nhắn' inside the card
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: inviteMessage));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  const Text('Đã sao chép tin nhắn mời!'),
                              backgroundColor: colors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Sao chép tin nhắn',
                                style: TextStyle(
                                  fontSize: 13.5,
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
                ),
                const SizedBox(height: 12),

                // Option 1: Sao chép tin nhắn
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.copy_rounded,
                    color: colors.textPrimary,
                    size: 22,
                  ),
                  title: Text(
                    'Sao chép tin nhắn',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: inviteMessage));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Đã sao chép tin nhắn mời!'),
                        backgroundColor: colors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                // Option 2: Chia sẻ trong cuộc trò chuyện (IMG4)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: colors.textPrimary,
                    size: 22,
                  ),
                  title: Text(
                    'Chia sẻ trong cuộc trò chuyện',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref
                        .read(socialSessionsProvider.notifier)
                        .addSharedSessionMessage(session.id, session);
                    _tabController.animateTo(_isAdmin ? 3 : 2);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Đã chia sẻ buổi Social vào cuộc trò chuyện!',
                        ),
                        backgroundColor: colors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleContactHost(
    SocialSessionModel session, [
    AppColorsExtension? colorsParam,
  ]) {
    final colors = colorsParam ?? context.colors;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Liên hệ Host: ${session.hostClubName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (session.hostPhone != null)
                  ListTile(
                    leading: Icon(Icons.phone, color: colors.success),
                    title: Text('Gọi điện: ${session.hostPhone}'),
                    onTap: () {
                      Navigator.pop(ctx);
                      launchUrl(Uri.parse('tel:${session.hostPhone}'));
                    },
                  ),
                if (session.zaloGroupUrl != null)
                  ListTile(
                    leading: const Icon(Icons.group, color: AppTheme.primary),
                    title: const Text('Tham gia nhóm Zalo'),
                    subtitle: Text(session.zaloGroupUrl!),
                    onTap: () {
                      Navigator.pop(ctx);
                      launchUrl(
                        Uri.parse(session.zaloGroupUrl!),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppTheme.primary,
                  ),
                  title: const Text('Gửi tin nhắn trong app'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _tabController.animateTo(_isAdmin ? 3 : 2); // Switch to Chat tab
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleRequestJoin(BuildContext context, SocialSessionModel session) {
    SocialJoinBottomSheet.show(context, session);
  }

  void _handleShare(SocialSessionModel session) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép link chia sẻ buổi ${session.title}!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMoreOptions(BuildContext context, SocialSessionModel session) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.report_problem_outlined),
                title: const Text('Báo cáo buổi Social này'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cảm ơn bạn đã gửi báo cáo.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: const Text('Ẩn các buổi của Host này'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
