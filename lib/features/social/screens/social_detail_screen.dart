import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:app_quanly_giaidau/providers/social_provider.dart';
import 'package:app_quanly_giaidau/features/social/widgets/detail_tab/social_join_bottom_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/detail_tab/social_details_tab.dart';
import 'package:app_quanly_giaidau/features/social/widgets/participant_tab/social_participants_tab.dart';
import 'package:app_quanly_giaidau/features/social/widgets/payment_tab/social_payment_tab.dart';
import 'package:app_quanly_giaidau/features/social/widgets/chat_tab/social_chat_tab.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_cancel_session_dialog.dart';
import 'package:app_quanly_giaidau/features/social/widgets/detail_tab/social_contact_host_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/detail_tab/social_find_players_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/participant_tab/social_add_participant_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_more_options_sheet.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/features/social/screens/create_social_screen.dart';

class SocialDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final bool? isHost;

  const SocialDetailScreen({super.key, required this.sessionId, this.isHost});

  @override
  ConsumerState<SocialDetailScreen> createState() => _SocialDetailScreenState();
}

class _SocialDetailScreenState extends ConsumerState<SocialDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  bool get _isHost {
    if (widget.isHost != null) return widget.isHost!;
    final session = ref
        .read(socialSessionDetailProvider(widget.sessionId))
        .asData
        ?.value;
    if (session != null) {
      if (session.isHost) return true;
      final currentUser = ref.read(userProfileProvider).asData?.value;
      if (session.creatorId.isNotEmpty &&
          currentUser != null &&
          session.creatorId == currentUser.id) {
        return true;
      }
      if (session.creatorId == 'me') return true;
      if (session.participants.any(
        (p) =>
            p.isHost &&
            (p.id == currentUser?.id ||
                (currentUser != null && p.name == currentUser.fullName)),
      )) {
        return true;
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isHost ? 4 : 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionAsync = ref.watch(
      socialSessionDetailProvider(widget.sessionId),
    );

    return sessionAsync.when(
      loading: () => Scaffold(
        backgroundColor: colors.bgDark,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Chi tiết Social',
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: colors.bgDark,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Chi tiết Social',
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  style: TextStyle(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref
                      .read(
                        socialSessionDetailProvider(widget.sessionId).notifier,
                      )
                      .refresh(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (session) {
        final host = widget.isHost ?? session.isHost;
        final showPayment = host && session.feePerSlot > 0;
        final tabLength = 3 + (showPayment ? 1 : 0);
        if (_tabController.length != tabLength) {
          _tabController.dispose();
          _tabController = TabController(length: tabLength, vsync: this);
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
                          if (showPayment) ...[
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
                            index: showPayment ? 3 : 2,
                            label: 'Trò chuyện',
                            isActive: activeIndex == (showPayment ? 3 : 2),
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
                    SocialDetailsTab(
                      session: session,
                      isHost: host,
                      onContactHost: () => _handleContactHost(session),
                      onFindPlayers: () => SocialFindPlayersSheet.show(
                        context,
                        session,
                        onShareToChat: () => _shareToClubChat(session),
                      ),
                    ),
                    SocialParticipantsTab(
                      session: session,
                      isHost: host,
                      onAddParticipant: (slot) =>
                          SocialAddParticipantSheet.show(
                            context,
                            session,
                            slot,
                          ),
                    ),
                    if (showPayment) SocialPaymentTab(session: session),
                    SocialChatTab(session: session),
                  ],
                ),
              ),

              // Bottom Sticky Action Bar (IMG2 & IMG3)
              _buildBottomActionBar(context, isDark, session, colors),
            ],
          ),
        );
      },
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
        icon: Icon(Icons.arrow_back, color: colors.textPrimary, size: 24),
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
          onPressed: () => _showMoreOptions(session),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 1: CHI TIẾT (IMG2 Upper + IMG3 Lower)
  // ═══════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════
  //  TAB 2: NGƯỜI THAM GIA (Ảnh 3 Reclub)
  // ═══════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════
  //  TAB THANH TOÁN (Dành cho Quản lý CLB)
  // ═══════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════
  //  TAB 3: TRÒ CHUYỆN (IMG4)
  // ═══════════════════════════════════════════════════════

  // ── Card Social Session inside Chat (IMG4) ──

  // ═══════════════════════════════════════════════════════
  //  BOTTOM ACTION BAR (IMG2 & IMG3)
  // ═══════════════════════════════════════════════════════
  Widget _buildBottomActionBar(
    BuildContext context,
    bool isDark,
    SocialSessionModel session,
    AppColorsExtension colors,
  ) {
    if (_isHost) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(top: BorderSide(color: colors.border, width: 1)),
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
                  onPressed: () => _handleContactHost(session),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
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
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
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

  // ── Chia sẻ vào cuộc trò chuyện Câu lạc bộ ──
  String _buildClubChatShareMessage(SocialSessionModel session) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    final feeLine = session.pricePerSlot > 0
        ? '💵 Phí: ${currencyFormatter.format(session.pricePerSlot)} / người'
        : '💵 Phí: Miễn phí';
    final timeLine =
        '⏰ ${session.dayOfWeek}, ngày ${session.dayOfMonth.toString().padLeft(2, '0')} Th${session.dateTime.month.toString().padLeft(2, '0')} lúc ${session.timeSlot}';
    return '''${session.title.toUpperCase()}
$timeLine
📍 ${session.venueName}
$feeLine
👥 ${session.currentParticipants}/${session.maxParticipants}

RSVP: https://sporto.vn/social/${session.id}''';
  }

  Future<void> _shareToClubChat(SocialSessionModel session) async {
    final communityId = session.communityId ?? session.clubId;
    if (communityId == null || communityId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Buổi Social này không thuộc Câu lạc bộ nào.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final message = _buildClubChatShareMessage(session);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get(
        '/chat/rooms',
        queryParameters: {'type': 'CLUB', 'communityId': communityId},
      );
      final raw = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      final room = raw is List
          ? (raw.isEmpty ? null : raw.first as Map<String, dynamic>)
          : (raw as Map<String, dynamic>?);
      final roomId = room?['id']?.toString();
      if (roomId == null || roomId.isEmpty) {
        throw Exception('Không tìm thấy phòng chat CLB');
      }
      await dio.post(
        '/chat/messages',
        data: {'roomId': roomId, 'messageText': message},
      );
      if (!mounted) return;
      context.push(
        '/club/$communityId/chat?name=${Uri.encodeComponent(session.hostClubName)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chia sẻ vào cuộc trò chuyện CLB'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleContactHost(SocialSessionModel session) {
    SocialContactHostSheet.show(
      context,
      session,
      onOpenChat: () =>
          _tabController.animateTo((_isHost && session.feePerSlot > 0) ? 3 : 2),
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

  void _showMoreOptions(SocialSessionModel session) {
    void comingSoon() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tính năng đang phát triển'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    SocialMoreOptionsSheet.show(
      context,
      session,
      isHost: _isHost,
      onRepeat: comingSoon,
      onEdit: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CreateSocialScreen(
          clubId: session.communityId ?? '',
          clubName: session.hostClubName,
          clubLogoUrl: session.hostClubAvatar,
          initialSession: session,
        ),
      ),
      onCancel: _cancelSession,
      onMute: comingSoon,
      onReport: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn bạn đã gửi báo cáo.'),
          behavior: SnackBarBehavior.floating,
        ),
      ),
    );
  }

  Future<void> _cancelSession() async {
    final confirmed = await SocialCancelSessionDialog.show(context);
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(socialSessionDetailProvider(widget.sessionId).notifier)
          .cancelSession();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final successColor = context.colors.success;
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Đã hủy buổi Social thành công!'),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
